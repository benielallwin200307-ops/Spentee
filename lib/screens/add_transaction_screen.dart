import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../models/transaction.dart';
import '../state/app_state.dart';

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

/// Screen 8 — Add Transaction Screen
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
  String _amountStr = '250';
  DateTime _selectedDate = DateTime.now();
  late _CategoryItem _selectedCategory;
  final TextEditingController _noteController = TextEditingController(text: 'Coffee with friends ☕');

  final List<_CategoryItem> _expenseCategories = const [
    _CategoryItem(name: 'Food & Drinks', icon: Icons.restaurant_rounded, color: AppTheme.accentPink),
    _CategoryItem(name: 'Transport', icon: Icons.directions_car_rounded, color: AppTheme.accentCyan),
    _CategoryItem(name: 'Shopping', icon: Icons.shopping_bag_rounded, color: AppTheme.accentPurple),
    _CategoryItem(name: 'Bills & Utilities', icon: Icons.receipt_long_rounded, color: AppTheme.accentOrange),
    _CategoryItem(name: 'Entertainment', icon: Icons.sports_esports_rounded, color: AppTheme.accentBlue),
    _CategoryItem(name: 'Groceries', icon: Icons.local_grocery_store_rounded, color: Color(0xFF10B981)),
    _CategoryItem(name: 'Health & Care', icon: Icons.medical_services_rounded, color: Color(0xFFEF4444)),
    _CategoryItem(name: 'Others', icon: Icons.more_horiz_rounded, color: AppTheme.textGrey),
  ];

  final List<_CategoryItem> _incomeCategories = const [
    _CategoryItem(name: 'Salary', icon: Icons.attach_money_rounded, color: AppTheme.primaryMint),
    _CategoryItem(name: 'Freelance', icon: Icons.laptop_mac_rounded, color: AppTheme.accentCyan),
    _CategoryItem(name: 'Investments', icon: Icons.trending_up_rounded, color: AppTheme.accentPurple),
    _CategoryItem(name: 'Gift / Bonus', icon: Icons.card_giftcard_rounded, color: AppTheme.accentOrange),
  ];

  final List<_CategoryItem> _transferCategories = const [
    _CategoryItem(name: 'Bank Transfer', icon: Icons.account_balance_rounded, color: AppTheme.accentBlue),
    _CategoryItem(name: 'Sent to Friend', icon: Icons.person_rounded, color: AppTheme.accentPurple),
    _CategoryItem(name: 'Savings Vault', icon: Icons.lock_clock_rounded, color: AppTheme.primaryMint),
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
        if (_amountStr == '0') {
          _amountStr = value;
        } else if (_amountStr.length < 9) {
          _amountStr = '$_amountStr$value';
        }
      }
    });
  }

  void _showCategoryPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgCard,
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
              const Text(
                'Select Category',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1.1,
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
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? cat.color.withValues(alpha: 0.2)
                              : AppTheme.bgSurface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? cat.color : AppTheme.borderSubtle,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CategoryBadge(icon: cat.icon, color: cat.color, size: 36),
                            const SizedBox(height: 6),
                            Text(
                              cat.name,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isSelected ? Colors.white : AppTheme.textGrey,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
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
        );
      },
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primaryMint,
              onPrimary: AppTheme.bgDark,
              surface: AppTheme.bgCard,
              onSurface: Colors.white,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: AppTheme.bgCard,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _onSave() {
    final parsedAmount = double.tryParse(_amountStr) ?? 0.0;
    if (parsedAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppTheme.accentPink,
          content: Text('Please enter an amount greater than 0!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

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
      note: _noteController.text.trim(),
    );

    appState.addTransaction(newTx);

    final typeLabel = _selectedType == TransactionType.expense
        ? 'Expense'
        : _selectedType == TransactionType.income
            ? 'Income'
            : 'Transfer';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.bgCard,
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: AppTheme.primaryMint, size: 20),
            const SizedBox(width: 10),
            Text(
              'Saved ₹${parsedAmount.toStringAsFixed(0)} $typeLabel!',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );

    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Add Transaction',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Column(
              children: [
                // Expense / Income / Transfer Segment Selector
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppTheme.bgSurface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      _TypePill(
                        label: 'Expense',
                        isSelected: _selectedType == TransactionType.expense,
                        activeColor: AppTheme.primaryMint,
                        onTap: () {
                          setState(() {
                            _selectedType = TransactionType.expense;
                            _selectedCategory = _categoriesForType.first;
                          });
                        },
                      ),
                      _TypePill(
                        label: 'Income',
                        isSelected: _selectedType == TransactionType.income,
                        activeColor: AppTheme.accentCyan,
                        onTap: () {
                          setState(() {
                            _selectedType = TransactionType.income;
                            _selectedCategory = _categoriesForType.first;
                          });
                        },
                      ),
                      _TypePill(
                        label: 'Transfer',
                        isSelected: _selectedType == TransactionType.transfer,
                        activeColor: AppTheme.accentBlue,
                        onTap: () {
                          setState(() {
                            _selectedType = TransactionType.transfer;
                            _selectedCategory = _categoriesForType.first;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Big Amount Display
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  alignment: Alignment.center,
                  child: Text(
                    '₹$_amountStr',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Interactive Numeric Keypad
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    children: [
                      _KeypadRow(
                        keys: const ['1', '2', '3'],
                        onTap: _onKeypadTap,
                      ),
                      const SizedBox(height: 12),
                      _KeypadRow(
                        keys: const ['4', '5', '6'],
                        onTap: _onKeypadTap,
                      ),
                      const SizedBox(height: 12),
                      _KeypadRow(
                        keys: const ['7', '8', '9'],
                        onTap: _onKeypadTap,
                      ),
                      const SizedBox(height: 12),
                      _KeypadRow(
                        keys: const ['.', '0', 'backspace'],
                        onTap: _onKeypadTap,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Form Fields (Category, Date, Note)
                SpenteeCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  borderRadius: 18,
                  child: Column(
                    children: [
                      // Category Field
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CategoryBadge(
                          icon: _selectedCategory.icon,
                          color: _selectedCategory.color,
                          size: 38,
                        ),
                        title: const Text(
                          'Category',
                          style: TextStyle(color: AppTheme.textGrey, fontSize: 12),
                        ),
                        subtitle: Text(
                          _selectedCategory.name,
                          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.textDim, size: 14),
                        onTap: _showCategoryPicker,
                      ),
                      const Divider(color: AppTheme.borderSubtle, height: 1),

                      // Date Field
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const CategoryBadge(
                          icon: Icons.calendar_today_rounded,
                          color: AppTheme.accentCyan,
                          size: 38,
                        ),
                        title: const Text(
                          'Date',
                          style: TextStyle(color: AppTheme.textGrey, fontSize: 12),
                        ),
                        subtitle: Text(
                          '${_selectedDate.day} Oct ${_selectedDate.year}',
                          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.textDim, size: 14),
                        onTap: _pickDate,
                      ),
                      const Divider(color: AppTheme.borderSubtle, height: 1),

                      // Note Field
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const CategoryBadge(
                          icon: Icons.edit_note_rounded,
                          color: AppTheme.accentPurple,
                          size: 38,
                        ),
                        title: const Text(
                          'Note',
                          style: TextStyle(color: AppTheme.textGrey, fontSize: 12),
                        ),
                        subtitle: TextField(
                          controller: _noteController,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 4),
                            hintText: 'Add an optional note...',
                            hintStyle: TextStyle(color: AppTheme.textDim, fontSize: 13),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Save Button
                NeonButton(
                  text: 'Save',
                  onPressed: _onSave,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Helper for keypad row.
class _KeypadRow extends StatelessWidget {
  final List<String> keys;
  final Function(String) onTap;

  const _KeypadRow({required this.keys, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: keys.map((key) {
        final isBackspace = key == 'backspace';
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Material(
              color: AppTheme.bgSurface,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => onTap(key),
                child: Container(
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.borderSubtle, width: 1),
                  ),
                  child: isBackspace
                      ? const Icon(Icons.backspace_outlined, color: Colors.white, size: 20)
                      : Text(
                          key,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
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
}

/// Helper for top type pill.
class _TypePill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color activeColor;
  final VoidCallback onTap;

  const _TypePill({
    required this.label,
    required this.isSelected,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? AppTheme.bgDark : AppTheme.textGrey,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
