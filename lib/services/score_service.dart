import 'package:supabase_flutter/supabase_flutter.dart';

class ScoreService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<void> guardarPontuacao(int score) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AuthException('Utilizador não autenticado.');
    }

    await _client.from('pontuacoes').insert({
      'user_id': userId,
      'score': score,
    });
  }

  Future<List<Map<String, dynamic>>> obterClassificacao() async {
    final response = await _client.from('classificacao').select();
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> obterConfiguracaoJogo() async {
    final response = await _client
        .from('configuracoes_jogo')
        .select('velocidade_jogo, espaco_obstaculos, gravidade')
        .eq('id', 1)
        .single();
    return response;
  }
}
