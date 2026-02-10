
class NewsModel {
  final String id;
  final String title;
  final String imageUrl;
  final String source; // e.g., "Sky Sports", "BBC"
  final String timeAgo; // e.g., "2h ago"
  final String url;

  NewsModel({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.source,
    required this.timeAgo,
    required this.url,
  });
}
