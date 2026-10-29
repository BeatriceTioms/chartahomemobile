import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/links.dart';
import 'auth_widgets.dart';

/// New resident account: name, email and a password that meets the rules.
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _accepted = false;
  bool _busy = false;
  bool _tried = false;
  String? _serverError;
  bool _confirmSent = false;

  @override
  void dispose() {
    for (final c in [_name, _email, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _err(bool bad, String key) => _tried && bad ? context.tr(key) : null;

  String? get _nameError => _err(_name.text.trim().length < 2, 'err_name_required');
  String? get _emailError => _tried
      ? (_email.text.trim().isEmpty
            ? context.tr('err_email_required')
            : (!isValidEmail(_email.text) ? context.tr('err_email_invalid') : null))
      : null;
  String? get _passwordError => _err(!isStrongPassword(_password.text), 'err_password_weak');
  String? get _confirmError => _err(_confirm.text != _password.text, 'err_password_match');

  bool get _valid =>
      _nameError == null && _emailError == null && _passwordError == null && _confirmError == null && _accepted;

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _tried = true;
      _serverError = null;
    });
    if (!_valid) {
      if (!_accepted) setState(() => _serverError = context.tr('err_accept_terms'));
      return;
    }
    setState(() => _busy = true);
    final error = await context.appRead.signUp(name: _name.text, email: _email.text, password: _password.text);
    if (!mounted) return;
    if (error == 'confirm_email_sent') {
      // Email confirmation is on in Supabase: nothing more to do here.
      setState(() {
        _busy = false;
        _confirmSent = true;
      });
    } else if (error != null) {
      setState(() {
        _busy = false;
        _serverError = context.tr(error);
      });
    } else {
      // Signed in: close the auth stack and let the app take over.
      Navigator.of(context).popUntil((r) => r.isFirst);
    }
  }

  void _refresh(_) {
    if (_tried) setState(() {});
  }

  /// A word in the acceptance sentence that opens the page on chartahome.com
  /// instead of ticking the box.
  InlineSpan _link(String label, String page) => WidgetSpan(
    alignment: PlaceholderAlignment.baseline,
    baseline: TextBaseline.alphabetic,
    child: GestureDetector(
      onTap: () => openLegal(context, page),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13.5,
          height: 1.45,
          color: AppColors.ink,
          fontWeight: FontWeight.w600,
          decoration: TextDecoration.underline,
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      compactHero: true,
      title: context.tr('create_account'),
      subtitle: context.tr('signup_sub'),
      onBack: () => Navigator.pop(context),
      footer: AuthSwitch(
        question: context.tr('have_account'),
        action: context.tr('sign_in'),
        onTap: () => Navigator.pop(context),
      ),
      children: [
        if (_confirmSent) AuthBanner(text: context.tr('confirm_email_sent'), success: true),
        if (_serverError != null) AuthBanner(text: _serverError!),
        AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthField(
                label: context.tr('full_name'),
                controller: _name,
                icon: Icons.person_outline_rounded,
                hint: 'Arnaud Fouda',
                capitalization: TextCapitalization.words,
                autofillHints: const [AutofillHints.name],
                error: _nameError,
                onChanged: _refresh,
              ),
              AuthField(
                label: context.tr('email'),
                controller: _email,
                icon: Icons.mail_outline_rounded,
                hint: 'nom@exemple.cm',
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                error: _emailError,
                onChanged: _refresh,
              ),
              AuthField(
                label: context.tr('password'),
                controller: _password,
                icon: Icons.lock_outline_rounded,
                password: true,
                autofillHints: const [AutofillHints.newPassword],
                error: _passwordError,
                onChanged: (_) => setState(() {}),
              ),
              PasswordRules(password: _password.text),
              AuthField(
                label: context.tr('confirm_password'),
                controller: _confirm,
                icon: Icons.lock_outline_rounded,
                password: true,
                autofillHints: const [AutofillHints.newPassword],
                textInputAction: TextInputAction.done,
                error: _confirmError,
                onChanged: _refresh,
                onSubmitted: (_) => _submit(),
              ),
            ],
          ),
        ),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _accepted = !_accepted);
          },
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 22,
                height: 22,
                margin: const EdgeInsets.only(top: 1),
                decoration: BoxDecoration(
                  color: _accepted ? AppColors.ink : AppColors.white,
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(color: _accepted ? AppColors.ink : AppColors.faint, width: 1.5),
                ),
                child: _accepted ? const Icon(Icons.check_rounded, size: 15, color: AppColors.white) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    style: const TextStyle(fontSize: 13.5, height: 1.45, color: AppColors.muted),
                    children: [
                      TextSpan(text: context.tr('accept_terms_a')),
                      _link(context.tr('terms_of_use'), 'terms'),
                      TextSpan(text: context.tr('accept_terms_and')),
                      _link(context.tr('privacy_policy'), 'privacy'),
                      TextSpan(text: context.tr('accept_terms_b')),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 26),
        AuthPrimaryButton(label: context.tr('create_account'), loading: _busy, onPressed: _submit),
      ],
    );
  }
}
