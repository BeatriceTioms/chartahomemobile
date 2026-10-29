import 'dart:async';

import 'package:flutter/material.dart';

import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import 'auth_widgets.dart';

enum _Step { email, code, password }

/// Reset in three short steps on one screen: email → 6-digit code from the
/// email → new password. Ends back on login with the email filled in.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, this.email});
  final String? email;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  _Step _step = _Step.email;
  late final _email = TextEditingController(text: widget.email);
  final _code = TextEditingController();
  final _codeFocus = FocusNode();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  bool _tried = false;
  String? _serverError;
  int _resendIn = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in [_email, _code, _password, _confirm]) {
      c.dispose();
    }
    _codeFocus.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    _timer?.cancel();
    setState(() => _resendIn = 30);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _resendIn--);
      if (_resendIn <= 0) t.cancel();
    });
  }

  Future<void> _sendCode({bool resend = false}) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _tried = true;
      _serverError = null;
    });
    if (!isValidEmail(_email.text)) return;
    setState(() => _busy = true);
    await context.appRead.requestPasswordReset(_email.text.trim());
    if (!mounted) return;
    setState(() {
      _busy = false;
      _tried = false;
      _step = _Step.code;
      _code.clear();
    });
    _startResendTimer();
    if (resend) toast(context, context.tr('code_resent'));
    Future.delayed(const Duration(milliseconds: 300), () => _codeFocus.requestFocus());
  }

  Future<void> _verify() async {
    if (_code.text.length != 6 || _busy) return;
    setState(() {
      _busy = true;
      _serverError = null;
    });
    final error = await context.appRead.verifyResetCode(_email.text.trim(), _code.text);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (error != null) {
        _serverError = context.tr(error);
      } else {
        _step = _Step.password;
      }
    });
  }

  Future<void> _savePassword() async {
    FocusScope.of(context).unfocus();
    setState(() => _tried = true);
    if (!isStrongPassword(_password.text) || _confirm.text != _password.text) return;
    setState(() => _busy = true);
    await context.appRead.updatePassword(_email.text.trim(), _password.text);
    if (!mounted) return;
    // Back to login with the email filled in; the login screen shows the
    // "password updated" banner.
    Navigator.of(context).pop(_email.text.trim());
  }

  void _back() {
    if (_step == _Step.email) {
      Navigator.pop(context);
    } else {
      setState(() {
        _step = _step == _Step.password ? _Step.code : _Step.email;
        _serverError = null;
        _tried = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final (title, subtitle) = switch (_step) {
      _Step.email => (context.tr('reset_title'), context.tr('reset_sub')),
      _Step.code => (context.tr('check_email'), context.tr('reset_code_sent', {'email': _email.text.trim()})),
      _Step.password => (context.tr('new_password_title'), context.tr('new_password_sub')),
    };

    return AuthScaffold(
      compactHero: true,
      title: title,
      subtitle: subtitle,
      onBack: _back,
      children: [
        _StepDots(index: _step.index),
        const SizedBox(height: 24),
        if (_serverError != null) AuthBanner(text: _serverError!),
        ...switch (_step) {
          _Step.email => _emailStep(),
          _Step.code => _codeStep(),
          _Step.password => _passwordStep(),
        },
      ],
    );
  }

  List<Widget> _emailStep() => [
    AuthField(
      label: context.tr('email'),
      controller: _email,
      icon: Icons.mail_outline_rounded,
      hint: 'nom@exemple.cm',
      keyboardType: TextInputType.emailAddress,
      autofillHints: const [AutofillHints.email],
      textInputAction: TextInputAction.done,
      error: _tried && !isValidEmail(_email.text) ? context.tr('err_email_invalid') : null,
      onChanged: (_) => _tried ? setState(() {}) : null,
      onSubmitted: (_) => _sendCode(),
    ),
    const SizedBox(height: 8),
    AuthPrimaryButton(label: context.tr('send_code'), loading: _busy, onPressed: _sendCode),
  ];

  List<Widget> _codeStep() => [
    OtpField(
      controller: _code,
      focusNode: _codeFocus,
      onChanged: (v) {
        setState(() => _serverError = null);
        if (v.length == 6) _verify();
      },
    ),
    const SizedBox(height: 18),
    Center(
      child: TextButton(
        onPressed: _resendIn > 0 ? null : () => _sendCode(resend: true),
        child: Text(
          _resendIn > 0 ? context.tr('resend_in', {'n': _resendIn}) : context.tr('resend'),
          style: TextStyle(color: _resendIn > 0 ? AppColors.faint : AppColors.ink, fontWeight: FontWeight.w600),
        ),
      ),
    ),
    const SizedBox(height: 12),
    AuthPrimaryButton(label: context.tr('verify'), loading: _busy, onPressed: _code.text.length == 6 ? _verify : null),
    const SizedBox(height: 14),
    Text(
      context.tr('check_spam'),
      textAlign: TextAlign.center,
      style: const TextStyle(color: AppColors.faint, fontSize: 12.5, height: 1.4),
    ),
  ];

  List<Widget> _passwordStep() => [
    AuthField(
      label: context.tr('new_password'),
      controller: _password,
      icon: Icons.lock_outline_rounded,
      password: true,
      autofillHints: const [AutofillHints.newPassword],
      error: _tried && !isStrongPassword(_password.text) ? context.tr('err_password_weak') : null,
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
      error: _tried && _confirm.text != _password.text ? context.tr('err_password_match') : null,
      onChanged: (_) => _tried ? setState(() {}) : null,
      onSubmitted: (_) => _savePassword(),
    ),
    const SizedBox(height: 8),
    AuthPrimaryButton(label: context.tr('save_password'), loading: _busy, onPressed: _savePassword),
  ];
}

class _StepDots extends StatelessWidget {
  const _StepDots({required this.index});
  final int index;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (var i = 0; i < 3; i++) ...[
        if (i > 0) const SizedBox(width: 6),
        Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 4,
            decoration: BoxDecoration(
              color: i <= index ? AppColors.brand : AppColors.line,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ],
    ],
  );
}
