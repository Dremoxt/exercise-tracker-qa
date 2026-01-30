import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/exercise_provider.dart';
import '../config/theme.dart';
import '../models/models.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  int _selectedPeriod = 1; // 1, 3, 6, or 12 months

  @override
  Widget build(BuildContext context) {
    return Consumer<ExerciseProvider>(
      builder: (context, provider, child) {
        final summaries = provider.monthlySummaries;
        final personalBest = provider.personalBest;
        final categoryStats = provider.getCategoryStatsForPeriod(_selectedPeriod);
        
        return Scaffold(
          appBar: AppBar(
            title: const Text('Records'),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Monthly Bar Chart (at the top)
                if (summaries.isNotEmpty)
                  _buildMonthlyBarChart(context, summaries, personalBest),

                const SizedBox(height: 24),

                // Category Stats Section
                Text(
                  'Category Performance',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                
                // Period selector
                _buildPeriodSelector(context),
                
                const SizedBox(height: 16),
                
                if (categoryStats.isEmpty)
                  _buildEmptyState(context, 'No data for this period')
                else
                  ...() {
                    // Calculate overall average across all categories
                    final overallAverage = categoryStats.isNotEmpty
                        ? categoryStats.map((s) => s.averagePercentage).reduce((a, b) => a + b) / categoryStats.length
                        : 0.0;
                    return categoryStats.map(
                      (stat) => _buildCategoryStatCard(context, stat, overallAverage),
                    );
                  }(),
                
                const SizedBox(height: 24),

                // Monthly Records
                Text(
                  'Monthly Records',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),

                if (summaries.isEmpty)
                  _buildEmptyState(context, 'Start tracking to see your records!')
                else
                  ...summaries.map((summary) => _buildMonthCard(context, summary, personalBest)),
                
                const SizedBox(height: 100),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPeriodSelector(BuildContext context) {
    final theme = Theme.of(context);
    final periods = [
      {'value': 1, 'label': '1M'},
      {'value': 3, 'label': '3M'},
      {'value': 6, 'label': '6M'},
      {'value': 12, 'label': '1Y'},
    ];
    
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.brightness == Brightness.light
              ? Colors.grey.shade200
              : Colors.grey.shade800,
        ),
      ),
      child: Row(
        children: periods.map((period) {
          final isSelected = _selectedPeriod == period['value'];
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedPeriod = period['value'] as int;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  period['label'] as String,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : theme.textTheme.bodyMedium?.color,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }

  Widget _buildCategoryStatCard(BuildContext context, CategoryMonthlyStats stat, double overallAverage) {
    final theme = Theme.of(context);
    final deviation = stat.averagePercentage - overallAverage;
    final isPositive = deviation >= 0;
    final deviationColor = deviation.abs() < 5
        ? Colors.grey
        : isPositive
            ? Colors.green
            : Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.brightness == Brightness.light
              ? Colors.grey.shade200
              : Colors.grey.shade800,
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              AppTheme.getCategoryIcon(stat.categoryIcon),
              color: AppTheme.primaryColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),

          // Name and stats
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stat.categoryName,
                  style: theme.textTheme.titleSmall,
                ),
                Text(
                  '${stat.totalSetsCompleted} sets • ${stat.daysWithActivity} days',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),

          // Deviation from average
          Text(
            '${isPositive ? '+' : ''}${deviation.toStringAsFixed(0)}%',
            style: theme.textTheme.titleMedium?.copyWith(
              color: deviationColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyBarChart(
    BuildContext context,
    List<MonthlySummary> summaries,
    MonthlySummary? personalBest,
  ) {
    final theme = Theme.of(context);
    // Take last 12 months max, reversed so oldest is on the left
    final displaySummaries = summaries.take(12).toList().reversed.toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.brightness == Brightness.light
              ? Colors.grey.shade200
              : Colors.grey.shade800,
        ),
      ),
      child: SizedBox(
        height: 120,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Y-axis labels
            SizedBox(
              width: 28,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('100', style: theme.textTheme.bodySmall?.copyWith(fontSize: 9, color: Colors.grey)),
                  Text('75', style: theme.textTheme.bodySmall?.copyWith(fontSize: 9, color: Colors.grey)),
                  Text('50', style: theme.textTheme.bodySmall?.copyWith(fontSize: 9, color: Colors.grey)),
                  Text('25', style: theme.textTheme.bodySmall?.copyWith(fontSize: 9, color: Colors.grey)),
                  const SizedBox(height: 20), // Space for month labels
                ],
              ),
            ),
            const SizedBox(width: 4),
            // Bars
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: displaySummaries.map((summary) {
                  final isPersonalBest = personalBest != null &&
                      summary.year == personalBest.year &&
                      summary.month == personalBest.month;
                  final percentage = summary.averagePercentage.clamp(0.0, 100.0);
                  final barHeight = (percentage / 100) * 80;

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Personal best indicator (star above bar)
                          if (isPersonalBest)
                            const Padding(
                              padding: EdgeInsets.only(bottom: 2),
                              child: Icon(
                                Icons.star,
                                color: Color(0xFFFFD700),
                                size: 10,
                              ),
                            ),
                          // Vertical bar
                          Container(
                            width: double.infinity,
                            height: barHeight > 0 ? barHeight : 2,
                            decoration: BoxDecoration(
                              color: AppTheme.getProgressColor(percentage),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Month label
                          Text(
                            DateFormat('M').format(
                              DateTime(summary.year, summary.month),
                            ),
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthCard(
    BuildContext context,
    MonthlySummary summary,
    MonthlySummary? personalBest,
  ) {
    final theme = Theme.of(context);
    final isPersonalBest = personalBest != null &&
        summary.year == personalBest.year &&
        summary.month == personalBest.month;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPersonalBest
              ? const Color(0xFFFFD700)
              : theme.brightness == Brightness.light
                  ? Colors.grey.shade200
                  : Colors.grey.shade800,
          width: isPersonalBest ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          // Month/Year
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      DateFormat('MMM yyyy').format(
                        DateTime(summary.year, summary.month),
                      ),
                      style: theme.textTheme.titleMedium,
                    ),
                    if (isPersonalBest) ...[
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.star,
                        color: Color(0xFFFFD700),
                        size: 16,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${summary.daysTracked}/${summary.daysWithGoals} days • ${summary.totalStrokes} sets',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          
          // Progress bar
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${summary.averagePercentage.toStringAsFixed(1)}%',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppTheme.getProgressColor(summary.averagePercentage),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (summary.averagePercentage / 100).clamp(0.0, 1.0),
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.getProgressColor(summary.averagePercentage),
                    ),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
