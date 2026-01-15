const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const admin = require('firebase-admin');

// Load environment variables
dotenv.config();

// Initialize Firebase Admin
// By default, use production Firebase (not emulators)
// To use emulators, explicitly set FIRESTORE_EMULATOR_HOST in .env
const useEmulators = process.env.FIRESTORE_EMULATOR_HOST && process.env.FIRESTORE_EMULATOR_HOST !== '';

if (useEmulators) {
  // Use emulators - minimal config needed (only if explicitly configured)
  console.log('⚠️  MODE EMULATOR ACTIVÉ (développement local uniquement)');
  console.log(`   Firestore Emulator: ${process.env.FIRESTORE_EMULATOR_HOST}`);
  console.log('   ⚠️  Les données seront enregistrées dans les emulators, pas dans Firebase en ligne');
  
  if (!process.env.FIREBASE_PROJECT_ID) {
    process.env.FIREBASE_PROJECT_ID = 'demo-project';
  }
  
  try {
    admin.initializeApp({
      projectId: process.env.FIREBASE_PROJECT_ID,
    });
    console.log('✅ Firebase Admin SDK initialisé avec les emulators');
    console.log(`   Project ID: ${process.env.FIREBASE_PROJECT_ID}`);
  } catch (error) {
    // If already initialized, that's okay
    if (error.code !== 'app/already-initialized') {
      console.error('\n❌ ERREUR lors de l\'initialisation de Firebase Admin:', error.message);
      throw error;
    }
    console.log('✅ Firebase Admin SDK déjà initialisé');
  }
} else if (!process.env.FIREBASE_PROJECT_ID || !process.env.FIREBASE_CLIENT_EMAIL || !process.env.FIREBASE_PRIVATE_KEY) {
  console.error('\n❌ ERREUR: Fichier .env manquant ou incomplet!\n');
  console.log('📋 Pour résoudre ce problème:');
  console.log('');
  console.log('1. Créez un fichier .env dans le dossier backend/');
  console.log('2. Utilisez env.example.txt comme référence pour créer votre .env');
  console.log('');
  console.log('3. Remplissez les valeurs dans .env avec vos credentials Firebase:');
  console.log('   - FIREBASE_PROJECT_ID: votre project ID (ex: actionapp-38a33)');
  console.log('   - FIREBASE_CLIENT_EMAIL: email du service account');
  console.log('   - FIREBASE_PRIVATE_KEY: clé privée du service account');
  console.log('');
  console.log('💡 Pour obtenir les credentials:');
  console.log('   1. Allez sur https://console.firebase.google.com');
  console.log('   2. Sélectionnez votre projet');
  console.log('   3. Paramètres du projet > Comptes de service');
  console.log('   4. Cliquez sur "Générer une nouvelle clé privée"');
  console.log('   5. Téléchargez le JSON et extrayez les valeurs');
  console.log('');
    console.log('💡 Note: Les emulators peuvent être utilisés en définissant FIRESTORE_EMULATOR_HOST dans .env');
    console.log('   Mais par défaut, le backend utilise Firebase en production (en ligne)');
    console.log('');
    process.exit(1);
} else {
  // Use production Firebase with credentials
  try {
    admin.initializeApp({
      credential: admin.credential.cert({
        projectId: process.env.FIREBASE_PROJECT_ID,
        clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
        privateKey: process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
      }),
    });
    console.log('✅ Firebase Admin SDK initialisé avec succès (PRODUCTION)');
    console.log(`   Project ID: ${process.env.FIREBASE_PROJECT_ID}`);
    console.log('   📍 Les données seront enregistrées directement dans Firebase en ligne');
  } catch (error) {
    // If already initialized, that's okay
    if (error.code !== 'app/already-initialized') {
      console.error('\n❌ ERREUR lors de l\'initialisation de Firebase Admin:', error.message);
      console.log('\n💡 Vérifiez que:');
      console.log('   1. Le fichier .env existe dans le dossier backend/');
      console.log('   2. Les valeurs FIREBASE_PROJECT_ID, FIREBASE_CLIENT_EMAIL et FIREBASE_PRIVATE_KEY sont correctes');
      console.log('   3. La clé privée est entre guillemets et les \\n sont préservés');
      console.log('');
      process.exit(1);
    }
    console.log('✅ Firebase Admin SDK déjà initialisé');
  }
}

// Initialize Express app
const app = express();

// Middleware
// CORS configuration - allow all origins for development
app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  credentials: false
}));

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Log all incoming requests (after body parsing)
app.use((req, res, next) => {
  console.log(`\n🔵 [${new Date().toLocaleTimeString()}] ${req.method} ${req.path}`);
  console.log(`   From: ${req.ip || req.connection.remoteAddress || 'unknown'}`);
  if (req.headers.authorization) {
    console.log('   Auth: Bearer token present');
  }
  if (req.body && Object.keys(req.body).length > 0) {
    const bodyPreview = JSON.stringify(req.body).substring(0, 200);
    console.log('   Body:', bodyPreview + (bodyPreview.length >= 200 ? '...' : ''));
  }
  next();
});


// Test endpoints (before auth routes for debugging)
app.get('/test', (req, res) => {
  console.log('✅ Test GET endpoint hit!');
  res.json({ message: 'Backend is reachable!' });
});

app.post('/test', (req, res) => {
  console.log('✅ Test POST endpoint hit!');
  console.log('   Body:', JSON.stringify(req.body));
  res.json({ message: 'POST request received!', body: req.body });
});

// Routes
app.use('/api/auth', require('./routes/auth.routes'));
app.use('/api/users', require('./routes/users.routes'));
app.use('/api/orders', require('./routes/orders.routes'));
app.use('/api/advertisers', require('./routes/advertisers.routes'));
app.use('/api/promotions', require('./routes/promotions.routes'));

// Health check
app.get('/health', (req, res) => {
  console.log('✅ Health check hit!');
  res.json({ status: 'ok', message: 'Server is running' });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error('\n❌ ERROR:', err.message);
  console.error('Stack:', err.stack);
  console.error('Request:', req.method, req.path);
  console.error('');
  res.status(500).json({ 
    success: false,
    error: 'Something went wrong!',
    message: err.message 
  });
});

// Start server
const PORT = process.env.PORT || 3000;
// Listen on all interfaces (0.0.0.0) to allow connections from emulators
console.log(`\n🚀 Starting server on port ${PORT}...`);
app.listen(PORT, '0.0.0.0', () => {
  console.log(`\n✅ Server is running on port ${PORT}`);
  console.log(`   Local: http://localhost:${PORT}`);
  console.log(`   Network: http://0.0.0.0:${PORT}`);
  console.log(`   For Android Emulator: http://10.0.2.2:${PORT}`);
  if (useEmulators) {
    console.log(`   ⚠️  Firestore Emulator: ${process.env.FIRESTORE_EMULATOR_HOST}`);
    console.log(`   ⚠️  MODE EMULATOR - Les données ne seront PAS enregistrées dans Firebase en ligne`);
  } else {
    console.log(`   ✅ Firebase Production - Les données seront enregistrées directement dans Firebase en ligne`);
  }
  console.log('');
  console.log('📡 Ready to receive requests...');
  console.log('   Test with: curl http://localhost:3000/health');
  console.log('');
}).on('error', (err) => {
  console.error('\n❌ Server failed to start:');
  console.error(`   Port ${PORT} might already be in use`);
  console.error(`   Error: ${err.message}`);
  process.exit(1);
});

module.exports = app;
