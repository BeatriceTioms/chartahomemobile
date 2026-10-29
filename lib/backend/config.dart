/// Where the app's backend lives. The same Supabase project and the same web
/// app (Next.js on Vercel) as the Charta Home dashboard.
///
/// Values come from `--dart-define-from-file=env/prod.json` (see
/// env/example.json). With none set, the app runs on demo data.
class BackendConfig {
  BackendConfig._();

  /// Supabase · Project Settings › API. The anon key is public by design;
  /// row level security is what protects the data.
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  /// The web app, e.g. https://chartahome.com. PayUnit, Resend and signed
  /// photo URLs are server-side there; the app never holds their keys.
  static const apiBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// Deep link the app opens on (iOS URL type / Android intent filter).
  /// Add `chartahome://**` to Supabase › Authentication › URL Configuration.
  static const scheme = 'chartahome';
  static const authRedirect = '$scheme://auth-callback';
  static const paymentReturn = '$scheme://payment-return';

  /// Shows the Google and Apple buttons. Set SOCIAL_SIGN_IN to true only once
  /// both providers are on in Supabase › Authentication › Providers: App
  /// Review taps every button, and a dead one is a rejection.
  static const socialSignIn = bool.fromEnvironment('SOCIAL_SIGN_IN');

  /// The public website, where the privacy policy, terms and account
  /// deletion pages live. Linked from the app and from both store listings.
  static const website = 'https://www.chartahome.com';
  static const supportEmail = 'hello@chartahome.com';
  static String legalUrl(String page, String lang) => '$website/${lang == 'en' ? 'en' : 'fr'}/$page';

  static bool get isConfigured => supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty && apiBaseUrl.isNotEmpty;
}
