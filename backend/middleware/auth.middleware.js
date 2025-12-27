const admin = require('firebase-admin');

/**
 * Middleware to verify Firebase ID token
 * Adds req.user with decoded token data
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
    
    const decodedToken = await admin.auth().verifyIdToken(token);
    
    // Add user info to request object
    req.user = {
      uid: decodedToken.uid,
      phone: decodedToken.phone_number,
      email: decodedToken.email,
      emailVerified: decodedToken.email_verified,
      phoneVerified: decodedToken.phone_number ? true : false,
    };
    
    next();
  } catch (error) {
    console.error('Token verification error:', error);
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

module.exports = {
  verifyToken,
  optionalVerifyToken,
};
