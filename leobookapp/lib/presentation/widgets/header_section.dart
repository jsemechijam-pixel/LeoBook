import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../logic/cubit/home_cubit.dart';
import '../../../logic/cubit/search_cubit.dart';
import '../screens/search_screen.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';

class HeaderSection extends StatelessWidget {
  final DateTime selectedDate;
  final String selectedSport;
  final Function(DateTime) onDateChanged;
  final Function(String) onSportChanged;

  const HeaderSection({
    super.key,
    required this.selectedDate,
    required this.selectedSport,
    required this.onDateChanged,
    required this.onSportChanged,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Bar
        Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.sports_soccer, color: AppColors.primary, size: 30),
                  const SizedBox(width: 10),
                  Text(
                    "LeoBook",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : AppColors.textDark,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.search,
                      color: AppColors.textGrey,
                      size: 24,
                    ),
                    onPressed: () {
                      final homeState = context.read<HomeCubit>().state;
                      if (homeState is HomeLoaded) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BlocProvider(
                              create: (context) => SearchCubit(
                                allMatches: homeState.allMatches,
                                allRecommendations:
                                    homeState.allRecommendations,
                              ),
                              child: const SearchScreen(),
                            ),
                          ),
                        );
                      }
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.menu, color: AppColors.textGrey, size: 24),
                    onPressed: () {},
                  ),
                ],
              ),
            ],
          ),
        ),

        // Navigation Tabs (Active Sport)
        SizedBox(
          height: 48,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildNavTab(context, "All", selectedSport == 'ALL'),
                _buildNavTab(context, "Football", selectedSport == 'FOOTBALL'),
                _buildNavTab(
                  context,
                  "Basketball",
                  selectedSport == 'BASKETBALL',
                ),
                _buildNavTab(context, "Tennis", selectedSport == 'TENNIS'),
                _buildNavTab(context, "Esports", selectedSport == 'ESPORTS'),
              ],
            ),
          ),
        ),

        Divider(
          height: 1,
          color: isDark
              ? AppColors.cardDark
              : Colors.grey.withValues(alpha: 0.2),
        ),

        // Date Strip
        Container(
          height: 85, // Increased from 75 to prevent overflow
          margin: const EdgeInsets.only(top: 4),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 7,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemBuilder: (context, index) {
              final dayOffset = index - 3;
              final date = DateTime(
                now.year,
                now.month,
                now.day,
              ).add(Duration(days: dayOffset));

              final isSelected =
                  date.year == selectedDate.year &&
                  date.month == selectedDate.month &&
                  date.day == selectedDate.day;

              return _buildDateItem(context, date, isSelected);
            },
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildNavTab(BuildContext context, String title, bool isSelected) {
    return GestureDetector(
      onTap: () => onSportChanged(title.toUpperCase()),
      child: Container(
        margin: const EdgeInsets.only(right: 28),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: isSelected
              ? const Border(
                  bottom: BorderSide(color: AppColors.primary, width: 2.5),
                )
              : null,
        ),
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isSelected ? AppColors.primary : AppColors.textGrey,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildDateItem(BuildContext context, DateTime date, bool isSelected) {
    final now = DateTime.now();
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final dayName = DateFormat('EEE').format(date).toUpperCase();
    final dayNum = DateFormat('d MMM').format(date).toUpperCase();

    return GestureDetector(
      onTap: () => onDateChanged(date),
      child: Container(
        width: 75,
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  width: 1,
                )
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isToday ? "TODAY" : dayName,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                color: isSelected
                    ? AppColors.primary
                    : (isDark ? Colors.white38 : Colors.black38),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              dayNum,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? AppColors.primary
                    : (isDark ? Colors.white70 : Colors.black87),
              ),
            ),
            if (isSelected) ...[
              const SizedBox(height: 4),
              Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
