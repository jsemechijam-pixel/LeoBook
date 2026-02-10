class ApiUrls {
  // Access localhost from Android Emulator: 10.0.2.2
  // Access localhost from Web: localhost

  static const String _githubBase =
      "https://raw.githubusercontent.com/emenikecj/LeoBook/main/Data/Store";

  static String get baseUrl => _githubBase;

  static String get schedules => "$baseUrl/schedules.csv";
  static String get predictions => "$baseUrl/predictions.csv";
  static String get predictionsDb => "$baseUrl/predictions.db";
  static String get recommended => "$baseUrl/recommended.json";
  static String get teams => "$baseUrl/teams.csv";
}
