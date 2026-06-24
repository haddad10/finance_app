import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../providers/transaction_provider.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  String _insightType = 'EXPENSE';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionProvider>().loadStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final tx = context.watch<TransactionProvider>();
    final colors = AppColors.of(context);
    final isExpense = _insightType == 'EXPENSE';

    Map<String, double> data = {};
    final statsKey = isExpense ? 'expense_by_category' : 'incomes_by_category';
    
    if (tx.stats.containsKey(statsKey) && tx.stats[statsKey] is Map) {
      data = (tx.stats[statsKey] as Map).cast<String, dynamic>().map((k, v) => MapEntry(k, (v as num).toDouble()));
    }

    if (data.isEmpty) {
      for (var t in tx.transactions) {
        if (isExpense ? !t.isIncome : t.isIncome) {
          data[t.category] = (data[t.category] ?? 0) + t.amount;
        }
      }
    }

    final hasData = data.isNotEmpty;

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        title: const Text('Insights'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.black, width: 3),
            boxShadow: const [
              BoxShadow(
                color: Colors.black,
                offset: Offset(5, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isExpense ? 'Analisis Pengeluaran' : 'Analisis Pemasukan',
                    style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: colors.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        _InsightToggleBtn(
                          label: 'Keluar',
                          selected: isExpense,
                          color: AppColors.expense,
                          onTap: () => setState(() => _insightType = 'EXPENSE'),
                        ),
                        _InsightToggleBtn(
                          label: 'Masuk',
                          selected: !isExpense,
                          color: AppColors.income,
                          onTap: () => setState(() => _insightType = 'INCOME'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              SizedBox(
                height: 250,
                child: hasData
                    ? PieChart(
                        PieChartData(
                          sectionsSpace: 6,
                          centerSpaceRadius: 50,
                          startDegreeOffset: -90,
                          sections: data.entries.map((e) {
                            final index = data.keys.toList().indexOf(e.key);
                            final colorsList = isExpense 
                              ? [AppColors.expense, AppColors.accent, const Color(0xFFFACC15), const Color(0xFFFB923C), const Color(0xFFEF4444)]
                              : [AppColors.income, const Color(0xFF3B82F6), const Color(0xFF8B5CF6), const Color(0xFFEC4899), const Color(0xFF10B981)];
                            
                            return PieChartSectionData(
                              color: colorsList[index % colorsList.length],
                              value: e.value,
                              title: '',
                              radius: 60,
                              badgeWidget: _buildChartBadge(e.key, colorsList[index % colorsList.length]),
                              badgePositionPercentageOffset: 1.4,
                            );
                          }).toList(),
                        ),
                        swapAnimationDuration: const Duration(milliseconds: 750),
                        swapAnimationCurve: Curves.elasticOut,
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.pie_chart_outline_rounded, color: colors.textMuted, size: 60),
                            const SizedBox(height: 16),
                            Text(
                              isExpense ? 'Belum ada data pengeluaran' : 'Belum ada data pemasukan',
                              style: TextStyle(color: colors.textMuted, fontSize: 14, fontStyle: FontStyle.italic),
                            ),
                          ],
                        ),
                      ),
              ),
              if (hasData) const SizedBox(height: 50),
              if (hasData)
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: data.entries.map((e) {
                    final index = data.keys.toList().indexOf(e.key);
                    final colorsList = isExpense 
                              ? [AppColors.expense, AppColors.accent, const Color(0xFFFACC15), const Color(0xFFFB923C), const Color(0xFFEF4444)]
                              : [AppColors.income, const Color(0xFF3B82F6), const Color(0xFF8B5CF6), const Color(0xFFEC4899), const Color(0xFF10B981)];
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(color: colorsList[index % colorsList.length], shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 8),
                        Text(e.key, style: TextStyle(color: colors.textSecondary, fontSize: 14, fontWeight: FontWeight.w600)),
                      ],
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChartBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.95),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black, width: 1.5),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _InsightToggleBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  
  const _InsightToggleBtn({required this.label, required this.selected, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? color.withOpacity(0.3) : Colors.transparent),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? color : colors.textMuted,
            fontSize: 12,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
