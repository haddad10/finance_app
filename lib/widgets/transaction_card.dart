import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../theme/app_theme.dart';
import '../widgets/dot_grid_painter.dart';
import '../widgets/comic_dialog.dart';

class TransactionCard extends StatelessWidget {
  final TransactionModel transaction;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const TransactionCard({
    super.key,
    required this.transaction,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isIncome = transaction.isIncome;
    final color = isIncome ? AppColors.income : AppColors.expense;
    final dt = DateTime.tryParse(transaction.createdAt);
    final amountStr = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(transaction.amount);

    return Dismissible(
      key: Key(transaction.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.expense.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_rounded, color: AppColors.expense),
      ),
      confirmDismiss: (_) async {
        return await showComicConfirmDialog(
          context: context,
          title: 'Yakin ni bro?',
          content: 'Transaksi ini bakal dihapus permanen loh, nyesel gak nanti?',
          emoji: '🗑️',
          confirmText: 'Hapus!',
          cancelText: 'Gak Jadi',
        );
      },
      onDismissed: (_) => onDelete?.call(),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.black, width: 3),
            boxShadow: const [
              BoxShadow(
                color: Colors.black,
                blurRadius: 0,
                offset: Offset(5, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              // Colored dot
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black, width: 2),
                ),
              ),
              const SizedBox(width: 16),
              // Category
              Expanded(
                child: Text(
                  transaction.category,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
              // Amount
              Text(
                '${isIncome ? '' : '- '}$amountStr',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('makan') || cat.contains('food')) return Icons.restaurant_rounded;
    if (cat.contains('transport')) return Icons.directions_car_rounded;
    if (cat.contains('belanja') || cat.contains('shop')) return Icons.shopping_bag_rounded;
    if (cat.contains('hiburan') || cat.contains('entertain')) return Icons.sports_esports_rounded;
    if (cat.contains('gaji') || cat.contains('salary')) return Icons.payments_rounded;
    if (cat.contains('kesehatan') || cat.contains('health')) return Icons.medical_services_rounded;
    return transaction.isIncome ? Icons.add_chart_rounded : Icons.receipt_long_rounded;
  }
}
