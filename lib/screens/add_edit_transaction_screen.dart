import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../widgets/dot_grid_painter.dart';
import '../models/transaction_model.dart';
import '../providers/transaction_provider.dart';
import '../widgets/comic_dialog.dart';

class AddEditTransactionScreen extends StatefulWidget {
  final TransactionModel? transaction; // null = tambah baru

  const AddEditTransactionScreen({super.key, this.transaction});

  @override
  State<AddEditTransactionScreen> createState() => _AddEditTransactionScreenState();
}

class _AddEditTransactionScreenState extends State<AddEditTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  String _type = 'expense';
  String _category = '';
  bool _isLoading = false;

  bool get isEditing => widget.transaction != null;

  static const _expenseCategories = [
    'Makanan', 'Transportasi', 'Belanja', 'Hiburan',
    'Kesehatan', 'Tagihan', 'Pendidikan', 'Lainnya',
  ];

  static const _incomeCategories = [
    'Gaji', 'Freelance', 'Investasi', 'Bonus',
    'Hadiah', 'Bisnis', 'Lainnya',
  ];

  List<String> get _categories => _type == 'income' ? _incomeCategories : _expenseCategories;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      final tx = widget.transaction!;
      _type = tx.type;
      _category = tx.category;
      _amountCtrl.text = tx.amount.toStringAsFixed(0);
      _noteCtrl.text = tx.note;
    } else {
      _category = _expenseCategories[0];
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_category.isEmpty) {
      _showError('Pilih kategori terlebih dahulu');
      return;
    }

    final tx = context.read<TransactionProvider>();
    final amount = double.parse(_amountCtrl.text.replaceAll(',', '').replaceAll('.', ''));

    // ── Validasi saldo: jangan sampai minus ──────────────────────────────────
    if (_type == 'expense' && !isEditing) {
      final currentBalance = (tx.balance['balance'] as num?)?.toDouble() ?? 0.0;
      if (amount > currentBalance) {
        _showError(
          'Saldo tidak cukup!\n\n'
          'Saldo kamu: Rp ${currentBalance.toStringAsFixed(0)}\n'
          'Pengeluaran: Rp ${amount.toStringAsFixed(0)}\n\n'
          'Tambah pemasukan dulu ya!',
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    bool success;
    if (isEditing) {
      success = await tx.updateTransaction(
        id: widget.transaction!.id,
        type: _type,
        amount: amount,
        category: _category,
        note: _noteCtrl.text.trim(),
      );
    } else {
      success = await tx.createTransaction(
        type: _type,
        amount: amount,
        category: _category,
        note: _noteCtrl.text.trim(),
      );
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      await showComicAlertDialog(
        context: context,
        title: isEditing ? 'Berhasil Diubah!' : 'Mantap Bossque! 💸',
        content: isEditing ? 'Data transaksimu berhasil diperbarui.' : 'Transaksi berhasil dicatat! Lanjutkan perjuangan finansialmu!',
        emoji: isEditing ? '✍️' : '🤑',
        shadowColor: AppColors.income,
      );
      if (mounted) Navigator.pop(context);
    } else {
      showComicAlertDialog(
        context: context,
        title: 'Gagal Menyimpan 😵',
        content: tx.error ?? 'Ada masalah saat menyimpan transaksi, coba lagi ya.',
        emoji: '🔧',
        shadowColor: AppColors.expense,
      );
    }
  }

  void _showError(String msg) {
    showComicAlertDialog(
      context: context,
      title: 'Waduh Error! 😵',
      content: msg,
      emoji: '⚠️',
      shadowColor: AppColors.expense,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isEditing = widget.transaction != null;
    final isExpense = _type == 'expense';
    final accentColor = isExpense ? AppColors.expense : AppColors.income;
    // ── Responsive sizing via MediaQuery ──
    final screenH = MediaQuery.of(context).size.height;
    final screenW = MediaQuery.of(context).size.width;
    final isSmall = screenH < 750;
    final hPad = screenW * 0.06; // 6% horizontal padding
    final amountFontSize = isSmall ? 40.0 : 52.0;
    final sectionGap = isSmall ? 10.0 : 18.0;
    final innerGap = isSmall ? 6.0 : 10.0;
    final btnHeight = isSmall ? 50.0 : 60.0;

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('FINZ', 
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 24)),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, size: 26),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Background Dot Pattern
          Positioned.fill(
            child: CustomPaint(
              painter: DotGridPainter(
                dotColor: Colors.black.withAlpha(20),
                spacing: 16,
                dotSize: 1.5,
              ),
            ),
          ),
          Form(
            key: _formKey,
            child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: hPad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: innerGap),
              _buildTypeToggle(colors),
              SizedBox(height: sectionGap),

              // ── Amount Input ──
              Center(
                child: Column(
                  children: [
                    Text('BERAPA NIH?', style: TextStyle(
                      color: colors.textMuted,
                      fontWeight: FontWeight.w900,
                      fontSize: isSmall ? 11 : 13,
                      letterSpacing: 3,
                    )),
                    SizedBox(height: innerGap),
                    TextFormField(
                      controller: _amountCtrl,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: TextStyle(
                        fontSize: amountFontSize,
                        fontWeight: FontWeight.w900,
                        color: accentColor,
                        letterSpacing: -2,
                      ),
                      decoration: InputDecoration(
                        hintText: '0',
                        hintStyle: TextStyle(color: accentColor.withOpacity(0.15)),
                        prefixText: 'Rp ',
                        prefixStyle: TextStyle(
                          fontSize: isSmall ? 16 : 20,
                          fontWeight: FontWeight.w900,
                          color: accentColor.withOpacity(0.4),
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: isSmall ? 4 : 8),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Jangan kosong dong';
                        if ((double.tryParse(v) ?? 0) <= 0) return 'Masa nol?';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: sectionGap),

              // ── Kategori ──
              Text('KATEGORI', style: TextStyle(
                color: colors.textPrimary,
                fontWeight: FontWeight.w900,
                fontSize: isSmall ? 12 : 14,
                letterSpacing: 1,
              )),
              SizedBox(height: innerGap),

              // ── Dynamic Grid ──
              LayoutBuilder(builder: (context, constraints) {
                final crossCount = constraints.maxWidth < 300 ? 3 : 4;
                final cellSize = (constraints.maxWidth - (crossCount - 1) * 6) / crossCount;
                final iconSize = cellSize * 0.48;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossCount,
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 6,
                    childAspectRatio: 1.15,
                  ),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final isSelected = _category == cat;
                    return InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() => _category = cat);
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOut,
                            width: iconSize,
                            height: iconSize,
                            decoration: BoxDecoration(
                              color: isSelected ? accentColor : colors.surfaceLight,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.black, width: 2),
                              boxShadow: isSelected ? [
                                BoxShadow(
                                  color: Colors.black,
                                  offset: const Offset(3, 3),
                                )
                              ] : null,
                            ),
                            child: Icon(
                              _getCategoryIcon(cat),
                              color: isSelected ? Colors.white : colors.textPrimary.withOpacity(0.6),
                              size: iconSize * 0.46,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            cat,
                            style: TextStyle(
                              fontSize: isSmall ? 8 : 9,
                              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500,
                              color: isSelected ? accentColor : colors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    );
                  },
                );
              }),

              SizedBox(height: sectionGap),
              Text('CATATAN', style: TextStyle(
                color: colors.textPrimary,
                fontWeight: FontWeight.w900,
                fontSize: isSmall ? 12 : 14,
                letterSpacing: 1,
              )),
              SizedBox(height: innerGap),
              Container(
                decoration: BoxDecoration(
                  color: colors.surfaceLight,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.black, width: 3),
                  boxShadow: const [
                    BoxShadow(color: Colors.black, offset: Offset(3, 3)),
                  ],
                ),
                child: TextField(
                  controller: _noteCtrl,
                  maxLines: 1,
                  style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Keep it spill...',
                    hintStyle: TextStyle(color: colors.textMuted, fontSize: 13, fontWeight: FontWeight.normal),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
              SizedBox(height: sectionGap),

              SizedBox(
                width: double.infinity,
                height: btnHeight,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(color: Colors.black, offset: Offset(4, 4), blurRadius: 0)
                    ],
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: const BorderSide(color: Colors.black, width: 3),
                      ),
                      elevation: 0,
                    ),
                    onPressed: _isLoading ? null : _save,
                    child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.black, strokeWidth: 3)
                      : Text(
                          isEditing ? 'FIX IT!' : 'GASSS!',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.black),
                        ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      ],
    ),
  );
}

  Widget _buildTypeToggle(ThemeColors colors) {
    final isExpense = _type == 'expense';
    return Container(
      height: 60,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: colors.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black, width: 3),
        boxShadow: const [
          BoxShadow(color: Colors.black, offset: Offset(3, 3))
        ],
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 400),
            curve: Curves.elasticOut,
            alignment: isExpense ? Alignment.centerLeft : Alignment.centerRight,
            child: Container(
              width: (MediaQuery.of(context).size.width - 64) / 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isExpense 
                    ? [AppColors.expense, const Color(0xFFFF5F6D)]
                    : [AppColors.income, const Color(0xFF11998E)],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black,
                    offset: Offset(2, 2),
                  ),
                ],
              ),
            ),
          ),
          Row(
            children: [
              _buildTypeOption('Pengeluaran', isExpense, () {
                setState(() {
                  _type = 'expense';
                  _category = _expenseCategories[0];
                });
              }),
              _buildTypeOption('Pemasukan', !isExpense, () {
                setState(() {
                  _type = 'income';
                  _category = _incomeCategories[0];
                });
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypeOption(String label, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.of(context).textMuted,
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('makan')) return Icons.restaurant_rounded;
    if (cat.contains('transport')) return Icons.directions_car_rounded;
    if (cat.contains('belanja')) return Icons.shopping_bag_rounded;
    if (cat.contains('hiburan')) return Icons.sports_esports_rounded;
    if (cat.contains('kesehatan')) return Icons.medical_services_rounded;
    if (cat.contains('tagihan')) return Icons.receipt_long_rounded;
    if (cat.contains('pendidikan')) return Icons.school_rounded;
    if (cat.contains('gaji')) return Icons.payments_rounded;
    if (cat.contains('freelance')) return Icons.laptop_mac_rounded;
    if (cat.contains('investasi')) return Icons.trending_up_rounded;
    if (cat.contains('bonus')) return Icons.card_giftcard_rounded;
    if (cat.contains('hadiah')) return Icons.redeem_rounded;
    if (cat.contains('bisnis')) return Icons.storefront_rounded;
    return Icons.category_rounded;
  }
}
