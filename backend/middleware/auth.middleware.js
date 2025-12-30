const admin = require('firebase-admin');

/**
 * Decode JWT token without verification (for emulator tokens)
 */
function decodeJWT(token) {
  try {
    const parts = token.split('.');
    if (parts.length !== 3) {
      return null;
    }
    const payload = parts[1];
    const decoded = Buffer.from(payload, 'base64').toString('utf-8');
    return JSON.parse(decoded);
  } catch (error) {
    return null;
  }
}

/**
 * Middleware to verify Firebase ID token
 * Adds req.user with decoded token data
 * Supports both production tokens and emulator tokens
 */
const verifyToken = async (req, res, next) => {
  try {
    const token = req.headers.authorization?.replace('Bearer ', '');
    
    if (!token) {
      return res.status(401).json({ 
        success: false,
        error: 'No token provided' 
      });
    }
    
    // Try to verify as a real Firebase token first
    try {
      const decodedToken = await admin.auth().verifyIdToken(token);
      
      // Add user info to request object
      req.user = {
        uid: decodedToken.uid,
        phone: decodedToken.phone_number,
        email: decodedToken.email,
        emailVerified: decodedToken.email_verified,
        phoneVerified: decodedToken.phone_number ? true : false,
      };
      
      return next();
    } catch (verifyError) {
      // If verification fails with "kid" claim error, it's likely an emulator token
      if (verifyError.code === 'auth/argument-error' && verifyError.message.includes('kid')) {
        console.log('⚠️ Emulator token detected, decoding without verification...');
        
        // Decode the JWT token without verification to extract user info
        const decoded = decodeJWT(token);
        
        if (decoded && decoded.user_id) {
          // Extract user info from decoded token
          const uid = decoded.user_id;
          
          console.log('✅ Extracted UID from emulator token:', uid);
          
          // For emulator tokens, use info from decoded token directly
          // We don't need to call admin.auth().getUser() which requires production Firebase
          req.user = {
            uid: uid,
            phone: decoded.phone_number || null,
            email: decoded.email || null,
            emailVerified: decoded.email_verified || false,
            phoneVerified: decoded.phone_number ? true : false,
          };
          
          console.log('✅ User set from emulator token:', req.user.uid);
          return next();
        } else {
          console.error('❌ Could not decode emulator token');
          return res.status(401).json({
            success: false,
            error: 'Invalid emulator token format',
            message: 'Could not extract user information from token'
          });
        }
      }
      
      // For other errors, throw them
      throw verifyError;
    }
  } catch (error) {
    console.error('\n❌ Token verification error:');
    console.error('   Message:', error.message);
    console.error('   Code:', error.code);
    console.error('   Stack:', error.stack);
    res.status(401).json({ 
      success: false,
      error: 'Invalid token',
      message: error.message 
    });
  }
};

/**
 * Optional token verification - doesn't fail if no token
 * Adds req.user only if token is valid
 */
const optionalVerifyToken = async (req, res, next) => {
  try {
    const token = req.headers.authorization?.replace('Bearer ', '');
    
    if (token) {
      try {
        const decodedToken = await admin.auth().verifyIdToken(token);
        req.user = {
          uid: decodedToken.uid,
          phone: decodedToken.phone_number,
          email: decodedToken.email,
          emailVerified: decodedToken.email_verified,
          phoneVerified: decodedToken.phone_number ? true : false,
        };
      } catch (error) {
        // Invalid token, but continue without req.user
        console.warn('Invalid token in optional verification:', error.message);
      }
    }
    
    next();
  } catch (error) {
    // Continue even if there's an error
    next();
  }
};

// Alias for backward compatibility
const authenticateToken = verifyToken;

module.exports = {
  verifyToken,
  authenticateToken,
  optionalVerifyToken,
};
