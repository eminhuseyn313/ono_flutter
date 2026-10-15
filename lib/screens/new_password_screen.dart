import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ono_ui.dart';

/// After tapping a password-reset link: choose the new password.
class NewPasswordScreen extends StatefulWidget {
  const NewPasswordScreen({super.key});

  @override
  State<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen> {
  final _password = TextEditingController();
  final _again = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _password.dispose();
    _again.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final p = _password.text;
    if (p.length < 6) {
      toast(context, 'At least 6 characters.');
      return;
    }
    if (p != _again.text) {
      toast(context, 'The two passwords differ.');
      return;
    }
    setState(() => _saving = true);
    final error = await context.read<AuthProvider>().updatePassword(p);
    if (!mounted) return;
    setState(() => _saving = false);
    if (error != null) {
      toast(context, error);
      return;
    }
    toast(context, 'Password changed. Use it on every device.');
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return OnoPage(
      eyebrow: 'Account',
      title: 'Choose a new password',
      subtitle: 'You came from a reset link. Set the new password once; it works on the web and on your phone.',
      bottomBar: PrimaryButton(_saving ? 'Saving…' : 'Save the password',
          icon: Icons.lock_reset_rounded, onPressed: _saving ? null : _save),
      children: [
        const SizedBox(height: 16),
        TextField(
          controller: _password,
          obscureText: true,
          autofillHints: const [AutofillHints.newPassword],
          style: AppText.body(color: AppColors.white),
          decoration: const InputDecoration(labelText: 'New password'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _again,
          obscureText: true,
          onSubmitted: (_) => _save(),
          style: AppText.body(color: AppColors.white),
          decoration: const InputDecoration(labelText: 'The same again'),
        ),
        const SizedBox(height: 16),
        // A link that expired can't set a password: a way out.
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () => context.read<AuthProvider>().signOut(),
            child: const Text('Not now — sign out'),
          ),
        ),
      ],
    );
  }
}
