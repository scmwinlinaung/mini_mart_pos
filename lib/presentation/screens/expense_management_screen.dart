import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/product.dart';
import '../widgets/desktop_app_bar.dart';
import '../widgets/desktop_scaffold.dart';

class ExpenseManagementScreen extends StatefulWidget {
  const ExpenseManagementScreen({Key? key}) : super(key: key);

  @override
  State<ExpenseManagementScreen> createState() => _ExpenseManagementScreenState();
}

class _ExpenseManagementScreenState extends State<ExpenseManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  List<Expense> _expenses = [];
  List<Expense> _filteredExpenses = [];
  List<ExpenseCategory> _categories = [];
  bool _isLoading = false;
  bool _isAddingExpense = false;
  ExpenseCategory? _selectedCategory;
  Expense? _selectedExpense;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterExpenses);
    _selectedDate = DateTime.now();
    _dateController.text = _formatDate(DateTime.now());
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  void _filterExpenses() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredExpenses = _expenses.where((expense) {
        return expense.title.toLowerCase().contains(query) ||
            (expense.description?.toLowerCase().contains(query) ?? false) ||
            (expense.categoryName?.toLowerCase().contains(query) ?? false);
      }).toList();
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Implement actual data loading from database
      _categories = [
        ExpenseCategory(categoryId: 1, categoryName: 'Rent'),
        ExpenseCategory(categoryId: 2, categoryName: 'Utilities'),
        ExpenseCategory(categoryId: 3, categoryName: 'Salary'),
        ExpenseCategory(categoryId: 4, categoryName: 'Supplies'),
        ExpenseCategory(categoryId: 5, categoryName: 'Marketing'),
        ExpenseCategory(categoryId: 6, categoryName: 'Maintenance'),
        ExpenseCategory(categoryId: 7, categoryName: 'Other'),
      ];

      _expenses = [
        Expense(
          expenseId: 1,
          categoryId: 1,
          categoryName: 'Rent',
          userId: 1,
          userName: 'Admin',
          title: 'Monthly Shop Rent',
          description: 'Rent payment for December 2024',
          amount: 150000, // $1500.00
          expenseDate: DateTime.now().subtract(const Duration(days: 5)),
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
        ),
        Expense(
          expenseId: 2,
          categoryId: 2,
          categoryName: 'Utilities',
          userId: 1,
          userName: 'Admin',
          title: 'Electricity Bill',
          description: 'Electricity consumption for November 2024',
          amount: 25000, // $250.00
          expenseDate: DateTime.now().subtract(const Duration(days: 10)),
          createdAt: DateTime.now().subtract(const Duration(days: 10)),
        ),
        Expense(
          expenseId: 3,
          categoryId: 4,
          categoryName: 'Supplies',
          userId: 2,
          userName: 'Cashier',
          title: 'Office Supplies',
          description: 'Purchase of printer paper and pens',
          amount: 3500, // $35.00
          expenseDate: DateTime.now().subtract(const Duration(days: 15)),
          createdAt: DateTime.now().subtract(const Duration(days: 15)),
        ),
        Expense(
          expenseId: 4,
          categoryId: 3,
          categoryName: 'Salary',
          userId: 1,
          userName: 'Admin',
          title: 'Staff Salary - December',
          description: 'Monthly salary payments',
          amount: 300000, // $3000.00
          expenseDate: DateTime.now().subtract(const Duration(days: 1)),
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ];

      _filteredExpenses = List.from(_expenses);
    } catch (e) {
      _showErrorSnackBar('Failed to load expenses: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addExpense() async {
    if (!_validateExpenseForm()) return;

    setState(() {
      _isAddingExpense = true;
    });

    try {
      // TODO: Implement actual expense creation in database
      final amountInCents = (double.parse(_amountController.text) * 100).round();
      final newExpense = Expense(
        expenseId: _expenses.length + 1,
        categoryId: _selectedCategory?.categoryId ?? 7,
        categoryName: _selectedCategory?.categoryName ?? 'Other',
        userId: 1, // TODO: Get current user ID
        userName: 'Current User', // TODO: Get current user name
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        amount: amountInCents,
        expenseDate: _selectedDate ?? DateTime.now(),
        createdAt: DateTime.now(),
      );

      setState(() {
        _expenses.add(newExpense);
        _filteredExpenses = List.from(_expenses);
      });

      _clearExpenseForm();
      _hideExpenseDialog();
      _showSuccessSnackBar('Expense added successfully');
    } catch (e) {
      _showErrorSnackBar('Failed to add expense: $e');
    } finally {
      setState(() {
        _isAddingExpense = false;
      });
    }
  }

  Future<void> _deleteExpense(Expense expense) async {
    final confirmed = await _showDeleteConfirmationDialog(expense);
    if (!confirmed) return;

    try {
      // TODO: Implement actual expense deletion from database
      setState(() {
        _expenses.removeWhere((e) => e.expenseId == expense.expenseId);
        _filteredExpenses = List.from(_expenses);
      });

      _showSuccessSnackBar('Expense deleted successfully');
    } catch (e) {
      _showErrorSnackBar('Failed to delete expense: $e');
    }
  }

  bool _validateExpenseForm() {
    final title = _titleController.text.trim();
    final amount = _amountController.text.trim();

    if (title.isEmpty) {
      _showErrorSnackBar('Please enter expense title');
      return false;
    }

    if (amount.isEmpty) {
      _showErrorSnackBar('Please enter expense amount');
      return false;
    }

    if (_selectedCategory == null) {
      _showErrorSnackBar('Please select expense category');
      return false;
    }

    try {
      double.parse(amount);
    } catch (e) {
      _showErrorSnackBar('Please enter a valid amount');
      return false;
    }

    return true;
  }

  void _clearExpenseForm() {
    _titleController.clear();
    _descriptionController.clear();
    _amountController.clear();
    _selectedCategory = null;
    _selectedExpense = null;
    _selectedDate = DateTime.now();
    _dateController.text = _formatDate(DateTime.now());
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = _formatDate(picked);
      });
    }
  }

  void _showAddExpenseDialog() {
    _clearExpenseForm();
    showDialog(
      context: context,
      builder: (context) => _buildExpenseDialog(),
    );
  }

  void _hideExpenseDialog() {
    Navigator.of(context).pop();
  }

  Widget _buildExpenseDialog() {
    return AlertDialog(
      title: const Text('Add New Expense'),
      content: SizedBox(
        width: 450,
        child: Form(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Expense Title *',
                  hintText: 'Enter expense title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<ExpenseCategory>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category *',
                  border: OutlineInputBorder(),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category.categoryName),
                  );
                }).toList(),
                onChanged: (category) {
                  setState(() {
                    _selectedCategory = category;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount *',
                  hintText: 'Enter amount',
                  prefixText: '\$ ',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dateController,
                decoration: InputDecoration(
                  labelText: 'Date *',
                  hintText: 'Select date',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    onPressed: _selectDate,
                    icon: const Icon(Icons.calendar_today),
                  ),
                ),
                readOnly: true,
                onTap: _selectDate,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Enter expense description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isAddingExpense ? null : _hideExpenseDialog,
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isAddingExpense ? null : _addExpense,
          child: _isAddingExpense
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Add Expense'),
        ),
      ],
    );
  }

  Future<bool> _showDeleteConfirmationDialog(Expense expense) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expense'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete this expense?'),
            const SizedBox(height: 12),
            Text('Title: ${expense.title}'),
            Text('Amount: ${expense.formattedAmount}'),
            Text('Category: ${expense.categoryDisplay}'),
            const SizedBox(height: 8),
            const Text(
              'This action cannot be undone.',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  double get _totalExpenses {
    return _filteredExpenses.fold<double>(0, (sum, expense) => sum + expense.amountDouble);
  }

  @override
  Widget build(BuildContext context) {
    return DesktopScaffold(
      appBar: const DesktopAppBar(
        title: 'Expense Management',
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Search Expenses',
                      hintText: 'Search by title, description, or category...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _showAddExpenseDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Expense'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Expenses',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          '\$${_totalExpenses.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Expense Count',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          _filteredExpenses.length.toString(),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredExpenses.isEmpty
                      ? _buildEmptyState()
                      : _buildExpenseTable(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final hasExpenses = _expenses.isNotEmpty;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasExpenses ? Icons.search_off : Icons.receipt_long_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            hasExpenses ? 'No expenses found' : 'No expenses yet',
            style: TextStyle(
              fontSize: 20,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasExpenses
                ? 'Try adjusting your search terms'
                : 'Add your first expense to get started',
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
          if (!hasExpenses) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showAddExpenseDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add First Expense'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExpenseTable() {
    return Card(
      elevation: 4,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: const [
                  Expanded(
                    flex: 1,
                    child: Text(
                      'Date',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Title',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      'Category',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      'Amount',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      'Added By',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      'Actions',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ..._filteredExpenses.asMap().entries.map((entry) {
              final index = entry.key;
              final expense = entry.value;
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: index % 2 == 0 ? Colors.white : Colors.grey[50],
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey[200]!,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: Text(
                        expense.expenseDateDisplay,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            expense.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          if (expense.description != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              expense.description!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          expense.categoryDisplay,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.blue[700],
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        expense.formattedAmount,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.red,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        expense.userName ?? '—',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: IconButton(
                        onPressed: () => _deleteExpense(expense),
                        icon: const Icon(Icons.delete, size: 20),
                        tooltip: 'Delete Expense',
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}