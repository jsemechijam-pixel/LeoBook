
class MatchModel {
  final String date;
  final String time;
  final String homeTeam;
  final String awayTeam;
  final String? homeScore;
  final String? awayScore;
  final String status; // Scheduled, Live, Finished
  final String? prediction;
  final String? odds; // e.g. "1.68"
  final String? confidence; // High/Medium/Low
  final String? league; // e.g. "ENGLAND: Premier League"
  final String sport;
  
  final String fixtureId; // Key for merging
  final bool isLive;
  final String? liveMinute; 
  final bool isFeatured;
  final String? valueTag;

  MatchModel({
    required this.fixtureId,
    required this.date,
    required this.time,
    required this.homeTeam,
    required this.awayTeam,
    this.homeScore,
    this.awayScore,
    required this.status,
    required this.sport,
    this.league,
    this.prediction,
    this.odds,
    this.confidence,
    this.isLive = false,
    this.liveMinute,
    this.isFeatured = false,
    this.valueTag,
  });

  factory MatchModel.fromCsv(Map<String, dynamic> row, [Map<String, dynamic>? predictionData]) {
    final fixtureId = row['fixture_id']?.toString() ?? '';
    final isLive = (row['match_status'] ?? '').toString().toLowerCase().contains('live');
    final matchLink = row['match_link']?.toString() ?? '';
    
    String sport = 'Football';
    if (matchLink.contains('/basketball/')) sport = 'Basketball';
    if (matchLink.contains('/tennis/')) sport = 'Tennis';
    if (matchLink.contains('/hockey/')) sport = 'Hockey';

    // Merge prediction data if available
    String? prediction;
    String? confidence;
    bool isFeatured = false;
    
    if (predictionData != null) {
      prediction = predictionData['prediction'];
      confidence = predictionData['confidence'];
      if (confidence != null && (confidence.contains('High') || confidence.contains('Very High'))) {
        isFeatured = true;
      }
    }

    return MatchModel(
      fixtureId: fixtureId,
      date: row['date'] ?? '',
      time: row['match_time'] ?? '',
      homeTeam: row['home_team'] ?? '',
      awayTeam: row['away_team'] ?? '',
      homeScore: row['home_score']?.toString(), 
      awayScore: row['away_score']?.toString(),
      status: row['match_status'] ?? 'Scheduled',
      league: row['region_league']?.toString(), // Added
      sport: sport,
      isLive: isLive,
      prediction: prediction,
      confidence: confidence,
      isFeatured: isFeatured,
    );
  }
}
