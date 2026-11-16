import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<AuthResponse> registar({
    required String email,
    required String password,
    required String username,
  }) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
      data: {'username': username},
    );
  }

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    final userId = response.user?.id;
    if (userId != null) {
      final perfil = await _client
          .from('perfis')
          .select('bloqueado')
          .eq('id', userId)
          .single();

      if (perfil['bloqueado'] == true) {
        await _client.auth.signOut();
        throw const AuthException('Esta conta está bloqueada.');
      }
    }

    return response;
  }

  Future<void> logout() async {
    await _client.auth.signOut();
  }

  Future<void> recuperarPalavraPasse(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(
        email,
        redirectTo: kIsWeb ? 'http://localhost:3000/' : 'flappyiscte://callback/',
      );
    } on AuthException catch (e) {
      throw Exception('Erro ao recuperar palavra-passe: ${e.message}');
    } catch (e) {
      throw Exception('Não foi possível enviar o e-mail de recuperação. Tenta novamente.');
    }
  }
}
