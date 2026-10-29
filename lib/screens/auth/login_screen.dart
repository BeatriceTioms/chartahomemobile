import 'package:flutter/material.dart';

import '../../backend/config.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../backend/backend.dart';
import 'auth_widgets.dart';
import 'forgot_password_screen.dart';
import 'signup_screen.dart';

/// Email and password, like the Charta Home web app.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.email, this.notice});

  /// Prefilled after a password reset or sign-up elsewhere.
  final String? email;

  /// Success message to show on arrival, e.g. "Password updated".
  final String? notice;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final _email = TextEditingController(text: widget.email);
  final _password = TextEditingController();
  bool _busy = false;
  SocialProvider? _socialBusy;
  late bool _keep = context.appRead.keepSignedIn;
  bool _tried = false;
  String? _serverError;
  late String? _notice = widget.notice;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  String? get _emailError {
    if (!_tried) return null;
    if (_email.text.trim().isEmpty) return context.tr('err_email_required');
    if (!isValidEmail(_email.text)) return context.tr('err_email_invalid');
    return null;
  }

  String? get _passwordError => _tried && _password.text.isEmpty ? context.tr('err_password_required') : null;

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _tried = true;
      _serverError = null;
      _notice = null;
    });
    if (_emailError != null || _passwordError != null) return;
    setState(() => _busy = true);
    final error = await context.appRead.signIn(_email.text, _password.text);
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _busy = false;
        _serverError = context.tr(error);
      });
    }
  }

  Future<void> _social(SocialProvider provider) async {
    setState(() {
      _socialBusy = provider;
      _serverError = null;
    });
    final error = await context.appRead.signInWithProvider(provider);
    if (!mounted) return;
    setState(() {
      _socialBusy = null;
      if (error != null) _serverError = context.tr(error);
    });
  }

  Future<void> _forgot() async {
    final email = await Navigator.of(
      context,
    ).push<String>(MaterialPageRoute(builder: (_) => ForgotPasswordScreen(email: _email.text.trim())));
    if (email != null && mounted) {
      setState(() {
        _email.text = email;
        _password.clear();
        _tried = false;
        _serverError = null;
        _notice = context.tr('password_updated');
      });
    }
  }

  void _push(Widget page) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: context.tr('welcome_back'),
      subtitle: context.tr('login_sub'),
      footer: AuthSwitch(
        question: context.tr('no_account'),
        action: context.tr('create_account'),
        onTap: () => _push(const SignupScreen()),
      ),
      children: [
        AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_notice != null) AuthBanner(text: _notice!, success: true),
              if (_serverError != null) AuthBanner(text: _serverError!),
              AuthField(
                label: context.tr('email'),
                controller: _email,
                icon: Icons.mail_outline_rounded,
                hint: 'nom@exemple.cm',
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email, AutofillHints.username],
                error: _emailError,
                onChanged: (_) => _tried ? setState(() {}) : null,
              ),
              AuthField(
                label: context.tr('password'),
                controller: _password,
                icon: Icons.lock_outline_rounded,
                password: true,
                autofillHints: const [AutofillHints.password],
                textInputAction: TextInputAction.done,
                error: _passwordError,
                onChanged: (_) => _tried ? setState(() {}) : null,
                onSubmitted: (_) => _submit(),
              ),
            ],
          ),
        ),
        Row(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                setState(() => _keep = !_keep);
                context.appRead.setKeepSignedIn(_keep);
              },
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: _keep ? AppColors.brand : AppColors.white,
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(color: _keep ? AppColors.brand : AppColors.faint, width: 1.5),
                    ),
                    child: _keep ? const Icon(Icons.check_rounded, size: 15, color: AppColors.white) : null,
                  ),
                  const SizedBox(width: 10),
                  Text(context.tr('keep_signed_in'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: _forgot,
              child: Text(
                context.tr('forgot_password'),
                style: const TextStyle(color: AppColors.brand, fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        AuthPrimaryButton(label: context.tr('sign_in'), loading: _busy, onPressed: _submit),
        if (BackendConfig.socialSignIn || context.appRead.backend.isDemo) ...[
          const SizedBox(height: 24),
          SocialButtons(onTap: _social, busy: _socialBusy),
        ],
      ],
    );
  }
}
