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
    final theme = MascotThemeData.of(context);

    final lentActive = appState.activeLentRecords;
    final borrowedActive = appState.activeBorrowedRecords;
    final settled = appState.settledDebtRecords;

    return Scaffold(
      backgroundColor: const Color(0xFF030D11),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF092027),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF133C47)),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 16,
              color: Colors.white,
            ),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Lent & Borrowed',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Add Loan / Borrowing',
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.primaryAccent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.primaryAccent.withValues(alpha: 0.4),
                ),
              ),
              child: Icon(
                Icons.add_rounded,
                size: 20,
                color: theme.primaryAccent,
              ),
            ),
            onPressed: () => _openAddEditModal(context, appState),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // ── Summary Cards ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: _buildSummaryCards(appState),
          ),

          // ── Tabs ───────────────────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF091E25),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF133944)),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: theme.primaryAccent,
                borderRadius: BorderRadius.circular(12),
              ),
              labelColor: const Color(0xFF021015),
              unselectedLabelColor: const Color(0xFF88A6B2),
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Money Lent'),
                      if (lentActive.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        _buildCountBadge(lentActive.length, isSelected: _tabController.index == 0),
                      ],
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Borrowed'),
                      if (borrowedActive.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        _buildCountBadge(borrowedActive.length, isSelected: _tabController.index == 1),
                      ],
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Settled'),
                      if (settled.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        _buildCountBadge(settled.length, isSelected: _tabController.index == 2),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Filter Chips ───────────────────────────────────────────────────
          if (_tabController.index < 2)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
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
        backgroundColor: theme.primaryAccent,
        foregroundColor: const Color(0xFF03161C),
        icon: const Icon(Icons.add_rounded, size: 22),
        label: const Text(
          'Add Record',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
        ),
        onPressed: () => _openAddEditModal(context, appState),
      ),
    );
  }

  Widget _buildCountBadge(int count, {required bool isSelected}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF03161C).withValues(alpha: 0.25)
            : const Color(0xFF12343E),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: isSelected ? const Color(0xFF03161C) : Colors.white,
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _filter == label;
    return GestureDetector(
      onTap: () => setState(() => _filter = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF144552)
              : const Color(0xFF091E25),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryMint : const Color(0xFF12343E),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF88A6B2),
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
    final overdueCount = appState.overdueDebtsCount;

    return Row(
      children: [
        // To Collect (Receivables)
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF062B28), Color(0xFF0A1F24)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF104A41)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryMint.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.call_received_rounded,
                        color: AppTheme.primaryMint,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'To Collect',
                      style: TextStyle(
                        color: Color(0xFF8BB5AB),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  _formatCurrency(toCollect),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
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
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2C190B), Color(0xFF1B1612)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF4D2B12)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFB300).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.call_made_rounded,
                        color: Color(0xFFFFB300),
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'To Repay',
                      style: TextStyle(
                        color: Color(0xFFC7A17D),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (overdueCount > 0) ...[
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF3366).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$overdueCount Overdue',
                          style: const TextStyle(
                            color: Color(0xFFFF3366),
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  _formatCurrency(toRepay),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
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
                  color: AppTheme.primaryMint,
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
      decoration: BoxDecoration(
        color: const Color(0xFF071920),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: record.isOverdue
              ? const Color(0xFFFF3366).withValues(alpha: 0.4)
              : const Color(0xFF0F323D),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Avatar, Name, Amounts, Status Chip
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                CircleAvatar(
                  radius: 22,
                  backgroundColor: record.type == DebtType.lent
                      ? const Color(0xFF0B3B33)
                      : const Color(0xFF382312),
                  child: Text(
                    record.personName.isNotEmpty
                        ? record.personName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: record.type == DebtType.lent
                          ? AppTheme.primaryMint
                          : const Color(0xFFFFB300),
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Name & Date
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
                      const SizedBox(height: 3),
                      Text(
                        '${record.type == DebtType.lent ? "Lent on" : "Borrowed on"} ${_formatDate(record.date)}',
                        style: const TextStyle(
                          color: Color(0xFF7E9FA9),
                          fontSize: 12,
                        ),
                      ),
                      if (record.note.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          record.note,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF5A7A84),
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Outstanding amount & Status chip
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatCurrency(record.outstandingAmount),
                      style: TextStyle(
                        color: record.isFullySettled
                            ? const Color(0xFF00E676)
                            : (record.type == DebtType.lent
                                ? AppTheme.primaryMint
                                : const Color(0xFFFFB300)),
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: record.statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: record.statusColor.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        record.statusLabel,
                        style: TextStyle(
                          color: record.statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Progress bar (if partially repaid)
          if (record.repayments.isNotEmpty && !record.isFullySettled)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: record.progressRatio,
                      backgroundColor: const Color(0xFF0F323D),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        record.type == DebtType.lent
                            ? AppTheme.primaryMint
                            : const Color(0xFFFFB300),
                      ),
                      minHeight: 5,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Repaid: ${_formatCurrency(record.repaidAmount)} of ${_formatCurrency(record.amount)}',
                        style: const TextStyle(
                          color: Color(0xFF7E9FA9),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${(record.progressRatio * 100).round()}%',
                        style: TextStyle(
                          color: record.type == DebtType.lent
                              ? AppTheme.primaryMint
                              : const Color(0xFFFFB300),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),

          // Due date banner
          if (record.dueDate != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(
                    record.isOverdue
                        ? Icons.warning_amber_rounded
                        : Icons.event_available_rounded,
                    size: 14,
                    color: record.isOverdue
                        ? const Color(0xFFFF3366)
                        : const Color(0xFF7E9FA9),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    record.isOverdue
                        ? 'Due date was ${_formatDate(record.dueDate!)} (${record.daysOverdue}d overdue)'
                        : 'Due on ${_formatDate(record.dueDate!)} (${record.daysUntilDue}d left)',
                    style: TextStyle(
                      color: record.isOverdue
                          ? const Color(0xFFFF3366)
                          : const Color(0xFF7E9FA9),
                      fontSize: 11,
                      fontWeight: record.isOverdue
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 10),

          // ── Funny Reminder Bubble ──────────────────────────────────────────
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0A222B),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF144350)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('💬', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        funnyReminder,
                        style: const TextStyle(
                          color: Color(0xFFBDE0EA),
                          fontSize: 12,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Shuffle reminder button
                    InkWell(
                      onTap: () {
                        setState(() {
                          _reminderSeedMap[record.id] =
                              (_reminderSeedMap[record.id] ?? 0) + 1;
                        });
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        child: Row(
                          children: [
                            Icon(Icons.refresh_rounded,
                                size: 13, color: Color(0xFF7E9FA9)),
                            SizedBox(width: 4),
                            Text(
                              'Another Joke',
                              style: TextStyle(
                                color: Color(0xFF7E9FA9),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Copy reminder message button
                    InkWell(
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
                                const Icon(Icons.check_circle_rounded,
                                    color: AppTheme.primaryMint, size: 18),
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
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryMint.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.primaryMint.withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.copy_rounded,
                                size: 12, color: AppTheme.primaryMint),
                            SizedBox(width: 4),
                            Text(
                              'Copy Reminder',
                              style: TextStyle(
                                color: AppTheme.primaryMint,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Actions Footer ─────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF051318),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: Row(
              children: [
                if (!record.isFullySettled)
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: record.type == DebtType.lent
                            ? AppTheme.primaryMint
                            : const Color(0xFFFFB300),
                        foregroundColor: const Color(0xFF03161C),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      icon: const Icon(Icons.payments_rounded, size: 16),
                      label: Text(
                        record.type == DebtType.lent ? 'Record Repayment' : 'Record My Payment',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      onPressed: () => _openRepaymentModal(context, appState, record),
                    ),
                  ),

                if (record.repayments.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF88A6B2),
                      side: const BorderSide(color: Color(0xFF144350)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    icon: const Icon(Icons.history_rounded, size: 16),
                    label: Text(
                      'History (${record.repayments.length})',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                    onPressed: () => _openHistoryModal(context, record),
                  ),
                ],

                const Spacer(),

                // More Options: Edit & Delete
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF7E9FA9)),
                  color: const Color(0xFF0A222B),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onSelected: (val) {
                    if (val == 'edit') {
                      _openAddEditModal(context, appState, existing: record);
                    } else if (val == 'delete') {
                      _confirmDelete(context, appState, record);
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_rounded, size: 16, color: Colors.white),
                          SizedBox(width: 8),
                          Text('Edit', style: TextStyle(color: Colors.white, fontSize: 13)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFFF3366)),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Color(0xFFFF3366), fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
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
  }) {
    final nameController = TextEditingController(text: existing?.personName ?? '');
    final amountController = TextEditingController(
      text: existing != null
          ? existing.amount.toStringAsFixed(existing.amount.truncateToDouble() == existing.amount ? 0 : 2)
          : '',
    );
    final noteController = TextEditingController(text: existing?.note ?? '');

    DebtType selectedType = existing?.type ?? DebtType.lent;
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
                        final picked = await DateRestriction.showRestrictedDatePicker(
                          context,
                          initialDate: selectedDueDate ?? DateRestriction.localToday,
                          primaryColor: AppTheme.primaryMint,
                          surfaceColor: const Color(0xFF091E25),
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

  // ── History Modal ──────────────────────────────────────────────────────────
  void _openHistoryModal(BuildContext context, LentBorrowedRecord record) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF091E25),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
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
              Text(
                'Repayment History • ${record.personName}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Total Repaid: ${_formatCurrency(record.repaidAmount)} of ${_formatCurrency(record.amount)}',
                style: const TextStyle(
                  color: AppTheme.primaryMint,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              if (record.repayments.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'No repayments recorded yet.',
                      style: TextStyle(color: Color(0xFF88A6B2)),
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: record.repayments.length,
                    separatorBuilder: (_, _) => const Divider(color: Color(0xFF0F323D)),
                    itemBuilder: (ctx, idx) {
                      final rep = record.repayments[idx];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0C2A34),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.check_circle_outline_rounded,
                            color: AppTheme.primaryMint,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          _formatCurrency(rep.amount),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: Text(
                          rep.note.isNotEmpty
                              ? '${_formatDate(rep.date)} • ${rep.note}'
                              : _formatDate(rep.date),
                          style: const TextStyle(
                            color: Color(0xFF7E9FA9),
                            fontSize: 12,
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
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
