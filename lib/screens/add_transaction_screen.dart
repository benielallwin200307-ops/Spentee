import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/transaction.dart';
import '../state/app_state.dart';
import 'lent_borrowed_screen.dart';
import '../utils/date_restriction.dart';

class _CategoryItem {
  final String name;
  final IconData icon;
  final Color color;

  const _CategoryItem({
    required this.name,
    required this.icon,
    required this.color,
  });
}

/// Screen 8 — Redesigned Add Transaction Screen
/// Matches the reference UI with custom numeric keypad, category/date/note cards,
/// transaction type switcher, and persistent saving with full financial integrity.
class AddTransactionScreen extends StatefulWidget {
  final TransactionType initialType;

  const AddTransactionScreen({
    super.key,
    this.initialType = TransactionType.expense,
  });

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  late TransactionType _selectedType;
  String _amountStr = '0';
  DateTime _selectedDate = DateTime.now();
  late _CategoryItem _selectedCategory;
  String _note = '';
  bool _isSaving = false;

  final List<_CategoryItem> _expenseCategories = const [
    _CategoryItem(
        name: 'Food & Drinks',
        icon: Icons.restaurant_rounded,
        color: AppTheme.accentPink),
    _CategoryItem(
        name: 'Transport',
        icon: Icons.directions_car_rounded,
        color: AppTheme.accentCyan),
    _CategoryItem(
        name: 'Shopping',
        icon: Icons.shopping_bag_rounded,
        color: AppTheme.accentPurple),
    _CategoryItem(
        name: 'Bills & Utilities',
        icon: Icons.receipt_long_rounded,
        color: AppTheme.accentOrange),
    _CategoryItem(
        name: 'Entertainment',
        icon: Icons.sports_esports_rounded,
        color: AppTheme.accentBlue),
    _CategoryItem(
        name: 'Groceries',
        icon: Icons.local_grocery_store_rounded,
        color: Color(0xFF10B981)),
    _CategoryItem(
        name: 'Health & Care',
        icon: Icons.medical_services_rounded,
        color: Color(0xFFEF4444)),
    _CategoryItem(
        name: 'Others',
        icon: Icons.more_horiz_rounded,
        color: AppTheme.textGrey),
  ];

  final List<_CategoryItem> _incomeCategories = const [
    _CategoryItem(
        name: 'Salary',
        icon: Icons.account_balance_wallet_rounded,
        color: AppTheme.primaryMint),
    _CategoryItem(
        name: 'Freelance',
        icon: Icons.laptop_mac_rounded,
        color: AppTheme.accentCyan),
    _CategoryItem(
        name: 'Investments',
        icon: Icons.trending_up_rounded,
        color: AppTheme.accentPurple),
    _CategoryItem(
        name: 'Gift / Bonus',
        icon: Icons.card_giftcard_rounded,
        color: AppTheme.accentOrange),
  ];

  final List<_CategoryItem> _transferCategories = const [
    _CategoryItem(
        name: 'Bank Transfer',
        icon: Icons.account_balance_rounded,
        color: AppTheme.accentBlue),
    _CategoryItem(
        name: 'Sent to Friend',
        icon: Icons.person_rounded,
        color: AppTheme.accentPurple),
    _CategoryItem(
        name: 'Savings Vault',
        icon: Icons.lock_clock_rounded,
        color: AppTheme.primaryMint),
    _CategoryItem(
        name: 'Wallet Transfer',
        icon: Icons.wallet_rounded,
        color: AppTheme.accentCyan),
  ];

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
    _selectedCategory = _categoriesForType.first;
  }

  List<_CategoryItem> get _categoriesForType {
    switch (_selectedType) {
      case TransactionType.expense:
        return _expenseCategories;
      case TransactionType.income:
        return _incomeCategories;
      case TransactionType.transfer:
        return _transferCategories;
    }
  }

  void _onTypeSelected(TransactionType type) {
    if (_selectedType == type) return;
    setState(() {
      _selectedType = type;
      _selectedCategory = _categoriesForType.first;
    });
  }

  void _onKeypadTap(String value) {
    setState(() {
      if (value == 'backspace') {
        if (_amountStr.isNotEmpty) {
          _amountStr = _amountStr.substring(0, _amountStr.length - 1);
          if (_amountStr.isEmpty) _amountStr = '0';
        }
      } else if (value == '.') {
        if (!_amountStr.contains('.')) {
          _amountStr = '$_amountStr.';
        }
      } else {
        // Digit pressed
        if (_amountStr == '0') {
          _amountStr = value;
        } else {
          // If decimal present, allow max 2 decimal places
          if (_amountStr.contains('.')) {
            final parts = _amountStr.split('.');
            if (parts.length > 1 && parts[1].length >= 2) {
              return; // Already 2 decimal places
            }
          } else if (_amountStr.length >= 9) {
            return; // Max integer digits
          }
          _amountStr = '$_amountStr$value';
        }
      }
    });
  }

  String _formatDisplayDate(DateTime d) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${d.day} ${months[d.month]} ${d.year}';
  }

  void _showCategoryPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0A181D),
      barrierColor: Colors.black.withValues(alpha: 0.7),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E3842),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Select Category',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF112A32),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFF1B424E), width: 1),
                      ),
                      child: Text(
                        _selectedType == TransactionType.expense
                            ? 'Expense'
                            : _selectedType == TransactionType.income
                                ? 'Income'
                                : 'Transfer',
                        style: const TextStyle(
                          color: AppTheme.primaryMint,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.45,
                  ),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 1.05,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: _categoriesForType.length,
                    itemBuilder: (context, index) {
                      final cat = _categoriesForType[index];
                      final isSelected = cat.name == _selectedCategory.name;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCategory = cat;
                          });
                          Navigator.pop(ctx);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? cat.color.withValues(alpha: 0.18)
                                : const Color(0xFF081418),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? cat.color
                                  : const Color(0xFF142E36),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: cat.color.withValues(alpha: 0.18),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(cat.icon,
                                    color: cat.color, size: 22),
                              ),
                              const SizedBox(height: 8),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                child: Text(
                                  cat.name,
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : AppTheme.textGrey,
                                    fontSize: 11,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickDate() async {
    final picked = await DateRestriction.showRestrictedDatePicker(
      context,
      initialDate: _selectedDate,
      primaryColor: AppTheme.primaryMint,
      surfaceColor: const Color(0xFF0B1920),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _showNoteModal() {
    final controller = TextEditingController(text: _note);
    final quickEmojis = ['☕ Coffee', '🍔 Dining', '🛒 Shopping', '🚕 Travel', '🎬 Movie', '💡 Bills', '🎁 Gift', '💼 Work'];

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0A181D),
      barrierColor: Colors.black.withValues(alpha: 0.7),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3842),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Add Note',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Add an optional note or reminder for this transaction.',
                style: TextStyle(
                  color: AppTheme.textGrey,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF081418),
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: const Color(0xFF16323B), width: 1.2),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: TextField(
                  controller: controller,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'e.g. Coffee with friends ☕',
                    hintStyle:
                        TextStyle(color: Color(0xFF556980), fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: quickEmojis.map((tag) {
                  return GestureDetector(
                    onTap: () {
                      controller.text = tag;
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10242B),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFF173842), width: 1),
                      ),
                      child: Text(
                        tag,
                        style: const TextStyle(
                          color: Color(0xFFB0C4CB),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _note = '';
                        });
                        Navigator.pop(ctx);
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF1B3B44)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Clear',
                          style: TextStyle(
                              color: Color(0xFF7E97A0),
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _note = controller.text.trim();
                        });
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryMint,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Save Note',
                        style: TextStyle(
                          color: Color(0xFF04190F),
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _onSave() async {
    if (_isSaving) return;

    final parsedAmount = double.tryParse(_amountStr) ?? 0.0;
    if (parsedAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF2A101C),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          content: Row(
            children: const [
              Icon(Icons.error_outline_rounded,
                  color: AppTheme.accentPink, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Please enter an amount greater than ₹0!',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );
      return;
    }

    if (DateRestriction.isFuture(_selectedDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF2A101C),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          content: Row(
            children: const [
              Icon(Icons.error_outline_rounded,
                  color: AppTheme.accentPink, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Transaction date cannot be in the future! Please select today or an earlier date.',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final appState = AppStateScope.of(context);
      final newTx = Transaction(
        id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
        title: _selectedCategory.name,
        amount: parsedAmount,
        type: _selectedType,
        category: _selectedCategory.name,
        icon: _selectedCategory.icon,
        categoryColor: _selectedCategory.color,
        date: _selectedDate,
        note: _note.trim(),
      );

      // Persist to database/storage
      await appState.addTransaction(newTx);

      if (!mounted) return;

      final typeLabel = _selectedType == TransactionType.expense
          ? 'Expense'
          : _selectedType == TransactionType.income
              ? 'Income'
              : 'Transfer';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF0D2526),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: AppTheme.primaryMint, size: 20),
              const SizedBox(width: 10),
              Text(
                'Saved ₹${parsedAmount.toStringAsFixed(parsedAmount.truncateToDouble() == parsedAmount ? 0 : 2)} $typeLabel!',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      );

      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF2A101C),
            behavior: SnackBarBehavior.floating,
            content: Text(
              'Failed to save transaction: $e',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = MascotThemeData.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFF040A0F),
      body: Stack(
        children: [
          // Ambient soft glow in top-right corner
          Positioned(
            top: -60,
            right: -60,
            child: IgnorePointer(
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      theme.primaryAccent.withValues(alpha: 0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Ambient soft glow in bottom-left corner
          Positioned(
            bottom: -80,
            left: -80,
            child: IgnorePointer(
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF004D40).withValues(alpha: 0.12),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ─── Header: Back Button + Title + Subtitle ───────────────
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF0B191E),
                              border: Border.all(
                                color: const Color(0xFF163238),
                                width: 1.2,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.chevron_left_rounded,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RichText(
                              text: TextSpan(
                                children: [
                                  const TextSpan(
                                    text: 'Add ',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'Transaction',
                                    style: TextStyle(
                                      color: theme.primaryAccent,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Track every rupee. Build a better you.',
                              style: TextStyle(
                                color: Color(0xFF7E97A0),
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ─── Transaction Type Selector ───────────────────────────
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF07171C),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF112D34),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        children: [
                          _buildTypeTab(
                            label: 'Expense',
                            icon: Icons.restaurant_rounded,
                            type: TransactionType.expense,
                          ),
                          _buildTypeTab(
                            label: 'Income',
                            icon: Icons.south_rounded,
                            type: TransactionType.income,
                          ),
                          _buildTypeTab(
                            label: 'Transfer',
                            icon: Icons.sync_alt_rounded,
                            type: TransactionType.transfer,
                          ),
                        ],
                      ),
                    ),

                    if (_selectedType == TransactionType.transfer) ...[
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const LentBorrowedScreen(),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0A222B),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF133C47)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.handshake_rounded, size: 14, color: AppTheme.primaryMint),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Tracking money lent or borrowed? Open Lent & Borrowed',
                                  style: TextStyle(
                                    color: Color(0xFFBDE0EA),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Icon(Icons.chevron_right_rounded, size: 16, color: AppTheme.primaryMint),
                            ],
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // ─── Amount Display Card ─────────────────────────────────
                    Container(
                      width: double.infinity,
                      height: 112,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF0C242A),
                            Color(0xFF07181D),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: const Color(0xFF153F47),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Rupee circular badge
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF0D2A30),
                                border: Border.all(
                                  color: const Color(0xFF194C53),
                                  width: 1,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                '₹',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            // Amount text with scaling
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _amountStr,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 48,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -1,
                                      ),
                                    ),
                                    // Mascot accent cursor
                                    Container(
                                      width: 3,
                                      height: 44,
                                      margin: const EdgeInsets.only(left: 4),
                                      decoration: BoxDecoration(
                                        color: theme.primaryAccent,
                                        borderRadius:
                                            BorderRadius.circular(2),
                                        boxShadow: [
                                          BoxShadow(
                                            color: theme.primaryAccent
                                                .withValues(alpha: 0.8),
                                            blurRadius: 6,
                                            spreadRadius: 1,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ─── Custom Numeric Keypad ───────────────────────────────
                    Column(
                      children: [
                        _buildKeypadRow(['1', '2', '3']),
                        const SizedBox(height: 10),
                        _buildKeypadRow(['4', '5', '6']),
                        const SizedBox(height: 10),
                        _buildKeypadRow(['7', '8', '9']),
                        const SizedBox(height: 10),
                        _buildKeypadRow(['.', '0', 'backspace']),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // ─── Transaction Detail Rows (Category, Date, Note) ──────
                    // Row 1: Category
                    _buildDetailCard(
                      icon: _selectedCategory.icon,
                      iconColor: const Color(0xFFFF3377),
                      badgeBgColor: const Color(0xFF2C1422),
                      badgeBorderColor: const Color(0xFF5A1E3C),
                      label: 'Category',
                      value: _selectedCategory.name,
                      onTap: _showCategoryPicker,
                    ),

                    const SizedBox(height: 10),

                    // Row 2: Date
                    _buildDetailCard(
                      icon: Icons.calendar_today_rounded,
                      iconColor: const Color(0xFF00E5FF),
                      badgeBgColor: const Color(0xFF0F2B33),
                      badgeBorderColor: const Color(0xFF144D59),
                      label: 'Date',
                      value: _formatDisplayDate(_selectedDate),
                      onTap: _pickDate,
                    ),

                    const SizedBox(height: 10),

                    // Row 3: Note
                    _buildDetailCard(
                      icon: Icons.description_rounded,
                      iconColor: const Color(0xFFB388FF),
                      badgeBgColor: const Color(0xFF26163A),
                      badgeBorderColor: const Color(0xFF4C2775),
                      label: 'Note',
                      value: _note.isNotEmpty ? _note : 'Add note (optional)',
                      onTap: _showNoteModal,
                    ),

                    const SizedBox(height: 22),

                    // ─── Save Button ─────────────────────────────────────────
                    GestureDetector(
                      onTap: _isSaving ? null : _onSave,
                      child: Container(
                        width: double.infinity,
                        height: 58,
                        decoration: BoxDecoration(
                          color: theme.primaryAccent,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: theme.primaryAccent
                                  .withValues(alpha: 0.45),
                              blurRadius: 18,
                              spreadRadius: 1,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            if (_isSaving)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Color(0xFF04190F),
                                      strokeWidth: 2.4,
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    'Saving...',
                                    style: TextStyle(
                                      color: Color(0xFF04190F),
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              )
                            else
                              const Text(
                                'Save',
                                style: TextStyle(
                                  color: Color(0xFF04190F),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            if (!_isSaving)
                              Positioned(
                                right: 10,
                                child: Container(
                                  width: 42,
                                  height: 42,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFF062315),
                                  ),
                                  child: const Icon(
                                    Icons.arrow_forward_rounded,
                                    color: AppTheme.primaryMint,
                                    size: 22,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Helper to build segmented tabs for Expense / Income / Transfer
  Widget _buildTypeTab({
    required String label,
    required IconData icon,
    required TransactionType type,
  }) {
    final theme = MascotThemeData.of(context);
    final isSelected = _selectedType == type;

    return Expanded(
      child: GestureDetector(
        onTap: () => _onTypeSelected(type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? theme.primaryAccent : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: theme.primaryAccent.withValues(alpha: 0.35),
                      blurRadius: 10,
                      spreadRadius: 0,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? const Color(0xFF051C11)
                    : const Color(0xFF7E97A0),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? const Color(0xFF051C11)
                      : const Color(0xFF7E97A0),
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Helper to build a single row of numeric keypad buttons
  Widget _buildKeypadRow(List<String> keys) {
    return Row(
      children: keys.map((key) {
        final isBackspace = key == 'backspace';

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _onKeypadTap(key),
                splashColor: AppTheme.primaryMint.withValues(alpha: 0.15),
                highlightColor: AppTheme.primaryMint.withValues(alpha: 0.08),
                child: Container(
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A191E),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF132D35),
                      width: 1,
                    ),
                  ),
                  child: isBackspace
                      ? const Icon(
                          Icons.backspace_outlined,
                          color: Colors.white,
                          size: 21,
                        )
                      : Text(
                          key,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 23,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Helper to build a detail card row (Category, Date, Note)
  Widget _buildDetailCard({
    required IconData icon,
    required Color iconColor,
    required Color badgeBgColor,
    required Color badgeBorderColor,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        splashColor: AppTheme.primaryMint.withValues(alpha: 0.08),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF0A181D),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFF143038),
              width: 1.1,
            ),
          ),
          child: Row(
            children: [
              // Colored icon badge
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: badgeBgColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: badgeBorderColor,
                    width: 1,
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 14),
              // Label & Value
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Color(0xFF7E97A0),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF7E97A0),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
