const admin = require('firebase-admin');
const firebaseService = require('../services/firebase.service');

/**
 * Verify Firebase ID Token and return user info
 * POST /api/auth/verify-token
 */
const verifyToken = async (req, res) => {
  try {
    const token = req.headers.authorization?.replace('Bearer ', '');
    
    if (!token) {
      return res.status(401).json({ 
        success: false,
        error: 'No token provided' 
      });
    }
    
    const decodedToken = await admin.auth().verifyIdToken(token);
    
    res.json({ 
      success: true,
      uid: decodedToken.uid,
      phone: decodedToken.phone_number,
      email: decodedToken.email,
    });
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
 * Create or update user profile after OTP verification
 * POST /api/auth/create-profile
 * Body: { token: string, phoneNumber: string, displayName?: string }
 */
const createProfile = async (req, res) => {
  try {
    const { token, phoneNumber, displayName } = req.body;
    
    if (!token) {
      return res.status(401).json({ 
        success: false,
        error: 'Token is required' 
      });
    }
    
    // Verify the Firebase ID token
    const decodedToken = await admin.auth().verifyIdToken(token);
    const uid = decodedToken.uid;
    
    // Check if user already exists in Firestore
    const userDoc = await admin.firestore().collection('users').doc(uid).get();
    
    const userData = {
      phoneNumber: phoneNumber || decodedToken.phone_number,
      displayName: displayName || null,
      email: decodedToken.email || null,
      createdAt: userDoc.exists 
        ? userDoc.data().createdAt 
        : admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      lastLoginAt: admin.firestore.FieldValue.serverTimestamp(),
    };
    
    // Create or update user profile
    await admin.firestore().collection('users').doc(uid).set(userData, { merge: true });
    
    // Get the created/updated user data
    const updatedUserDoc = await admin.firestore().collection('users').doc(uid).get();
    
    res.json({ 
      success: true,
      user: {
        id: uid,
        ...updatedUserDoc.data()
      }
    });
  } catch (error) {
    console.error('Create profile error:', error);
    res.status(500).json({ 
      success: false,
      error: 'Failed to create profile',
      message: error.message 
    });
  }
};

/**
 * Get user profile
 * GET /api/auth/profile
 * Headers: Authorization: Bearer <token>
 */
const getProfile = async (req, res) => {
  try {
    const token = req.headers.authorization?.replace('Bearer ', '');
    
    if (!token) {
      return res.status(401).json({ 
        success: false,
        error: 'No token provided' 
      });
    }
    
    const decodedToken = await admin.auth().verifyIdToken(token);
    const uid = decodedToken.uid;
    
    const userDoc = await admin.firestore().collection('users').doc(uid).get();
    
    if (!userDoc.exists) {
      return res.status(404).json({ 
        success: false,
        error: 'User profile not found' 
      });
    }
    
    res.json({ 
      success: true,
      user: {
        id: uid,
        ...userDoc.data()
      }
    });
  } catch (error) {
    console.error('Get profile error:', error);
    res.status(401).json({ 
      success: false,
      error: 'Invalid token',
      message: error.message 
    });
  }
};

/**
 * Update user profile
 * PUT /api/auth/profile
 * Headers: Authorization: Bearer <token>
 * Body: { displayName?: string, ... }
 */
const updateProfile = async (req, res) => {
  try {
    const token = req.headers.authorization?.replace('Bearer ', '');
    
    if (!token) {
      return res.status(401).json({ 
        success: false,
        error: 'No token provided' 
      });
    }
    
    const decodedToken = await admin.auth().verifyIdToken(token);
    const uid = decodedToken.uid;
    
    const updateData = {
      ...req.body,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };
    
    // Remove fields that shouldn't be updated directly
    delete updateData.id;
    delete updateData.createdAt;
    
    await admin.firestore().collection('users').doc(uid).update(updateData);
    
    const updatedUserDoc = await admin.firestore().collection('users').doc(uid).get();
    
    res.json({ 
      success: true,
      user: {
        id: uid,
        ...updatedUserDoc.data()
      }
    });
  } catch (error) {
    console.error('Update profile error:', error);
    res.status(500).json({ 
      success: false,
      error: 'Failed to update profile',
      message: error.message 
    });
  }
};

/**
 * Login with email/password (for admin/web)
 * POST /api/auth/login
 */
const login = async (req, res) => {
  try {
    const { email, password } = req.body;
    
    if (!email || !password) {
      return res.status(400).json({ 
        success: false,
        error: 'Email and password are required' 
      });
    }
    
    // Note: Firebase Admin SDK doesn't support email/password authentication directly
    // This should be done client-side with Firebase Auth SDK
    // This endpoint is kept for API consistency but should return appropriate message
    
    res.status(501).json({ 
      success: false,
      error: 'Email/password login should be done client-side with Firebase Auth SDK',
      message: 'Use Firebase Auth SDK on client to sign in, then send the ID token to verify-token endpoint'
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ 
      success: false,
      error: error.message 
    });
  }
};

/**
 * Register with email/password (for admin/web)
 * POST /api/auth/register
 */
const register = async (req, res) => {
  try {
    const { email, password, name } = req.body;
    
    if (!email || !password) {
      return res.status(400).json({ 
        success: false,
        error: 'Email and password are required' 
      });
    }
    
    // Note: Firebase Admin SDK can create users, but authentication should be client-side
    // This endpoint creates a user account but password auth must be done client-side
    
    const userRecord = await admin.auth().createUser({
      email,
      password,
      displayName: name,
    });
    
    // Create user profile in Firestore
    await admin.firestore().collection('users').doc(userRecord.uid).set({
      email,
      displayName: name,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    
    res.json({ 
      success: true,
      message: 'User created successfully',
      uid: userRecord.uid 
    });
  } catch (error) {
    console.error('Register error:', error);
    res.status(500).json({ 
      success: false,
      error: 'Registration failed',
      message: error.message 
    });
  }
};

/**
 * Logout (client-side operation, this just logs the action)
 * POST /api/auth/logout
 */
const logout = async (req, res) => {
  try {
    // Logout is handled client-side by Firebase Auth SDK
    // This endpoint just confirms the logout action
    res.json({ 
      success: true,
      message: 'Logout successful' 
    });
  } catch (error) {
    console.error('Logout error:', error);
    res.status(500).json({ 
      success: false,
      error: error.message 
    });
  }
};

/**
 * Check if phone number exists
 * GET /api/auth/check-phone?phoneNumber=+1234567890
 */
const checkPhone = async (req, res) => {
  try {
    const { phoneNumber } = req.query;
    
    if (!phoneNumber) {
      return res.status(400).json({ 
        success: false,
        error: 'Phone number is required' 
      });
    }
    
    // Note: Firebase Admin SDK doesn't have a direct way to check if a phone number exists
    // This would require querying Firestore or using Firebase Auth REST API
    // For now, we'll check in Firestore
    
    const usersSnapshot = await admin.firestore()
      .collection('users')
      .where('phoneNumber', '==', phoneNumber)
      .limit(1)
      .get();
    
    const exists = !usersSnapshot.empty;
    
    res.json({ 
      success: true,
      exists,
      phoneNumber 
    });
  } catch (error) {
    console.error('Check phone error:', error);
    res.status(500).json({ 
      success: false,
      error: 'Failed to check phone number',
      message: error.message 
    });
  }
};

module.exports = {
  verifyToken,
  createProfile,
  getProfile,
  updateProfile,
  login,
  register,
  logout,
  checkPhone,
};
