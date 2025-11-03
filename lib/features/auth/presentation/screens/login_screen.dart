import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/data/connectivity_service.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../router/app_router.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../pos/application/pos_navigation_provider.dart';
import '../../domain/entities/session.dart';
import '../providers/auth_provider.dart';
import '../providers/passcode_provider.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _deviceCodeController = TextEditingController();
  ProviderSubscription<AsyncValue<Session?>>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = ref.listenManual(
      authControllerProvider,
      (previous, next) {
        next.whenOrNull(
          data: (session) {
            if (session != null && mounted) {
              final passcodeStatus = ref.read(passcodeStatusProvider);
              final defaultRoute = ref.read(defaultPosRouteProvider);
              if (passcodeStatus.requiresPasscode) {
                context.go(PasscodeRoute.path);
              } else {
                context.go(defaultRoute);
              }
            }
          },
        );
      },
    );
    ref.read(authControllerProvider);
  }

  @override
  void dispose() {
    _subscription?.close();
    _deviceCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(authControllerProvider);
    final connectivity = ref.watch(connectivityStatusProvider);
    final isOffline = connectivity.value == ConnectivityStatus.offline;

    final onSurface =
        theme.brightness == Brightness.dark ? Colors.white : Colors.black87;
    final onSurfaceSecondary =
        theme.brightness == Brightness.dark ? Colors.white70 : Colors.black54;

    return AppScaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Stack(
          children: [
            // ---------- Main Content ----------
            Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ---------- Logo ----------
                        Image.asset(
                          'assets/icon/icon.png',
                          width: 100,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 40),

                        // ---------- Title ----------
                        Text(
                          'Sign in with a device code',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),

                        // ---------- Subtitle ----------
                        Text(
                          'Device codes allow you to sign in without sharing your account email and password.',
                          style: TextStyle(
                            fontSize: 14,
                            color: onSurfaceSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),

                        // ---------- Input field ----------
                        TextFormField(
                          controller: _deviceCodeController,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 22, // bigger visible input
                            letterSpacing: 4,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            hintText: '•••• •••• ••••', // dot-style placeholder
                            hintStyle: const TextStyle(
                              fontSize: 26,
                              letterSpacing: 6,
                              color: Colors.grey,
                            ),
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Color(0xFFED2433), // red focus border
                                width: 2,
                              ),
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: const [DeviceCodeInputFormatter()],
                          validator: (value) {
                            final trimmed = (value ?? '').trim();
                            if (trimmed.isEmpty) {
                              return 'Device code is required';
                            }
                            final digitsOnly = trimmed.replaceAll('-', '');
                            if (digitsOnly.length != 12 ||
                                !RegExp(r'^[0-9-]+$').hasMatch(trimmed)) {
                              return 'Enter a valid code';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 24),

                        // ---------- Offline Notice ----------
                        if (isOffline) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'No internet connection. Connect to the network to register this device.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onErrorContainer,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // ---------- Button ----------
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color(0xFFED2433), // 🔴 red
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            onPressed:
                                state.isLoading || isOffline ? null : _onSubmit,
                            child: state.isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'SIGN IN',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),

                        // ---------- Error (space reserved so layout doesn’t move) ----------
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 70, // static reserved space (error or empty)
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 220),
                            opacity: state.hasError ? 1 : 0,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFE8E8),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Device code entered is incorrect. Please enter correct code or contact us for more details.',
                                style: TextStyle(
                                  color: Color(0xFFD32F2F),
                                  fontSize: 13,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ---------- Footer (Fixed Bottom) ----------
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text.rich(
                    TextSpan(
                      style: TextStyle(
                        fontSize: 14,
                        color: onSurfaceSecondary,
                        height: 1.4,
                      ),
                      children: const [
                        TextSpan(text: 'Need Quick Help?  '),
                        TextSpan(
                          text: '+91 9032757325     ',
                          style: TextStyle(
                            color: Color(0xFF00AEEF),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text: 'Contact for support ',
                        ),
                        TextSpan(
                          text: 'support@nebour.app     ',
                          style: TextStyle(color: Color(0xFF00AEEF)),
                        ),
                        TextSpan(text: 'version 0.01'),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onSubmit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final raw = _deviceCodeController.text.trim();
    final sanitized = raw.replaceAll(RegExp(r'[^0-9]'), '');
    ref.read(authControllerProvider.notifier).login(sanitized);
  }
}

class DeviceCodeInputFormatter extends TextInputFormatter {
  const DeviceCodeInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final truncated = digits.length <= 12 ? digits : digits.substring(0, 12);
    final buffer = StringBuffer();
    for (var i = 0; i < truncated.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write('-');
      buffer.write(truncated[i]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
