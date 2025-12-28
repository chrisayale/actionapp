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
 * Body: { 
 *   token: string, 
 *   phoneNumber?: string,
 *   displayName?: string,
 *   gender?: 'M' | 'F',
 *   dateOfBirth?: string (ISO 8601),
 *   photoUrl?: string,
 *   pin?: string (4 digits),
 * }
 */
const createProfile = async (req, res) => {
  try {
    const { 
      token, 
      phoneNumber, 
      displayName, 
      gender, 
      dateOfBirth, 
      photoUrl,
      pin 
    } = req.body;
    
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
    
    // Validate PIN if provided (must be 4 digits)
    if (pin !== undefined && pin !== null && pin !== '') {
      if (!/^\d{4}$/.test(pin)) {
        return res.status(400).json({
          success: false,
          error: 'PIN must be exactly 4 digits'
        });
      }
    }
    
    // Validate gender if provided
    if (gender !== undefined && gender !== null && gender !== '') {
      if (!['M', 'F'].includes(gender)) {
        return res.status(400).json({
          success: false,
          error: 'Gender must be "M" or "F"'
        });
      }
    }
    
    // Validate date of birth if provided
    let validatedDateOfBirth = null;
    if (dateOfBirth !== undefined && dateOfBirth !== null && dateOfBirth !== '') {
      const date = new Date(dateOfBirth);
      if (isNaN(date.getTime())) {
        return res.status(400).json({
          success: false,
          error: 'Invalid date of birth format. Use ISO 8601 format (YYYY-MM-DD)'
        });
      }
      // Ensure user is at least 13 years old
      const minDate = new Date();
      minDate.setFullYear(minDate.getFullYear() - 13);
      if (date > minDate) {
        return res.status(400).json({
          success: false,
          error: 'User must be at least 13 years old'
        });
      }
      validatedDateOfBirth = date.toISOString();
    }
    
    // Hash PIN if provided (simple hash for now, consider bcrypt for production)
    let hashedPin = null;
    if (pin !== undefined && pin !== null && pin !== '') {
      // For now, we'll store a simple hash. In production, use bcrypt
      const crypto = require('crypto');
      hashedPin = crypto.createHash('sha256').update(pin).digest('hex');
    }
    
    // Determine if profile is complete
    // Profile is complete if: PIN, gender, and dateOfBirth are all provided
    const profileComplete = !!(pin && gender && validatedDateOfBirth);
    
    const userData = {
      phoneNumber: phoneNumber || decodedToken.phone_number || null,
      displayName: displayName || null,
      gender: gender || null,
      dateOfBirth: validatedDateOfBirth,
      photoUrl: photoUrl || null,
      pin: hashedPin, // Store hashed PIN (null if not provided)
      profileComplete,
      email: decodedToken.email || null,
      createdAt: userDoc.exists 
        ? userDoc.data().createdAt 
        : admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      lastLoginAt: admin.firestore.FieldValue.serverTimestamp(),
    };
    
    // Remove null values for cleaner data
    Object.keys(userData).forEach(key => {
      if (userData[key] === null) {
        delete userData[key];
      }
    });
    
    // Create or update user profile
    await admin.firestore().collection('users').doc(uid).set(userData, { merge: true });
    
    // Update Firebase Auth displayName and photoURL if provided
    const authUpdateData = {};
    if (displayName) {
      authUpdateData.displayName = displayName;
    }
    if (photoUrl) {
      authUpdateData.photoURL = photoUrl;
    }
    
    if (Object.keys(authUpdateData).length > 0) {
      await admin.auth().updateUser(uid, authUpdateData);
    }
    
    // Get the created/updated user data
    const updatedUserDoc = await admin.firestore().collection('users').doc(uid).get();
    const userDataResponse = updatedUserDoc.data();
    
    // Don't return PIN in response
    if (userDataResponse.pin) {
      delete userDataResponse.pin;
    }
    
    res.json({ 
      success: true,
      user: {
        id: uid,
        ...userDataResponse
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
 * Body: { 
 *   displayName?: string,
 *   gender?: 'M' | 'F',
 *   dateOfBirth?: string (ISO 8601),
 *   photoUrl?: string,
 *   pin?: string (4 digits),
 * }
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
    
    const { 
      displayName, 
      gender, 
      dateOfBirth, 
      photoUrl,
      pin 
    } = req.body;
    
    // Get existing user data
    const userDoc = await admin.firestore().collection('users').doc(uid).get();
    const existingData = userDoc.exists ? userDoc.data() : {};
    
    const updateData = {
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };
    
    // Update displayName if provided
    if (displayName !== undefined) {
      updateData.displayName = displayName || null;
    }
    
    // Update gender if provided
    if (gender !== undefined) {
      if (gender && !['M', 'F'].includes(gender)) {
        return res.status(400).json({
          success: false,
          error: 'Gender must be "M" or "F"'
        });
      }
      updateData.gender = gender || null;
    }
    
    // Update date of birth if provided
    if (dateOfBirth !== undefined) {
      if (dateOfBirth && dateOfBirth !== '') {
        const date = new Date(dateOfBirth);
        if (isNaN(date.getTime())) {
          return res.status(400).json({
            success: false,
            error: 'Invalid date of birth format. Use ISO 8601 format (YYYY-MM-DD)'
          });
        }
        // Ensure user is at least 13 years old
        const minDate = new Date();
        minDate.setFullYear(minDate.getFullYear() - 13);
        if (date > minDate) {
          return res.status(400).json({
            success: false,
            error: 'User must be at least 13 years old'
          });
        }
        updateData.dateOfBirth = date.toISOString();
      } else {
        updateData.dateOfBirth = null;
      }
    }
    
    // Update photo URL if provided
    if (photoUrl !== undefined) {
      updateData.photoUrl = photoUrl || null;
    }
    
    // Update PIN if provided
    if (pin !== undefined) {
      if (pin && pin !== '') {
        if (!/^\d{4}$/.test(pin)) {
          return res.status(400).json({
            success: false,
            error: 'PIN must be exactly 4 digits'
          });
        }
        // Hash PIN
        const crypto = require('crypto');
        updateData.pin = crypto.createHash('sha256').update(pin).digest('hex');
      } else {
        updateData.pin = null;
      }
    }
    
    // Determine if profile is complete
    const finalData = { ...existingData, ...updateData };
    const profileComplete = !!(
      finalData.pin && 
      finalData.gender && 
      finalData.dateOfBirth
    );
    updateData.profileComplete = profileComplete;
    
    // Remove null values
    Object.keys(updateData).forEach(key => {
      if (updateData[key] === null && key !== 'displayName' && key !== 'gender' && key !== 'dateOfBirth' && key !== 'photoUrl') {
        delete updateData[key];
      }
    });
    
    // Remove fields that shouldn't be updated directly
    delete updateData.id;
    delete updateData.createdAt;
    
    await admin.firestore().collection('users').doc(uid).update(updateData);
    
    // Update Firebase Auth displayName and photoURL if provided
    const authUpdateData = {};
    if (displayName !== undefined) {
      authUpdateData.displayName = displayName || null;
    }
    if (photoUrl !== undefined) {
      authUpdateData.photoURL = photoUrl || null;
    }
    
    if (Object.keys(authUpdateData).length > 0) {
      await admin.auth().updateUser(uid, authUpdateData);
    }
    
    // Get the updated user data
    const updatedUserDoc = await admin.firestore().collection('users').doc(uid).get();
    const userDataResponse = updatedUserDoc.data();
    
    // Don't return PIN in response
    if (userDataResponse.pin) {
      delete userDataResponse.pin;
    }
    
    res.json({ 
      success: true,
      user: {
        id: uid,
        ...userDataResponse
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
