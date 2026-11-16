import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/score_service.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  final _scoreService = ScoreService();
  final String? _currentUserId = Supabase.instance.client.auth.currentUser?.id;

  bool _carregando = true;
  String? _mensagemErro;
  List<Map<String, dynamic>> _classificacao = [];

  @override
  void initState() {
    super.initState();
    _carregarClassificacao();
  }

  Future<void> _carregarClassificacao() async {
    setState(() {
      _carregando = true;
      _mensagemErro = null;
    });

    try {
      final dados = await _scoreService.obterClassificacao();
      if (mounted) {
        setState(() {
          _classificacao = dados;
          _carregando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _mensagemErro =
              'Não foi possível carregar a classificação. Tenta novamente.';
          _carregando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Classificação'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_carregando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_mensagemErro != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _mensagemErro!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _carregarClassificacao,
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar de novo'),
              ),
            ],
          ),
        ),
      );
    }

    if (_classificacao.isEmpty) {
      return RefreshIndicator(
        onRefresh: _carregarClassificacao,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 100),
            Center(
              child: Text(
                'Nenhuma pontuação registada ainda.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _carregarClassificacao,
      child: ListView.builder(
        itemCount: _classificacao.length,
        itemBuilder: (context, index) {
          final item = _classificacao[index];
          final userId = item['user_id'] as String?;
          final username = item['username'] as String? ?? 'Anónimo';
          final imagemPerfil = item['imagem_perfil'] as String?;
          final score = item['melhor_score'] ?? 0;
          final isCurrentUser = userId != null && userId == _currentUserId;

          return Container(
            color: isCurrentUser
                ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.4)
                : null,
            child: ListTile(
              leading: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 32,
                    child: Text(
                      '#${index + 1}',
                      style: TextStyle(
                        fontWeight:
                            isCurrentUser ? FontWeight.bold : FontWeight.normal,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundImage: imagemPerfil != null &&
                            imagemPerfil.isNotEmpty
                        ? NetworkImage(imagemPerfil)
                        : null,
                    child: (imagemPerfil == null || imagemPerfil.isEmpty)
                        ? const Icon(Icons.person)
                        : null,
                  ),
                ],
              ),
              title: Text(
                username,
                style: TextStyle(
                  fontWeight:
                      isCurrentUser ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              trailing: Text(
                '$score pts',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight:
                      isCurrentUser ? FontWeight.bold : FontWeight.bold,
                  color: isCurrentUser
                      ? Theme.of(context).colorScheme.primary
                      : Colors.black87,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
