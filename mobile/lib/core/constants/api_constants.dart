class ApiConstants {
  // Backend API URL - Change this to your backend URL
  // For development, use: http://localhost:3000/api (or 10.0.2.2:3000/api for Android emulator)
  // For production, use your deployed backend URL
  
  // Backend API URL - Use your local IP address for Android Emulator
  // 10.0.2.2 is the standard way, but if it doesn't work, use your local IP
  // static const String baseUrl = 'http://10.0.2.2:3000/api'; // Android emulator (standard)
  static const String baseUrl = 'http://10.246.168.188:3000/api'; // Using local IP
  // static const String baseUrl = 'http://localhost:3000/api'; // iOS simulator / Web
  // static const String baseUrl = 'https://your-backend-url.com/api'; // Production

  // Endpoints
  static const String advertisers = '/advertisers';
  static const String promotions = '/promotions';
}

