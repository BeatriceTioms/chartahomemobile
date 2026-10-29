import 'dart:async';

import 'package:url_launcher/url_launcher.dart';

import 'backend.dart';

/// Opens PayUnit's hosted checkout (MTN MoMo, Orange Money or card are
/// chosen there) and waits for the web app to confirm the outcome.
///
/// PayUnit sends the resident back to the web's /pay/return, which bounces
/// to chartahome://payment-return; either way the answer comes from asking
/// the server, which asks PayUnit, never from the redirect itself.
Future<PaymentOutcome> runCheckout(
  ChartaBackend backend,
  CheckoutSession session, {
  Duration every = const Duration(seconds: 3),
  Duration timeout = const Duration(minutes: 10),
}) async {
  final url = session.checkoutUrl;
  if (url != null) {
    final opened = await launchUrl(url, mode: LaunchMode.inAppBrowserView);
    if (!opened) throw BackendException('err_checkout_open');
  }
  final deadline = DateTime.now().add(timeout);
  while (true) {
    final outcome = await backend.paymentStatus(session.reference);
    if (outcome != PaymentOutcome.pending) {
      if (url != null) unawaited(closeInAppWebView());
      return outcome;
    }
    if (DateTime.now().isAfter(deadline)) return PaymentOutcome.pending;
    await Future.delayed(every);
  }
}
