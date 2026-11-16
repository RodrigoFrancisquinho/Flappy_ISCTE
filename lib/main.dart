import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config.dart';
import 'componentes/bird.dart';
import 'jogo.dart';
import 'screens/admin.dart';
import 'screens/definicoes.dart';
import 'screens/leaderboard.dart';
import 'screens/login.dart';
import 'services/auth_service.dart';
import 'services/perfil_service.dart';
import 'services/score_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flappy Game',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: session == null
          ? const LoginScreen()
          : const MyHomePage(title: 'Flappy Game'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _isAdmin = false;
  int _moedas = 0;

  @override
  void initState() {
    super.initState();
    _carregarPerfil();
  }

  Future<void> _carregarPerfil() async {
    try {
      final perfil = await PerfilService().obterPerfil();

      if (perfil['bloqueado'] == true) {
        await AuthService().logout();
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => const LoginScreen(
                mensagemInicial: 'Esta conta está bloqueada.',
              ),
            ),
            (route) => false,
          );
        }
        return;
      }

      if (mounted) {
        setState(() {
          _isAdmin = perfil['is_admin'] == true;
          _moedas = (perfil['moedas'] as int?) ?? 0;
        });
      }
    } catch (_) {}
  }

  Future<void> _openGame() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const GamePage()),
    );
    _carregarPerfil();
  }

  void _openLeaderboard() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const LeaderboardPage()),
    );
  }

  Future<void> _openDefinicoes() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const DefinicoesPage()),
    );
    _carregarPerfil();
  }

  void _openAdmin() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AdminPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
            decoration: BoxDecoration(
              color: Colors.amber.shade100,
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(color: Colors.amber.shade700, width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🪙', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 4),
                Text(
                  '$_moedas',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade900,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          if (_isAdmin)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              tooltip: 'Administração',
              onPressed: _openAdmin,
            ),
          IconButton(
            icon: const Icon(Icons.leaderboard),
            tooltip: 'Classificação',
            onPressed: _openLeaderboard,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Definições',
            onPressed: _openDefinicoes,
          ),
        ],
      ),
      body: Center(
        child: FilledButton.icon(
          onPressed: _openGame,
          icon: const Icon(Icons.play_arrow),
          label: const Text('Play'),
        ),
      ),
    );
  }
}

/// Full-screen game with a back button on top.
class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  bool _carregandoConfig = true;
  Future<void>? _saveFuture;

  @override
  void initState() {
    super.initState();
    _carregarConfiguracoesJogo();
  }

  Future<void> _carregarConfiguracoesJogo() async {
    try {
      final config = await ScoreService().obterConfiguracaoJogo();
      final vel = (config['velocidade_jogo'] as num?)?.toDouble();
      final esp = (config['espaco_obstaculos'] as num?)?.toDouble();
      final grav = (config['gravidade'] as num?)?.toDouble();

      if (vel != null && vel > 0) FlappyGame.pipeSpeed = vel;
      if (esp != null && esp > 0) FlappyGame.gapHeight = esp;
      if (grav != null && grav > 0) Bird.gravity = grav;
    } catch (_) {
      // Usa os valores padrão em caso de falha na leitura
    } finally {
      if (mounted) {
        setState(() {
          _carregandoConfig = false;
        });
      }
    }
  }

  void _aoTerminarJogo(int score, int coins) {
    setState(() {
      _saveFuture = _guardarResultadoPartida(score, coins);
    });
  }

  Future<void> _guardarResultadoPartida(int score, int coins) async {
    if (score > 0) {
      try {
        await ScoreService().guardarPontuacao(score);
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Não foi possível guardar a pontuação.'),
            ),
          );
        }
      }
    }

    if (coins > 0) {
      try {
        await PerfilService().adicionarMoedas(coins);
      } catch (e) {
        print('ERRO SUPABASE MOEDAS: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Não foi possível guardar as moedas apanhadas.'),
            ),
          );
        }
      }
    }
  }

  Future<void> _voltarParaMenu() async {
    if (_saveFuture != null) {
      await _saveFuture;
    }
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_carregandoConfig) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _voltarParaMenu();
      },
      child: Scaffold(
        body: Stack(
          children: [
            GameWidget.controlled(
              gameFactory: () => FlappyGame(
                onGameOver: _aoTerminarJogo,
              ),
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: _voltarParaMenu,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
