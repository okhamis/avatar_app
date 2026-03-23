class BiometricService {
  Future<bool> authenticate(String reason) async {
    // Placeholder for local auth
    await Future.delayed(const Duration(seconds: 1));
    return true; // Simulate pass
  }
}
