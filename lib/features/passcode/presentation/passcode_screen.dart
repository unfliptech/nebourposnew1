// lib/features/passcode/presentation/passcode_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nebourpos/core/data/secure_storage.dart';

import '../../../router/route_guards.dart';
import '../../../core/providers/core_providers.dart';

class PasscodeScreen extends ConsumerStatefulWidget {
  const PasscodeScreen({super.key});

  @override
  ConsumerState<PasscodeScreen> createState() => _PasscodeScreenState();
}

class _PasscodeScreenState extends ConsumerState<PasscodeScreen> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _error = null);

    final input = _controller.text.trim();
    if (input.isEmpty) {
      setState(() => _error = 'Enter passcode');
      return;
    }

    final store = ref.read(secureStoreProvider);
    final saved = await store.read(SK.passcodeValue);

    if (saved == null || saved.isEmpty || saved != input) {
      setState(() => _error = 'Incorrect passcode');
      return;
    }

    // Unlock + clear the lock flag. Pending route is optional in your impl.
    ref.read(passcodeStatusProvider.notifier).unlock();
    await store.write(SK.isPasscodeRequired, 'false');

    if (!mounted) return;
    context.go(PosRoute.path); // or to a stored pending route
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter Passcode',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                obscureText: true,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: '••••',
                  errorText: _error,
                  border: const OutlineInputBorder(),
                ),
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  child: const Text('Unlock'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
