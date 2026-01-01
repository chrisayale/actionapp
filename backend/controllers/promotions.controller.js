const admin = require('firebase-admin');
const db = admin.firestore();

/**
 * Helper function to convert Firestore timestamp to ISO string
 */
const convertTimestamps = (data) => {
  const result = { ...data };
  
  if (result.createdAt) {
    if (result.createdAt.toDate) {
      result.createdAt = result.createdAt.toDate().toISOString();
    } else if (result.createdAt instanceof Date) {
      result.createdAt = result.createdAt.toISOString();
    }
  }
  
  if (result.updatedAt) {
    if (result.updatedAt.toDate) {
      result.updatedAt = result.updatedAt.toDate().toISOString();
    } else if (result.updatedAt instanceof Date) {
      result.updatedAt = result.updatedAt.toISOString();
    }
  }
  
  if (result.startDate) {
    if (result.startDate.toDate) {
      result.startDate = result.startDate.toDate().toISOString();
    } else if (result.startDate instanceof Date) {
      result.startDate = result.startDate.toISOString();
    }
  }
  
  if (result.endDate) {
    if (result.endDate.toDate) {
      result.endDate = result.endDate.toDate().toISOString();
    } else if (result.endDate instanceof Date) {
      result.endDate = result.endDate.toISOString();
    }
  }
  
  return result;
};

/**
 * Create a new promotion
 * POST /api/promotions
 */
const createPromotion = async (req, res) => {
  try {
    console.log('📝 Creating promotion...');
    console.log('   User ID:', req.user?.uid);
    
    const {
      establishmentId,
      establishmentName,
      establishmentLogoUrl,
      boissonId,
      boissonName,
      boissonImageUrl,
      formule,
      imageUrl,
      startDate,
      endDate,
      isUnlimited = false,
    } = req.body;

    // Validation
    if (!establishmentId || !establishmentName || !boissonId || !boissonName || !formule) {
      return res.status(400).json({
        success: false,
        error: 'establishmentId, establishmentName, boissonId, boissonName, and formule are required',
      });
    }

    // Dates are required unless promotion is unlimited
    if (!isUnlimited && (!startDate || !endDate)) {
      return res.status(400).json({
        success: false,
        error: 'startDate and endDate are required when promotion is not unlimited',
      });
    }

    // Verify that the establishment belongs to the user
    try {
      const establishmentDoc = await db.collection('establishments').doc(establishmentId).get();
      
      if (!establishmentDoc.exists) {
        return res.status(404).json({
          success: false,
          error: 'Establishment not found',
        });
      }

      const establishmentData = establishmentDoc.data();
      if (establishmentData.userId !== req.user.uid) {
        return res.status(403).json({
          success: false,
          error: 'You do not have permission to create promotions for this establishment',
        });
      }
    } catch (error) {
      console.error('❌ Error verifying establishment:', error);
      return res.status(500).json({
        success: false,
        error: 'Failed to verify establishment',
        message: error.message,
      });
    }

    const now = admin.firestore.Timestamp.now();
    
    // Parse dates
    const startDateObj = startDate instanceof Date 
      ? admin.firestore.Timestamp.fromDate(startDate)
      : admin.firestore.Timestamp.fromDate(new Date(startDate));
    
    const endDateObj = endDate instanceof Date
      ? admin.firestore.Timestamp.fromDate(endDate)
      : admin.firestore.Timestamp.fromDate(new Date(endDate));

    // Validate date range
    if (endDateObj.toMillis() < startDateObj.toMillis()) {
      return res.status(400).json({
        success: false,
        error: 'endDate must be after startDate',
      });
    }

    const promotionData = {
      establishmentId,
      establishmentName: establishmentName.trim(),
      establishmentLogoUrl: establishmentLogoUrl || null,
      boissonId,
      boissonName: boissonName.trim(),
      boissonImageUrl: boissonImageUrl || null,
      formule: formule.trim(),
      imageUrl: imageUrl || null,
      startDate: startDateObj,
      endDate: endDateObj,
      isActive: true,
      isUnlimited: Boolean(isUnlimited),
      createdAt: now,
      updatedAt: now,
    };

    console.log('📝 Attempting to save promotion to Firestore...');
    console.log('   Collection: promotions');
    console.log('   Data keys:', Object.keys(promotionData));
    
    try {
      const docRef = await db.collection('promotions').add(promotionData);
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
        ...convertTimestamps(createdData),
      };

      console.log('✅ Promotion created successfully');
      console.log('   ID:', docRef.id);
      console.log('   Establishment:', establishmentName);

      res.status(201).json({
        success: true,
        promotion: responseData,
      });
    } catch (firestoreError) {
      console.error('❌ Firestore error:', firestoreError);
      console.error('   Error code:', firestoreError.code);
      console.error('   Error message:', firestoreError.message);
      throw firestoreError;
    }
  } catch (error) {
    console.error('\n❌ Error creating promotion:');
    console.error('   Message:', error.message);
    console.error('   Stack:', error.stack);
    res.status(500).json({
      success: false,
      error: 'Failed to create promotion',
      message: error.message,
    });
  }
};

/**
 * Get all public active promotions (for home page)
 * GET /api/promotions/public
 * No authentication required
 */
const getPublicPromotions = async (req, res) => {
  try {
    console.log('📋 Getting public promotions...');
    
    const now = admin.firestore.Timestamp.now();
    
    // Get all active promotions
    // Note: We can't use orderBy with where on different fields without a composite index
    // So we'll fetch all active promotions and sort in memory
    const activePromotionsQuery = db
      .collection('promotions')
      .where('isActive', '==', true);
    
    const snapshot = await activePromotionsQuery.get();
    
    // Filter promotions that are either unlimited or still valid
    const promotions = snapshot.docs
      .map((doc) => {
        const data = doc.data();
        return {
          id: doc.id,
          ...data,
        };
      })
      .filter((promotion) => {
        // If unlimited, always include
        if (promotion.isUnlimited === true) {
          return true;
        }
        
        // Check if endDate is in the future
        let endDate;
        if (promotion.endDate?.toDate) {
          endDate = promotion.endDate.toDate();
        } else if (promotion.endDate instanceof Date) {
          endDate = promotion.endDate;
        } else if (promotion.endDate) {
          endDate = new Date(promotion.endDate);
        } else {
          return false; // No endDate and not unlimited
        }
        
        const nowDate = new Date();
        return endDate >= nowDate;
      })
      .map((promotion) => {
        // Convert timestamps to ISO strings
        return {
          id: promotion.id,
          ...convertTimestamps(promotion),
        };
      })
      // Sort by createdAt descending (most recent first)
      .sort((a, b) => {
        const dateA = a.createdAt ? new Date(a.createdAt).getTime() : 0;
        const dateB = b.createdAt ? new Date(b.createdAt).getTime() : 0;
        return dateB - dateA; // Descending order
      });
    
    console.log(`✅ Found ${promotions.length} public active promotions`);
    
    res.json({
      success: true,
      promotions,
      count: promotions.length,
    });
  } catch (error) {
    console.error('\n❌ Error getting public promotions:');
    console.error('   Message:', error.message);
    console.error('   Stack:', error.stack);
    res.status(500).json({
      success: false,
      error: 'Failed to get public promotions',
      message: error.message,
    });
  }
};

/**
 * Get all promotions for an establishment
 * GET /api/promotions?establishmentId=xxx
 */
const getPromotions = async (req, res) => {
  try {
    const { establishmentId } = req.query;

    if (!establishmentId) {
      return res.status(400).json({
        success: false,
        error: 'establishmentId query parameter is required',
      });
    }

    // Verify that the establishment belongs to the user
    try {
      const establishmentDoc = await db.collection('establishments').doc(establishmentId).get();
      
      if (!establishmentDoc.exists) {
        return res.status(404).json({
          success: false,
          error: 'Establishment not found',
        });
      }

      const establishmentData = establishmentDoc.data();
      if (establishmentData.userId !== req.user.uid) {
        return res.status(403).json({
          success: false,
          error: 'You do not have permission to view promotions for this establishment',
        });
      }
    } catch (error) {
      console.error('❌ Error verifying establishment:', error);
      return res.status(500).json({
        success: false,
        error: 'Failed to verify establishment',
        message: error.message,
      });
    }

    const snapshot = await db
      .collection('promotions')
      .where('establishmentId', '==', establishmentId)
      .orderBy('createdAt', 'desc')
      .get();

    const promotions = snapshot.docs.map((doc) => {
      const data = doc.data();
      return {
        id: doc.id,
        ...convertTimestamps(data),
      };
    });

    res.json({
      success: true,
      promotions,
    });
  } catch (error) {
    console.error('\n❌ Error getting promotions:');
    console.error('   Message:', error.message);
    console.error('   Stack:', error.stack);
    res.status(500).json({
      success: false,
      error: 'Failed to get promotions',
      message: error.message,
    });
  }
};

/**
 * Get a single promotion by ID
 * GET /api/promotions/:id
 */
const getPromotionById = async (req, res) => {
  try {
    const { id } = req.params;

    const doc = await db.collection('promotions').doc(id).get();

    if (!doc.exists) {
      return res.status(404).json({
        success: false,
        error: 'Promotion not found',
      });
    }

    const promotionData = doc.data();

    // Verify that the promotion's establishment belongs to the user
    const establishmentDoc = await db.collection('establishments').doc(promotionData.establishmentId).get();
    
    if (!establishmentDoc.exists || establishmentDoc.data().userId !== req.user.uid) {
      return res.status(403).json({
        success: false,
        error: 'You do not have permission to view this promotion',
      });
    }

    const responseData = {
      id: doc.id,
      ...convertTimestamps(promotionData),
    };

    res.json({
      success: true,
      promotion: responseData,
    });
  } catch (error) {
    console.error('\n❌ Error getting promotion:');
    console.error('   Message:', error.message);
    console.error('   Stack:', error.stack);
    res.status(500).json({
      success: false,
      error: 'Failed to get promotion',
      message: error.message,
    });
  }
};

/**
 * Update a promotion
 * PUT /api/promotions/:id
 */
const updatePromotion = async (req, res) => {
  try {
    const { id } = req.params;
    const {
      boissonId,
      boissonName,
      boissonImageUrl,
      formule,
      imageUrl,
      startDate,
      endDate,
      isActive,
    } = req.body;

    // Get the promotion
    const promotionDoc = await db.collection('promotions').doc(id).get();

    if (!promotionDoc.exists) {
      return res.status(404).json({
        success: false,
        error: 'Promotion not found',
      });
    }

    const promotionData = promotionDoc.data();

    // Verify that the promotion's establishment belongs to the user
    const establishmentDoc = await db.collection('establishments').doc(promotionData.establishmentId).get();
    
    if (!establishmentDoc.exists || establishmentDoc.data().userId !== req.user.uid) {
      return res.status(403).json({
        success: false,
        error: 'You do not have permission to update this promotion',
      });
    }

    // Build update data
    const updateData = {
      updatedAt: admin.firestore.Timestamp.now(),
    };

    if (boissonId !== undefined) updateData.boissonId = boissonId;
    if (boissonName !== undefined) updateData.boissonName = boissonName.trim();
    if (boissonImageUrl !== undefined) updateData.boissonImageUrl = boissonImageUrl || null;
    if (formule !== undefined) updateData.formule = formule.trim();
    if (imageUrl !== undefined) updateData.imageUrl = imageUrl || null;
    if (isActive !== undefined) updateData.isActive = isActive;

    // Handle dates
    if (startDate !== undefined) {
      updateData.startDate = startDate instanceof Date
        ? admin.firestore.Timestamp.fromDate(startDate)
        : admin.firestore.Timestamp.fromDate(new Date(startDate));
    }

    if (endDate !== undefined) {
      updateData.endDate = endDate instanceof Date
        ? admin.firestore.Timestamp.fromDate(endDate)
        : admin.firestore.Timestamp.fromDate(new Date(endDate));
    }

    // Validate date range if both dates are being updated
    if (updateData.startDate && updateData.endDate) {
      if (updateData.endDate.toMillis() < updateData.startDate.toMillis()) {
        return res.status(400).json({
          success: false,
          error: 'endDate must be after startDate',
        });
      }
    } else if (updateData.endDate && promotionData.startDate) {
      const startDateObj = promotionData.startDate.toDate ? promotionData.startDate.toDate() : new Date(promotionData.startDate);
      const endDateObj = updateData.endDate.toDate ? updateData.endDate.toDate() : new Date(updateData.endDate);
      if (endDateObj < startDateObj) {
        return res.status(400).json({
          success: false,
          error: 'endDate must be after startDate',
        });
      }
    } else if (updateData.startDate && promotionData.endDate) {
      const startDateObj = updateData.startDate.toDate ? updateData.startDate.toDate() : new Date(updateData.startDate);
      const endDateObj = promotionData.endDate.toDate ? promotionData.endDate.toDate() : new Date(promotionData.endDate);
      if (endDateObj < startDateObj) {
        return res.status(400).json({
          success: false,
          error: 'endDate must be after startDate',
        });
      }
    }

    await db.collection('promotions').doc(id).update(updateData);

    // Get updated document
    const updatedDoc = await db.collection('promotions').doc(id).get();
    const updatedData = updatedDoc.data();

    const responseData = {
      id: updatedDoc.id,
      ...convertTimestamps(updatedData),
    };

    res.json({
      success: true,
      promotion: responseData,
    });
  } catch (error) {
    console.error('\n❌ Error updating promotion:');
    console.error('   Message:', error.message);
    console.error('   Stack:', error.stack);
    res.status(500).json({
      success: false,
      error: 'Failed to update promotion',
      message: error.message,
    });
  }
};

/**
 * Delete a promotion
 * DELETE /api/promotions/:id
 */
const deletePromotion = async (req, res) => {
  try {
    const { id } = req.params;

    // Get the promotion
    const promotionDoc = await db.collection('promotions').doc(id).get();

    if (!promotionDoc.exists) {
      return res.status(404).json({
        success: false,
        error: 'Promotion not found',
      });
    }

    const promotionData = promotionDoc.data();

    // Verify that the promotion's establishment belongs to the user
    const establishmentDoc = await db.collection('establishments').doc(promotionData.establishmentId).get();
    
    if (!establishmentDoc.exists || establishmentDoc.data().userId !== req.user.uid) {
      return res.status(403).json({
        success: false,
        error: 'You do not have permission to delete this promotion',
      });
    }

    await db.collection('promotions').doc(id).delete();

    res.json({
      success: true,
      message: 'Promotion deleted successfully',
    });
  } catch (error) {
    console.error('\n❌ Error deleting promotion:');
    console.error('   Message:', error.message);
    console.error('   Stack:', error.stack);
    res.status(500).json({
      success: false,
      error: 'Failed to delete promotion',
      message: error.message,
    });
  }
};

/**
 * Toggle promotion active status
 * PATCH /api/promotions/:id/toggle-active
 */
const toggleActive = async (req, res) => {
  try {
    const { id } = req.params;

    // Get the promotion
    const promotionDoc = await db.collection('promotions').doc(id).get();

    if (!promotionDoc.exists) {
      return res.status(404).json({
        success: false,
        error: 'Promotion not found',
      });
    }

    const promotionData = promotionDoc.data();

    // Verify that the promotion's establishment belongs to the user
    const establishmentDoc = await db.collection('establishments').doc(promotionData.establishmentId).get();
    
    if (!establishmentDoc.exists || establishmentDoc.data().userId !== req.user.uid) {
      return res.status(403).json({
        success: false,
        error: 'You do not have permission to modify this promotion',
      });
    }

    const newActiveStatus = !promotionData.isActive;

    await db.collection('promotions').doc(id).update({
      isActive: newActiveStatus,
      updatedAt: admin.firestore.Timestamp.now(),
    });

    // Get updated document
    const updatedDoc = await db.collection('promotions').doc(id).get();
    const updatedData = updatedDoc.data();

    const responseData = {
      id: updatedDoc.id,
      ...convertTimestamps(updatedData),
    };

    res.json({
      success: true,
      promotion: responseData,
    });
  } catch (error) {
    console.error('\n❌ Error toggling promotion active status:');
    console.error('   Message:', error.message);
    console.error('   Stack:', error.stack);
    res.status(500).json({
      success: false,
      error: 'Failed to toggle promotion active status',
      message: error.message,
    });
  }
};

/**
 * Continue promotion (make it unlimited)
 * PATCH /api/promotions/:id/continue
 */
const continuePromotion = async (req, res) => {
  try {
    const { id } = req.params;

    // Get the promotion
    const promotionDoc = await db.collection('promotions').doc(id).get();

    if (!promotionDoc.exists) {
      return res.status(404).json({
        success: false,
        error: 'Promotion not found',
      });
    }

    const promotionData = promotionDoc.data();

    // Verify that the promotion's establishment belongs to the user
    const establishmentDoc = await db.collection('establishments').doc(promotionData.establishmentId).get();
    
    if (!establishmentDoc.exists || establishmentDoc.data().userId !== req.user.uid) {
      return res.status(403).json({
        success: false,
        error: 'You do not have permission to modify this promotion',
      });
    }

    await db.collection('promotions').doc(id).update({
      isUnlimited: true,
      isActive: true, // Ensure it's active when continuing
      updatedAt: admin.firestore.Timestamp.now(),
    });

    // Get updated document
    const updatedDoc = await db.collection('promotions').doc(id).get();
    const updatedData = updatedDoc.data();

    const responseData = {
      id: updatedDoc.id,
      ...convertTimestamps(updatedData),
    };

    res.json({
      success: true,
      promotion: responseData,
    });
  } catch (error) {
    console.error('\n❌ Error continuing promotion:');
    console.error('   Message:', error.message);
    console.error('   Stack:', error.stack);
    res.status(500).json({
      success: false,
      error: 'Failed to continue promotion',
      message: error.message,
    });
  }
};

module.exports = {
  createPromotion,
  getPublicPromotions,
  getPromotions,
  getPromotionById,
  updatePromotion,
  deletePromotion,
  toggleActive,
  continuePromotion,
};



