import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../backend/config.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';

/// Pages on chartahome.com: `privacy`, `terms` or `delete-account`.
/// Opened in the in-app browser so the user stays in the app.
Future<void> openLegal(BuildContext context, String page) async {
  final lang = context.appRead.lang;
  final ok = await launchUrl(
    Uri.parse(BackendConfig.legalUrl(page, lang)),
    mode: LaunchMode.inAppBrowserView,
  ).catchError((_) => false);
  if (!ok && context.mounted) toast(context, context.tr('cannot_open_link'), icon: Icons.error_outline_rounded);
}

/// Opens the mail app on a message to support.
Future<void> emailSupport(BuildContext context) async {
  final uri = Uri(
    scheme: 'mailto',
    path: BackendConfig.supportEmail,
    query: 'subject=${Uri.encodeComponent(context.tr('help_email_subject'))}',
  );
  final ok = await launchUrl(uri).catchError((_) => false);
  // No mail app set up: at least show where to write.
  if (!ok && context.mounted) toast(context, BackendConfig.supportEmail, icon: Icons.mail_outline_rounded);
}

/// Starts a phone call (the agent, the agency, a technician). Without a
/// number, or on a device that cannot call, shows what there is instead.
Future<void> callNumber(BuildContext context, String phone) async {
  final digits = phone.replaceAll(RegExp(r'[^\d+]'), '');
  if (digits.isEmpty) {
    toast(context, context.tr('cannot_open_link'), icon: Icons.error_outline_rounded);
    return;
  }
  final ok = await launchUrl(Uri(scheme: 'tel', path: digits)).catchError((_) => false);
  if (!ok && context.mounted) toast(context, phone, icon: Icons.call_rounded);
}
