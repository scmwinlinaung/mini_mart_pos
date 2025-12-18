import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/product.dart';
import '../widgets/desktop_app_bar.dart';
import '../widgets/desktop_scaffold.dart';

class CustomerManagementScreen extends StatefulWidget {
  const CustomerManagementScreen({Key? key}) : super(key: key);

  @override
  State<CustomerManagementScreen> createState() => _CustomerManagementScreenState();
}

class _CustomerManagementScreenState extends State<CustomerManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  List<Customer> _customers = [];
  List<Customer> _filteredCustomers = [];
  bool _isLoading = false;
  bool _isAddingCustomer = false;
  Customer? _selectedCustomer;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterCustomers);
    _loadCustomers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _filterCustomers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCustomers = _customers.where((customer) {
        return (customer.fullName?.toLowerCase().contains(query) ?? false) ||
            (customer.phoneNumber?.toLowerCase().contains(query) ?? false) ||
            (customer.address?.toLowerCase().contains(query) ?? false);
      }).toList();
    });
  }

  Future<void> _loadCustomers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Implement actual customer loading from database
      // For now, show sample data
      _customers = [
        Customer(
          customerId: 1,
          phoneNumber: '+959123456789',
          fullName: 'John Doe',
          address: '123 Main St, Yangon',
          loyaltyPoints: 150,
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
        ),
        Customer(
          customerId: 2,
          phoneNumber: '+959987654321',
          fullName: 'Jane Smith',
          address: '456 Oak Ave, Mandalay',
          loyaltyPoints: 75,
          createdAt: DateTime.now().subtract(const Duration(days: 15)),
        ),
        Customer(
          customerId: 3,
          phoneNumber: '+959555666777',
          fullName: 'Bob Wilson',
          loyaltyPoints: 200,
          createdAt: DateTime.now().subtract(const Duration(days: 60)),
        ),
      ];
      _filteredCustomers = List.from(_customers);
    } catch (e) {
      _showErrorSnackBar('Failed to load customers: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addCustomer() async {
    if (!_validateCustomerForm()) return;

    setState(() {
      _isAddingCustomer = true;
    });

    try {
      // TODO: Implement actual customer creation in database
      final newCustomer = Customer(
        customerId: _customers.length + 1,
        phoneNumber: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        fullName: _nameController.text.trim().isEmpty ? null : _nameController.text.trim(),
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        loyaltyPoints: 0,
        createdAt: DateTime.now(),
      );

      setState(() {
        _customers.add(newCustomer);
        _filteredCustomers = List.from(_customers);
      });

      _clearCustomerForm();
      _hideAddCustomerDialog();
      _showSuccessSnackBar('Customer added successfully');
    } catch (e) {
      _showErrorSnackBar('Failed to add customer: $e');
    } finally {
      setState(() {
        _isAddingCustomer = false;
      });
    }
  }

  Future<void> _updateCustomer(Customer customer) async {
    if (!_validateCustomerForm()) return;

    setState(() {
      _isAddingCustomer = true;
    });

    try {
      // TODO: Implement actual customer update in database
      final updatedCustomer = Customer(
        customerId: customer.customerId,
        phoneNumber: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        fullName: _nameController.text.trim().isEmpty ? null : _nameController.text.trim(),
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        loyaltyPoints: customer.loyaltyPoints,
        createdAt: customer.createdAt,
      );

      setState(() {
        final index = _customers.indexWhere((c) => c.customerId == customer.customerId);
        if (index != -1) {
          _customers[index] = updatedCustomer;
          _filteredCustomers = List.from(_customers);
        }
      });

      _clearCustomerForm();
      _hideAddCustomerDialog();
      _showSuccessSnackBar('Customer updated successfully');
    } catch (e) {
      _showErrorSnackBar('Failed to update customer: $e');
    } finally {
      setState(() {
        _isAddingCustomer = false;
      });
    }
  }

  Future<void> _deleteCustomer(Customer customer) async {
    final confirmed = await _showDeleteConfirmationDialog(customer);
    if (!confirmed) return;

    try {
      // TODO: Implement actual customer deletion from database
      setState(() {
        _customers.removeWhere((c) => c.customerId == customer.customerId);
        _filteredCustomers = List.from(_customers);
      });

      _showSuccessSnackBar('Customer deleted successfully');
    } catch (e) {
      _showErrorSnackBar('Failed to delete customer: $e');
    }
  }

  bool _validateCustomerForm() {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty && phone.isEmpty) {
      _showErrorSnackBar('Please provide either name or phone number');
      return false;
    }

    return true;
  }

  void _clearCustomerForm() {
    _nameController.clear();
    _phoneController.clear();
    _addressController.clear();
    _selectedCustomer = null;
  }

  void _showAddCustomerDialog() {
    _selectedCustomer = null;
    _clearCustomerForm();
    showDialog(
      context: context,
      builder: (context) => _buildCustomerDialog(),
    );
  }

  void _showEditCustomerDialog(Customer customer) {
    _selectedCustomer = customer;
    _nameController.text = customer.fullName ?? '';
    _phoneController.text = customer.phoneNumber ?? '';
    _addressController.text = customer.address ?? '';
    showDialog(
      context: context,
      builder: (context) => _buildCustomerDialog(),
    );
  }

  void _hideAddCustomerDialog() {
    Navigator.of(context).pop();
  }

  Widget _buildCustomerDialog() {
    final isEditing = _selectedCustomer != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit Customer' : 'Add New Customer'),
      content: SizedBox(
        width: 400,
        child: Form(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  hintText: 'Enter customer name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  hintText: 'Enter phone number',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  hintText: 'Enter customer address',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              if (isEditing) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Loyalty Points: ${_selectedCustomer!.loyaltyPoints}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Member Since: ${_selectedCustomer!.createdAt.day}/${_selectedCustomer!.createdAt.month}/${_selectedCustomer!.createdAt.year}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isAddingCustomer ? null : _hideAddCustomerDialog,
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isAddingCustomer ? null : () {
            if (isEditing) {
              _updateCustomer(_selectedCustomer!);
            } else {
              _addCustomer();
            }
          },
          child: _isAddingCustomer
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(isEditing ? 'Update' : 'Add'),
        ),
      ],
    );
  }

  Future<bool> _showDeleteConfirmationDialog(Customer customer) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Customer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete this customer?'),
            const SizedBox(height: 12),
            if (customer.fullName != null)
              Text('Name: ${customer.fullName}'),
            if (customer.phoneNumber != null)
              Text('Phone: ${customer.phoneNumber}'),
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

  @override
  Widget build(BuildContext context) {
    return DesktopScaffold(
      appBar: const DesktopAppBar(
        title: 'Customer Management',
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
                      labelText: 'Search Customers',
                      hintText: 'Search by name, phone, or address...',
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
                  onPressed: _showAddCustomerDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Customer'),
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
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredCustomers.isEmpty
                      ? _buildEmptyState()
                      : _buildCustomerTable(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final hasCustomers = _customers.isNotEmpty;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasCustomers ? Icons.search_off : Icons.people_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            hasCustomers ? 'No customers found' : 'No customers yet',
            style: TextStyle(
              fontSize: 20,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasCustomers
                ? 'Try adjusting your search terms'
                : 'Add your first customer to get started',
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
          if (!hasCustomers) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showAddCustomerDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add First Customer'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCustomerTable() {
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
                      'Customer ID',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Name',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Phone Number',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Address',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      'Loyalty Points',
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
            ..._filteredCustomers.asMap().entries.map((entry) {
              final index = entry.key;
              final customer = entry.value;
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
                        '#${customer.customerId}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        customer.fullName ?? '—',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        customer.phoneNumber ?? '—',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        customer.address ?? '—',
                        style: const TextStyle(fontSize: 14),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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
                          color: customer.loyaltyPoints > 100
                              ? Colors.amber[100]
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          customer.loyaltyPoints.toString(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: customer.loyaltyPoints > 100
                                ? Colors.amber[800]
                                : Colors.grey[700],
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () => _showEditCustomerDialog(customer),
                            icon: const Icon(Icons.edit, size: 20),
                            tooltip: 'Edit Customer',
                            color: Colors.blue,
                          ),
                          IconButton(
                            onPressed: () => _deleteCustomer(customer),
                            icon: const Icon(Icons.delete, size: 20),
                            tooltip: 'Delete Customer',
                            color: Colors.red,
                          ),
                        ],
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