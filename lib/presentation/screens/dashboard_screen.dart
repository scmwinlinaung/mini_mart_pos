import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/logic/auth/auth_cubit.dart';
import '../widgets/desktop_app_bar.dart';
import '../widgets/desktop_scaffold.dart';
import 'pos_screen.dart';
import 'product_management_screen.dart';
import 'inventory_screen.dart';
import 'sales_history_screen.dart';
import 'user_management_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DesktopScaffold(
      appBar: DesktopAppBar(
        title: 'Mini Mart POS - Dashboard',
        actions: [
          BlocBuilder<AuthCubit, AuthState>(
            builder: (context, state) {
              return state.whenOrNull(
                authenticated: (session) => _buildUserMenu(context, session),
              ) ?? const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Row(
        children: [
          // Sidebar Navigation
          SizedBox(
            width: 280,
            child: Card(
              elevation: 4,
              margin: const EdgeInsets.all(16),
              child: _buildSidebar(context),
            ),
          ),

          // Main Content Area
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildMainContent(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserMenu(BuildContext context, userSession) {
    return PopupMenuButton<String>(
      icon: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.person),
          const SizedBox(width: 8),
          Text(
            userSession.user.fullName,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.arrow_drop_down),
        ],
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'profile',
          child: Row(
            children: [
              const Icon(Icons.person_outline),
              const SizedBox(width: 8),
              Text(userSession.user.fullName),
              const Spacer(),
              Chip(
                label: Text(
                  userSession.user.roleName ?? 'User',
                  style: const TextStyle(fontSize: 12),
                ),
                backgroundColor: _getRoleColor(userSession.user.roleName),
              ),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'divider',
          child: Divider(),
        ),
        const PopupMenuItem(
          value: 'settings',
          child: Row(
            children: [
              Icon(Icons.settings_outlined),
              SizedBox(width: 8),
              Text('Settings'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout, color: Colors.red),
              SizedBox(width: 8),
              Text('Logout', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        _handleUserMenuSelection(context, value);
      },
    );
  }

  Color _getRoleColor(String? roleName) {
    switch (roleName?.toLowerCase()) {
      case 'admin':
        return Colors.purple[100]!;
      case 'manager':
        return Colors.blue[100]!;
      case 'cashier':
        return Colors.green[100]!;
      default:
        return Colors.grey[100]!;
    }
  }

  Widget _buildSidebar(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        return state.whenOrNull(
          authenticated: (session) => Column(
            children: [
              // User Info Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Theme.of(context).primaryColor,
                      child: Text(
                        session.user.fullName.isNotEmpty
                            ? session.user.fullName[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            session.user.fullName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            session.user.roleName ?? 'User',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Navigation Menu
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    _buildNavItem(
                      context,
                      icon: Icons.point_of_sale,
                      title: 'POS / Sales',
                      onTap: () => _navigateToScreen(context, const PosScreen()),
                    ),
                    _buildNavItem(
                      context,
                      icon: Icons.inventory_2,
                      title: 'Products',
                      onTap: () => _navigateToScreen(context, const ProductManagementScreen()),
                      enabled: session.isAdmin || session.isManager,
                    ),
                    _buildNavItem(
                      context,
                      icon: Icons.category,
                      title: 'Inventory',
                      onTap: () => _navigateToScreen(context, const InventoryScreen()),
                      enabled: session.isAdmin || session.isManager,
                    ),
                    _buildNavItem(
                      context,
                      icon: Icons.history,
                      title: 'Sales History',
                      onTap: () => _navigateToScreen(context, const SalesHistoryScreen()),
                      enabled: session.isAdmin || session.isManager,
                    ),
                    _buildNavItem(
                      context,
                      icon: Icons.people,
                      title: 'User Management',
                      onTap: () => _navigateToScreen(context, const UserManagementScreen()),
                      enabled: session.isAdmin,
                    ),
                    _buildNavItem(
                      context,
                      icon: Icons.settings,
                      title: 'Settings',
                      onTap: () => _navigateToScreen(context, const SettingsScreen()),
                      enabled: session.isAdmin || session.isManager,
                    ),
                  ],
                ),
              ),

              // Quick Stats
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  border: Border(
                    top: BorderSide(color: Colors.grey[200]!),
                  ),
                ),
                child: _buildQuickStats(),
              ),
            ],
          ),
        ) ?? const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    return ListTile(
      enabled: enabled,
      leading: Icon(
        icon,
        color: enabled ? Theme.of(context).primaryColor : Colors.grey,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: enabled ? FontWeight.w500 : FontWeight.normal,
          color: enabled ? null : Colors.grey,
        ),
      ),
      onTap: enabled ? onTap : null,
      tileColor: enabled ? null : Colors.grey[100],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  Widget _buildQuickStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Stats',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildStatCard('Today\'s Sales', '\$0', Colors.green),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard('Low Stock', '0', Colors.orange),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome to Mini Mart POS',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Select an option from the sidebar to get started.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),

            // Quick Action Cards
            Expanded(
              child: GridView.count(
                crossAxisCount: 4,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
                children: [
                  _buildQuickActionCard(
                    context,
                    icon: Icons.point_of_sale,
                    title: 'Start New Sale',
                    description: 'Process customer transactions',
                    color: Colors.blue,
                    onTap: () => _navigateToScreen(context, const PosScreen()),
                  ),
                  _buildQuickActionCard(
                    context,
                    icon: Icons.inventory,
                    title: 'Manage Products',
                    description: 'Add, edit, and delete products',
                    color: Colors.green,
                  ),
                  _buildQuickActionCard(
                    context,
                    icon: Icons.barcode_reader,
                    title: 'Stock Check',
                    description: 'View inventory levels',
                    color: Colors.orange,
                  ),
                  _buildQuickActionCard(
                    context,
                    icon: Icons.analytics,
                    title: 'View Reports',
                    description: 'Sales and inventory analytics',
                    color: Colors.purple,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleUserMenuSelection(BuildContext context, String selection) {
    switch (selection) {
      case 'profile':
        // Show profile dialog
        break;
      case 'settings':
        _navigateToScreen(context, const SettingsScreen());
        break;
      case 'logout':
        _showLogoutDialog(context);
        break;
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<AuthCubit>().logout();
            },
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToScreen(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => screen),
    );
  }
}