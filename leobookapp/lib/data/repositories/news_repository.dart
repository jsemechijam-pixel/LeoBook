
import '../models/news_model.dart';

class NewsRepository {
  Future<List<NewsModel>> fetchNews() async {
    // Mock Data for now as no backend source exists yet
    await Future.delayed(Duration(milliseconds: 800)); // Simulate latency
    
    return [
      NewsModel(
        id: '1',
        title: "Mbappe Scores Hat-trick in Real Madrid Thriller",
        imageUrl: "https://via.placeholder.com/150", // Placeholder
        source: "Marca",
        timeAgo: "1h ago",
        url: "https://www.marca.com",
      ),
      NewsModel(
        id: '2',
        title: "Premier League Title Race Heats Up: Arsenal vs City",
        imageUrl: "https://via.placeholder.com/150",
        source: "Sky Sports",
        timeAgo: "3h ago",
        url: "https://www.skysports.com",
      ),
      NewsModel(
        id: '3',
        title: "Transfer Rumors: Neymar to return to Santos?",
        imageUrl: "https://via.placeholder.com/150",
        source: "Goal.com",
        timeAgo: "5h ago",
        url: "https://www.goal.com",
      ),
    ];
  }
}
