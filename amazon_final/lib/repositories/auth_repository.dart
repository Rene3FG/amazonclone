import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/exceptions.dart';

class AuthRepository {
  final _client  = Supabase.instance.client;
  final _storage = const FlutterSecureStorage();

  User? get currentUser => _client.auth.currentUser;

  Future<void> signIn(String email, String password) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email.trim(), password: password,
      );
      if (response.user == null) {
        throw const AppAuthException('Correo o contraseña incorrectos');
      }
    } on AppAuthException {
      rethrow;
    } on AuthApiException catch (e) {
      throw AppAuthException('Error de autenticación: ${e.message}');
    } catch (e) {
      throw AppAuthException('Error inesperado: $e');
    }
  }

  Future<void> signUp(String email, String password) async {
    try {
      final response = await _client.auth.signUp(
        email: email.trim(), password: password,
      );
      if (response.user == null) {
        throw const AppAuthException('No se pudo crear la cuenta');
      }
    } on AppAuthException {
      rethrow;
    } catch (e) {
      throw AppAuthException('Error al registrar: $e');
    }
  }

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (_) {}
  }

  Future<void> saveCredentials(String email, String password) async {
    await _storage.write(key: 'saved_email',    value: email);
    await _storage.write(key: 'saved_password', value: password);
  }

  Future<Map<String, String>?> getSavedCredentials() async {
    final email    = await _storage.read(key: 'saved_email');
    final password = await _storage.read(key: 'saved_password');
    if (email != null && password != null) {
      return {'email': email, 'password': password};
    }
    return null;
  }

  Future<void> clearSavedCredentials() async {
    await _storage.delete(key: 'saved_email');
    await _storage.delete(key: 'saved_password');
  }
}
