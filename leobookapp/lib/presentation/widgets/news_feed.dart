import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:leobookapp/core/constants/app_colors.dart';
import 'package:leobookapp/core/constants/responsive_constants.dart';
import 'package:leobookapp/data/models/news_model.dart';

class NewsFeed extends StatelessWidget {
  final List<NewsModel> news;

  const NewsFeed({super.key, required this.news});

  @override
  Widget build(BuildContext context) {
    if (news.isEmpty) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardW = Responsive.cardWidth(constraints.maxWidth,
            minWidth: 240, maxWidth: 320);
        final listH = cardW * 0.9; // Proportional to card width

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                children: [
                  Icon(Icons.newspaper, color: AppColors.primary, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    "LATEST UPDATES",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.7)
                          : AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: listH,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: news.length,
                itemBuilder: (context, index) {
                  return _buildNewsCard(context, news[index], isDark, cardW);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNewsCard(
      BuildContext context, NewsModel item, bool isDark, double cardWidth) {
    return GestureDetector(
      onTap: () async {
        final uri = Uri.parse(item.url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        }
      },
      child: Container(
        width: cardWidth,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Container — ratio-based, never clips
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.black.withValues(alpha: 0.04),
                child: Icon(
                  Icons.image_outlined,
                  color: isDark ? Colors.white12 : Colors.black12,
                  size: 36,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                          color: isDark ? Colors.white : AppColors.textDark,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          item.source.toUpperCase(),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.access_time_filled,
                          size: 10,
                          color: AppColors.textGrey.withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item.timeAgo.toUpperCase(),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textGrey.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
