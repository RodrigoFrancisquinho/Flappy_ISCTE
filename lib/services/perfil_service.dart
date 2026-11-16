import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

class PerfilService {
  final SupabaseClient _client = Supabase.instance.client;

  String? get currentUserId => _client.auth.currentUser?.id;

  Future<Map<String, dynamic>> obterPerfil() async {
    final userId = currentUserId;
    if (userId == null) {
      throw const AuthException('Utilizador não autenticado.');
    }

    final response = await _client
        .from('perfis')
        .select('username, imagem_perfil, som_ativo, is_admin')
        .eq('id', userId)
        .single();

    return response;
  }

  Future<void> atualizarUsername(String username) async {
    final userId = currentUserId;
    if (userId == null) {
      throw const AuthException('Utilizador não autenticado.');
    }

    await _client.from('perfis').update({
      'username': username,
    }).eq('id', userId);
  }

  Future<void> atualizarSom(bool ativo) async {
    final userId = currentUserId;
    if (userId == null) {
      throw const AuthException('Utilizador não autenticado.');
    }

    await _client.from('perfis').update({
      'som_ativo': ativo,
    }).eq('id', userId);
  }

  Future<String> atualizarImagem(File ficheiro) async {
    final userId = currentUserId;
    if (userId == null) {
      throw const AuthException('Utilizador não autenticado.');
    }

    final path = '$userId/avatar.jpg';

    await _client.storage.from('avatars').upload(
          path,
          ficheiro,
          fileOptions: const FileOptions(upsert: true),
        );

    final baseUrl = _client.storage.from('avatars').getPublicUrl(path);
    final urlComCache = '$baseUrl?v=${DateTime.now().millisecondsSinceEpoch}';

    await _client.from('perfis').update({
      'imagem_perfil': urlComCache,
    }).eq('id', userId);

    return urlComCache;
  }
}
