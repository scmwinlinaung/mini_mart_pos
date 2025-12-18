import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mini_mart_pos/core/bloc/language/language_state.dart';
import 'package:mini_mart_pos/data/models/auth.dart';
import '../../data/logic/auth/auth_cubit.dart';
import '../../data/logic/dashboard/dashboard_cubit.dart';
import '../widgets/desktop_app_bar.dart';
import '../widgets/desktop_scaffold.dart';
import '../widgets/profit_loss_chart.dart';
import '../widgets/dashboard_summary.dart';
import '../widgets/language_selector.dart';
import '../../core/service_locator.dart';
import '../../core/constants/app_strings.dart';
import '../../core/bloc/language/language_bloc.dart';
import 'pos_screen.dart';
import 'product_management_screen.dart';
import 'inventory_screen.dart';
import 'sales_history_screen.dart';
import 'user_management_screen.dart';
import 'category_management_screen.dart';
import 'supplier_management_screen.dart';
import 'settings_screen.dart';
import 'customer_management_screen.dart';
import 'expense_management_screen.dart';
import 'purchase_management_screen.dart';
import 'inventory_management_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<DashboardCubit>()..loadDashboardData(),
      child: DesktopScaffold(
        appBar: DesktopAppBar(
          showBackButton: false,
          title: context.getString(AppStrings.dashboardTitle),
          actions: [
            // Language toggle
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: LanguageToggle(),
            ),
            BlocBuilder<AuthCubit, AuthState>(
              builder: (context, state) {
                return state.whenOrNull(
                      authenticated: (session) =>
                          _buildUserMenu(context, session),
                    ) ??
                    const SizedBox.shrink();
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
          Text(userSession.user.fullName, style: const TextStyle(fontSize: 14)),
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
              BlocBuilder<LanguageBloc, LanguageState>(
                builder: (context, langState) {
                  final languageCode = langState.getLanguageCode();
                  return Chip(
                    label: Text(
                      userSession.user.getLocalizedRoleName(languageCode),
                      style: const TextStyle(fontSize: 12),
                    ),
                    backgroundColor: _getRoleColor(userSession.user.role.name),
                  );
                },
              ),
            ],
          ),
        ),
        const PopupMenuItem(value: 'divider', child: Divider()),
        PopupMenuItem(
          value: 'settings',
          child: Row(
            children: [
              const Icon(Icons.settings_outlined),
              const SizedBox(width: 8),
              LocalizedText(AppStrings.settings),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              const Icon(Icons.logout, color: Colors.red),
              const SizedBox(width: 8),
              LocalizedText(
                AppStrings.logout,
                style: const TextStyle(color: Colors.red),
              ),
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
                              BlocBuilder<LanguageBloc, LanguageState>(
                                builder: (context, langState) {
                                  final languageCode = langState
                                      .getLanguageCode();
                                  return Text(
                                    session.user.getLocalizedRoleName(
                                      languageCode,
                                    ),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  );
                                },
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
                        // Sales Section
                        _buildNavSectionHeader(
                          context,
                          context.getString(AppStrings.sales),
                        ),
                        _buildNavItem(
                          context,
                          icon: Icons.point_of_sale,
                          title: context.getString(AppStrings.newSale),
                          onTap: () =>
                              _navigateToScreen(context, const PosScreen()),
                        ),
                        _buildNavItem(
                          context,
                          icon: Icons.history,
                          title: context.getString(
                            AppStrings.recentTransactions,
                          ),
                          onTap: () => _navigateToScreen(
                            context,
                            const SalesHistoryScreen(),
                          ),
                          enabled: session.isAdmin || session.isManager,
                        ),
                        const SizedBox(height: 8),

                        // Inventory Section
                        _buildNavSectionHeader(
                          context,
                          context.getString(AppStrings.inventory),
                        ),
                        _buildNavItem(
                          context,
                          icon: Icons.inventory_2,
                          title: context.getString(
                            AppStrings.productManagement,
                          ),
                          onTap: () => _navigateToScreen(
                            context,
                            const ProductManagementScreen(),
                          ),
                          enabled: session.isAdmin || session.isManager,
                        ),
                        _buildNavItem(
                          context,
                          icon: Icons.inventory,
                          title: context.getString(AppStrings.inventoryTitle),
                          onTap: () => _navigateToScreen(
                            context,
                            const InventoryManagementScreen(),
                          ),
                          enabled: session.isAdmin || session.isManager,
                        ),
                        _buildNavItem(
                          context,
                          icon: Icons.category,
                          title: context.getString(AppStrings.currentStock),
                          onTap: () => _navigateToScreen(
                            context,
                            const InventoryScreen(),
                          ),
                          enabled: session.isAdmin || session.isManager,
                        ),
                        _buildNavItem(
                          context,
                          icon: Icons.receipt_long,
                          title: context.getString(
                            AppStrings.purchaseManagement,
                          ),
                          onTap: () => _navigateToScreen(
                            context,
                            const PurchaseManagementScreen(),
                          ),
                          enabled: session.isAdmin || session.isManager,
                        ),
                        _buildNavItem(
                          context,
                          icon: Icons.category,
                          title: context.getString(
                            AppStrings.categoryManagement,
                          ),
                          onTap: () => _navigateToScreen(
                            context,
                            const CategoryManagementScreen(),
                          ),
                          enabled: session.isAdmin || session.isManager,
                        ),
                        _buildNavItem(
                          context,
                          icon: Icons.business,
                          title: context.getString(
                            AppStrings.supplierManagement,
                          ),
                          onTap: () => _navigateToScreen(
                            context,
                            const SupplierManagementScreen(),
                          ),
                          enabled: session.isAdmin || session.isManager,
                        ),
                        const SizedBox(height: 8),

                        // Customer Section
                        _buildNavSectionHeader(
                          context,
                          context.getString(AppStrings.customerManagement),
                        ),
                        _buildNavItem(
                          context,
                          icon: Icons.people,
                          title: context.getString(
                            AppStrings.customerManagement,
                          ),
                          onTap: () => _navigateToScreen(
                            context,
                            const CustomerManagementScreen(),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Financial Section
                        _buildNavSectionHeader(
                          context,
                          context.getString(AppStrings.expenseManagement),
                        ),
                        _buildNavItem(
                          context,
                          icon: Icons.account_balance_wallet,
                          title: context.getString(
                            AppStrings.expenseManagement,
                          ),
                          onTap: () => _navigateToScreen(
                            context,
                            const ExpenseManagementScreen(),
                          ),
                          enabled: session.isAdmin || session.isManager,
                        ),
                        const SizedBox(height: 8),

                        // Admin Section
                        if (session.isAdmin || session.isManager)
                          _buildNavSectionHeader(
                            context,
                            context.getString(AppStrings.settings),
                          ),
                        if (session.isAdmin)
                          _buildNavItem(
                            context,
                            icon: Icons.admin_panel_settings,
                            title: context.getString(AppStrings.settings),
                            onTap: () => _navigateToScreen(
                              context,
                              const UserManagementScreen(),
                            ),
                            enabled: session.isAdmin,
                          ),
                        if (session.isAdmin || session.isManager)
                          _buildNavItem(
                            context,
                            icon: Icons.settings,
                            title: context.getString(AppStrings.settings),
                            onTap: () => _navigateToScreen(
                              context,
                              const SettingsScreen(),
                            ),
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
                      border: Border(top: BorderSide(color: Colors.grey[200]!)),
                    ),
                    child: _buildQuickStats(),
                  ),
                ],
              ),
            ) ??
            const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildNavSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
          letterSpacing: 0.5,
        ),
      ),
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
        size: 20,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: enabled ? FontWeight.w500 : FontWeight.normal,
          color: enabled ? null : Colors.grey,
          fontSize: 14,
        ),
      ),
      onTap: enabled ? onTap : null,
      tileColor: enabled ? null : Colors.grey[100],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
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
            Expanded(child: _buildStatCard('Low Stock', '0', Colors.orange)),
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
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildMainContent(BuildContext context) {
    return BlocBuilder<DashboardCubit, DashboardState>(
      builder: (context, state) {
        return state.when(
          initial: () => _buildWelcomeContent(context),
          loading: () => const Center(child: CircularProgressIndicator()),
          loaded: (dashboardData) =>
              _buildDashboardContent(context, dashboardData),
          error: (message) => _buildErrorContent(context, message),
        );
      },
    );
  }

  Widget _buildDashboardContent(BuildContext context, dynamic dashboardData) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Business Dashboard',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              IconButton(
                onPressed: () => context.read<DashboardCubit>().refresh(),
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh Dashboard',
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Financial Summary
          DashboardSummary(dashboardData: dashboardData),
          const SizedBox(height: 24),

          // Charts Row
          Row(
            children: [
              // Monthly Chart
              Expanded(
                child: ProfitLossChart(monthlyData: dashboardData.monthlyData),
              ),
              const SizedBox(width: 16),
            ],
          ),
          const SizedBox(height: 16),

          // Yearly Chart (if data available)
          if (dashboardData.yearlyData.isNotEmpty) ...[
            ProfitLossChart(
              monthlyData: [], // Not used for yearly chart
              isYearly: true,
              yearlyData: dashboardData.yearlyData,
            ),
            const SizedBox(height: 24),
          ],

          // Quick Actions
          Text(
            'Quick Actions',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          BlocBuilder<AuthCubit, AuthState>(
            builder: (context, authState) {
              return authState.whenOrNull(
                    authenticated: (session) => GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 4,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.2,
                      children: _buildRoleBasedQuickActions(context, session),
                    ),
                  ) ??
                  const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeContent(BuildContext context) {
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
              'Loading dashboard data...',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorContent(BuildContext context, String message) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(
              'Dashboard Error',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.read<DashboardCubit>().refresh(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
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
                child: Icon(icon, size: 32, color: color),
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
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildRoleBasedQuickActions(
    BuildContext context,
    UserSession session,
  ) {
    List<Widget> actions = [];

    // Actions available for all roles
    actions.add(
      _buildQuickActionCard(
        context,
        icon: Icons.point_of_sale,
        title: context.getString(AppStrings.newSale),
        description: 'Process customer transactions',
        color: Colors.blue,
        onTap: () => _navigateToScreen(context, const PosScreen()),
      ),
    );

    actions.add(
      _buildQuickActionCard(
        context,
        icon: Icons.people,
        title: context.getString(AppStrings.customerManagement),
        description: 'Register new customer',
        color: Colors.teal,
        onTap: () =>
            _navigateToScreen(context, const CustomerManagementScreen()),
      ),
    );

    // Management and Admin actions
    if (session.isManager || session.isAdmin) {
      actions.add(
        _buildQuickActionCard(
          context,
          icon: Icons.inventory,
          title: context.getString(AppStrings.productManagement),
          description: 'Add, edit, and delete products',
          color: Colors.green,
          onTap: () =>
              _navigateToScreen(context, const ProductManagementScreen()),
        ),
      );

      actions.add(
        _buildQuickActionCard(
          context,
          icon: Icons.receipt_long,
          title: context.getString(AppStrings.purchaseManagement),
          description: 'Add new stock purchase',
          color: Colors.orange,
          onTap: () =>
              _navigateToScreen(context, const PurchaseManagementScreen()),
        ),
      );
    } else {
      // Cashier-specific limited actions
      actions.add(
        _buildQuickActionCard(
          context,
          icon: Icons.inventory,
          title: context.getString(AppStrings.currentStock),
          description: 'View current stock levels',
          color: Colors.green,
          onTap: () => _navigateToScreen(context, const InventoryScreen()),
        ),
      );

      actions.add(
        _buildQuickActionCard(
          context,
          icon: Icons.history,
          title: context.getString(AppStrings.recentTransactions),
          description: 'View recent sales history',
          color: Colors.purple,
          onTap: () => _navigateToScreen(context, const SalesHistoryScreen()),
        ),
      );
    }

    // Admin-only actions
    if (session.isAdmin) {
      actions.add(
        _buildQuickActionCard(
          context,
          icon: Icons.admin_panel_settings,
          title: context.getString(AppStrings.userManagement),
          description: 'Manage user accounts and permissions',
          color: Colors.red,
          onTap: () => _navigateToScreen(context, const UserManagementScreen()),
        ),
      );

      actions.add(
        _buildQuickActionCard(
          context,
          icon: Icons.account_balance_wallet,
          title: context.getString(AppStrings.expenseManagement),
          description: 'Track business expenses',
          color: Colors.brown,
          onTap: () =>
              _navigateToScreen(context, const ExpenseManagementScreen()),
        ),
      );
    }

    return actions.take(8).toList(); // Limit to 8 cards for better UI
  }

  void _navigateToScreen(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => screen));
  }
}
