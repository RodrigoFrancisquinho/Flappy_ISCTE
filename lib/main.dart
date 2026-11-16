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

  @override
  void initState() {
    super.initState();
    _verificarAdmin();
  }

  Future<void> _verificarAdmin() async {
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
        });
      }
    } catch (_) {}
  }

  void _openGame() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const GamePage()),
    );
  }

  void _openLeaderboard() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const LeaderboardPage()),
    );
  }

  void _openDefinicoes() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const DefinicoesPage()),
    );
  }

  void _openAdmin() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AdminPage()),
    );
  }

  Future<void> _logout() async {
    await AuthService().logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
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
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Terminar sessão',
            onPressed: _logout,
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

  Future<void> _guardarPontuacao(BuildContext context, int score) async {
    if (score <= 0) return;

    try {
      await ScoreService().guardarPontuacao(score);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível guardar a pontuação.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_carregandoConfig) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          GameWidget.controlled(
            gameFactory: () => FlappyGame(
              onGameOver: (score) => _guardarPontuacao(context, score),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
