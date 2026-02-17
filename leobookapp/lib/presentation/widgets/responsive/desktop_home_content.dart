import 'package:flutter/material.dart';
import 'top_predictions_grid.dart';
import 'category_bar.dart';
import 'accuracy_report_card.dart';
import 'top_odds_list.dart';
import 'side_ruler.dart';
import '../../../logic/cubit/home_cubit.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/match_sorter.dart';
import '../match_card.dart';
import '../footnote_section.dart';
import 'package:leobookapp/data/models/match_model.dart';

class DesktopHomeContent extends StatefulWidget {
  final HomeLoaded state;
  final bool isSidebarExpanded;

  const DesktopHomeContent({
    super.key,
    required this.state,
    required this.isSidebarExpanded,
  });

  @override
  State<DesktopHomeContent> createState() => _DesktopHomeContentState();
}

class _DesktopHomeContentState extends State<DesktopHomeContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController;
  int _visibleMatchCount = 12;

  // Match counts for tab labels
  int _allCount = 0;
  int _finishedCount = 0;
  int _scheduledCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
    _scrollController = ScrollController();
    _scrollController.addListener(() => setState(() {}));
    _computeCounts();
  }

  @override
  void didUpdateWidget(covariant DesktopHomeContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      _computeCounts();
    }
  }

  void _computeCounts() {
    final matches = widget.state.filteredMatches.cast<MatchModel>();
    _allCount = matches.length;
    _finishedCount =
        MatchSorter.getSortedMatches(matches, MatchTabType.finished)
            .whereType<MatchModel>()
            .length;
    _scheduledCount =
        MatchSorter.getSortedMatches(matches, MatchTabType.scheduled)
            .whereType<MatchModel>()
            .length;
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      if (_visibleMatchCount != 12) {
        setState(() => _visibleMatchCount = 12);
      } else {
        setState(() {});
      }
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const TopPredictionsGrid(),
                  const SizedBox(height: 48),
                  const AccuracyReportCard(),
                  const SizedBox(height: 48),
                  const TopOddsList(),
                  const SizedBox(height: 48),
                ]),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyHeaderDelegate(
                height: 92,
                child: Container(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: const CategoryBar(),
                ),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyHeaderDelegate(
                height: 50,
                child: Container(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  alignment: Alignment.centerLeft,
                  child: _buildTabBar(),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.only(
                  left: 40, right: 40, top: 24, bottom: 24),
              sliver: SliverToBoxAdapter(
                child: Builder(
                  builder: (context) {
                    final index = _tabController.index;
                    MatchTabType type;
                    switch (index) {
                      case 1:
                        type = MatchTabType.finished;
                        break;
                      case 2:
                        type = MatchTabType.scheduled;
                        break;
                      default:
                        type = MatchTabType.all;
                    }

                    return _buildMatchGroupedList(type);
                  },
                ),
              ),
            ),
            // Footer
            const SliverToBoxAdapter(
              child: FootnoteSection(),
            ),
          ],
        ),
        // Sticky Side Ruler
        Positioned(
          top: 150, // Positioned below the typical header area
          right: 20,
          bottom: 100, // Leave space for footer
          width: 36,
          child: Builder(
            builder: (context) {
              final index = _tabController.index;
              MatchTabType type;
              switch (index) {
                case 1:
                  type = MatchTabType.finished;
                  break;
                case 2:
                  type = MatchTabType.scheduled;
                  break;
                default:
                  type = MatchTabType.all;
              }

              // Only show if we've scrolled past the top sections
              final showRuler = _scrollController.hasClients &&
                  _scrollController.offset > 400;

              if (!showRuler) return const SizedBox.shrink();

              return Center(
                child: _buildSideRuler(type) ?? const SizedBox.shrink(),
              );
            },
          ),
        ),
      ],
    );
  }

  TabBar _buildTabBar() {
    return TabBar(
      controller: _tabController,
      isScrollable: true,
      labelPadding: const EdgeInsets.only(right: 32),
      indicatorColor: AppColors.primary,
      indicatorWeight: 4,
      dividerColor: Colors.white10,
      labelColor: Colors.white,
      unselectedLabelColor: AppColors.textGrey,
      labelStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.5,
      ),
      tabs: [
        Tab(text: "ALL PREDICTIONS ($_allCount)"),
        Tab(text: "FINISHED ($_finishedCount)"),
        Tab(text: "SCHEDULED ($_scheduledCount)"),
      ],
    );
  }

  // ---------- Grouped Match List ----------

  Widget _buildMatchGroupedList(MatchTabType type) {
    final items = MatchSorter.getSortedMatches(
      widget.state.filteredMatches.cast(),
      type,
    );

    if (items.isEmpty) {
      return const Center(
        child: Text(
          "No matches found for this category",
          style: TextStyle(color: AppColors.textGrey),
        ),
      );
    }

    final List<Widget> children = [];
    List<MatchModel> currentGroupMatches = [];

    void flushGroup() {
      if (currentGroupMatches.isNotEmpty) {
        final groupSnapshot = List<MatchModel>.from(currentGroupMatches);
        children.add(
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: widget.isSidebarExpanded ? 3 : 4,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              mainAxisExtent: 350,
            ),
            itemCount: groupSnapshot.length,
            itemBuilder: (context, idx) => MatchCard(match: groupSnapshot[idx]),
          ),
        );
        children.add(const SizedBox(height: 32));
        currentGroupMatches = [];
      }
    }

    for (final item in items) {
      if (item is MatchGroupHeader) {
        flushGroup();
        children.add(_buildSectionHeader(item.title));
      } else if (item is MatchModel) {
        currentGroupMatches.add(item);
      }
    }
    flushGroup();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 24),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              height: 1,
              color: Colors.white10,
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Side Ruler ----------

  Widget? _buildSideRuler(MatchTabType type) {
    List<String> labels;
    switch (type) {
      case MatchTabType.all:
        final leagueNames = widget.state.filteredMatches
            .map((m) => m.league ?? 'Other')
            .toSet()
            .toList()
          ..sort();
        labels = SideRuler.alphabeticalLabels(leagueNames);
        break;
      case MatchTabType.finished:
        labels = SideRuler.finishedTimeLabels();
        break;
      case MatchTabType.scheduled:
        labels = SideRuler.scheduledTimeLabels();
        break;
    }

    if (labels.isEmpty) return null;

    return SideRuler(
      labels: labels,
      onLabelTapped: (idx) => _scrollToSection(idx, labels[idx], type),
    );
  }

  void _scrollToSection(int index, String label, MatchTabType type) {
    // Basic jumping logic
    final targetOffset = 800.0 + (index * 300.0);
    _scrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }
}

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  _StickyHeaderDelegate({required this.child, required this.height});

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  bool shouldRebuild(_StickyHeaderDelegate oldDelegate) =>
      oldDelegate.height != height || oldDelegate.child != child;
}
