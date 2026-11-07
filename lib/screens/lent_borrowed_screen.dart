import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/lent_borrowed_record.dart';
import '../services/debt_reminder_library.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/date_restriction.dart';

/// Screen for tracking money lent to friends and money borrowed from others,
/// with full/partial repayment tracking and funny contextual reminders.
class LentBorrowedScreen extends StatefulWidget {
  const LentBorrowedScreen({super.key});

  @override
  State<LentBorrowedScreen> createState() => _LentBorrowedScreenState();
}

class _LentBorrowedScreenState extends State<LentBorrowedScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _filter = 'All'; // All, Pending, Overdue, Partially Repaid
  final Map<String, int> _reminderSeedMap = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatCurrency(double amt) {
    return '₹${amt.toStringAsFixed(amt.truncateToDouble() == amt ? 0 : 2)}';
  }

  String _formatDate(DateTime d) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);

    final lentActive = appState.activeLentRecords;
    final borrowedActive = appState.activeBorrowedRecords;
    final settled = appState.settledDebtRecords;

    return Scaffold(
      backgroundColor: const Color(0xFF020C10),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 64,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Center(
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFF061E24),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF0F3B44), width: 1.2),
                ),
                child: const Icon(
                  Icons.chevron_left_rounded,
                  size: 26,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
        title: const Text(
          'Lent & Borrowed',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => _openAddEditModal(context, appState),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFF061E24),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFF00E5A3),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    size: 24,
                    color: Color(0xFF00E5A3),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Summary Cards ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: _buildSummaryCards(appState),
          ),

          // ── Main Tabs (Underline Navigation Bar) ───────────────────────────
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFF0D2F38), width: 1.2),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFF00E5A3),
              indicatorWeight: 3.0,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: const Color(0xFF00E5A3),
              labelPadding: const EdgeInsets.symmetric(horizontal: 4),
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              tabs: [
                Tab(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Money Lent'),
                        if (lentActive.isNotEmpty) ...[
                          const SizedBox(width: 5),
                          _buildCountBadge(
                            lentActive.length,
                            isSelected: _tabController.index == 0,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                Tab(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Borrowed'),
                        if (borrowedActive.isNotEmpty) ...[
                          const SizedBox(width: 5),
                          _buildCountBadge(
                            borrowedActive.length,
                            isSelected: _tabController.index == 1,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                Tab(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Settled'),
                        if (settled.isNotEmpty) ...[
                          const SizedBox(width: 5),
                          _buildCountBadge(
                            settled.length,
                            isSelected: _tabController.index == 2,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Status Filter Chips ─────────────────────────────────────────────
          if (_tabController.index < 2)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('All'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Pending'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Partially Repaid'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Overdue'),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 8),

          // ── Tab Views ──────────────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildRecordsList(
                  context,
                  appState,
                  _filterRecords(lentActive),
                  emptyTitle: 'No money lent out',
                  emptySubtitle:
                      'Did you spot a friend for coffee or lunch? Tap + to keep track!',
                  isLentTab: true,
                ),
                _buildRecordsList(
                  context,
                  appState,
                  _filterRecords(borrowedActive),
                  emptyTitle: 'No borrowed money',
                  emptySubtitle:
                      'You currently owe nothing to anyone! Peaceful wallet vibes ✨',
                  isLentTab: false,
                ),
                _buildRecordsList(
                  context,
                  appState,
                  settled,
                  emptyTitle: 'No settled records yet',
                  emptySubtitle:
                      'Completed full repayments will be celebrated and archived here!',
                  isSettledTab: true,
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF00E5A3),
        foregroundColor: const Color(0xFF03161C),
        elevation: 4,
        icon: const Icon(Icons.add_rounded, size: 22, color: Color(0xFF03161C)),
        label: const Text(
          'Add Record',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14,
            color: Color(0xFF03161C),
          ),
        ),
        onPressed: () {
          final defaultType = _tabController.index == 1
              ? DebtType.borrowed
              : DebtType.lent;
          _openAddEditModal(context, appState, initialType: defaultType);
        },
      ),
    );
  }

  Widget _buildCountBadge(int count, {required bool isSelected}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF00E5A3).withValues(alpha: 0.18)
            : const Color(0xFF0F323B),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: isSelected ? const Color(0xFF00E5A3) : const Color(0xFF7A9FA9),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _filter == label;
    return GestureDetector(
      onTap: () => setState(() => _filter = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF072128) : const Color(0xFF06181E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF00E5A3) : const Color(0xFF0F323B),
            width: isSelected ? 1.4 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF7A9FA9),
          ),
        ),
      ),
    );
  }

  List<LentBorrowedRecord> _filterRecords(List<LentBorrowedRecord> records) {
    if (_filter == 'All') return records;
    if (_filter == 'Pending') {
      return records.where((r) => r.status == DebtStatus.pending).toList();
    }
    if (_filter == 'Partially Repaid') {
      return records.where((r) => r.status == DebtStatus.partiallyRepaid).toList();
    }
    if (_filter == 'Overdue') {
      return records.where((r) => r.status == DebtStatus.overdue).toList();
    }
    return records;
  }

  // ── Summary Cards ──────────────────────────────────────────────────────────
  Widget _buildSummaryCards(AppState appState) {
    final toCollect = appState.totalLentOutstanding;
    final toRepay = appState.totalBorrowedOutstanding;

    return Row(
      children: [
        // To Collect (Receivables)
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF061E24),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF0D3D46), width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A333A),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.north_east_rounded,
                        color: Color(0xFF00E5A3),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Flexible(
                      child: Text(
                        'To Collect',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Color(0xFF7CA1AA),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _formatCurrency(toCollect),
                    style: const TextStyle(
                      color: Color(0xFF00E5A3),
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 12),

        // To Repay (Payables)
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1713),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF382C1F), width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFF332514),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.south_east_rounded,
                        color: Color(0xFFFFB300),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Flexible(
                      child: Text(
                        'To Repay',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Color(0xFF9E8E7D),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _formatCurrency(toRepay),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Records List ───────────────────────────────────────────────────────────
  Widget _buildRecordsList(
    BuildContext context,
    AppState appState,
    List<LentBorrowedRecord> records, {
    required String emptyTitle,
    required String emptySubtitle,
    bool isLentTab = false,
    bool isSettledTab = false,
  }) {
    if (records.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFF092027),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF133C47)),
                ),
                child: const Icon(
                  Icons.handshake_rounded,
                  color: Color(0xFF00E5A3),
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                emptyTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                emptySubtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF88A6B2),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      itemCount: records.length,
      itemBuilder: (ctx, idx) {
        final record = records[idx];
        return _buildDebtCard(context, appState, record);
      },
    );
  }

  // ── Record Card ────────────────────────────────────────────────────────────
  Widget _buildDebtCard(
    BuildContext context,
    AppState appState,
    LentBorrowedRecord record,
  ) {
    final seed = _reminderSeedMap[record.id] ?? 0;
    final funnyReminder = DebtReminderLibrary.getRandomReminder(record, seed: seed);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF061E24),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: record.isOverdue
              ? const Color(0xFFFF3366).withValues(alpha: 0.4)
              : const Color(0xFF0E3842),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header Row: Circular Avatar, Name, Amount, Status Badge ─────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Circular Initial Avatar
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Color(0xFF0B3439),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  record.personName.trim().isNotEmpty
                      ? record.personName.trim()[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Name & Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.personName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${record.type == DebtType.lent ? "Lent on" : "Borrowed on"} ${_formatDate(record.date)}',
                      style: const TextStyle(
                        color: Color(0xFF769AA5),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Outstanding Amount & Status Chip
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatCurrency(
                      record.outstandingAmount > 0
                          ? record.outstandingAmount
                          : record.amount,
                    ),
                    style: TextStyle(
                      color: record.isFullySettled
                          ? const Color(0xFF00E676)
                          : (record.type == DebtType.lent
                              ? const Color(0xFF00E5A3)
                              : const Color(0xFFFFB300)),
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  _buildStatusBadge(record),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Due Date Row ───────────────────────────────────────────────────
          if (record.dueDate != null)
            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 14,
                  color: record.isOverdue
                      ? const Color(0xFFFF3366)
                      : const Color(0xFF769AA5),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    record.isOverdue
                        ? 'Due ${_formatDate(record.dueDate!)} · ${record.daysOverdue} days overdue'
                        : 'Due ${_formatDate(record.dueDate!)} · ${record.daysUntilDue} days left',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: record.isOverdue
                          ? const Color(0xFFFF3366)
                          : const Color(0xFF769AA5),
                      fontSize: 12,
                      fontWeight:
                          record.isOverdue ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            )
          else if (record.note.isNotEmpty)
            Row(
              children: [
                const Icon(
                  Icons.notes_rounded,
                  size: 14,
                  color: Color(0xFF769AA5),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    record.note,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF769AA5),
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),

          const SizedBox(height: 12),

          // ── Reminder Panel (Embedded Box) ───────────────────────────────────
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF08232B),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF0F3C47), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.chat_bubble_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        funnyReminder,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(height: 1, color: Color(0xFF0D353E)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Another Joke
                    Flexible(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () {
                          setState(() {
                            _reminderSeedMap[record.id] =
                                (_reminderSeedMap[record.id] ?? 0) + 1;
                          });
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.refresh_rounded,
                                size: 15,
                                color: Color(0xFF769AA5),
                              ),
                              SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  'Another joke',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Color(0xFF769AA5),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 6),

                    // Copy reminder
                    Flexible(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: funnyReminder));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: const Color(0xFF0F323D),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              content: Row(
                                children: [
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    color: Color(0xFF00E5A3),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Copied reminder! Ready to send to ${record.personName} 🚀',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.copy_rounded,
                                size: 14,
                                color: Color(0xFF00E5A3),
                              ),
                              SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  'Copy reminder',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Color(0xFF00E5A3),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Action Footer: Record Repayment & Three-Dot Overflow ────────────
          Row(
            children: [
              if (!record.isFullySettled)
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00E5A3),
                        foregroundColor: const Color(0xFF03161C),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(
                        Icons.account_balance_wallet_rounded,
                        size: 18,
                        color: Color(0xFF03161C),
                      ),
                      label: Text(
                        record.type == DebtType.lent
                            ? 'Record Repayment'
                            : 'Record My Payment',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF03161C),
                        ),
                      ),
                      onPressed: () => _openRepaymentModal(context, appState, record),
                    ),
                  ),
                )
              else
                Expanded(
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B3322),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF145437)),
                    ),
                    alignment: Alignment.center,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFF00E676),
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Fully Settled',
                          style: TextStyle(
                            color: Color(0xFF00E676),
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(width: 10),

              // Three-Dot Overflow Button
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF072128),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF0E3842), width: 1.2),
                ),
                child: PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  color: const Color(0xFF08232B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: Color(0xFF0F3B44)),
                  ),
                  onSelected: (val) {
                    if (val == 'details') {
                      _showDetailsModal(context, appState, record);
                    } else if (val == 'edit') {
                      _openAddEditModal(context, appState, existing: record);
                    } else if (val == 'delete') {
                      _confirmDelete(context, appState, record);
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'details',
                      child: Row(
                        children: [
                          Icon(
                            Icons.visibility_outlined,
                            size: 17,
                            color: Colors.white,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'View Details',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(
                            Icons.edit_outlined,
                            size: 17,
                            color: Colors.white,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Edit',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline_rounded,
                            size: 17,
                            color: Color(0xFFFF3366),
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Delete',
                            style: TextStyle(
                              color: Color(0xFFFF3366),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(LentBorrowedRecord record) {
    Color bg;
    Color border;
    Color text;

    switch (record.status) {
      case DebtStatus.pending:
        bg = const Color(0xFF382310);
        border = const Color(0xFF5A3815);
        text = const Color(0xFFFFB300);
        break;
      case DebtStatus.partiallyRepaid:
        bg = const Color(0xFF0A2B33);
        border = const Color(0xFF104A57);
        text = const Color(0xFF00E5FF);
        break;
      case DebtStatus.overdue:
        bg = const Color(0xFF38121A);
        border = const Color(0xFF661E2E);
        text = const Color(0xFFFF3366);
        break;
      case DebtStatus.settled:
        bg = const Color(0xFF0B3322);
        border = const Color(0xFF145437);
        text = const Color(0xFF00E676);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border, width: 1),
      ),
      child: Text(
        record.statusLabel,
        style: TextStyle(
          color: text,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  void _showDetailsModal(
    BuildContext context,
    AppState appState,
    LentBorrowedRecord record,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF061E24),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F3B44),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Title and direction badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Loan Details',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    _buildStatusBadge(record),
                  ],
                ),
                const SizedBox(height: 16),

              // Person tile
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF08252D),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF0F3C47)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: Color(0xFF0B3439),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        record.personName.trim().isNotEmpty
                            ? record.personName.trim()[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            record.personName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            record.type == DebtType.lent
                                ? 'Money Lent (Receivable)'
                                : 'Money Borrowed (Payable)',
                            style: TextStyle(
                              color: record.type == DebtType.lent
                                  ? const Color(0xFF00E5A3)
                                  : const Color(0xFFFFB300),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Financial stats grid
              Row(
                children: [
                  Expanded(
                    child: _buildDetailStatBox(
                      'Original',
                      _formatCurrency(record.amount),
                      Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildDetailStatBox(
                      'Repaid',
                      _formatCurrency(record.repaidAmount),
                      const Color(0xFF00E676),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildDetailStatBox(
                      'Outstanding',
                      _formatCurrency(record.outstandingAmount),
                      record.type == DebtType.lent
                          ? const Color(0xFF00E5A3)
                          : const Color(0xFFFFB300),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Date info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF08252D),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF0F3C47)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Transaction Date',
                            style: TextStyle(
                                color: Color(0xFF769AA5), fontSize: 12)),
                        Text(_formatDate(record.date),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                    if (record.dueDate != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Due Date',
                              style: TextStyle(
                                  color: Color(0xFF769AA5), fontSize: 12)),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              '${_formatDate(record.dueDate!)} (${record.isOverdue ? "${record.daysOverdue}d overdue" : "${record.daysUntilDue}d left"})',
                              textAlign: TextAlign.end,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: record.isOverdue
                                    ? const Color(0xFFFF3366)
                                    : Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (record.note.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Note',
                              style: TextStyle(
                                  color: Color(0xFF769AA5), fontSize: 12)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              record.note,
                              textAlign: TextAlign.end,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              if (record.repayments.isNotEmpty) ...[
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Repayment History',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700)),
                    Text('${record.repayments.length} installment(s)',
                        style: const TextStyle(
                            color: Color(0xFF769AA5), fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(maxHeight: 140),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: record.repayments.length,
                    separatorBuilder: (c, i) => const SizedBox(height: 6),
                    itemBuilder: (c, i) {
                      final rep = record.repayments[i];
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF08252D),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_formatCurrency(rep.amount),
                                    style: const TextStyle(
                                        color: Color(0xFF00E676),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800)),
                                if (rep.note.isNotEmpty)
                                  Text(rep.note,
                                      style: const TextStyle(
                                          color: Color(0xFF769AA5),
                                          fontSize: 11)),
                              ],
                            ),
                            Row(
                              children: [
                                Text(_formatDate(rep.date),
                                    style: const TextStyle(
                                        color: Color(0xFF769AA5), fontSize: 11)),
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (dCtx) => AlertDialog(
                                        backgroundColor: const Color(0xFF0A222B),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(18)),
                                        title: const Text('Delete Repayment?',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w800)),
                                        content: Text(
                                          'Remove ${_formatCurrency(rep.amount)} repayment installment? This will adjust your balance.',
                                          style: const TextStyle(
                                              color: Color(0xFFBDE0EA)),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(dCtx, false),
                                            child: const Text('Cancel',
                                                style: TextStyle(
                                                    color: Color(0xFF88A6B2))),
                                          ),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  const Color(0xFFFF3366),
                                              foregroundColor: Colors.white,
                                            ),
                                            onPressed: () =>
                                                Navigator.pop(dCtx, true),
                                            child: const Text('Delete'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true && context.mounted) {
                                      Navigator.of(ctx).pop();
                                      await appState.deleteRepayment(
                                        debtId: record.id,
                                        repaymentId: rep.id,
                                      );
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: const Padding(
                                    padding: EdgeInsets.all(4.0),
                                    child: Icon(
                                      Icons.delete_outline_rounded,
                                      size: 16,
                                      color: Color(0xFFFF6B81),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],

              const SizedBox(height: 18),
              Row(
                children: [
                  if (!record.isFullySettled) ...[
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00E5A3),
                            foregroundColor: const Color(0xFF03161C),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(
                              Icons.account_balance_wallet_rounded,
                              size: 18),
                          label: const Text('Record Repayment',
                              style: TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w800)),
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            _openRepaymentModal(context, appState, record);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFF0F3C47)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Close',
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
  }

  Widget _buildDetailStatBox(String title, String value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF08252D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF0F3C47)),
      ),
      child: Column(
        children: [
          Text(title,
              style: const TextStyle(
                  color: Color(0xFF769AA5),
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                  color: valueColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  // ── Add / Edit Modal ───────────────────────────────────────────────────────
  void _openAddEditModal(
    BuildContext context,
    AppState appState, {
    LentBorrowedRecord? existing,
    DebtType? initialType,
  }) {
    final nameController = TextEditingController(text: existing?.personName ?? '');
    final amountController = TextEditingController(
      text: existing != null
          ? existing.amount.toStringAsFixed(existing.amount.truncateToDouble() == existing.amount ? 0 : 2)
          : '',
    );
    final noteController = TextEditingController(text: existing?.note ?? '');

    DebtType selectedType = existing?.type ?? initialType ?? DebtType.lent;
    DateTime selectedDate = existing?.date ?? DateTime.now();
    DateTime? selectedDueDate = existing?.dueDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF091E25),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFF133C47),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Title
                    Text(
                      existing == null ? 'Add Lent or Borrowed Record' : 'Edit Record',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Direction Selector: Money I Lent vs Money I Borrowed
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF051318),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setModalState(() => selectedType = DebtType.lent),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: selectedType == DebtType.lent
                                      ? AppTheme.primaryMint
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(
                                    'Money I Lent',
                                    style: TextStyle(
                                      color: selectedType == DebtType.lent
                                          ? const Color(0xFF021015)
                                          : const Color(0xFF88A6B2),
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setModalState(() => selectedType = DebtType.borrowed),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: selectedType == DebtType.borrowed
                                      ? const Color(0xFFFFB300)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(
                                    'Money I Borrowed',
                                    style: TextStyle(
                                      color: selectedType == DebtType.borrowed
                                          ? const Color(0xFF021015)
                                          : const Color(0xFF88A6B2),
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Person's Name
                    const Text(
                      "Person's Name",
                      style: TextStyle(color: Color(0xFF88A6B2), fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameController,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFF071920),
                        hintText: 'e.g. Rahul, Priya',
                        hintStyle: const TextStyle(color: Color(0xFF4A6E78)),
                        prefixIcon: const Icon(Icons.person_rounded, color: AppTheme.primaryMint, size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF133C47)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF133C47)),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Amount
                    const Text(
                      "Amount",
                      style: TextStyle(color: Color(0xFF88A6B2), fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFF071920),
                        hintText: '0',
                        hintStyle: const TextStyle(color: Color(0xFF4A6E78)),
                        prefixIcon: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Text(
                            '₹',
                            style: TextStyle(
                              color: AppTheme.primaryMint,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF133C47)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF133C47)),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Record Transaction Date
                    const Text(
                      "Date",
                      style: TextStyle(color: Color(0xFF88A6B2), fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () async {
                        final picked = await DateRestriction.showRestrictedDatePicker(
                          context,
                          initialDate: selectedDate,
                          primaryColor: AppTheme.primaryMint,
                          surfaceColor: const Color(0xFF091E25),
                        );
                        if (picked != null) {
                          setModalState(() => selectedDate = picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF071920),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF133C47)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded, size: 18, color: Color(0xFF00E5FF)),
                            const SizedBox(width: 10),
                            Text(
                              _formatDate(selectedDate),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Due Date
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Expected Repayment Date (Optional)",
                          style: TextStyle(color: Color(0xFF88A6B2), fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        if (selectedDueDate != null)
                          GestureDetector(
                            onTap: () => setModalState(() => selectedDueDate = null),
                            child: const Text('Clear', style: TextStyle(color: Color(0xFFFF3366), fontSize: 11)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () async {
                        final now = DateTime.now();
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDueDate ?? now.add(const Duration(days: 7)),
                          firstDate: now.subtract(const Duration(days: 365)),
                          lastDate: now.add(const Duration(days: 365 * 5)),
                          builder: (ctx, child) {
                            return Theme(
                              data: Theme.of(ctx).copyWith(
                                colorScheme: const ColorScheme.dark(
                                  primary: Color(0xFF00E5A3),
                                  onPrimary: Color(0xFF03161C),
                                  surface: Color(0xFF091E25),
                                  onSurface: Colors.white,
                                ),
                                dialogTheme: const DialogThemeData(
                                  backgroundColor: Color(0xFF091E25),
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setModalState(() => selectedDueDate = picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF071920),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF133C47)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded, size: 18, color: Color(0xFF00E5FF)),
                            const SizedBox(width: 10),
                            Text(
                              selectedDueDate != null
                                  ? _formatDate(selectedDueDate!)
                                  : 'Select expected date',
                              style: TextStyle(
                                color: selectedDueDate != null ? Colors.white : const Color(0xFF4A6E78),
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Note
                    const Text(
                      "Note (Optional)",
                      style: TextStyle(color: Color(0xFF88A6B2), fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: noteController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFF071920),
                        hintText: 'e.g. For movie tickets, repaid via GPay',
                        hintStyle: const TextStyle(color: Color(0xFF4A6E78)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF133C47)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF133C47)),
                        ),
                      ),
                    ),

                    const SizedBox(height: 22),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryMint,
                          foregroundColor: const Color(0xFF03161C),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () {
                          final name = nameController.text.trim();
                          final amt = double.tryParse(amountController.text.trim());

                          if (name.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Please enter the person's name")),
                            );
                            return;
                          }
                          if (amt == null || amt <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Please enter a valid amount greater than 0")),
                            );
                            return;
                          }

                          if (DateRestriction.isFuture(selectedDate)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Record date cannot be in the future. Please select today or an earlier date.")),
                            );
                            return;
                          }

                          if (existing != null) {
                            final updated = existing.copyWith(
                              type: selectedType,
                              personName: name,
                              amount: amt,
                              date: selectedDate,
                              dueDate: selectedDueDate,
                              note: noteController.text.trim(),
                            );
                            appState.updateDebt(updated);
                          } else {
                            final newRecord = LentBorrowedRecord(
                              id: 'debt_${DateTime.now().millisecondsSinceEpoch}',
                              type: selectedType,
                              personName: name,
                              amount: amt,
                              date: selectedDate,
                              dueDate: selectedDueDate,
                              note: noteController.text.trim(),
                            );
                            appState.addDebt(newRecord);
                          }

                          Navigator.of(ctx).pop();
                        },
                        child: Text(
                          existing == null ? 'Save Record' : 'Update Record',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ── Repayment Modal ────────────────────────────────────────────────────────
  void _openRepaymentModal(
    BuildContext context,
    AppState appState,
    LentBorrowedRecord record,
  ) {
    final outstanding = record.outstandingAmount;
    final amountController = TextEditingController(
      text: outstanding.toStringAsFixed(outstanding.truncateToDouble() == outstanding ? 0 : 2),
    );
    final noteController = TextEditingController();
    DateTime repaymentDate = DateTime.now();
    bool isFullPayment = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF091E25),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFF133C47),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text('🎉', style: TextStyle(fontSize: 22)),
                        const SizedBox(width: 8),
                        Text(
                          record.type == DebtType.lent
                              ? 'Record Repayment from ${record.personName}'
                              : 'Record Repayment to ${record.personName}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Outstanding Balance: ${_formatCurrency(outstanding)}',
                      style: const TextStyle(
                        color: AppTheme.primaryMint,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Quick Toggle: Full vs Partial
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setModalState(() {
                                isFullPayment = true;
                                amountController.text = outstanding.toStringAsFixed(
                                    outstanding.truncateToDouble() == outstanding ? 0 : 2);
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: isFullPayment ? AppTheme.primaryMint : const Color(0xFF071920),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isFullPayment ? AppTheme.primaryMint : const Color(0xFF133C47),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'Full Repayment (${_formatCurrency(outstanding)})',
                                  style: TextStyle(
                                    color: isFullPayment ? const Color(0xFF021015) : Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setModalState(() {
                                isFullPayment = false;
                                amountController.clear();
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: !isFullPayment ? const Color(0xFF00E5FF) : const Color(0xFF071920),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: !isFullPayment ? const Color(0xFF00E5FF) : const Color(0xFF133C47),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'Partial Repayment',
                                  style: TextStyle(
                                    color: !isFullPayment ? const Color(0xFF021015) : Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Repayment Amount Input
                    const Text(
                      "Amount Repaid",
                      style: TextStyle(color: Color(0xFF88A6B2), fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFF071920),
                        prefixIcon: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Text(
                            '₹',
                            style: TextStyle(
                              color: AppTheme.primaryMint,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF133C47)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF133C47)),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Optional Note
                    const Text(
                      "Payment Note (Optional)",
                      style: TextStyle(color: Color(0xFF88A6B2), fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: noteController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFF071920),
                        hintText: 'e.g. Paid via UPI, Cash in hand',
                        hintStyle: const TextStyle(color: Color(0xFF4A6E78)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF133C47)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF133C47)),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Repayment Date
                    const Text(
                      "Payment Date",
                      style: TextStyle(color: Color(0xFF88A6B2), fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () async {
                        final picked = await DateRestriction.showRestrictedDatePicker(
                          context,
                          initialDate: repaymentDate,
                          primaryColor: AppTheme.primaryMint,
                          surfaceColor: const Color(0xFF091E25),
                        );
                        if (picked != null) {
                          setModalState(() => repaymentDate = picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF071920),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF133C47)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded, size: 18, color: Color(0xFF00E5FF)),
                            const SizedBox(width: 10),
                            Text(
                              _formatDate(repaymentDate),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 22),

                    // Confirm Repayment Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryMint,
                          foregroundColor: const Color(0xFF03161C),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () async {
                          final parsed = double.tryParse(amountController.text.trim());
                          if (parsed == null || parsed <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter a valid repayment amount')),
                            );
                            return;
                          }
                          if (parsed > outstanding + 0.001) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Amount cannot exceed outstanding balance of ${_formatCurrency(outstanding)}'),
                              ),
                            );
                            return;
                          }
                          if (DateRestriction.isFuture(repaymentDate)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Repayment date cannot be in the future.')),
                            );
                            return;
                          }

                          final nav = Navigator.of(ctx);
                          final messenger = ScaffoldMessenger.of(context);
                          final success = await appState.recordRepayment(
                            debtId: record.id,
                            amount: parsed,
                            date: repaymentDate,
                            note: noteController.text.trim(),
                          );

                          if (success && mounted) {
                            nav.pop();
                            messenger.showSnackBar(
                              SnackBar(
                                backgroundColor: const Color(0xFF0C2A34),
                                behavior: SnackBarBehavior.floating,
                                content: Text(
                                  'Recorded ${_formatCurrency(parsed)} repayment! Balance updated.',
                                  style: const TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ),
                            );
                          }
                        },
                        child: const Text(
                          'Confirm Repayment',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ── Delete Confirmation ────────────────────────────────────────────────────
  void _confirmDelete(
    BuildContext context,
    AppState appState,
    LentBorrowedRecord record,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0A222B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Record?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        content: Text(
          'Are you sure you want to delete this record for ${record.personName} (${_formatCurrency(record.amount)})?',
          style: const TextStyle(color: Color(0xFFBDE0EA)),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF88A6B2))),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF3366),
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
            onPressed: () {
              appState.deleteDebt(record.id);
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }
}
