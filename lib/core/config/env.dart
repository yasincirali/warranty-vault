/// Build-time configuration. Values come only from `--dart-define`;
/// there are deliberately no fallback literals, so no key ever lands in git.
abstract final class Env {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  /// Without a backend the app runs on demo data (design reviews, tests,
  /// store screenshots).
  static bool get hasBackend => supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
