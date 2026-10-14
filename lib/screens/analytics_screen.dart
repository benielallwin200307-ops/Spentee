import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class _CategoryStat {
  final String title;
  final String amount;
  final String percentStr;
  final double ratio;
  final Color color;
  final IconData icon;

  const _CategoryStat({
    required this.title,
    required this.amount,
    required this.percentStr,
    required this.ratio,
    required this.color,
    required this.icon,
  });
}

/// Screen 9 — Analytics / Reports Screen
class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int _selectedFilter = 2; // 0: Daily, 1: Weekly, 2: Monthly, 3: Yearly
  int _monthIndex = 9; // October (0-indexed: 9)

  final List<String> _filters = const ['Daily', 'Weekly', 'Monthly', 'Yearly'];
  final List<String> _months = const [
    'January 2026', 'February 2026', 'March 2026', 'April 2026',
    'May 2026', 'June 2026', 'July 2026', 'August 2026',
    'September 2026', 'October 2026', 'November 2026', 'December 2026'
  ];

  final List<_CategoryStat> _categoryStats = const [
    _CategoryStat(
      title: 'Food & Drinks',
      amount: '₹5,420',
      percentStr: '29%',
      ratio: 0.29,
      color: AppTheme.accentPink,
      icon: Icons.restaurant_rounded,
    ),
    _CategoryStat(
      title: 'Shopping',
      amount: '₹4,680',
      percentStr: '25%',
      ratio: 0.25,
      color: AppTheme.accentPurple,
      icon: Icons.shopping_bag_rounded,
    ),
    _CategoryStat(
      title: 'Transport',
      amount: '₹2,800',
      percentStr: '15%',
      ratio: 0.15,
      color: AppTheme.accentCyan,
      icon: Icons.directions_car_rounded,
    ),
    _CategoryStat(
      title: 'Bills & Utilities',
      amount: '₹2,100',
      percentStr: '11%',
      ratio: 0.11,
      color: AppTheme.accentOrange,
      icon: Icons.receipt_long_rounded,
    ),
    _CategoryStat(
      title: 'Entertainment',
      amount: '₹1,420',
      percentStr: '8%',
      ratio: 0.08,
      color: AppTheme.accentBlue,
      icon: Icons.sports_esports_rounded,
    ),
    _CategoryStat(
      title: 'Others',
      amount: '₹1,000',
      percentStr: '5%',
      ratio: 0.05,
      color: Color(0xFF10B981),
      icon: Icons.more_horiz_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                const Text(
                  'Analytics',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),

                // Period Filter Pills
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppTheme.bgSurface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: List.generate(_filters.length, (index) {
                      final isSelected = index == _selectedFilter;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedFilter = index;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSelected ? AppTheme.primaryMint : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _filters[index],
                              style: TextStyle(
                                color: isSelected ? AppTheme.bgDark : AppTheme.textGrey,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),

                const SizedBox(height: 16),

                // Month Selector Navigation
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textGrey, size: 16),
                      onPressed: () {
                        setState(() {
                          if (_monthIndex > 0) _monthIndex--;
                        });
                      },
                    ),
                    Text(
                      _months[_monthIndex],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.textGrey, size: 16),
                      onPressed: () {
                        setState(() {
                          if (_monthIndex < _months.length - 1) _monthIndex++;
                        });
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Spending Total Card with Trend
                SpenteeCard(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Spending',
                            style: TextStyle(
                              color: AppTheme.textGrey,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryMint.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.arrow_downward_rounded, color: AppTheme.primaryMint, size: 14),
                                SizedBox(width: 4),
                                Text(
                                  '12% vs last month',
                                  style: TextStyle(
                                    color: AppTheme.primaryMint,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '₹18,420',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Bar Chart Representation
                      _SimpleBarChart(),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Category Breakdown Header
                const Text(
                  'Category Breakdown',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),

                // Category Breakdown List
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _categoryStats.length,
                  separatorBuilder: (_, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = _categoryStats[index];
                    return SpenteeCard(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      borderRadius: 16,
                      child: Column(
                        children: [
                          Row(
                            children: [
                              CategoryBadge(icon: item.icon, color: item.color, size: 36),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Text(
                                item.amount,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 34,
                                child: Text(
                                  item.percentStr,
                                  textAlign: TextAlign.end,
                                  style: const TextStyle(
                                    color: AppTheme.textGrey,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          // Progress Bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: item.ratio,
                              backgroundColor: AppTheme.bgSurface,
                              valueColor: AlwaysStoppedAnimation<Color>(item.color),
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),

                // Sample Data Disclaimer
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.bgSurface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline_rounded, size: 16, color: AppTheme.textDim),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Initial figures represent sample demo data based on your spending patterns.',
                          style: TextStyle(color: AppTheme.textDim, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A custom sleek bar chart widget matching the visual reference.
class _SimpleBarChart extends StatelessWidget {
  final List<double> weeklyValues = const [2400, 1800, 3100, 2200];
  final List<String> weekLabels = const ['Week 1', 'Week 2', 'Week 3', 'Week 4'];
  final List<LinearGradient> barGradients = const [
    LinearGradient(colors: [Color(0xFF00E5FF), Color(0xFF0284C7)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
    LinearGradient(colors: [Color(0xFFFF3366), Color(0xFFBE185D)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
    LinearGradient(colors: [Color(0xFFA855F7), Color(0xFF6B21A8)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
    LinearGradient(colors: [Color(0xFF00E676), Color(0xFF047857)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
  ];

  @override
  Widget build(BuildContext context) {
    const double maxVal = 3500;
    const double chartHeight = 150;

    return Column(
      children: [
        SizedBox(
          height: chartHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Y-Axis markers
              const Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('3K', style: TextStyle(color: AppTheme.textDim, fontSize: 10)),
                  Text('2K', style: TextStyle(color: AppTheme.textDim, fontSize: 10)),
                  Text('1K', style: TextStyle(color: AppTheme.textDim, fontSize: 10)),
                  Text('0', style: TextStyle(color: AppTheme.textDim, fontSize: 10)),
                ],
              ),
              const SizedBox(width: 12),

              // Bars Container
              Expanded(
                child: Stack(
                  children: [
                    // Grid background lines
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(
                        4,
                        (_) => const Divider(color: AppTheme.borderSubtle, height: 1),
                      ),
                    ),

                    // Actual Bars
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(weeklyValues.length, (index) {
                        final val = weeklyValues[index];
                        final barHeight = (val / maxVal) * chartHeight;

                        return Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              width: 32,
                              height: barHeight,
                              decoration: BoxDecoration(
                                gradient: barGradients[index],
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                                boxShadow: [
                                  BoxShadow(
                                    color: barGradients[index].colors.first.withValues(alpha: 0.35),
                                    blurRadius: 8,
                                    offset: const Offset(0, -2),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // X-Axis labels
        Padding(
          padding: const EdgeInsets.only(left: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: weekLabels.map((lbl) {
              return Text(
                lbl,
                style: const TextStyle(
                  color: AppTheme.textGrey,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
