class ApiConstants {
  // Backend API URL - Change this to your backend URL
  // For development, use: http://localhost:3000/api (or 10.0.2.2:3000/api for Android emulator)
  // For production, use your deployed backend URL
  
  // Backend API URL - Use 10.0.2.2 for Android Emulator (this is the standard way)
  // 10.0.2.2 is a special alias that points to localhost (127.0.0.1) on the host machine
  // If 10.0.2.2 doesn't work, try your local IP address (e.g., 10.225.40.188)
  static const String baseUrl = 'http://10.225.40.188:3000/api'; // Using local IP for testing
  // static const String baseUrl = 'http://10.0.2.2:3000/api'; // Android emulator (standard)
  // static const String baseUrl = 'http://localhost:3000/api'; // iOS simulator / Web
  // static const String baseUrl = 'https://your-backend-url.com/api'; // Production

  // Endpoints
  static const String advertisers = '/advertisers';
}

