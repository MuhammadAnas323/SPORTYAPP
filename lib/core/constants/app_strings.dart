/// User-facing copy used across SportyApp.
///
/// Keeping strings centralised makes future localisation (arb) trivial.
abstract final class AppStrings {
  AppStrings._();

  // ---- Brand ----------------------------------------------------------------
  static const String appName = 'SportyApp';
  static const String appTagline = 'Your feeds. Your channels. One stadium.';
  static const String appDescription =
      'SportyApp is a shell that comes alive with the sport APIs you connect. '
      'No bundled data — every match, score and card below is streamed straight '
      'from a channel you own.';

  // ---- Auth (Firebase email/password) ---------------------------------------
  static const String loginTitle = 'Welcome back';
  static const String loginSubtitle =
      'Sign in with your SportyApp account to open your connected channels.';
  static const String registerTitle = 'Create your account';
  static const String registerSubtitle =
      'Your channels and settings sync to your SportyApp account.';
  static const String forgotPasswordTitle = 'Reset password';
  static const String forgotPasswordSubtitle =
      'Enter your email and we will send you a link to reset your password.';
  static const String emailLabel = 'Email';
  static const String emailHint = 'you@example.com';
  static const String passwordLabel = 'Password';
  static const String passwordHint = 'At least 8 characters';
  static const String nameLabel = 'Name';
  static const String nameHint = 'How should we greet you?';
  static const String signIn = 'Sign in';
  static const String createAccount = 'Create account';
  static const String noAccount = 'No account yet?';
  static const String haveAccount = 'Already have an account?';
  static const String signUp = 'Sign up';
  static const String resetPassword = 'Reset password';
  static const String backToLogin = 'Back to sign in';
  static const String passwordResetSent =
      'We have emailed you a link to reset your password. Check your inbox.';
  static const String signOut = 'Sign out';

  // ---- Empty state CTA --------------------------------------------------------
  static const String noMatchesTitle = 'No matches yet';
  static const String noMatchesBody =
      'Matches from your connected channels will appear here.';
  static const String noChannelsTitle = 'No channels connected yet';
  static const String noChannelsBody =
      'SportyApp has no data of its own. Connect and verify at least one sport '
      'API and your Home feed will appear here.';
  static const String addFirstChannel = 'Add your first channel';
  static const String nothingLiveTitle = 'Nothing live right now';
  static const String nothingLiveBody =
      'None of your connected channels report a live match at the moment. '
      'Head back Home for upcoming and recent action.';
  static const String goHome = 'Back to Home';

  // ---- Home / Live -----------------------------------------------------------
  static const String homeTitle = 'Home';
  static const String liveTitle = 'Live';
  static const String searchHint = 'Search your channels';
  static const String filterAll = 'All';
  static const String filterCricket = 'Cricket';
  static const String filterFootball = 'Football';
  static const String featuredLive = 'Featured live';
  static const String liveNow = 'LIVE';
  static const String upcoming = 'Upcoming';
  static const String recent = 'Recent';
  static const String pullToRefresh = 'Pull to refresh every channel';
  static const String refreshing = 'Talking to your channels…';
  static const String via = 'via';
  static const String sourceFetchFailed =
      'This channel just failed. The rest of your feed is unaffected.';
  static const String retry = 'Retry';
  static const String viewAll = 'View all';

  // ---- Match detail ----------------------------------------------------------
  static const String tabInfo = 'Info';
  static const String tabScorecard = 'Scorecard';
  static const String tabMatchStats = 'Stats';
  static const String tabCommentary = 'Commentary';
  static const String noCommentary = 'No commentary returned for this match.';
  static const String noScorecard = 'No scorecard returned for this match.';
  static const String matchLoading = 'Fetching match detail…';
  static const String matchDetailError =
      'This channel failed to return match detail.';

  // ---- Profile ----------------------------------------------------------------
  static const String profileTitle = 'Profile';
  static const String accountSection = 'Account';
  static const String apiIntegrationsSection = 'API Integrations';
  static const String apiSettings = 'API Settings';
  static const String settingsSection = 'Settings';
  static const String aboutSection = 'About';
  static const String supportSection = 'Support & Contact';
  static const String editProfile = 'Edit profile';
  static const String addChannel = 'Add API';
  static const String addChannelBody =
      'Connect a sport data source to your feed. You can add as many as you like.';
  static const String chooseApiType = 'Choose API type';
  static const String connectedApis = 'Connected APIs';
  static const String connectedApisEmpty = 'No connected APIs yet';
  static const String channelsEmpty = 'No connections yet';
  static const String channelsEmptyBody =
      'Add your first sport API to start building your feed.';
  static const String connectionLabel = 'Connection name';
  static const String connectionLabelHint = 'e.g. My cricket API';
  static const String sportType = 'Sport type';
  static const String sportTypeHelper =
      'You can add as many Cricket and Football APIs as you like.';
  static const String cricketApi = 'Cricket API';
  static const String footballApi = 'Football API';
  static const String cricketApiHelper =
      'Scores, ball-by-ball commentary and live streams';
  static const String footballApiHelper =
      'Scores, fixtures and live streams';
  static const String baseUrl = 'Base URL / host';
  static const String baseUrlHint = 'https://api.example.com/v1';
  static const String apiKey = 'API key';
  static const String apiKeyHint = 'Paste your secret key here';
  static const String authStyle = 'Auth style';
  static const String authStyleBearer = 'Bearer token';
  static const String authStyleHeader = 'Custom header';
  static const String authStyleQuery = 'Query param';
  static const String customHeaderName = 'Header name';
  static const String customHeaderNameHint = 'e.g. X-Api-Key';
  static const String queryParamName = 'Query param name';
  static const String queryParamNameHint = 'e.g. api_key';
  static const String extraHeaders = 'Extra headers (optional)';
  static const String extraHeadersHint = 'Header: Value, one per line';
  static const String testConnection = 'Test connection';
  static const String testingConnection = 'Testing…';
  static const String testSuccess = 'Connection verified';
  static const String testSuccessBody =
      'The host accepted your key. You can save this channel.';
  static const String testFailure = 'Test failed';
  static const String save = 'Save channel';
  static const String saveRequired =
      'You must pass a connection test before saving.';
  static const String editConnection = 'Edit channel';
  static const String deleteConnection = 'Delete channel';
  static const String deleteConfirmTitle = 'Delete this channel?';
  static const String deleteConfirmBody =
      'Its saved key will be permanently removed from your account.';
  static const String cancel = 'Cancel';
  static const String delete = 'Delete';
  static const String enabled = 'Enabled';
  static const String disabled = 'Paused';
  static const String reTest = 'Re-test';
  static const String connected = 'Connected';
  static const String notTested = 'Not tested';
  static const String failed = 'Failed';
  static const String testing = 'Testing…';
  static const String liveNowStatus = 'Live now';
  static const String keyMasked = '••••••••';
  static const String poweredBy = 'Powered by your own channels';

  // ---- Settings ----------------------------------------------------------------
  static const String theme = 'Theme';
  static const String themeLight = 'Light';
  static const String themeDark = 'Dark';
  static const String themeSystem = 'System';
  static const String notifications = 'Notifications';
  static const String notificationsLiveStarts =
      'Live-start alerts for followed channels';
  static const String notificationsSounds = 'Sounds';
  static const String notificationsNote =
      'Notification preferences are local placeholders — push delivery via FCM '
      'is a planned extension (see README "Future-ready hooks").';

  // ---- About / Support ---------------------------------------------------------
  static const String aboutBody =
      'SportyApp is a multi-sport live companion that renders only the data your '
      'own connected sport APIs return. No bundled backend, no sample data.';
  static const String version = 'Version 0.1.0';
  static const String supportBody =
      'SportyApp does not own any sport data. For issues with a specific source, '
      'please contact the provider of the API you connected.';
  static const String contactEmail = 'support@sportyapp.app';
  static const String sendFeedback = 'Send feedback';
  static const String documentation = 'Documentation';
}
