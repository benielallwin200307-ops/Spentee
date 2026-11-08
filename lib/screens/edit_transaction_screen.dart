import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/transaction.dart';
import '../state/app_state.dart';
import '../utils/date_restriction.dart';
import '../models/category_model.dart';
import '../widgets/spentee_loading.dart';
import '../widgets/insufficient_balance_dialog.dart';

/// Screen allowing users to edit an existing transaction record with full validation.
class EditTransactionScreen extends StatefulWidget {
  final Transaction transaction;

  const EditTransactionScreen({
    super.key,
    required this.transaction,
  });

  @override
  State<EditTransactionScreen> createState() => _EditTransactionScreenState();
}

class _EditTransactionScreenState extends State<EditTransactionScreen> {
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _noteController;

  late TransactionType _selectedType;
  late CategoryItem _selectedCategory;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  bool _isSaving = false;

  static const List<String> _accountOptions = [
    'Primary Bank Account',
    'Savings Account',
    'Cash / Wallet',
    'Secondary Bank Account',
  ];

  late String _sourceAccount;
  late String _destinationAccount;

  static final List<CategoryItem> _transferCategories = [
    CategoryItem(
      id: 'cat_own_account_transfer',
      name: 'Own Account Transfer',
      isExpense: false,
      isCustom: false,
      icon: Icons.swap_horiz_rounded,
      color: AppTheme.accentBlue,
    ),
    CategoryItem(
      id: 'cat_gold_investment',
      name: 'Gold Investment',
      isExpense: false,
      isCustom: false,
      icon: Icons.monetization_on_rounded,
      color: AppTheme.accentAmber,
    ),
    CategoryItem(
      id: 'cat_mutual_fund_sip',
      name: 'Mutual Fund / SIP',
      isExpense: false,
      isCustom: false,
      icon: Icons.auto_graph_rounded,
      color: AppTheme.accentCyan,
    ),
    CategoryItem(
      id: 'cat_stocks_etfs',
      name: 'Stocks & ETFs',
      isExpense: false,
      isCustom: false,
      icon: Icons.trending_up_rounded,
      color: AppTheme.primaryMint,
    ),
    CategoryItem(
      id: 'cat_savings_deposits',
      name: 'Savings & Deposits',
      isExpense: false,
      isCustom: false,
      icon: Icons.savings_rounded,
      color: AppTheme.primaryMint,
    ),
    CategoryItem(
      id: 'cat_retirement_investments',
      name: 'Retirement Investments',
      isExpense: false,
      isCustom: false,
      icon: Icons.shield_rounded,
      color: AppTheme.accentPurple,
    ),
    CategoryItem(
      id: 'cat_other_investment',
      name: 'Other Investment',
      isExpense: false,
      isCustom: false,
      icon: Icons.account_balance_wallet_rounded,
      color: AppTheme.textGrey,
    ),
    // Historical categories preserved for backward compatibility
    CategoryItem(
      id: 'cat_bank_transfer',
      name: 'Bank Transfer',
      isExpense: false,
      isCustom: false,
      icon: Icons.account_balance_rounded,
      color: AppTheme.accentBlue,
    ),
    CategoryItem(
      id: 'cat_savings_vault',
      name: 'Savings Vault',
      isExpense: false,
      isCustom: false,
      icon: Icons.lock_clock_rounded,
      color: AppTheme.primaryMint,
    ),
    CategoryItem(
      id: 'cat_wallet_transfer',
      name: 'Wallet Transfer',
      isExpense: false,
      isCustom: false,
      icon: Icons.wallet_rounded,
      color: AppTheme.accentCyan,
    ),
  ];

  @override
  void initState() {
    super.initState();
    final tx = widget.transaction;
    _titleController = TextEditingController(text: tx.title);
    final formattedInitialAmount =
        tx.amount.truncateToDouble() == tx.amount
            ? tx.amount.toInt().toString()
            : tx.amount.toString();
    _amountController = TextEditingController(text: formattedInitialAmount);
    _noteController = TextEditingController(text: tx.note);

    _selectedType = tx.type;
    _selectedDate = tx.date;
    _selectedTime = TimeOfDay(hour: tx.date.hour, minute: tx.date.minute);
    _sourceAccount = tx.sourceAccount ?? 'Primary Bank Account';
    _destinationAccount = tx.destinationAccount ?? 'Savings Account';

    // Resolve initial category option
    _selectedCategory = _resolveCategory(tx.category, tx.type);
  }

  CategoryItem _resolveCategory(String name, TransactionType type,
      [AppState? appState]) {
    final list = _categoriesFor(type, appState);
    for (final opt in list) {
      if (opt.name.toLowerCase().trim() == name.toLowerCase().trim()) {
        return opt;
      }
    }
    return CategoryItem(
      id: 'cat_custom_${name.toLowerCase().replaceAll(' ', '_')}',
      name: name,
      isExpense: type == TransactionType.expense,
      isCustom: true,
      icon: widget.transaction.category.toLowerCase().trim() ==
              name.toLowerCase().trim()
          ? widget.transaction.icon
          : Transaction.iconForCategory(name),
      color: widget.transaction.category.toLowerCase().trim() ==
              name.toLowerCase().trim()
          ? widget.transaction.categoryColor
          : Transaction.colorForCategory(name),
    );
  }

  List<CategoryItem> _categoriesFor(TransactionType type,
      [AppState? appState]) {
    if (appState != null) {
      switch (type) {
        case TransactionType.expense:
          return appState.customCategories.where((c) => c.isExpense).toList();
        case TransactionType.income:
          return appState.customCategories.where((c) => !c.isExpense).toList();
        case TransactionType.transfer:
          return _transferCategories;
        default:
          return appState.customCategories.where((c) => c.isExpense).toList();
      }
    }
    switch (type) {
      case TransactionType.expense:
        return AppState.defaultCategories.where((c) => c.isExpense).toList();
      case TransactionType.income:
        return AppState.defaultCategories.where((c) => !c.isExpense).toList();
      case TransactionType.transfer:
        return _transferCategories;
      default:
        return AppState.defaultCategories.where((c) => c.isExpense).toList();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _onTypeChanged(TransactionType newType) {
    if (_selectedType == newType) return;
    final appState = AppStateScope.of(context);
    setState(() {
      _selectedType = newType;
      // Switch category if current category isn't in new list
      final newCats = _categoriesFor(newType, appState);
      final exists = newCats.any((c) =>
          c.name.toLowerCase().trim() ==
          _selectedCategory.name.toLowerCase().trim());
      if (!exists && newCats.isNotEmpty) {
        _selectedCategory = newCats.first;
      }
    });
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

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primaryMint,
              surface: Color(0xFF0B1920),
              onSurface: Colors.white,
            ),
            timePickerTheme: const TimePickerThemeData(
              backgroundColor: Color(0xFF0B1920),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _showCategoryPicker(AppState appState) {
    final categories = _categoriesFor(_selectedType, appState);

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
                const SizedBox(height: 16),
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
                    Text(
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
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final cat = categories[index];
                      final isSelected = cat.name.toLowerCase().trim() ==
                          _selectedCategory.name.toLowerCase().trim();

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
                                  shape: BoxShape.circle,
                                  color: cat.color.withValues(alpha: 0.2),
                                ),
                                child: Icon(
                                  cat.icon,
                                  color: cat.color,
                                  size: 22,
                                ),
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

  void _showAccountPicker(bool isSource) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF071319),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
                Text(
                  isSource ? 'Select Source Account' : 'Select Destination Account',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                ..._accountOptions.map((acc) {
                  final isSelected = isSource
                      ? _sourceAccount == acc
                      : _destinationAccount == acc;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        setState(() {
                          if (isSource) {
                            _sourceAccount = acc;
                          } else {
                            _destinationAccount = acc;
                          }
                        });
                        Navigator.pop(ctx);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primaryMint.withValues(alpha: 0.12)
                              : const Color(0xFF0C1F26),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.primaryMint
                                : const Color(0xFF14353F),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              acc.toLowerCase().contains('cash')
                                  ? Icons.wallet_rounded
                                  : Icons.account_balance_rounded,
                              color: isSelected
                                  ? AppTheme.primaryMint
                                  : AppTheme.textGrey,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                acc,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : const Color(0xFFCFDEE3),
                                  fontSize: 14,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                ),
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle_rounded,
                                color: AppTheme.primaryMint,
                                size: 18,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _onSaveChanges() async {
    if (_isSaving) return;

    final parsedAmount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (parsedAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF2A101C),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          content: const Row(
            children: [
              Icon(Icons.error_outline_rounded, color: AppTheme.accentPink, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Please enter a valid amount greater than ₹0!',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );
      return;
    }

    // Combine date and time
    final combinedDate = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    if (DateRestriction.isFuture(combinedDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF2A101C),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          content: const Row(
            children: [
              Icon(Icons.error_outline_rounded, color: AppTheme.accentPink, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Transaction date cannot be in the future! Please select today or an earlier date.',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );
      return;
    }

    final isOwnAccount = _selectedType == TransactionType.transfer &&
        !Transaction.isInvestmentCategory(_selectedCategory.name);

    if (isOwnAccount && _sourceAccount == _destinationAccount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF2A101C),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          content: const Row(
            children: [
              Icon(Icons.error_outline_rounded, color: AppTheme.accentPink, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Source and destination accounts must be different!',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );
      return;
    }

    final appState = AppStateScope.of(context);

    // Revalidate available balance for expenses accounting for the original transaction
    if (_selectedType == TransactionType.expense) {
      if (!appState.canAffordExpense(parsedAmount, excludeTransactionId: widget.transaction.id)) {
        final effectiveBal = appState.getEffectiveAvailableBalance(
          excludeTransactionId: widget.transaction.id,
        );
        await InsufficientBalanceDialog.show(
          context,
          availableBalance: effectiveBal,
          expenseAmount: parsedAmount,
        );
        return;
      }
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final rawTitle = _titleController.text.trim();
      final updatedTitle = rawTitle.isNotEmpty ? rawTitle : _selectedCategory.name;

      final updatedTx = widget.transaction.copyWith(
        title: updatedTitle,
        amount: parsedAmount,
        type: _selectedType,
        category: _selectedCategory.name,
        icon: _selectedCategory.icon,
        categoryColor: _selectedCategory.color,
        date: combinedDate,
        note: _noteController.text.trim(),
        sourceAccount:
            _selectedType == TransactionType.transfer ? _sourceAccount : null,
        destinationAccount: isOwnAccount ? _destinationAccount : null,
      );

      final success = await appState.updateTransaction(
        updatedTx,
        enforceBalanceValidation: true,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF0D2526),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: AppTheme.primaryMint, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Updated ${updatedTx.title} (₹${parsedAmount.toStringAsFixed(parsedAmount.truncateToDouble() == parsedAmount ? 0 : 2)}) successfully!',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        );
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _isSaving = false;
        });
        if (_selectedType == TransactionType.expense &&
            !appState.canAffordExpense(parsedAmount, excludeTransactionId: widget.transaction.id)) {
          final effectiveBal = appState.getEffectiveAvailableBalance(
            excludeTransactionId: widget.transaction.id,
          );
          await InsufficientBalanceDialog.show(
            context,
            availableBalance: effectiveBal,
            expenseAmount: parsedAmount,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Color(0xFF2A101C),
              behavior: SnackBarBehavior.floating,
              content: Text('Failed to update transaction.'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF2A101C),
            behavior: SnackBarBehavior.floating,
            content: Text('Error saving changes: $e', style: const TextStyle(color: Colors.white)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final dateStr = '${_selectedDate.day} ${months[_selectedDate.month]} ${_selectedDate.year}';
    final hour = _selectedTime.hour > 12 ? _selectedTime.hour - 12 : (_selectedTime.hour == 0 ? 12 : _selectedTime.hour);
    final period = _selectedTime.hour >= 12 ? 'PM' : 'AM';
    final minute = _selectedTime.minute.toString().padLeft(2, '0');
    final timeStr = '$hour:$minute $period';

    return Scaffold(
      backgroundColor: const Color(0xFF040A0F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        title: const Text(
          'Edit Transaction',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Type selector pills (Expense, Income, Transfer)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0B1920),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF142F38), width: 1.2),
                      ),
                      child: Row(
                        children: [
                          _buildTypeTab('Expense', TransactionType.expense, AppTheme.accentPink),
                          _buildTypeTab('Income', TransactionType.income, AppTheme.primaryMint),
                          _buildTypeTab('Transfer', TransactionType.transfer, AppTheme.accentBlue),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Amount Field
                    _buildInputLabel('Amount'),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0B1920),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF142F38), width: 1.2),
                      ),
                      child: Row(
                        children: [
                          const Text(
                            '₹',
                            style: TextStyle(
                              color: AppTheme.primaryMint,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _amountController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: '0',
                                hintStyle: TextStyle(color: AppTheme.textDim),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Title / Description
                    _buildInputLabel('Title / Description'),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0B1920),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF142F38), width: 1.2),
                      ),
                      child: TextField(
                        controller: _titleController,
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'e.g. Lunch with friends',
                          hintStyle: TextStyle(color: AppTheme.textDim, fontSize: 14),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Category Selector
                    _buildInputLabel('Category'),
                    GestureDetector(
                      onTap: () => _showCategoryPicker(appState),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0B1920),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF142F38), width: 1.2),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _selectedCategory.color.withValues(alpha: 0.2),
                              ),
                              child: Icon(
                                _selectedCategory.icon,
                                color: _selectedCategory.color,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _selectedCategory.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: AppTheme.textGrey,
                              size: 22,
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (_selectedType == TransactionType.transfer) ...[
                      const SizedBox(height: 18),
                      _buildInputLabel('From Account'),
                      GestureDetector(
                        onTap: () => _showAccountPicker(true),
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0B1920),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFF142F38), width: 1.2),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.account_balance_wallet_rounded, color: AppTheme.accentCyan, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _sourceAccount,
                                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                                ),
                              ),
                              const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.textGrey, size: 22),
                            ],
                          ),
                        ),
                      ),
                      if (!Transaction.isInvestmentCategory(_selectedCategory.name)) ...[
                        const SizedBox(height: 18),
                        _buildInputLabel('To Account'),
                        GestureDetector(
                          onTap: () => _showAccountPicker(false),
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0B1920),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFF142F38), width: 1.2),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.account_balance_rounded, color: AppTheme.accentBlue, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _destinationAccount,
                                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                                  ),
                                ),
                                const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.textGrey, size: 22),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],

                    const SizedBox(height: 18),

                    // Date & Time Row
                    Row(
                      children: [
                        // Date picker card
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInputLabel('Date'),
                              GestureDetector(
                                onTap: _pickDate,
                                behavior: HitTestBehavior.opaque,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0B1920),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: const Color(0xFF142F38), width: 1.2),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.calendar_today_rounded, size: 16, color: AppTheme.primaryMint),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          dateStr,
                                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Time picker card
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInputLabel('Time'),
                              GestureDetector(
                                onTap: _pickTime,
                                behavior: HitTestBehavior.opaque,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0B1920),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: const Color(0xFF142F38), width: 1.2),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.access_time_rounded, size: 16, color: AppTheme.accentCyan),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          timeStr,
                                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // Notes
                    _buildInputLabel('Notes (Optional)'),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0B1920),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF142F38), width: 1.2),
                      ),
                      child: TextField(
                        controller: _noteController,
                        maxLines: 3,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Add notes or remarks...',
                          hintStyle: TextStyle(color: AppTheme.textDim, fontSize: 13),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),

            // Bottom Buttons: Cancel & Save Changes
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: const BoxDecoration(
                color: Color(0xFF061015),
                border: Border(top: BorderSide(color: Color(0xFF142F38), width: 1)),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF1E3842), width: 1.2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    flex: 3,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _onSaveChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryMint,
                        foregroundColor: const Color(0xFF04190F),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                      ),
                      child: _isSaving
                          ? const SpenteeLoading.inline(
                              size: 20,
                              color: Color(0xFF04190F),
                            )
                          : const Text(
                              'Save Changes',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeTab(String label, TransactionType type, Color color) {
    final isSelected = _selectedType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onTypeChanged(type),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.18) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : Colors.transparent,
              width: 1.2,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : AppTheme.textGrey,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          color: AppTheme.textGrey,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
