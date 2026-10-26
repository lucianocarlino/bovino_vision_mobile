import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_config.dart';
import '../../core/api/api_exception.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/brand.dart';
import '../../core/widgets/feedback.dart';

/// Login like the web app (`src/features/auth/LoginPage.tsx`).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_sending || !_formKey.currentState!.validate()) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await context.read<AuthController>().login(_email.text, _password.text);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final expired = context.watch<AuthController>().sessionExpired;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 384),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: BrandLogo(size: 40, fontSize: 24)),
                  const SizedBox(height: 24),
                  AppCard(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const CardHeader(title: 'Iniciar sesión'),
                          if (expired && _error == null) ...[
                            const Notice(message: 'Tu sesión terminó. Iniciá sesión de nuevo.', tone: NoticeTone.warning),
                            const SizedBox(height: 16),
                          ],
                          if (_error != null) ...[
                            Notice(message: _error!, tone: NoticeTone.danger),
                            const SizedBox(height: 16),
                          ],
                          const _Label('Correo electrónico'),
                          TextFormField(
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.email],
                            textInputAction: TextInputAction.next,
                            validator: (value) =>
                                (value == null || value.trim().isEmpty) ? 'Ingresá tu correo.' : null,
                          ),
                          const SizedBox(height: 16),
                          const _Label('Contraseña'),
                          TextFormField(
                            controller: _password,
                            obscureText: true,
                            autofillHints: const [AutofillHints.password],
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submit(),
                            validator: (value) => (value == null || value.isEmpty) ? 'Ingresá tu contraseña.' : null,
                          ),
                          const SizedBox(height: 24),
                          AppButton(
                            label: _sending ? 'Ingresando…' : 'Ingresar',
                            icon: Icons.login,
                            size: AppButtonSize.lg,
                            expand: true,
                            loading: _sending,
                            onPressed: _submit,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (kDebugMode) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Servidor: ${ApiConfig.baseUrl}',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: AppColors.neutral500),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.neutral700)),
      );
}

/// Shown while the stored session is being restored.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BrandLogo(size: 40, fontSize: 24),
              SizedBox(height: 24),
              SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4)),
            ],
          ),
        ),
      );
}

/// The account has no permission that opens a screen of the mobile app.
class NoAccessScreen extends StatelessWidget {
  const NoAccessScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const BrandLogo(size: 40, fontSize: 24),
                  const SizedBox(height: 24),
                  const Notice(
                    message: 'Tu rol no tiene acceso a la aplicación móvil. Usá BovinoVision desde la web.',
                    tone: NoticeTone.warning,
                  ),
                  const SizedBox(height: 16),
                  AppButton(
                    label: 'Cerrar sesión',
                    icon: Icons.logout,
                    variant: AppButtonVariant.secondary,
                    onPressed: () => context.read<AuthController>().logout(),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
