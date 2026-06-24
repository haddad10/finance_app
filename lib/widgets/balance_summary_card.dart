import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../widgets/dot_grid_painter.dart';

class BalanceSummaryCard extends StatelessWidget {
  final Map<String, dynamic> balance;

  const BalanceSummaryCard({super.key, required this.balance});

  @override
  Widget build(BuildContext context) {
    final totalBalance = (balance['balance'] as num?)?.toDouble() ?? 0;
    final income = (balance['total_income'] as num?)?.toDouble() ?? 0;
    final expense = (balance['total_expense'] as num?)?.toDouble() ?? 0;

    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.centerLeft,
        children: [
          // Main Card
          Container(
            margin: const EdgeInsets.only(left: 30),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.black, width: 3),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black,
                  offset: Offset(5, 5),
                  blurRadius: 0,
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(40, 24, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SISA SALDOMU!',
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    fmt.format(totalBalance),
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                      height: 1.1,
                      shadows: [
                        Shadow(
                          color: AppColors.primary,
                          offset: Offset(3, 3),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Income & Expense Box
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: _StatItem(
                          label: 'IN',
                          value: income,
                          icon: Icons.arrow_downward_rounded,
                          color: AppColors.income,
                        ),
                      ),
                      Container(
                        height: 40,
                        width: 2,
                        color: Colors.black,
                      ),
                      Expanded(
                        child: _StatItem(
                          label: 'OUT',
                          value: expense,
                          icon: Icons.arrow_upward_rounded,
                          color: AppColors.expense,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Mascot Sticker hanging on top right
          Positioned(
            right: -20,
            top: -20,
            child: Image.asset(
              'assets/images/lucky_cat.png',
              height: 64,
              width: 64,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final double value;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.compactCurrency(locale: 'id_ID', symbol: 'Rp');
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            fmt.format(value),
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }
}

