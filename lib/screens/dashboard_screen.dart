import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../widgets/dot_grid_painter.dart';
import '../providers/auth_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/comic_dialog.dart';
import '../widgets/balance_summary_card.dart';
import '../widgets/transaction_card.dart';
import 'transactions_screen.dart';
import 'add_edit_transaction_screen.dart';
import 'login_screen.dart';
import 'insights_screen.dart';
import 'report_screen.dart';

import 'profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isInitialLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initData());
  }

  Future<void> _initData() async {
    await _loadData();
    if (mounted) setState(() => _isInitialLoading = false);
  }

  Future<void> _loadData() async {
    final tx = context.read<TransactionProvider>();
    await Future.wait([tx.loadBalance(), tx.loadTransactions(), tx.loadStats()]);
  }

  Future<void> _logout() async {
    final colors = AppColors.of(context);
    final authProvider = context.read<AuthProvider>();
    final confirm = await showComicConfirmDialog(
      context: context,
      title: 'Cabut Sekarang?',
      content: 'Yakin mau ninggalin FINZ? Balik lagi ya nanti bro!',
      emoji: '🥺',
      confirmText: 'Cabut Gas!',
      cancelText: 'Stay Dulu',
    );
    if (confirm == true && mounted) {
      await authProvider.logout();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitialLoading) return const _SplashScreen();

    final auth = context.watch<AuthProvider>();
    final tx = context.watch<TransactionProvider>();
    final theme = context.watch<ThemeProvider>();
    final colors = AppColors.of(context);
    final greeting = _getGreeting();

    return Scaffold(
      backgroundColor: colors.bg,
      body: Stack(
        children: [
          // Background Dot Pattern
          Positioned.fill(
            child: CustomPaint(
              painter: DotGridPainter(
                dotColor: theme.isDarkMode ? const Color(0x22FFFFFF) : const Color(0x1A000000), // Very faint dots
                spacing: 20.0,
                dotSize: 1.5,
              ),
            ),
          ),
          RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: colors.surface,
            onRefresh: _loadData,
            child: CustomScrollView(
              slivers: [
                // ── App Bar ────────────────────────────────────────────────────
                SliverAppBar(
                  expandedHeight: 0,
                  pinned: false,
                  backgroundColor: Colors.transparent,
                  surfaceTintColor: Colors.transparent,
                  centerTitle: false,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(greeting, style: TextStyle(color: colors.textMuted, fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                  Text(
                    (auth.user?.username ?? '').toUpperCase(),
                    style: TextStyle(color: colors.textPrimary, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                  ),
                ],
              ),
              actions: [
                // Theme Toggle
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: colors.surfaceLight,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                  child: IconButton(
                    icon: Icon(
                      theme.isDarkMode ? Icons.wb_sunny_rounded : Icons.nightlight_round_outlined,
                      color: theme.isDarkMode ? Colors.amber : AppColors.primary,
                      size: 20,
                    ),
                    onPressed: () => theme.toggleTheme(),
                  ),
                ),
                // Profile Menu
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  ),
                  child: Container(
                    margin: const EdgeInsets.only(right: 16),
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary,
                      border: Border.all(color: Colors.black, width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: colors.surfaceLight,
                      child: Text(
                        (auth.user?.username ?? 'U').substring(0, 1).toUpperCase(),
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: colors.textPrimary),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ── Balance Card ──────────────────────────────────────────
                  tx.balance.isEmpty
                      ? const _LoadingCard()
                      : BalanceSummaryCard(balance: tx.balance),

                  const SizedBox(height: 32),
                  const _VibeCheckCard(),
                  const SizedBox(height: 32),

                  // ── Stats Section ─────────────────────────────────────────
                  if (tx.stats.isNotEmpty) ...[
                    const _SectionHeader(title: 'WHERE\'S THE MONEY?'),
                    const SizedBox(height: 18),
                    _StatsChart(stats: tx.stats),
                    const SizedBox(height: 40),
                  ],

                  // ── Recent Transactions ─────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const _SectionHeader(title: 'RECENT FLEX'),
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const TransactionsScreen()),
                        ),
                        child: Row(
                          children: [
                            Text('Semua', style: TextStyle(color: colors.primary, fontSize: 13, fontWeight: FontWeight.bold)),
                            Icon(Icons.chevron_right_rounded, color: colors.primary, size: 18),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (tx.isLoading)
                    const Center(child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3),
                    ))
                  else if (tx.transactions.isEmpty)
                    _EmptyState(
                      onAdd: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AddEditTransactionScreen()),
                        );
                        _loadData();
                      },
                    )
                  else
                    ...tx.transactions.take(5).map(
                          (t) => TransactionCard(
                            transaction: t,
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AddEditTransactionScreen(transaction: t),
                                ),
                              );
                              _loadData();
                            },
                            onDelete: () => context.read<TransactionProvider>().deleteTransaction(t.id),
                          ),
                        ),

                  const SizedBox(height: 100),
                ]),
              ),
            ),
          ],
        ),
      ),
      ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black, width: 3),
          boxShadow: const [
            BoxShadow(
              color: Colors.black,
              offset: Offset(5, 5),
              blurRadius: 0,
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddEditTransactionScreen()),
            );
            _loadData();
          },
          backgroundColor: AppColors.primary,
          elevation: 0,
          shape: const CircleBorder(),
          child: const Icon(Icons.add_rounded, color: Colors.black, size: 36),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        padding: EdgeInsets.zero,
        height: 75,
        color: colors.surface,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Container(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Colors.black, width: 3)),
          ),
          child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavButton(
              icon: Icons.history_rounded,
              label: 'History',
              color: AppColors.income,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TransactionsScreen())),
            ),
            _NavButton(
              icon: Icons.analytics_outlined,
              label: 'Insights',
              color: AppColors.primary,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InsightsScreen())),
            ),
            const SizedBox(width: 40), // Space for FAB
            _NavButton(
              icon: Icons.pie_chart_outline_rounded,
              label: 'Report',
              color: AppColors.accent,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportScreen())),
            ),
            _NavButton(
              icon: Icons.ios_share_rounded,
              label: 'Export',
              color: AppColors.income,
              onTap: tx.isCsvLoading ? null : () => tx.exportCsv(context),
            ),
          ],
        ),
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 5) return 'Malam, King!';
    if (hour < 11) return 'Morning, Star!';
    if (hour < 15) return 'Wazzup, Buddy!';
    if (hour < 18) return 'Ayo Semangat!';
    return 'Malam, Glow up!';
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _NavButton({required this.icon, required this.label, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: colors.textSecondary, fontSize: 10, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Scaffold(
      backgroundColor: colors.bg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.bolt_rounded, color: AppColors.primary, size: 64),
            ),
            const SizedBox(height: 32),
            const Text(
              'FINZ',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 4, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              'Lagi spill data cuan lo...',
              style: TextStyle(color: colors.textMuted, fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 24),
            const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helper Widgets ──────────────────────────────────────────────────────────

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _QuickAction({required this.icon, required this.label, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.15), width: 1.5),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Text(
        title,
        style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
      );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black, width: 3),
      ),
      child: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(Icons.receipt_long_rounded, color: colors.textMuted, size: 56),
          const SizedBox(height: 12),
          Text('Belum ada transaksi', style: TextStyle(color: colors.textSecondary, fontSize: 15)),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onAdd,
            child: const Text('Tambahkan sekarang →', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}

class _StatsChart extends StatelessWidget {
  final Map<String, dynamic> stats;

  const _StatsChart({required this.stats});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final expenseStats = stats['expense_by_category'] as Map<String, dynamic>? ?? {};
    if (expenseStats.isEmpty) {
      return const SizedBox.shrink();
    }

    final total = expenseStats.values.fold<double>(0, (sum, v) => sum + (v as num).toDouble());
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    final chartColors = [
      AppColors.expense, AppColors.primary, AppColors.income,
      const Color(0xFFFBBF24), const Color(0xFF60A5FA), const Color(0xFFA78BFA),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black, width: 3),
        boxShadow: const [
          BoxShadow(
            color: Colors.black,
            offset: Offset(3, 3),
          ),
        ],
      ),
      child: Column(
        children: expenseStats.entries.toList().asMap().entries.map((entry) {
          final idx = entry.key;
          final category = entry.value.key;
          final amount = (entry.value.value as num).toDouble();
          final pct = total > 0 ? amount / total : 0.0;
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
                        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
                        const SizedBox(width: 8),
                        Text(category, style: TextStyle(color: colors.textPrimary, fontSize: 13)),
                      ],
                    ),
                    Text(fmt.format(amount), style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    backgroundColor: colors.border,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _VibeCheckCard extends StatelessWidget {
  const _VibeCheckCard();

  String _getRandomVibe() {
    final vibes = [
      "Ingat, isi dompet jangan cuma kabar burung! 🐦💸",
      "Self reward boleh, tapi tabungan harus tetep oke! ✨",
      "Lagi mode hemat atau gaya sultan hari ini? 👑",
      "Spill cuan tipis-tipis, lama-lama jadi bukit! ⛰️",
      "Kopi boleh mahal, prospek masa depan harus lebih mahal! ☕🚀",
      "Tabungan aman, tidur jadi tenang. Gass! 💤💎",
    ];
    // Gunakan detik sekarang sebagai index acak sederhana
    return vibes[DateTime.now().second % vibes.length];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A), // Solid black background
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black, width: 3),
        boxShadow: const [
          BoxShadow(
            color: AppColors.primary, // Yellow shadow
            offset: Offset(5, 5),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: Colors.black, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'VIBE CHECK',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getRandomVibe(),
                  style: const TextStyle(
                    color: Color(0xFFE5E7EB),
                    fontSize: 12,
                    height: 1.4,
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
