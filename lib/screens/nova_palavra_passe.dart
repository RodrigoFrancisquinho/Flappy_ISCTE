import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'login.dart';

class NovaPalavraPasseScreen extends StatefulWidget {
  const NovaPalavraPasseScreen({super.key});

  @override
  State<NovaPalavraPasseScreen> createState() => _NovaPalavraPasseScreenState();
}

class _NovaPalavraPasseScreenState extends State<NovaPalavraPasseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _novaPasswordController = TextEditingController();
  final _confirmarPasswordController = TextEditingController();

  bool _carregando = false;
  String? _mensagemErro;

  @override
  void dispose() {
    _novaPasswordController.dispose();
    _confirmarPasswordController.dispose();
    super.dispose();
  }

  Future<void> _guardarPalavraPasse() async {
    setState(() {
      _mensagemErro = null;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_novaPasswordController.text != _confirmarPasswordController.text) {
      setState(() {
        _mensagemErro = 'As palavras-passe não coincidem.';
      });
      return;
    }

    setState(() {
      _carregando = true;
    });

    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: _novaPasswordController.text),
      );

      await Supabase.instance.client.auth.signOut();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Palavra-passe atualizada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    } on AuthException catch (e) {
      setState(() {
        _mensagemErro = e.message;
      });
    } catch (e) {
      setState(() {
        _mensagemErro = 'Erro ao atualizar a palavra-passe. Tenta novamente.';
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
        title: const Text('Nova Palavra-passe'),
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
                controller: _novaPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Nova Palavra-passe',
                  border: OutlineInputBorder(),
                ),
                validator: (valor) {
                  final v = valor ?? '';
                  if (v.isEmpty) {
                    return 'Introduz a nova palavra-passe.';
                  }
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
                  labelText: 'Confirmar Nova Palavra-passe',
                  border: OutlineInputBorder(),
                ),
                validator: (valor) {
                  final v = valor ?? '';
                  if (v.isEmpty) {
                    return 'Confirma a nova palavra-passe.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24.0),
              _carregando
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _guardarPalavraPasse,
                      child: const Text('Guardar Palavra-passe'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
