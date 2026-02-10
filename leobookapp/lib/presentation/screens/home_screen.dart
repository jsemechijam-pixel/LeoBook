import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../logic/cubit/home_cubit.dart';
import '../../../logic/cubit/search_cubit.dart';
import '../screens/search_screen.dart';
import '../../core/constants/app_colors.dart';
import '../widgets/match_card.dart';
import '../widgets/header_section.dart';
import '../widgets/featured_carousel.dart';
import '../widgets/news_feed.dart';
import '../widgets/footnote_section.dart';
import 'all_predictions_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<HomeCubit, HomeState>(
          builder: (context, state) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            if (state is HomeLoading) {
              return Center(child: CircularProgressIndicator());
            } else if (state is HomeLoaded) {
              return RefreshIndicator(
                onRefresh: () async {
                  context.read<HomeCubit>().loadDashboard();
                },
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: HeaderSection(
                        selectedDate: state.selectedDate,
                        selectedSport: state.selectedSport,
                        onDateChanged: (date) =>
                            context.read<HomeCubit>().updateDate(date),
                        onSportChanged: (sport) =>
                            context.read<HomeCubit>().updateSport(sport),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 24.0,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(
                                    Icons.search,
                                    size: 20,
                                    color: AppColors.textGrey,
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => BlocProvider(
                                          create: (context) => SearchCubit(
                                            allMatches: state.allMatches,
                                            allRecommendations:
                                                state.allRecommendations,
                                          ),
                                          child: const SearchScreen(),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.tune,
                                    size: 20,
                                    color: AppColors.textGrey,
                                  ),
                                  onPressed: () {},
                                ),
                              ],
                            ),
                            Text(
                              "View More",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textGrey.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: FeaturedCarousel(
                        matches: state.featuredMatches,
                        recommendations: state.filteredRecommendations,
                        allMatches: state.allMatches,
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 16)),
                    SliverToBoxAdapter(child: NewsFeed(news: state.news)),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
                      sliver: SliverToBoxAdapter(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.list_alt,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "ALL PREDICTIONS",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    color: isDark
                                        ? Colors.white
                                        : AppColors.textDark,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 4,
                                    height: 4,
                                    decoration: const BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    "LIVE",
                                    style: TextStyle(
                                      fontSize: 8,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return MatchCard(match: state.filteredMatches[index]);
                        },
                        childCount: state.isAllMatchesExpanded
                            ? state.filteredMatches.length
                            : (state.filteredMatches.length > 12
                                  ? 12
                                  : state.filteredMatches.length),
                      ),
                    ),
                    if (!state.isAllMatchesExpanded &&
                        state.filteredMatches.length > 12)
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 16.0,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AllPredictionsScreen(
                                    date: state.selectedDate,
                                    sport: state.selectedSport,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "LOAD MORE (${state.filteredMatches.length - 12} MATCHES)",
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.1,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(
                                    Icons.keyboard_arrow_down,
                                    color: AppColors.primary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    SliverToBoxAdapter(child: FootnoteSection()),
                  ],
                ),
              );
            } else if (state is HomeError) {
              return Center(child: Text(state.message));
            }
            return Container();
          },
        ),
      ),
    );
  }
}
