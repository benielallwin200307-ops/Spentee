import 'package:flutter/material.dart';
import '../models/budget.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../models/transaction.dart';

/// Screen for managing monthly category budgets with live spending tracking.
class BudgetManagementScreen extends StatefulWidget {
  const BudgetManagementScreen({super.key});

  @override
  State<BudgetManagementScreen> createState() => _BudgetManagementScreenState();
}

class _BudgetManagementScreenState extends State<BudgetManagementScreen> {
  void _openAddOrEditBudgetDialog({Budget? existingBudget}) {
    final appState = AppStateScope.of(context);
    final isEditing = existingBudget != null;

    final categories = appState.customCategories
        .where((c) => c.isExpense)
        .map((c) => c.name)
        .toList();

    String selectedCategory = existingBudget?.category ??
        (categories.isNotEmpty ? categories.first : 'Food & Drinks');
    final amountController = TextEditingController(
      text: existingBudget != null
          ? existingBudget.limitAmount.toStringAsFixed(0)
          : '',
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0A181D),
      barrierColor: Colors.black.withValues(alpha: 0.7),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
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
                          color: const Color(0xFF1E3842),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isEditing ? 'Edit Category Budget' : 'Set Category Budget',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Track spending against a monthly limit.',
                      style: TextStyle(color: AppTheme.textGrey, fontSize: 13),
                    ),
                  const SizedBox(height: 18),

                  // Category Selector
                  const Text(
                    'Category',
                    style: TextStyle(
                      color: AppTheme.textGrey,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF081418),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: const Color(0xFF16323B), width: 1.2),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedCategory,
                        dropdownColor: const Color(0xFF0C242A),
                        isExpanded: true,
                        icon: const Icon(Icons.arrow_drop_down_rounded,
                            color: AppTheme.primaryMint),
                        items: categories.map((cat) {
                          return DropdownMenuItem<String>(
                            value: cat,
                            child: Row(
                              children: [
                                Icon(
                                  Transaction.iconForCategory(cat),
                                  color: Transaction.colorForCategory(cat),
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  cat,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: isEditing
                            ? null // Cannot change category when editing
                            : (val) {
                                if (val != null) {
                                  setModalState(() {
                                    selectedCategory = val;
                                  });
                                }
                              },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Amount Input
                  const Text(
                    'Monthly Limit (₹)',
                    style: TextStyle(
                      color: AppTheme.textGrey,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF081418),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: const Color(0xFF16323B), width: 1.2),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    child: TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'e.g. 5000',
                        hintStyle: TextStyle(
                          color: Color(0xFF556980),
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                        prefixText: '₹ ',
                        prefixStyle: TextStyle(
                          color: AppTheme.primaryMint,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                                color: Color(0xFF1B3B44)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Cancel',
                              style: TextStyle(
                                  color: Color(0xFF7E97A0),
                                  fontWeight: FontWeight.w700)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () async {
                            final parsed =
                                double.tryParse(amountController.text.trim()) ??
                                    0.0;
                            if (parsed <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Please enter a valid amount greater than ₹0'),
                                  backgroundColor: AppTheme.accentPink,
                                ),
                              );
                              return;
                            }

                            final messenger = ScaffoldMessenger.of(context);
                            Navigator.pop(ctx);

                            final now = DateTime.now();
                            if (isEditing) {
                              await appState.updateBudget(
                                existingBudget.copyWith(limitAmount: parsed),
                              );
                            } else {
                              final newBudget = Budget(
                                id: 'b_${DateTime.now().millisecondsSinceEpoch}',
                                category: selectedCategory,
                                limitAmount: parsed,
                                period: 'Monthly',
                                year: now.year,
                                month: now.month,
                              );
                              await appState.addBudget(newBudget);
                            }

                            if (mounted) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(isEditing
                                      ? 'Updated $selectedCategory budget!'
                                      : 'Set $selectedCategory budget to ₹${parsed.toStringAsFixed(0)}!'),
                                  backgroundColor: const Color(0xFF0D2526),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryMint,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            isEditing ? 'Save Changes' : 'Set Budget',
                            style: const TextStyle(
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
            ),
          );
          },
        );
      },
    );
  }

  void _confirmDeleteBudget(Budget budget) {
    final appState = AppStateScope.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0A181D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Delete Budget?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
        content: Text(
          'Are you sure you want to delete the monthly budget for "${budget.category}"? Your transactions will remain safe.',
          style: const TextStyle(color: AppTheme.textGrey, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF7E97A0))),
          ),
          ElevatedButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(ctx);
              await appState.deleteBudget(budget.id);
              if (mounted) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Removed ${budget.category} budget'),
                    backgroundColor: const Color(0xFF2A101C),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentPink,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Delete',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final budgets = appState.budgets;
    final transactions = appState.transactions;

    double totalBudget = 0.0;
    double totalSpent = 0.0;
    for (final b in budgets) {
      totalBudget += b.limitAmount;
      totalSpent += b.calculateSpent(transactions);
    }
    final overallRemaining =
        (totalBudget - totalSpent) < 0 ? 0.0 : (totalBudget - totalSpent);

    return Scaffold(
      backgroundColor: const Color(0xFF040A0F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Manage Budget',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded,
                color: AppTheme.primaryMint, size: 28),
            onPressed: () => _openAddOrEditBudgetDialog(),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary Banner Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0C242A), Color(0xFF07181D)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppTheme.primaryMint.withValues(alpha: 0.25),
                      width: 1.2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'October 2026 Budget',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppTheme.textGrey,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryMint.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${budgets.length} Categories',
                            style: const TextStyle(
                              color: AppTheme.primaryMint,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Total Spent',
                                style: TextStyle(
                                    color: Color(0xFF7E97A0), fontSize: 12),
                              ),
                              const SizedBox(height: 2),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  '₹${totalSpent.toStringAsFixed(0)}',
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
                        Container(
                          height: 36,
                          width: 1,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          color: const Color(0xFF16323B),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Remaining',
                                style: TextStyle(
                                    color: Color(0xFF7E97A0), fontSize: 12),
                              ),
                              const SizedBox(height: 2),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  '₹${overallRemaining.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    color: AppTheme.primaryMint,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          height: 36,
                          width: 1,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          color: const Color(0xFF16323B),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Total Limit',
                                style: TextStyle(
                                    color: Color(0xFF7E97A0), fontSize: 12),
                              ),
                              const SizedBox(height: 2),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  '₹${totalBudget.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    color: Color(0xFFB0C4CB),
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Category Budgets',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _openAddOrEditBudgetDialog(),
                    child: Row(
                      children: const [
                        Icon(Icons.add_circle_outline_rounded,
                            color: AppTheme.primaryMint, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'Add Budget',
                          style: TextStyle(
                            color: AppTheme.primaryMint,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              if (budgets.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  alignment: Alignment.center,
                  child: Column(
                    children: const [
                      Icon(Icons.savings_outlined,
                          color: Color(0xFF385560), size: 48),
                      SizedBox(height: 12),
                      Text(
                        'No category budgets set yet.',
                        style: TextStyle(
                            color: AppTheme.textGrey,
                            fontSize: 15,
                            fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Tap "Add Budget" to track your limits.',
                        style: TextStyle(
                            color: Color(0xFF556980), fontSize: 12),
                      ),
                    ],
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: budgets.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final b = budgets[index];
                    final spent = b.calculateSpent(transactions);
                    final ratio = b.calculateRatio(transactions);
                    final remaining = b.calculateRemaining(transactions);
                    final isOverspent = spent > b.limitAmount;

                    Color progressColor = AppTheme.primaryMint;
                    if (isOverspent) {
                      progressColor = AppTheme.accentPink;
                    } else if (ratio > 0.8) {
                      progressColor = AppTheme.accentOrange;
                    }

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF09181D),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                            color: const Color(0xFF143038), width: 1.1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Transaction.colorForCategory(b.category)
                                      .withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Transaction.colorForCategory(b.category)
                                        .withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Icon(
                                  Transaction.iconForCategory(b.category),
                                  color: Transaction.colorForCategory(b.category),
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      b.category,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      isOverspent
                                          ? 'Exceeded by ₹${(spent - b.limitAmount).toStringAsFixed(0)}'
                                          : '₹${remaining.toStringAsFixed(0)} left of ₹${b.limitAmount.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        color: isOverspent
                                            ? AppTheme.accentPink
                                            : AppTheme.textGrey,
                                        fontSize: 12,
                                        fontWeight: isOverspent
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined,
                                    color: Color(0xFF7E97A0), size: 18),
                                onPressed: () =>
                                    _openAddOrEditBudgetDialog(existingBudget: b),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded,
                                    color: Color(0xFF7E97A0), size: 18),
                                onPressed: () => _confirmDeleteBudget(b),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Progress Bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: ratio,
                              backgroundColor: const Color(0xFF132B33),
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(progressColor),
                              minHeight: 6,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '₹${spent.toStringAsFixed(0)} spent',
                                style: const TextStyle(
                                  color: Color(0xFF7E97A0),
                                  fontSize: 11,
                                ),
                              ),
                              Text(
                                '${(ratio * 100).toStringAsFixed(0)}%',
                                style: TextStyle(
                                  color: progressColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
