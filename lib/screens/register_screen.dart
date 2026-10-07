import 'package:flutter/material.dart';
import '../services/pb.dart';
import 'home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _pass2 = TextEditingController();
  bool _loading = false;

  Future<void> _register() async {
    if (_name.text.trim().isEmpty || _email.text.trim().isEmpty) {
      snack(context, 'Preencha nome e e-mail.');
      return;
    }
    if (!isValidEmail(_email.text.trim())) {
      snack(context, 'E-mail inválido.');
      return;
    }
    if (_pass.text.length < 8) {
      snack(context, 'A senha deve ter pelo menos 8 caracteres.');
      return;
    }
    if (_pass.text != _pass2.text) {
      snack(context, 'As senhas não conferem.');
      return;
    }
    setState(() => _loading = true);
    try {
      await pb.collection('users').create(body: {
        'name': _name.text.trim(),
        'email': _email.text.trim(),
        'password': _pass.text,
        'passwordConfirm': _pass2.text,
      });
      await pb.collection('users').authWithPassword(_email.text.trim(), _pass.text);
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
          context, MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false);
    } catch (e) {
      if (mounted) snack(context, 'Falha no cadastro: ${errMsg(e)}');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _field(TextEditingController c, String label,
          {bool obscure = false, TextInputType? type}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: TextField(
          controller: c,
          obscureText: obscure,
          keyboardType: type,
          decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        ),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Criar conta')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _field(_name, 'Nome'),
              _field(_email, 'E-mail', type: TextInputType.emailAddress),
              _field(_pass, 'Senha (mín. 8 caracteres)', obscure: true),
              _field(_pass2, 'Confirmar senha', obscure: true),
              FilledButton(
                onPressed: _loading ? null : _register,
                child: _loading
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Registrar'),
              ),
            ],
          ),
        ),
      );
}
