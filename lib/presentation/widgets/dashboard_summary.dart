import 'package:flutter/material.dart';
import '../../data/models/dashboard.dart';

class DashboardSummary extends StatelessWidget {
  final DashboardData dashboardData;

  const DashboardSummary({
    Key? key,
    required this.dashboardData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Financial Summary',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 4,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: [
                _buildSummaryCard(
                  'Total Revenue',
                  '\$${dashboardData.totalRevenue.toStringAsFixed(2)}',
                  Icons.trending_up,
                  Colors.green,
                ),
                _buildSummaryCard(
                  'Total Expenses',
                  '\$${dashboardData.totalExpenses.toStringAsFixed(2)}',
                  Icons.trending_down,
                  Colors.red,
                ),
                _buildSummaryCard(
                  'Net Profit',
                  '\$${dashboardData.totalProfit.toStringAsFixed(2)}',
                  dashboardData.totalProfit >= 0 ? Icons.attach_money : Icons.money_off,
                  dashboardData.totalProfit >= 0 ? Colors.blue : Colors.orange,
                ),
                _buildSummaryCard(
                  'Total Sales',
                  dashboardData.totalSales.toString(),
                  Icons.receipt_long,
                  Colors.purple,
                ),
                _buildSummaryCard(
                  'Total Products',
                  dashboardData.totalProducts.toString(),
                  Icons.inventory,
                  Colors.teal,
                ),
                _buildSummaryCard(
                  'Low Stock Items',
                  dashboardData.lowStockProducts.toString(),
                  Icons.warning,
                  dashboardData.lowStockProducts > 0 ? Colors.orange : Colors.grey,
                ),
                _buildSummaryCard(
                  'Cost of Goods',
                  '\$${dashboardData.totalCost.toStringAsFixed(2)}',
                  Icons.account_balance,
                  Colors.indigo,
                ),
                _buildSummaryCard(
                  'Profit Margin',
                  '${_calculateProfitMargin().toStringAsFixed(1)}%',
                  Icons.percent,
                  _getProfitMarginColor(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 20,
              ),
              const Spacer(),
              if (title.contains('Low Stock') && title != 'Low Stock Items')
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: title.contains('0') ? Colors.green : Colors.orange,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  double _calculateProfitMargin() {
    if (dashboardData.totalRevenue == 0) return 0.0;
    return (dashboardData.totalProfit / dashboardData.totalRevenue) * 100;
  }

  Color _getProfitMarginColor() {
    final margin = _calculateProfitMargin();
    if (margin >= 20) return Colors.green;
    if (margin >= 10) return Colors.blue;
    if (margin >= 5) return Colors.orange;
    return Colors.red;
  }
}