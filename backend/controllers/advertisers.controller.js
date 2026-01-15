const admin = require('firebase-admin');
const db = admin.firestore();

/**
 * Create a new advertiser establishment
 * POST /api/advertisers
 */
const createEstablishment = async (req, res) => {
  try {
    console.log('📝 Creating establishment...');
    console.log('   User ID:', req.user?.uid);
    const {
      type,
      name,
      logoUrl,
      enseigneUrl,
      documentUrl,
      location,
    } = req.body;

    // Handle both formats: direct fields or nested location object
    const ville = location?.ville || req.body.ville;
    const quartier = location?.quartier || req.body.quartier;
    const avenue = location?.avenue || req.body.avenue;
    const numero = location?.numero || req.body.numero;
    const latitude = location?.latitude ?? req.body.latitude;
    const longitude = location?.longitude ?? req.body.longitude;

    // Validation
    if (!type || !name || !logoUrl || !enseigneUrl) {
      return res.status(400).json({
        success: false,
        error: 'Type, name, logoUrl, and enseigneUrl are required',
      });
    }

    if (!ville || !quartier || !avenue || !numero || latitude == null || longitude == null) {
      return res.status(400).json({
        success: false,
        error: 'All location fields are required (ville, quartier, avenue, numero, latitude, longitude)',
      });
    }

    const now = admin.firestore.Timestamp.now();
    
    const establishmentData = {
      userId: req.user.uid,
      type,
      name: name.trim(),
      logoUrl,
      enseigneUrl,
      documentUrl: documentUrl || null,
      location: {
        ville: ville.trim(),
        quartier: quartier.trim(),
        avenue: avenue.trim(),
        numero: numero.trim(),
        latitude,
        longitude,
      },
      isActive: true,
      createdAt: now,
      updatedAt: now,
    };

    console.log('📝 Attempting to save establishment to Firestore...');
    console.log('   Collection: establishments');
    console.log('   Data keys:', Object.keys(establishmentData));
    if (process.env.FIRESTORE_EMULATOR_HOST) {
      console.log('   ⚠️  Firestore Emulator Host:', process.env.FIRESTORE_EMULATOR_HOST);
      console.log('   ⚠️  MODE EMULATOR - Les données ne seront PAS enregistrées dans Firebase en ligne');
    } else {
      console.log('   ✅ Firebase Production - Les données seront enregistrées directement dans Firebase en ligne');
    }
    
    try {
      const docRef = await db.collection('establishments').add(establishmentData);
      console.log('✅ Document reference created:', docRef.id);

      // Get the created document to return complete data
      const createdDoc = await docRef.get();
      if (!createdDoc.exists) {
        throw new Error('Document was not created successfully');
      }
      
      const createdData = createdDoc.data();
      console.log('✅ Document retrieved successfully');

      // Convert timestamps to ISO strings for JSON response
      const responseData = {
        id: docRef.id,
        ...createdData,
      };
      
      if (createdData.createdAt) {
        if (createdData.createdAt.toDate) {
          responseData.createdAt = createdData.createdAt.toDate().toISOString();
        } else if (createdData.createdAt instanceof Date) {
          responseData.createdAt = createdData.createdAt.toISOString();
        }
      }
      
      if (createdData.updatedAt) {
        if (createdData.updatedAt.toDate) {
          responseData.updatedAt = createdData.updatedAt.toDate().toISOString();
        } else if (createdData.updatedAt instanceof Date) {
          responseData.updatedAt = createdData.updatedAt.toISOString();
        }
      }

      console.log('✅ Establishment created successfully');
      console.log('   ID:', docRef.id);
      console.log('   Name:', establishmentData.name);

      res.status(201).json({
        success: true,
        establishment: responseData,
      });
    } catch (firestoreError) {
      console.error('❌ Firestore error:', firestoreError);
      console.error('   Error code:', firestoreError.code);
      console.error('   Error message:', firestoreError.message);
      throw firestoreError;
    }
  } catch (error) {
    console.error('\n❌ Error creating establishment:');
    console.error('   Message:', error.message);
    console.error('   Stack:', error.stack);
    res.status(500).json({
      success: false,
      error: 'Failed to create establishment',
      message: error.message,
    });
  }
};

/**
 * Get all establishments for the authenticated user
 * GET /api/advertisers
 */
const getEstablishments = async (req, res) => {
  try {
    const userId = req.user.uid;

    const snapshot = await db
      .collection('establishments')
      .where('userId', '==', userId)
      .orderBy('createdAt', 'desc')
      .get();

    const establishments = snapshot.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
    }));

    res.json({
      success: true,
      establishments,
    });
  } catch (error) {
    console.error('\n❌ Error getting establishments:');
    console.error('   Message:', error.message);
    console.error('   Stack:', error.stack);
    res.status(500).json({
      success: false,
      error: 'Failed to get establishments',
      message: error.message,
    });
  }
};

/**
 * Get a single establishment by ID
 * GET /api/advertisers/:id
 */
const getEstablishmentById = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.uid;

    const doc = await db.collection('establishments').doc(id).get();

    if (!doc.exists) {
      return res.status(404).json({
        success: false,
        error: 'Establishment not found',
      });
    }

    const data = doc.data();

    // Verify the establishment belongs to the user
    if (data.userId !== userId) {
      return res.status(403).json({
        success: false,
        error: 'Access denied',
      });
    }

    res.json({
      success: true,
      establishment: {
        id: doc.id,
        ...data,
      },
    });
  } catch (error) {
    console.error('Error getting establishment:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to get establishment',
      message: error.message,
    });
  }
};

/**
 * Update an establishment
 * PUT /api/advertisers/:id
 */
const updateEstablishment = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.uid;
    const {
      type,
      name,
      logoUrl,
      enseigneUrl,
      documentUrl,
      ville,
      quartier,
      avenue,
      numero,
      latitude,
      longitude,
      isActive,
    } = req.body;

    const docRef = db.collection('establishments').doc(id);
    const doc = await docRef.get();

    if (!doc.exists) {
      return res.status(404).json({
        success: false,
        error: 'Establishment not found',
      });
    }

    const data = doc.data();

    // Verify the establishment belongs to the user
    if (data.userId !== userId) {
      return res.status(403).json({
        success: false,
        error: 'Access denied',
      });
    }

    const updateData = {
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    if (type !== undefined) updateData.type = type;
    if (name !== undefined) updateData.name = name.trim();
    if (logoUrl !== undefined) updateData.logoUrl = logoUrl;
    if (enseigneUrl !== undefined) updateData.enseigneUrl = enseigneUrl;
    if (documentUrl !== undefined) updateData.documentUrl = documentUrl;
    if (isActive !== undefined) updateData.isActive = isActive;

    if (ville !== undefined || quartier !== undefined || avenue !== undefined || 
        numero !== undefined || latitude !== undefined || longitude !== undefined) {
      updateData.location = {
        ...(data.location || {}),
        ...(ville !== undefined && { ville: ville.trim() }),
        ...(quartier !== undefined && { quartier: quartier.trim() }),
        ...(avenue !== undefined && { avenue: avenue.trim() }),
        ...(numero !== undefined && { numero: numero.trim() }),
        ...(latitude !== undefined && { latitude }),
        ...(longitude !== undefined && { longitude }),
      };
    }

    await docRef.update(updateData);

    const updatedDoc = await docRef.get();

    res.json({
      success: true,
      establishment: {
        id: updatedDoc.id,
        ...updatedDoc.data(),
      },
    });
  } catch (error) {
    console.error('Error updating establishment:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to update establishment',
      message: error.message,
    });
  }
};

/**
 * Delete an establishment
 * DELETE /api/advertisers/:id
 */
const deleteEstablishment = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.uid;

    const docRef = db.collection('establishments').doc(id);
    const doc = await docRef.get();

    if (!doc.exists) {
      return res.status(404).json({
        success: false,
        error: 'Establishment not found',
      });
    }

    const data = doc.data();

    // Verify the establishment belongs to the user
    if (data.userId !== userId) {
      return res.status(403).json({
        success: false,
        error: 'Access denied',
      });
    }

    await docRef.delete();

    res.json({
      success: true,
      message: 'Establishment deleted successfully',
    });
  } catch (error) {
    console.error('Error deleting establishment:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to delete establishment',
      message: error.message,
    });
  }
};

module.exports = {
  createEstablishment,
  getEstablishments,
  getEstablishmentById,
  updateEstablishment,
  deleteEstablishment,
};

