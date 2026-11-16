import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../main.dart';
import '../services/auth_service.dart';
import 'registo.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.mensagemInicial});

  final String? mensagemInicial;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _carregando = false;
  String? _mensagemErro;

  @override
  void initState() {
    super.initState();
    _mensagemErro = widget.mensagemInicial;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submeterLogin() async {
    setState(() {
      _mensagemErro = null;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _carregando = true;
    });

    try {
      await _authService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => const MyHomePage(title: 'Flappy Game'),
          ),
          (route) => false,
        );
      }
    } on AuthException catch (e) {
      setState(() {
        _mensagemErro = e.message;
      });
    } catch (e) {
      setState(() {
        _mensagemErro = 'Ocorreu um erro ao iniciar sessão. Tenta novamente.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _carregando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Iniciar Sessão'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_mensagemErro != null) ...[
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Text(
                    _mensagemErro!,
                    style: TextStyle(color: Colors.red.shade900),
                  ),
                ),
                const SizedBox(height: 16.0),
              ],
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                validator: (valor) {
                  final v = valor?.trim() ?? '';
                  if (v.isEmpty) {
                    return 'Introduz o teu email.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Palavra-passe',
                  border: OutlineInputBorder(),
                ),
                validator: (valor) {
                  final v = valor ?? '';
                  if (v.isEmpty) {
                    return 'Introduz a tua palavra-passe.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24.0),
              _carregando
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _submeterLogin,
                      child: const Text('Entrar'),
                    ),
              const SizedBox(height: 16.0),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RegistoScreen()),
                  );
                },
                child: const Text('Ainda não tens conta? Regista-te aqui.'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
