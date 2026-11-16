import 'package:flutter/material.dart';

import '../services/admin_service.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final _adminService = AdminService();

  // Separador Utilizadores
  bool _carregandoUtilizadores = true;
  String? _mensagemErroUtilizadores;
  List<Map<String, dynamic>> _utilizadores = [];

  // Separador Pontuações
  bool _carregandoPontuacoes = true;
  String? _mensagemErroPontuacoes;
  List<Map<String, dynamic>> _pontuacoes = [];

  // Separador Jogo
  bool _carregandoJogo = true;
  String? _mensagemErroJogo;
  bool _guardandoJogo = false;
  final _velocidadeController = TextEditingController();
  final _espacoController = TextEditingController();
  final _gravidadeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _carregarUtilizadores();
    _carregarPontuacoes();
    _carregarConfiguracaoJogo();
  }

  @override
  void dispose() {
    _velocidadeController.dispose();
    _espacoController.dispose();
    _gravidadeController.dispose();
    super.dispose();
  }

  // --- LÓGICA DE UTILIZADORES ---
  Future<void> _carregarUtilizadores() async {
    setState(() {
      _carregandoUtilizadores = true;
      _mensagemErroUtilizadores = null;
    });

    try {
      final dados = await _adminService.listarUtilizadores();
      if (mounted) {
        setState(() {
          _utilizadores = dados;
          _carregandoUtilizadores = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _mensagemErroUtilizadores =
              'Não foi possível carregar os utilizadores.';
          _carregandoUtilizadores = false;
        });
      }
    }
  }

  Future<void> _confirmarBloqueio(
      String userId, String username, bool estadoAtual) async {
    final novoEstado = !estadoAtual;
    final acaoTexto = novoEstado ? 'bloquear' : 'desbloquear';

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${novoEstado ? 'Bloquear' : 'Desbloquear'} Utilizador'),
        content: Text(
          'Tem a certeza que deseja $acaoTexto o utilizador "$username"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: novoEstado ? Colors.red : Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text(novoEstado ? 'Bloquear' : 'Desbloquear'),
          ),
        ],
      ),
    );

    if (confirmado != true) return;

    try {
      await _adminService.definirBloqueio(userId, novoEstado);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Utilizador $username ${novoEstado ? 'bloqueado' : 'desbloqueado'} com sucesso.',
            ),
          ),
        );
        _carregarUtilizadores();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível alterar o estado do utilizador.'),
          ),
        );
      }
    }
  }

  // --- LÓGICA DE PONTUAÇÕES ---
  Future<void> _carregarPontuacoes() async {
    setState(() {
      _carregandoPontuacoes = true;
      _mensagemErroPontuacoes = null;
    });

    try {
      final dados = await _adminService.listarPontuacoes();
      if (mounted) {
        setState(() {
          _pontuacoes = dados;
          _carregandoPontuacoes = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _mensagemErroPontuacoes = 'Não foi possível carregar as pontuações.';
          _carregandoPontuacoes = false;
        });
      }
    }
  }

  Future<void> _confirmarEliminarPontuacao(
      int id, String username, int score) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Pontuação'),
        content: Text(
          'Tem a certeza que deseja eliminar a pontuação de $score pts do utilizador "$username"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmado != true) return;

    try {
      await _adminService.eliminarPontuacao(id);
      if (mounted) {
        setState(() {
          _pontuacoes.removeWhere((p) => p['id'] == id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pontuação eliminada com sucesso.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Não foi possível eliminar a pontuação. Permissão recusada.'),
          ),
        );
      }
    }
  }

  // --- LÓGICA DE JOGO ---
  Future<void> _carregarConfiguracaoJogo() async {
    setState(() {
      _carregandoJogo = true;
      _mensagemErroJogo = null;
    });

    try {
      final config = await _adminService.obterConfiguracao();
      if (mounted) {
        setState(() {
          _velocidadeController.text =
              (config['velocidade_jogo'] ?? 160).toString();
          _espacoController.text =
              (config['espaco_obstaculos'] ?? 300).toString();
          _gravidadeController.text = (config['gravidade'] ?? 1200).toString();
          _carregandoJogo = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _mensagemErroJogo =
              'Não foi possível carregar a configuração do jogo.';
          _carregandoJogo = false;
        });
      }
    }
  }

  Future<void> _guardarConfiguracaoJogo() async {
    final vel = double.tryParse(_velocidadeController.text);
    final esp = double.tryParse(_espacoController.text);
    final grav = double.tryParse(_gravidadeController.text);

    if (vel == null || vel <= 0 || esp == null || esp <= 0 || grav == null || grav <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Todos os valores devem ser números maiores que 0.'),
        ),
      );
      return;
    }

    setState(() {
      _guardandoJogo = true;
    });

    try {
      await _adminService.atualizarConfiguracao(
        velocidadeJogo: vel,
        espacoObstaculos: esp,
        gravidade: grav,
      );
      if (mounted) {
        setState(() {
          _guardandoJogo = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configuração do jogo atualizada com sucesso!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _guardandoJogo = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao atualizar a configuração do jogo.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Painel de Administração'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.people), text: 'Utilizadores'),
              Tab(icon: Icon(Icons.emoji_events), text: 'Pontuações'),
              Tab(icon: Icon(Icons.tune), text: 'Jogo'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildUtilizadoresTab(),
            _buildPontuacoesTab(),
            _buildJogoTab(),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS DOS SEPARADORES ---
  Widget _buildUtilizadoresTab() {
    if (_carregandoUtilizadores) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_mensagemErroUtilizadores != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_mensagemErroUtilizadores!),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _carregarUtilizadores,
              child: const Text('Tentar de novo'),
            ),
          ],
        ),
      );
    }

    if (_utilizadores.isEmpty) {
      return RefreshIndicator(
        onRefresh: _carregarUtilizadores,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 100),
            Center(child: Text('Nenhum utilizador encontrado.')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _carregarUtilizadores,
      child: ListView.builder(
        itemCount: _utilizadores.length,
        itemBuilder: (context, index) {
          final u = _utilizadores[index];
          final String userId = u['id'] as String;
          final String username = u['username'] as String? ?? 'Sem nome';
          final bool bloqueado = u['bloqueado'] == true;
          final bool isAdmin = u['is_admin'] == true;

          return ListTile(
            leading: Icon(
              isAdmin ? Icons.admin_panel_settings : Icons.person,
              color: isAdmin ? Colors.purple : Colors.grey,
            ),
            title: Text(username),
            subtitle: Text(
              isAdmin
                  ? 'Administrador'
                  : (bloqueado ? 'Bloqueado' : 'Ativo'),
              style: TextStyle(
                color: bloqueado ? Colors.red : Colors.green,
                fontWeight: FontWeight.w500,
              ),
            ),
            trailing: isAdmin
                ? const Chip(label: Text('Admin'))
                : Switch(
                    value: !bloqueado,
                    activeColor: Colors.green,
                    inactiveThumbColor: Colors.red,
                    onChanged: (novoEstadoAtivo) {
                      _confirmarBloqueio(userId, username, bloqueado);
                    },
                  ),
          );
        },
      ),
    );
  }

  Widget _buildPontuacoesTab() {
    if (_carregandoPontuacoes) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_mensagemErroPontuacoes != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_mensagemErroPontuacoes!),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _carregarPontuacoes,
              child: const Text('Tentar de novo'),
            ),
          ],
        ),
      );
    }

    if (_pontuacoes.isEmpty) {
      return RefreshIndicator(
        onRefresh: _carregarPontuacoes,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 100),
            Center(child: Text('Nenhuma pontuação registada.')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _carregarPontuacoes,
      child: ListView.builder(
        itemCount: _pontuacoes.length,
        itemBuilder: (context, index) {
          final p = _pontuacoes[index];
          final int id = p['id'] as int;
          final int score = p['score'] as int? ?? 0;
          final String username = p['perfis']?['username'] as String? ?? 'Anónimo';
          final String criadoEmRaw = p['criado_em'] as String? ?? '';
          final dataFormatada = criadoEmRaw.length >= 10
              ? criadoEmRaw.substring(0, 10)
              : criadoEmRaw;

          return ListTile(
            leading: CircleAvatar(
              child: Text('${index + 1}'),
            ),
            title: Text('$username - $score pts'),
            subtitle: Text('Data: $dataFormatada'),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _confirmarEliminarPontuacao(id, username, score),
            ),
          );
        },
      ),
    );
  }

  Widget _buildJogoTab() {
    if (_carregandoJogo) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_mensagemErroJogo != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_mensagemErroJogo!),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _carregarConfiguracaoJogo,
              child: const Text('Tentar de novo'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _velocidadeController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Velocidade do Jogo',
              border: OutlineInputBorder(),
              helperText: 'Exemplo: 160.0',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _espacoController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Espaço entre Obstáculos',
              border: OutlineInputBorder(),
              helperText: 'Exemplo: 300.0',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _gravidadeController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Gravidade',
              border: OutlineInputBorder(),
              helperText: 'Exemplo: 1200.0',
            ),
          ),
          const SizedBox(height: 24),
          _guardandoJogo
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton.icon(
                  onPressed: _guardarConfiguracaoJogo,
                  icon: const Icon(Icons.save),
                  label: const Text('Guardar Alterações'),
                ),
        ],
      ),
    );
  }
}
