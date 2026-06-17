import '../models/user_model.dart';

class AuthService {
  // Simulated login delay
  Future<UserModel?> login(String email, String password) async {
    await Future.delayed(const Duration(seconds: 2));
    
    // In a real app, you would make an HTTP request here.
    if (email.isNotEmpty && password.isNotEmpty) {
      return UserModel(
        id: '123',
        email: email,
        name: 'Test User',
      );
    }
    return null; // Simulated failure
  }
}
