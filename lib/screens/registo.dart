import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../main.dart';
import '../services/auth_service.dart';

class RegistoScreen extends StatefulWidget {
  const RegistoScreen({super.key});

  @override
  State<RegistoScreen> createState() => _RegistoScreenState();
}

class _RegistoScreenState extends State<RegistoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmarPasswordController = TextEditingController();
  final _authService = AuthService();

  bool _carregando = false;
  String? _mensagemErro;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmarPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submeterRegisto() async {
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
      await _authService.registar(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        username: _usernameController.text.trim(),
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
        _mensagemErro = 'Ocorreu um erro ao criar a conta. Tenta novamente.';
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
        title: const Text('Criar Conta'),
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
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Nome de utilizador',
                  border: OutlineInputBorder(),
                ),
                validator: (valor) {
                  final v = valor?.trim() ?? '';
                  if (v.length < 3 || v.length > 20) {
                    return 'O nome de utilizador deve ter entre 3 e 20 caracteres.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                validator: (valor) {
                  final v = valor?.trim() ?? '';
                  final emailRegExp =
                      RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                  if (!emailRegExp.hasMatch(v)) {
                    return 'Introduz um email válido.';
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
                  if (v.length < 6) {
                    return 'A palavra-passe deve ter pelo menos 6 caracteres.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _confirmarPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirmar palavra-passe',
                  border: OutlineInputBorder(),
                ),
                validator: (valor) {
                  if (valor != _passwordController.text) {
                    return 'As palavras-passe não coincidem.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24.0),
              _carregando
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _submeterRegisto,
                      child: const Text('Registar'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
