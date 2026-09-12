/// App-wide constant values. Anything that appears more than once in the
/// codebase (a Firestore collection name, a duration, a route string)
/// belongs here — never typed out again by hand elsewhere.
class AppConstants {
  AppConstants._();

  static const String appName = 'Talkway';
  static const String tagline = 'Talk your way, anywhere.';

  // --- Agora ---
  // TODO: replace with your real App ID from https://console.agora.io
  // Never commit a real production App ID to a public repo — read it from
  // --dart-define or a .env file instead (see README).
  static const String agoraAppId = String.fromEnvironment(
    'AGORA_APP_ID',
    defaultValue: 'YOUR_AGORA_APP_ID',
  );

  // --- Firestore collection names ---
  static const String usersCollection = 'users';
  static const String callsCollection = 'calls';

  // --- Realtime Database paths (used for low-latency call signaling) ---
  static const String callSignalingPath = 'call_signaling';
  static const String presencePath = 'presence';

  // --- Timing ---
  static const Duration ringingTimeout = Duration(seconds: 30);
  static const Duration splashMinDuration = Duration(milliseconds: 1200);
  static const Duration connectingTimeout = Duration(seconds: 20);

  // --- Shared preference / secure storage keys ---
  static const String keyIsFirstLaunch = 'is_first_launch';
}

/// Route name constants for Navigator — avoids typo-prone magic strings
/// scattered across the app.
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String contacts = '/contacts';
  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';
  static const String callHistory = '/history';
  static const String audioCall = '/call/audio';
  static const String videoCall = '/call/video';
  static const String incomingCall = '/call/incoming';
}
