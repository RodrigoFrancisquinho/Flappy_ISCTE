import 'package:supabase_flutter/supabase_flutter.dart';

class AdminService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> listarUtilizadores() async {
    final response = await _client
        .from('perfis')
        .select('id, username, bloqueado, is_admin')
        .order('username', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> definirBloqueio(String id, bool bloqueado) async {
    await _client.rpc('definir_bloqueio', params: {
      'alvo': id,
      'estado': bloqueado,
    });
  }

  Future<List<Map<String, dynamic>>> listarPontuacoes() async {
    final response = await _client
        .from('pontuacoes')
        .select('id, score, criado_em, perfis(username)')
        .order('score', ascending: false)
        .limit(100);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> eliminarPontuacao(int id) async {
    final response =
        await _client.from('pontuacoes').delete().eq('id', id).select();
    final lista = List<Map<String, dynamic>>.from(response);
    if (lista.isEmpty) {
      throw const AuthException(
          'Não foi possível eliminar a pontuação. Permissão recusada.');
    }
  }

  Future<Map<String, dynamic>> obterConfiguracao() async {
    final response = await _client
        .from('configuracoes_jogo')
        .select('velocidade_jogo, espaco_obstaculos, gravidade')
        .eq('id', 1)
        .single();
    return response;
  }

  Future<void> atualizarConfiguracao({
    required num velocidadeJogo,
    required num espacoObstaculos,
    required num gravidade,
  }) async {
    await _client.from('configuracoes_jogo').update({
      'velocidade_jogo': velocidadeJogo,
      'espaco_obstaculos': espacoObstaculos,
      'gravidade': gravidade,
    }).eq('id', 1);
  }
}
