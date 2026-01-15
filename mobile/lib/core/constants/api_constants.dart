class ApiConstants {
  // Backend API URL - Change this to your backend URL
  // For development, use: http://localhost:3000/api (or 10.0.2.2:3000/api for Android emulator)
  // For production, use your deployed backend URL
  
  // Backend API URL - Use your local IP address for Android Emulator
  // 10.0.2.2 is the standard way for Android Emulator to access localhost
  // If 10.0.2.2 doesn't work, try using your local IP address instead
  // static const String baseUrl = 'http://10.0.2.2:3000/api'; // Android emulator (standard)
  static const String baseUrl = 'http://10.228.218.188:3000/api'; // Using local IP (works for emulator and physical device)
  // static const String baseUrl = 'http://localhost:3000/api'; // iOS simulator / Web
  // static const String baseUrl = 'https://your-backend-url.com/api'; // Production

  // Endpoints
  static const String advertisers = '/advertisers';
  static const String promotions = '/promotions';
}

