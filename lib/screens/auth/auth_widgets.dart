import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../backend/backend.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/logo.dart';

/// Same rules as the SaaS: a valid email, and passwords of at least eight
/// characters (we also ask for a letter and a number).
bool isValidEmail(String v) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim());

bool passwordLongEnough(String v) => v.length >= 8;
bool passwordHasLetter(String v) => RegExp(r'[A-Za-z]').hasMatch(v);
bool passwordHasNumber(String v) => RegExp(r'\d').hasMatch(v);
bool isStrongPassword(String v) => passwordLongEnough(v) && passwordHasLetter(v) && passwordHasNumber(v);

/// Page frame shared by every auth screen (after the reference design): a
/// hero card with the Charta Home door on brand blue, a centred title and
/// subtitle, the form, and a footer link, on plain white.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
    this.onBack,
    this.footer,
    this.compactHero = false,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;
  final VoidCallback? onBack;
  final Widget? footer;

  /// A shorter hero for the longer forms (sign-up, reset).
  final bool compactHero;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.paddingOf(context).bottom + 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Hero(compact: compactHero, onBack: onBack),
                  SizedBox(height: compactHero ? 22 : 28),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.8),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.muted, fontSize: 14.5, height: 1.45),
                    ),
                  ),
                  const SizedBox(height: 26),
                  ...children,
                  if (footer != null) ...[const SizedBox(height: 18), footer!],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Brand card: the open door from the web's hero on the right, a blue wash
/// from the left carrying the wordmark, a tagline and a glass pill.
class _Hero extends StatelessWidget {
  const _Hero({required this.compact, this.onBack});
  final bool compact;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: compact ? 150 : 196,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xl - 6),
        boxShadow: [
          BoxShadow(
            color: AppColors.brand.withValues(alpha: 0.25),
            blurRadius: 30,
            spreadRadius: -8,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xl - 6),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset('assets/hero-door.png', fit: BoxFit.cover, alignment: const Alignment(0.75, 0.2)),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  stops: [0, 0.48, 0.85],
                  colors: [Color(0xF2003152), Color(0xCC0A4A74), Color(0x0014639B)],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 14, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (onBack != null)
                        _GlassButton(
                          onTap: onBack!,
                          child: const Icon(Icons.arrow_back_ios_new_rounded, size: 17, color: AppColors.white),
                        )
                      else
                        const Wordmark(size: 19, dark: true),
                      const Spacer(),
                      const LangToggle(onDark: true),
                    ],
                  ),
                  const Spacer(),
                  if (onBack != null) ...[const Wordmark(size: 17, dark: true), const SizedBox(height: 8)],
                  if (!compact) ...[
                    Text(
                      context.tr('auth_tagline'),
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 16,
                        height: 1.3,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: AppColors.white.withValues(alpha: 0.35)),
                    ),
                    child: Text(
                      context.tr('auth_pill'),
                      style: const TextStyle(color: AppColors.white, fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  const _GlassButton({required this.child, required this.onTap});
  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.white.withValues(alpha: 0.18),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.35)),
      ),
      child: child,
    ),
  );
}

/// Rounded input with a leading icon and a label that sits inside the field
/// and floats up when typing; show/hide for passwords; inline error.
class AuthField extends StatefulWidget {
  const AuthField({
    super.key,
    required this.label,
    required this.controller,
    required this.icon,
    this.hint,
    this.error,
    this.password = false,
    this.keyboardType,
    this.autofillHints,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
    this.onChanged,
    this.prefixText,
    this.capitalization = TextCapitalization.none,
  });

  final String label;
  final TextEditingController controller;
  final IconData icon;
  final String? hint;
  final String? error;
  final bool password;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final String? prefixText;
  final TextCapitalization capitalization;

  @override
  State<AuthField> createState() => _AuthFieldState();
}

class _AuthFieldState extends State<AuthField> {
  late bool _hidden = widget.password;
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.error != null;
    final focused = _focus.hasFocus;
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: BorderSide(color: c, width: w),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              boxShadow: focused
                  ? [
                      BoxShadow(
                        color: AppColors.brand.withValues(alpha: 0.12),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: TextField(
              controller: widget.controller,
              focusNode: _focus,
              obscureText: _hidden,
              keyboardType: widget.keyboardType,
              autofillHints: widget.autofillHints,
              textInputAction: widget.textInputAction,
              textCapitalization: widget.capitalization,
              autocorrect: !widget.password && widget.keyboardType != TextInputType.emailAddress,
              onSubmitted: widget.onSubmitted,
              onChanged: widget.onChanged,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                labelText: widget.label,
                hintText: widget.hint,
                labelStyle: const TextStyle(color: AppColors.muted, fontSize: 15),
                floatingLabelStyle: TextStyle(
                  color: hasError ? AppColors.ink : AppColors.brand,
                  fontWeight: FontWeight.w600,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                // Icon and country code always visible, not only on focus.
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 16, right: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(widget.icon, color: focused ? AppColors.brand : AppColors.muted, size: 21),
                      if (widget.prefixText != null) ...[
                        const SizedBox(width: 10),
                        Text(
                          widget.prefixText!.trim(),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.ink),
                        ),
                        const SizedBox(width: 10),
                        Container(width: 1, height: 22, color: AppColors.line),
                      ],
                    ],
                  ),
                ),
                prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                suffixIcon: widget.password
                    ? IconButton(
                        tooltip: context.tr(_hidden ? 'show_password' : 'hide_password'),
                        icon: Icon(
                          _hidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: AppColors.muted,
                          size: 21,
                        ),
                        onPressed: () => setState(() => _hidden = !_hidden),
                      )
                    : null,
                enabledBorder: border(hasError ? AppColors.ink : AppColors.line, hasError ? 1.4 : 1),
                focusedBorder: border(AppColors.brand, 1.6),
              ),
            ),
          ),
          if (hasError)
            Padding(
              padding: const EdgeInsets.only(top: 7, left: 6),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, size: 15, color: AppColors.ink),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(widget.error!, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Brand-blue gradient pill with a soft glow, for the main auth action.
class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({super.key, required this.label, required this.onPressed, this.loading = false});
  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: enabled || loading ? 1 : 0.45,
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
          gradient: const LinearGradient(colors: [AppColors.azure800, AppColors.azure600]),
          boxShadow: [
            BoxShadow(
              color: AppColors.brand.withValues(alpha: 0.3),
              blurRadius: 22,
              spreadRadius: -6,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: enabled
                ? () {
                    HapticFeedback.lightImpact();
                    onPressed!();
                  }
                : null,
            child: Center(
              child: loading
                  ? const SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.white),
                    )
                  : Text(
                      label,
                      style: const TextStyle(color: AppColors.white, fontSize: 16.5, fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "Or continue with" and the Google / Apple buttons.
class SocialButtons extends StatelessWidget {
  const SocialButtons({super.key, required this.onTap, this.busy});
  final ValueChanged<SocialProvider> onTap;
  final SocialProvider? busy;

  @override
  Widget build(BuildContext context) {
    Widget button(SocialProvider p, Widget icon, String label) => Expanded(
      child: SizedBox(
        height: 54,
        child: OutlinedButton(
          onPressed: busy == null ? () => onTap(p) : null,
          style: OutlinedButton.styleFrom(
            backgroundColor: AppColors.white,
            foregroundColor: AppColors.ink,
            side: const BorderSide(color: AppColors.line),
            shape: const StadiumBorder(),
          ),
          child: busy == p
              ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    icon,
                    const SizedBox(width: 10),
                    Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  ],
                ),
        ),
      ),
    );

    return Column(
      children: [
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(context.tr('or_continue'), style: const TextStyle(color: AppColors.muted, fontSize: 13)),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            button(
              SocialProvider.google,
              const Text(
                'G',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.ink),
              ),
              'Google',
            ),
            const SizedBox(width: 12),
            button(SocialProvider.apple, const Icon(Icons.apple, size: 22), 'Apple'),
          ],
        ),
      ],
    );
  }
}

/// Live checklist under a new password.
class PasswordRules extends StatelessWidget {
  const PasswordRules({super.key, required this.password});
  final String password;

  @override
  Widget build(BuildContext context) {
    Widget rule(bool ok, String label) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ok ? AppColors.brand : AppColors.white,
              border: Border.all(color: ok ? AppColors.brand : AppColors.silver, width: 1.4),
            ),
            child: ok ? const Icon(Icons.check_rounded, size: 12, color: AppColors.white) : null,
          ),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontSize: 13, color: ok ? AppColors.ink : AppColors.muted)),
        ],
      ),
    );
    final met = [passwordLongEnough(password), passwordHasLetter(password), passwordHasNumber(password)];
    final score = met.where((m) => m).length;
    return Padding(
      padding: const EdgeInsets.only(top: 0, bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (var i = 0; i < 3; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    height: 4,
                    decoration: BoxDecoration(
                      color: i < score ? AppColors.brand : AppColors.line,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          rule(met[0], context.tr('rule_length')),
          rule(met[1], context.tr('rule_letter')),
          rule(met[2], context.tr('rule_number')),
        ],
      ),
    );
  }
}

/// Error banner shown above a form after the server says no.
class AuthBanner extends StatelessWidget {
  const AuthBanner({super.key, required this.text, this.success = false});
  final String text;
  final bool success;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 20),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: success ? AppColors.brand : AppColors.white,
      borderRadius: BorderRadius.circular(AppRadius.md),
      border: Border.all(color: success ? AppColors.brand : AppColors.ink, width: 1.2),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          success ? Icons.check_circle_rounded : Icons.error_outline_rounded,
          size: 20,
          color: success ? AppColors.white : AppColors.ink,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.4,
              fontWeight: FontWeight.w500,
              color: success ? AppColors.white : AppColors.ink,
            ),
          ),
        ),
      ],
    ),
  );
}

/// "Question? Action" line at the bottom of auth screens.
class AuthSwitch extends StatelessWidget {
  const AuthSwitch({super.key, required this.question, required this.action, required this.onTap});
  final String question;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Center(
    child: GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '$question  ',
                style: const TextStyle(color: AppColors.muted),
              ),
              TextSpan(
                text: action,
                style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.brand),
              ),
            ],
          ),
          style: const TextStyle(fontSize: 14.5),
        ),
      ),
    ),
  );
}

/// Six boxes backed by one hidden field so paste and SMS/email autofill work.
class OtpField extends StatelessWidget {
  const OtpField({super.key, required this.controller, required this.focusNode, required this.onChanged});
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final text = controller.text;
    return GestureDetector(
      onTap: focusNode.requestFocus,
      child: Stack(
        children: [
          Opacity(
            opacity: 0,
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              keyboardType: TextInputType.number,
              autofillHints: const [AutofillHints.oneTimeCode],
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
              onChanged: onChanged,
            ),
          ),
          Row(
            children: [
              for (var i = 0; i < 6; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    height: 60,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(
                        color: i == text.length ? AppColors.brand : AppColors.line,
                        width: i == text.length ? 1.6 : 1,
                      ),
                    ),
                    child: Text(
                      i < text.length ? text[i] : '',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class LangToggle extends StatelessWidget {
  const LangToggle({super.key, this.onDark = false});
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: onDark ? AppColors.white.withValues(alpha: 0.18) : AppColors.white,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: onDark ? AppColors.white.withValues(alpha: 0.35) : AppColors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final l in const ['fr', 'en'])
            GestureDetector(
              onTap: () => app.setLang(l),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                decoration: BoxDecoration(
                  color: app.lang == l ? (onDark ? AppColors.white : AppColors.brand) : Colors.transparent,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  l.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: app.lang == l
                        ? (onDark ? AppColors.brand : AppColors.white)
                        : (onDark ? AppColors.white : AppColors.muted),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
