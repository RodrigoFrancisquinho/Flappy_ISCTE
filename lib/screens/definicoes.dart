import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';
import '../services/perfil_service.dart';
import 'login.dart';

class DefinicoesPage extends StatefulWidget {
  const DefinicoesPage({super.key});

  @override
  State<DefinicoesPage> createState() => _DefinicoesPageState();
}

class _DefinicoesPageState extends State<DefinicoesPage> {
  final _perfilService = PerfilService();
  final _authService = AuthService();
  final _usernameController = TextEditingController();
  final _picker = ImagePicker();

  bool _carregandoInicial = true;
  String? _mensagemErroInicial;

  bool _carregandoImagem = false;
  bool _carregandoUsername = false;
  String? _mensagemErroUsername;
  String? _imagemPerfilUrl;
  bool _somAtivo = true;

  @override
  void initState() {
    super.initState();
    _carregarPerfil();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _carregarPerfil() async {
    setState(() {
      _carregandoInicial = true;
      _mensagemErroInicial = null;
    });

    try {
      final dados = await _perfilService.obterPerfil();
      if (mounted) {
        setState(() {
          _usernameController.text = dados['username'] as String? ?? '';
          _imagemPerfilUrl = dados['imagem_perfil'] as String?;
          _somAtivo = dados['som_ativo'] as bool? ?? true;
          _carregandoInicial = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _mensagemErroInicial =
              'Não foi possível carregar o perfil. Tenta novamente.';
          _carregandoInicial = false;
        });
      }
    }
  }

  Future<void> _mostrarOpcoesImagem() async {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeria'),
              onTap: () {
                Navigator.of(ctx).pop();
                _selecionarEUploadImagem(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Câmara'),
              onTap: () {
                Navigator.of(ctx).pop();
                _selecionarEUploadImagem(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selecionarEUploadImagem(ImageSource origem) async {
    try {
      final ficheiroSelecionado = await _picker.pickImage(
        source: origem,
        maxWidth: 512,
        imageQuality: 80,
      );

      if (ficheiroSelecionado == null) return;

      setState(() {
        _carregandoImagem = true;
      });

      final novaUrl = await _perfilService.atualizarImagem(
        File(ficheiroSelecionado.path),
      );

      if (mounted) {
        setState(() {
          _imagemPerfilUrl = novaUrl;
          _carregandoImagem = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Imagem de perfil atualizada!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _carregandoImagem = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível carregar a imagem. Tenta novamente.'),
          ),
        );
      }
    }
  }

  Future<void> _guardarUsername() async {
    final novoUsername = _usernameController.text.trim();
    if (novoUsername.length < 3 || novoUsername.length > 20) {
      setState(() {
        _mensagemErroUsername =
            'O nome de utilizador deve ter entre 3 e 20 caracteres.';
      });
      return;
    }

    setState(() {
      _carregandoUsername = true;
      _mensagemErroUsername = null;
    });

    try {
      await _perfilService.atualizarUsername(novoUsername);
      if (mounted) {
        setState(() {
          _carregandoUsername = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nome de utilizador atualizado com sucesso!'),
          ),
        );
      }
    } on PostgrestException catch (e) {
      if (mounted) {
        setState(() {
          _carregandoUsername = false;
          if (e.code == '23505') {
            _mensagemErroUsername = 'Esse nome já está em uso.';
          } else {
            _mensagemErroUsername =
                'Erro ao atualizar nome. Tenta novamente.';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _carregandoUsername = false;
          _mensagemErroUsername =
              'Erro ao atualizar nome. Tenta novamente.';
        });
      }
    }
  }

  Future<void> _alterarSom(bool novoValor) async {
    final valorAntigo = _somAtivo;
    setState(() {
      _somAtivo = novoValor;
    });

    try {
      await _perfilService.atualizarSom(novoValor);
    } catch (e) {
      if (mounted) {
        setState(() {
          _somAtivo = valorAntigo;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível guardar a preferência de som.'),
          ),
        );
      }
    }
  }

  Future<void> _logout() async {
    await _authService.logout();
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
        title: const Text('Definições'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_carregandoInicial) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_mensagemErroInicial != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _mensagemErroInicial!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _carregarPerfil,
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar de novo'),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: _carregandoImagem ? null : _mostrarOpcoesImagem,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircleAvatar(
                  radius: 54,
                  backgroundImage: _imagemPerfilUrl != null &&
                          _imagemPerfilUrl!.isNotEmpty
                      ? NetworkImage(_imagemPerfilUrl!)
                      : null,
                  child: (_imagemPerfilUrl == null || _imagemPerfilUrl!.isEmpty)
                      ? const Icon(Icons.person, size: 54)
                      : null,
                ),
                if (_carregandoImagem)
                  const CircularProgressIndicator(color: Colors.white),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: const Icon(
                      Icons.camera_alt,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Toca para alterar a foto',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 32),

          if (_mensagemErroUsername != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Text(
                _mensagemErroUsername!,
                style: TextStyle(color: Colors.red.shade900),
              ),
            ),
            const SizedBox(height: 16),
          ],

          TextField(
            controller: _usernameController,
            decoration: const InputDecoration(
              labelText: 'Nome de utilizador',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: _carregandoUsername
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _guardarUsername,
                    child: const Text('Guardar Nome'),
                  ),
          ),
          const SizedBox(height: 32),
          const Divider(),
          SwitchListTile(
            title: const Text('Efeitos Sonoros'),
            subtitle: const Text('Ativar ou desativar os sons do jogo'),
            value: _somAtivo,
            onChanged: _alterarSom,
          ),
          const Divider(),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _logout,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
              ),
              icon: const Icon(Icons.logout),
              label: const Text('Terminar sessão'),
            ),
          ),
        ],
      ),
    );
  }
}
