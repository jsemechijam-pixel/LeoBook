import 'package:flutter/material.dart';
import '../../data/models/match_model.dart';
import '../../core/constants/app_colors.dart';
import '../screens/match_details_screen.dart';

class MatchCard extends StatelessWidget {
  final MatchModel match;
  const MatchCard({super.key, required this.match});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isFinished =
        match.status.toLowerCase().contains('finished') ||
        match.status.toUpperCase() == 'FT';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MatchDetailsScreen(match: match),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: match.isLive
                ? AppColors.liveRed.withValues(alpha: 0.3)
                : (isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.05)),
            width: match.isLive ? 1.5 : 1.0,
          ),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              children: [
                // Header (League & Time)
                Column(
                  children: [
                    Text(
                      (match.league ?? "SOCCER").toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textGrey.withValues(alpha: 0.8),
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      match.status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: match.isLive
                            ? AppColors.liveRed
                            : AppColors.textGrey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Teams Comparison / Result
                if (isFinished)
                  _buildFinishedLayout(isDark)
                else
                  _buildActiveLayout(isDark),

                const SizedBox(height: 20),

                // Prediction Section
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: match.isLive
                        ? AppColors.liveRed.withValues(alpha: 0.05)
                        : (isDark
                              ? Colors.white.withValues(alpha: 0.03)
                              : AppColors.backgroundLight),
                    borderRadius: BorderRadius.circular(12),
                    border: match.isLive
                        ? Border.all(
                            color: AppColors.liveRed.withValues(alpha: 0.1),
                          )
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            match.isLive
                                ? "IN-PLAY PREDICTION"
                                : "LEO PREDICTION",
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: match.isLive
                                  ? AppColors.liveRed
                                  : AppColors.textGrey,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            match.prediction ?? "N/A",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isFinished
                                  ? AppColors.success
                                  : AppColors.primary,
                              decoration:
                                  isFinished &&
                                      !(match.prediction?.contains(
                                            'Accurate',
                                          ) ??
                                          true)
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      if (match.odds != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isFinished
                                ? Colors.blueGrey.shade700
                                : AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    (isFinished
                                            ? Colors.blueGrey
                                            : AppColors.primary)
                                        .withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text(
                            match.odds!,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (match.isLive)
              Positioned(
                top: 0,
                right: 0,
                child: _LiveBadge(minute: match.liveMinute),
              ),
            if (isFinished)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(20),
                      bottomLeft: Radius.circular(10),
                    ),
                  ),
                  child: const Text(
                    "ACCURATE",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveLayout(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: _buildTeamLogoCol(match.homeTeam, isDark)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child:
              match.isLive ||
                  (match.homeScore != null && match.awayScore != null)
              ? Row(
                  children: [
                    Text(
                      match.homeScore ?? "0",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : AppColors.textDark,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.0),
                      child: Text(
                        "-",
                        style: TextStyle(
                          color: AppColors.textGrey,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    Text(
                      match.awayScore ?? "0",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : AppColors.textDark,
                      ),
                    ),
                  ],
                )
              : const Text(
                  "VS",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textGrey,
                  ),
                ),
        ),
        Expanded(child: _buildTeamLogoCol(match.awayTeam, isDark)),
      ],
    );
  }

  Widget _buildFinishedLayout(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            children: [
              _buildFinishedRow(match.homeTeam, match.homeScore ?? "0", isDark),
              const SizedBox(height: 8),
              _buildFinishedRow(match.awayTeam, match.awayScore ?? "0", isDark),
            ],
          ),
        ),
        Container(
          width: 1,
          height: 40,
          margin: const EdgeInsets.only(left: 16),
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.05),
        ),
        Container(
          padding: const EdgeInsets.only(left: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                "RESULT",
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textGrey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "FT",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFinishedRow(String teamName, String score, bool isDark) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : AppColors.backgroundLight,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              teamName.substring(0, 1).toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppColors.textGrey,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            teamName,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.textDark,
            ),
          ),
        ),
        Text(
          score,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : AppColors.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildTeamLogoCol(String teamName, bool isDark) {
    return Column(
      children: [
        _buildTeamLogo(teamName, isDark),
        const SizedBox(height: 8),
        Text(
          teamName,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : AppColors.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildTeamLogo(String teamName, bool isDark) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : AppColors.backgroundLight,
        shape: BoxShape.circle,
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Center(
        child: Text(
          teamName.substring(0, 1).toUpperCase(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: AppColors.textGrey.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}

class _LiveBadge extends StatefulWidget {
  final String? minute;
  const _LiveBadge({this.minute});

  @override
  State<_LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<_LiveBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.6, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: const BoxDecoration(
          color: AppColors.liveRed,
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(10),
          ),
        ),
        child: Text(
          "LIVE ${widget.minute ?? ''}".toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 8,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
