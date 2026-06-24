import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../providers/transaction_provider.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
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
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    final expenseStats = tx.stats['expense_by_category'] as Map<String, dynamic>? ?? {};
    final incomeStats = tx.stats['incomes_by_category'] as Map<String, dynamic>? ?? {};

    final totalExpense = expenseStats.values.fold<double>(0, (sum, v) => sum + (v as num).toDouble());
    final totalIncome = incomeStats.values.fold<double>(0, (sum, v) => sum + (v as num).toDouble());

    final chartColors = [
      AppColors.expense, AppColors.primary, AppColors.income,
      const Color(0xFFFBBF24), const Color(0xFF60A5FA), const Color(0xFFA78BFA),
    ];

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        title: const Text('Report Lengkap'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Summary Card
            Container(
              padding: const EdgeInsets.all(24),
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
                children: [
                  _SummaryRow('Total Pemasukan', totalIncome, AppColors.income, fmt, colors),
                  const Divider(height: 32, thickness: 2, color: Colors.black12),
                  _SummaryRow('Total Pengeluaran', totalExpense, AppColors.expense, fmt, colors),
                  const Divider(height: 32, thickness: 2, color: Colors.black12),
                  _SummaryRow('Sisa Saldo', totalIncome - totalExpense, AppColors.primary, fmt, colors, isBold: true),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Detail Pengeluaran
            if (expenseStats.isNotEmpty) ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Rincian Pengeluaran', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black, width: 2),
                ),
                child: Column(
                  children: expenseStats.entries.toList().asMap().entries.map((entry) {
                    final idx = entry.key;
                    final category = entry.value.key;
                    final amount = (entry.value.value as num).toDouble();
                    final pct = totalExpense > 0 ? amount / totalExpense : 0.0;
                    final color = chartColors[idx % chartColors.length];

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
                                  const SizedBox(width: 8),
                                  Text(category, style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                                ],
                              ),
                              Text(fmt.format(amount), style: TextStyle(color: colors.textSecondary, fontSize: 13, fontWeight: FontWeight.w700)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: pct,
                              backgroundColor: colors.border,
                              valueColor: AlwaysStoppedAnimation<Color>(color),
                              minHeight: 8,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _SummaryRow(String label, double value, Color color, NumberFormat fmt, ThemeColors colors, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.w900 : FontWeight.w600,
          ),
        ),
        Text(
          fmt.format(value),
          style: TextStyle(
            color: color,
            fontSize: isBold ? 20 : 16,
            fontWeight: FontWeight.w900,
            shadows: isBold ? [const Shadow(color: Colors.black26, offset: Offset(1, 1))] : null,
          ),
        ),
      ],
    );
  }
}
