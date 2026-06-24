import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../widgets/dot_grid_painter.dart';
import '../providers/transaction_provider.dart';
import '../widgets/transaction_card.dart';
import 'add_edit_transaction_screen.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final _scrollCtrl = ScrollController();
  int? _selectedMonth;
  int? _selectedYear;
  DateTime _focusedDate = DateTime.now();

  final _months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final tx = context.read<TransactionProvider>();
      tx.loadTransactions();
      tx.loadStats();
    });
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
      context.read<TransactionProvider>().loadNextPage();
    }
  }

  void _applyFilter() {
    final tx = context.read<TransactionProvider>();
    tx.setFilter(
          month: _selectedMonth,
          year: _selectedYear,
        );
    tx.loadStats();
  }

  void _clearFilter() {
    final tx = context.read<TransactionProvider>();
    setState(() {
      _selectedMonth = null;
      _selectedYear = null;
      _focusedDate = DateTime.now();
    });
    tx.clearFilter();
    tx.loadStats();
  }

  Future<void> _showFilterSheet() async {
    final now = DateTime.now();
    final colors = AppColors.of(context);
    await showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Filter Transaksi', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 20),
              Text('Bulan', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(12, (i) {
                  final month = i + 1;
                  final selected = _selectedMonth == month;
                  return GestureDetector(
                    onTap: () => setLocal(() => _selectedMonth = selected ? null : month),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.primary : colors.surfaceLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(_months[i],
                          style: TextStyle(
                            color: selected ? Colors.white : colors.textSecondary,
                            fontSize: 13,
                          )),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              Text('Tahun', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [now.year - 1, now.year, now.year + 1].map((year) {
                  final selected = _selectedYear == year;
                  return GestureDetector(
                    onTap: () => setLocal(() => _selectedYear = selected ? null : year),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.primary : colors.surfaceLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('$year',
                          style: TextStyle(
                            color: selected ? Colors.white : colors.textSecondary,
                            fontSize: 13,
                          )),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: colors.border),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _clearFilter();
                      },
                      child: Text('Reset', style: TextStyle(color: colors.textSecondary)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        setState(() {});
                        _applyFilter();
                      },
                      child: const Text('Terapkan'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tx = context.watch<TransactionProvider>();
    final colors = AppColors.of(context);
    final hasFilter = _selectedMonth != null || _selectedYear != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Transaksi'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              tx.sortOrder == 'desc' ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
              color: AppColors.primary,
            ),
            onPressed: () {
              tx.sortOrder = tx.sortOrder == 'desc' ? 'asc' : 'desc';
              tx.loadTransactions();
            },
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.filter_list_rounded),
                onPressed: _showFilterSheet,
              ),
              if (hasFilter)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: CustomScrollView(
        controller: _scrollCtrl,
        slivers: [
          SliverToBoxAdapter(
            child: _buildCalendarHeader(colors),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            sliver: tx.isLoading && tx.transactions.isEmpty
                ? const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  )
                : tx.transactions.isEmpty
                    ? SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.receipt_long_rounded, color: colors.textMuted, size: 64),
                              const SizedBox(height: 16),
                              Text(
                                'Tidak ada transaksi',
                                style: TextStyle(color: colors.textSecondary, fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (ctx, index) {
                            if (index == tx.transactions.length) {
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2)),
                              );
                            }
                            final t = tx.transactions[index];
                            return TransactionCard(
                              transaction: t,
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => AddEditTransactionScreen(transaction: t)),
                                );
                                tx.loadTransactions();
                              },
                              onDelete: () => context.read<TransactionProvider>().deleteTransaction(t.id),
                            );
                          },
                          childCount: tx.transactions.length + (tx.hasNextPage ? 1 : 0),
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEditTransactionScreen()),
          );
          tx.loadTransactions();
        },
      ),
    );
  }

  Widget _buildCalendarHeader(ThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                DateFormat('MMMM yyyy').format(_focusedDate),
                style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _focusedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                    builder: (ctx, child) {
                      return Theme(
                        data: Theme.of(ctx).copyWith(
                          colorScheme: ColorScheme.fromSeed(
                            seedColor: AppColors.primary,
                            brightness: Theme.of(ctx).brightness,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) {
                    setState(() {
                      _focusedDate = picked;
                      _selectedMonth = picked.month;
                      _selectedYear = picked.year;
                    });
                    _applyFilter();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.calendar_month_rounded, color: AppColors.primary, size: 20),
                ),
              ),
            ],
          ),
          Row(
            children: [
              _CalendarNavBtn(
                icon: Icons.chevron_left_rounded,
                onTap: () => setState(() => _focusedDate = DateTime(_focusedDate.year, _focusedDate.month - 1)),
              ),
              const SizedBox(width: 8),
              _CalendarNavBtn(
                icon: Icons.chevron_right_rounded,
                onTap: () => setState(() => _focusedDate = DateTime(_focusedDate.year, _focusedDate.month + 1)),
              ),
            ],
          ),
        ],
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? color.withOpacity(0.3) : Colors.transparent),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? color : colors.textMuted,
            fontSize: 11,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _CalendarNavBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CalendarNavBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: colors.surfaceLight,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: colors.textPrimary, size: 18),
      ),
    );
  }
}
