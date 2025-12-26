const admin = require('firebase-admin');

class FirebaseService {
  constructor() {
    this.db = admin.firestore();
    this.auth = admin.auth();
  }

  // User operations
  async createUser(userData) {
    const userRef = await this.db.collection('users').add({
      ...userData,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    return userRef.id;
  }

  async getUserById(userId) {
    const userDoc = await this.db.collection('users').doc(userId).get();
    if (!userDoc.exists) {
      throw new Error('User not found');
    }
    return { id: userDoc.id, ...userDoc.data() };
  }

  // Order operations
  async createOrder(orderData) {
    const orderRef = await this.db.collection('orders').add({
      ...orderData,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    return orderRef.id;
  }

  async getOrderById(orderId) {
    const orderDoc = await this.db.collection('orders').doc(orderId).get();
    if (!orderDoc.exists) {
      throw new Error('Order not found');
    }
    return { id: orderDoc.id, ...orderDoc.data() };
  }
}

module.exports = new FirebaseService();

