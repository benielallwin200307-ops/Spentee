import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

/// Screen for managing expense and income categories with full protection for historical transactions.
class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Color> _palette = const [
    Color(0xFFFF3377),
    Color(0xFF00E5FF),
    Color(0xFFA855F7),
    Color(0xFFFF9100),
    Color(0xFF00E676),
    Color(0xFF2979FF),
    Color(0xFF10B981),
    Color(0xFFEF4444),
    Color(0xFFFFD600),
    Color(0xFFEC4899),
    Color(0xFF8E9DAE),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddCategoryModal() {
    final appState = AppStateScope.of(context);
    final nameController = TextEditingController();
    bool isExpense = _tabController.index == 0;
    Color selectedColor = _palette.first;

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
                  const Text(
                    'Add Custom Category',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Category Type Selector
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setModalState(() => isExpense = true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: isExpense
                                  ? AppTheme.primaryMint
                                  : const Color(0xFF0C1F24),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Expense',
                              style: TextStyle(
                                color: isExpense
                                    ? const Color(0xFF051C11)
                                    : AppTheme.textGrey,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setModalState(() => isExpense = false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: !isExpense
                                  ? AppTheme.accentCyan
                                  : const Color(0xFF0C1F24),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Income',
                              style: TextStyle(
                                color: !isExpense
                                    ? const Color(0xFF051C11)
                                    : AppTheme.textGrey,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Name Field
                  const Text(
                    'Category Name',
                    style: TextStyle(color: AppTheme.textGrey, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF081418),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: const Color(0xFF16323B), width: 1.2),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: TextField(
                      controller: nameController,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'e.g. Subscriptions, Pet Care, Fitness',
                        hintStyle: TextStyle(
                            color: Color(0xFF556980), fontSize: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Color Picker
                  const Text(
                    'Accent Color',
                    style: TextStyle(color: AppTheme.textGrey, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _palette.map((color) {
                      final isSelected = selectedColor == color;
                      return GestureDetector(
                        onTap: () =>
                            setModalState(() => selectedColor = color),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.transparent,
                              width: 2.5,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Save & Cancel
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
                            final name = nameController.text.trim();
                            if (name.length < 2) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Category name must be at least 2 characters.'),
                                  backgroundColor: AppTheme.accentPink,
                                ),
                              );
                              return;
                            }

                            // Duplicate check for this type
                            final isDuplicate = appState.customCategories.any(
                                (c) =>
                                    c.isExpense == isExpense &&
                                    c.name.toLowerCase().trim() ==
                                        name.toLowerCase().trim());
                            if (isDuplicate) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'A category with this name already exists.'),
                                  backgroundColor: AppTheme.accentPink,
                                ),
                              );
                              return;
                            }

                            final newCat = CategoryItem(
                              id: 'cat_${DateTime.now().millisecondsSinceEpoch}',
                              name: name,
                              isExpense: isExpense,
                              isCustom: true,
                              icon: Icons.label_rounded,
                              color: selectedColor,
                              userId: appState.userUid.isNotEmpty ? appState.userUid : null,
                            );

                            final messenger = ScaffoldMessenger.of(context);
                            Navigator.pop(ctx);
                            await appState.addCustomCategory(newCat);
                            if (mounted) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text('Added "$name" category!'),
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
                          child: const Text(
                            'Add Category',
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
            ),
          );
          },
        );
      },
    );
  }

  void _showRenameModal(CategoryItem cat) {
    final appState = AppStateScope.of(context);
    final controller = TextEditingController(text: cat.name);

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0A181D),
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
              const Text(
                'Rename Category',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Historical transactions under this category will automatically update.',
                style: TextStyle(color: AppTheme.textGrey, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF081418),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: const Color(0xFF16323B), width: 1.2),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: TextField(
                  controller: controller,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  decoration: const InputDecoration(border: InputBorder.none),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF1B3B44)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Cancel',
                          style: TextStyle(color: Color(0xFF7E97A0))),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () async {
                        final newName = controller.text.trim();
                        if (newName.length < 2) return;
                        final messenger = ScaffoldMessenger.of(context);
                        Navigator.pop(ctx);
                        await appState.renameCategory(cat.id, newName);
                        if (mounted) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text('Renamed category to "$newName"'),
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
                      child: const Text(
                        'Save Name',
                        style: TextStyle(
                          color: Color(0xFF04190F),
                          fontWeight: FontWeight.w800,
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

  void _confirmDeleteCategory(CategoryItem cat) {
    final appState = AppStateScope.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0A181D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Delete Category?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
        content: Text(
          'Are you sure you want to delete "${cat.name}"? Past transactions will safely be preserved under the "Others" category.',
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
              await appState.deleteCategory(cat.id);
              if (mounted) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Deleted category "${cat.name}"'),
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

  Widget _buildCategoryList(List<CategoryItem> items) {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final cat = items[index];

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF09181D),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: const Color(0xFF143038), width: 1.1),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: cat.color.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: cat.color.withValues(alpha: 0.35), width: 1),
                ),
                alignment: Alignment.center,
                child: Icon(cat.icon, color: cat.color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  cat.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (!cat.isCustom)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF102830),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: const Color(0xFF173D47), width: 1),
                  ),
                  child: const Text(
                    'Default',
                    style: TextStyle(
                      color: Color(0xFF7E97A0),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              else ...[
                IconButton(
                  icon: const Icon(Icons.edit_outlined,
                      color: Color(0xFF7E97A0), size: 18),
                  onPressed: () => _showRenameModal(cat),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: Color(0xFF7E97A0), size: 18),
                  onPressed: () => _confirmDeleteCategory(cat),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final expenseCats =
        appState.customCategories.where((c) => c.isExpense).toList();
    final incomeCats =
        appState.customCategories.where((c) => !c.isExpense).toList();

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
          'Categories',
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
            onPressed: _showAddCategoryModal,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryMint,
          indicatorWeight: 3,
          labelColor: AppTheme.primaryMint,
          unselectedLabelColor: AppTheme.textGrey,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          tabs: [
            Tab(text: 'Expense (${expenseCats.length})'),
            Tab(text: 'Income (${incomeCats.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCategoryList(expenseCats),
          _buildCategoryList(incomeCats),
        ],
      ),
    );
  }
}
