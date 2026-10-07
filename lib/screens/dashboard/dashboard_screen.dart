import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routes/app_navigator.dart';
import '../../providers/auth_provider.dart';
import '../../providers/bill_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common/app_badge.dart';
import '../../widgets/common/app_confirm_dialog.dart';
import '../../widgets/common/app_error_state.dart';
import '../../widgets/common/app_loading_state.dart';
import '../analytics/sales_analytics_screen.dart';
import '../analytics/widgets/sales_line_chart_card.dart';
import '../analytics/widgets/top_customers_card.dart';
import '../analytics/widgets/top_selling_products_card.dart';
import '../billing/bill_list_screen.dart';
import '../billing/billing_screen.dart';
import '../customers/customer_list_screen.dart';
import '../inventory/label_print_screen.dart';
import '../inventory/product_list_screen.dart';
import '../settings/settings_screen.dart';
import '../stock/stock_dashboard_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedDesktopIndex = 0;
  int _mobileIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().loadDashboard();
    });
  }

  Future<void> _handleLogout(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    final confirmed = await AppConfirmDialog.show(
      context,
      title: 'Sign Out',
      message: 'Are you sure you want to end your cashier session and sign out from Vahaal Kids?',
      confirmLabel: 'Sign Out',
      isDestructive: true,
      icon: Icons.logout_rounded,
    );

    if (confirmed == true && mounted) {
      await authProvider.logout();
      if (mounted) {
        AppNavigator.toLogin();
      }
    }
  }

  void _onSelectDesktopDestination(int index) {
    setState(() {
      _selectedDesktopIndex = index;
    });
  }

  void _showMobileMoreSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    const Icon(Icons.grid_view_rounded, color: AppColors.primary, size: 22),
                    const SizedBox(width: 10),
                    const Text(
                      'Store Management Modules',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.6,
                  children: [
                    _MoreTile(
                      icon: Icons.warehouse_rounded,
                      title: 'Stock & Inventory',
                      subtitle: 'Transfers & audits',
                      color: AppColors.tertiary,
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        AppNavigator.toStock(context: context);
                      },
                    ),
                    _MoreTile(
                      icon: Icons.people_alt_rounded,
                      title: 'Customers',
                      subtitle: 'Directory & loyalty',
                      color: AppColors.accent,
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        AppNavigator.toCustomers(context: context);
                      },
                    ),
                    _MoreTile(
                      icon: Icons.qr_code_2_rounded,
                      title: 'Barcode Labels',
                      subtitle: 'Thermal tag print',
                      color: const Color(0xFF10B981),
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        AppNavigator.toLabelPrint(context: context);
                      },
                    ),
                    _MoreTile(
                      icon: Icons.insights_rounded,
                      title: 'Reports & Analytics',
                      subtitle: 'Charts & revenue',
                      color: const Color(0xFF8B5CF6),
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        AppNavigator.toReports(context: context);
                      },
                    ),
                    _MoreTile(
                      icon: Icons.settings_rounded,
                      title: 'Settings',
                      subtitle: 'Store & printers',
                      color: const Color(0xFF0EA5E9),
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        AppNavigator.toSettings(context: context);
                      },
                    ),
                    _MoreTile(
                      icon: Icons.warning_amber_rounded,
                      title: 'Low Stock Alerts',
                      subtitle: 'Restock queue',
                      color: AppColors.warning,
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        AppNavigator.toLowStock(context: context);
                      },
                    ),
                    _MoreTile(
                      icon: Icons.logout_rounded,
                      title: 'Sign Out',
                      subtitle: 'End cashier shift',
                      color: AppColors.error,
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        _handleLogout(context);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 960;

    if (isDesktop) {
      return _buildDesktopWorkstation(context, size);
    } else {
      return _buildMobileLayout(context, size);
    }
  }

  // ===========================================================================
  // DESKTOP WORKSTATION LAYOUT (>= 960px)
  // Left Navigation Rail/Sidebar + Main Content Area
  // ===========================================================================
  Widget _buildDesktopWorkstation(BuildContext context, Size size) {
    final authProvider = context.watch<AuthProvider>();
    final dashboardProvider = context.watch<DashboardProvider>();
    final billProvider = context.watch<BillProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = authProvider.userProfile;
    final role = user?.role ?? 'cashier';
    final overview = dashboardProvider.overview;

    final destinationTitles = [
      'Store Workstation Overview',
      'Billing Terminal',
      'Products Catalog & Variants',
      'Inventory & Stock Management',
      'Invoices & Sales History',
      'Customer Loyalty Directory',
      'Barcode Label Generation',
      'Sales & Revenue Analytics',
      'Settings & Hardware Preferences',
    ];

    final destinationSubtitles = [
      'Real-time store metrics, quick modules, and sales trends',
      'Scan barcodes, manage customer discounts, and print bills',
      'Search products, view variants (0-12Y), prices, and stock',
      'Audit stock levels, record stock-in, and monitor alerts',
      'Search customer bills, preview thermal slips, and WhatsApp share',
      'Customer profiles, loyalty spend, and default discount memory',
      'Configure label sizes (50x25, 38x25mm) and print price tags',
      'Daily, monthly, and yearly revenue graphs and performance breakdown',
      'Store details, thermal printer paper size (58mm/80mm), and preferences',
    ];

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC),
      body: Row(
        children: [
          // -------------------------------------------------------------------
          // Left Sidebar (Workstation Navigation Rail)
          // -------------------------------------------------------------------
          Container(
            width: 250,
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              border: Border(
                right: BorderSide(
                  color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                // Store Brand Header
                Container(
                  padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: isDark ? AppColors.borderDark : const Color(0xFFF1F5F9),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, AppColors.primaryDark],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.checkroom_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              AppConstants.appName,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Row(
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: const BoxDecoration(
                                    color: AppColors.success,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'Billing Workstation',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Cashier Profile Pill
                Container(
                  margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                        child: Text(
                          authProvider.userName.isNotEmpty
                              ? authProvider.userName[0].toUpperCase()
                              : 'C',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              authProvider.userName,
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            AppBadge.role(role),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Nav Destinations List
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    children: [
                      _SidebarNavItem(
                        icon: Icons.dashboard_rounded,
                        label: 'Dashboard',
                        isSelected: _selectedDesktopIndex == 0,
                        onTap: () => _onSelectDesktopDestination(0),
                      ),
                      _SidebarNavItem(
                        icon: Icons.point_of_sale_rounded,
                        label: 'Billing',
                        isSelected: _selectedDesktopIndex == 1,
                        badgeCount: billProvider.totalUniqueItems > 0
                            ? billProvider.totalUniqueItems
                            : null,
                        badgeColor: AppColors.primary,
                        onTap: () => _onSelectDesktopDestination(1),
                      ),
                      _SidebarNavItem(
                        icon: Icons.inventory_2_rounded,
                        label: 'Products',
                        isSelected: _selectedDesktopIndex == 2,
                        onTap: () => _onSelectDesktopDestination(2),
                      ),
                      _SidebarNavItem(
                        icon: Icons.warehouse_rounded,
                        label: 'Stock & Inventory',
                        isSelected: _selectedDesktopIndex == 3,
                        badgeCount: overview.lowStockCount > 0
                            ? overview.lowStockCount
                            : null,
                        badgeColor: AppColors.warning,
                        onTap: () => _onSelectDesktopDestination(3),
                      ),
                      _SidebarNavItem(
                        icon: Icons.receipt_long_rounded,
                        label: 'Sales & Bills',
                        isSelected: _selectedDesktopIndex == 4,
                        onTap: () => _onSelectDesktopDestination(4),
                      ),
                      _SidebarNavItem(
                        icon: Icons.people_alt_rounded,
                        label: 'Customers',
                        isSelected: _selectedDesktopIndex == 5,
                        onTap: () => _onSelectDesktopDestination(5),
                      ),
                      _SidebarNavItem(
                        icon: Icons.qr_code_2_rounded,
                        label: 'Barcode Labels',
                        isSelected: _selectedDesktopIndex == 6,
                        onTap: () => _onSelectDesktopDestination(6),
                      ),
                      _SidebarNavItem(
                        icon: Icons.insights_rounded,
                        label: 'Sales Analytics',
                        isSelected: _selectedDesktopIndex == 7,
                        onTap: () => _onSelectDesktopDestination(7),
                      ),
                      _SidebarNavItem(
                        icon: Icons.settings_rounded,
                        label: 'Settings',
                        isSelected: _selectedDesktopIndex == 8,
                        onTap: () => _onSelectDesktopDestination(8),
                      ),
                    ],
                  ),
                ),

                // Bottom Sidebar Actions
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      // Quick Action "+ New Sale"
                      SizedBox(
                        width: double.infinity,
                        height: 42,
                        child: ElevatedButton.icon(
                          onPressed: () => _onSelectDesktopDestination(1),
                          icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
                          label: const Text(
                            'New Sale',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Sign Out Button
                      SizedBox(
                        width: double.infinity,
                        height: 38,
                        child: OutlinedButton.icon(
                          onPressed: () => _handleLogout(context),
                          icon: const Icon(Icons.logout_rounded, size: 16, color: AppColors.error),
                          label: const Text(
                            'Sign Out',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.error,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
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

          // -------------------------------------------------------------------
          // Main Workstation Content Area
          // -------------------------------------------------------------------
          Expanded(
            child: Column(
              children: [
                // Top Workstation Header Bar
                Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : Colors.white,
                    border: Border(
                      bottom: BorderSide(
                        color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Active Tab Title and Subtitle
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              destinationTitles[_selectedDesktopIndex],
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.2,
                              ),
                            ),
                            Text(
                              destinationSubtitles[_selectedDesktopIndex],
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      // Today's Date Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.cardDark : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.calendar_today_rounded,
                              size: 13,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              DateFormat('EEE, d MMM yyyy').format(DateTime.now()),
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Live Cart Shortcut Pill (if items exist in cart)
                      if (billProvider.totalUniqueItems > 0 && _selectedDesktopIndex != 1) ...[
                        InkWell(
                          onTap: () => _onSelectDesktopDestination(1),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.shopping_bag_outlined,
                                  size: 14,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Cart: ${billProvider.totalQuantity} pcs (₹${billProvider.grandTotal.toStringAsFixed(0)})',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],

                      // Refresh Active View Button
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded),
                        tooltip: 'Refresh Store Data',
                        onPressed: () {
                          dashboardProvider.loadDashboard(refresh: true);
                        },
                      ),
                    ],
                  ),
                ),

                // Workstation Screen Content Body
                Expanded(
                  child: IndexedStack(
                    index: _selectedDesktopIndex,
                    children: [
                      // 0: Store Overview & KPIs
                      _buildOverviewContent(context, authProvider, dashboardProvider, true, size),
                      // 1: Billing Terminal
                      const BillingScreen(isEmbedded: true),
                      // 2: Products Catalog & Variants
                      const ProductListScreen(isEmbedded: true),
                      // 3: Inventory & Stock Management
                      const StockDashboardScreen(isEmbedded: true),
                      // 4: Invoices & Sales History
                      const BillListScreen(isEmbedded: true),
                      // 5: Customer Directory & Loyalty
                      const CustomerListScreen(isEmbedded: true),
                      // 6: Barcode Label Generation
                      const LabelPrintScreen(isEmbedded: true),
                      // 7: Sales & Revenue Analytics
                      const SalesAnalyticsScreen(isEmbedded: true),
                      // 8: Settings & Hardware Preferences
                      const SettingsScreen(isEmbedded: true),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // MOBILE LAYOUT (< 960px)
  // Material 3 AppBar + Bottom NavigationBar + Floating Action Button
  // ===========================================================================
  Widget _buildMobileLayout(BuildContext context, Size size) {
    final authProvider = context.watch<AuthProvider>();
    final dashboardProvider = context.watch<DashboardProvider>();
    final billProvider = context.watch<BillProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = authProvider.userProfile;
    final role = user?.role ?? 'cashier';

    final mobileScreens = [
      _buildOverviewContent(context, authProvider, dashboardProvider, false, size),
      const BillingScreen(isEmbedded: true),
      const ProductListScreen(isEmbedded: true),
      const BillListScreen(isEmbedded: true),
    ];

    final mobileTitles = [
      AppConstants.appName,
      'Billing',
      'Product Catalog',
      'Sales Invoices',
    ];

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.checkroom_rounded,
                color: AppColors.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              mobileTitles[_mobileIndex],
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
          ],
        ),
        actions: [
          AppBadge.role(role),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => dashboardProvider.loadDashboard(refresh: true),
          ),
          IconButton(
            tooltip: 'Sign Out',
            icon: const Icon(Icons.logout_rounded, color: AppColors.error),
            onPressed: () => _handleLogout(context),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: IndexedStack(
        index: _mobileIndex,
        children: mobileScreens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _mobileIndex,
        onDestinationSelected: (index) {
          if (index == 4) {
            _showMobileMoreSheet(context);
          } else {
            setState(() {
              _mobileIndex = index;
            });
          }
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Overview',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: billProvider.totalUniqueItems > 0,
              label: Text('${billProvider.totalUniqueItems}'),
              child: const Icon(Icons.point_of_sale_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: billProvider.totalUniqueItems > 0,
              label: Text('${billProvider.totalUniqueItems}'),
              child: const Icon(Icons.point_of_sale_rounded),
            ),
            label: 'New Bill',
          ),
          const NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2_rounded),
            label: 'Products',
          ),
          const NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'Invoices',
          ),
          const NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view_rounded),
            label: 'More',
          ),
        ],
      ),
      floatingActionButton: _mobileIndex == 0
          ? FloatingActionButton.extended(
              heroTag: 'mobile_new_bill_fab',
              onPressed: () {
                setState(() {
                  _mobileIndex = 1;
                });
              },
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.point_of_sale_rounded),
              label: const Text(
                'New Sale',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            )
          : null,
    );
  }

  // ===========================================================================
  // RETAIL DASHBOARD OVERVIEW CONTENT
  // Greeting card, 8 KPI cards, sales line chart, top products/customers, quick modules
  // ===========================================================================
  Widget _buildOverviewContent(
    BuildContext context,
    AuthProvider authProvider,
    DashboardProvider dashboardProvider,
    bool isDesktop,
    Size size,
  ) {
    if (dashboardProvider.isLoading && dashboardProvider.chartPoints.isEmpty) {
      return const AppLoadingState(message: 'Loading store metrics & sales data...');
    }

    if (dashboardProvider.errorMessage != null &&
        dashboardProvider.overview.totalProductsCount == 0) {
      return AppErrorState(
        message: dashboardProvider.errorMessage!,
        onRetry: () => dashboardProvider.loadDashboard(refresh: true),
      );
    }

    final overview = dashboardProvider.overview;
    final user = authProvider.userProfile;
    final role = user?.role ?? 'cashier';

    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Header Card with Store Online Status
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  authProvider.isAdmin ? const Color(0xFF6D28D9) : AppColors.primaryDark,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.28),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome, ${authProvider.userName}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              role.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              user?.email ?? '',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.circle, size: 8, color: AppColors.success),
                      const SizedBox(width: 6),
                      Text(
                        'Store Online',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.95),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section Header: Core KPI Cards
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Sales & Store Overview',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimaryLight,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  if (isDesktop) {
                    _onSelectDesktopDestination(7);
                  } else {
                    AppNavigator.toReports(context: context);
                  }
                },
                icon: const Icon(Icons.analytics_rounded, size: 16),
                label: const Text('Detailed Analytics'),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 8 Core Dashboard KPI Cards Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: isDesktop ? 4 : (size.width > 600 ? 2 : 1),
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: isDesktop ? 2.1 : 2.4,
            children: [
              // 1. Today's Sales
              _KpiCard(
                title: "Today's Sales",
                value: '₹${overview.todaySales.toStringAsFixed(2)}',
                subtitle: '${overview.todayBillsCount} bills generated today',
                icon: Icons.today_rounded,
                color: AppColors.primary,
                onTap: () {
                  if (isDesktop) {
                    _onSelectDesktopDestination(4);
                  } else {
                    setState(() => _mobileIndex = 3);
                  }
                },
              ),

              // 2. Today's Bills
              _KpiCard(
                title: "Today's Bills",
                value: '${overview.todayBillsCount} Bills',
                subtitle: 'Completed transactions',
                icon: Icons.receipt_long_rounded,
                color: const Color(0xFF0EA5E9),
                onTap: () {
                  if (isDesktop) {
                    _onSelectDesktopDestination(4);
                  } else {
                    setState(() => _mobileIndex = 3);
                  }
                },
              ),

              // 3. This Month Sales
              _KpiCard(
                title: 'This Month Sales',
                value: '₹${overview.monthSales.toStringAsFixed(2)}',
                subtitle:
                    '${overview.monthBillsCount} bills in ${DateFormat('MMM yyyy').format(DateTime.now())}',
                icon: Icons.calendar_month_rounded,
                color: AppColors.secondary,
                onTap: () {
                  if (isDesktop) {
                    _onSelectDesktopDestination(7);
                  } else {
                    AppNavigator.toReports(context: context);
                  }
                },
              ),

              // 4. This Year Sales
              _KpiCard(
                title: 'This Year Sales',
                value: '₹${overview.yearSales.toStringAsFixed(2)}',
                subtitle: '${overview.yearBillsCount} bills in ${DateTime.now().year}',
                icon: Icons.auto_graph_rounded,
                color: const Color(0xFF8B5CF6),
                onTap: () {
                  if (isDesktop) {
                    _onSelectDesktopDestination(7);
                  } else {
                    AppNavigator.toReports(context: context);
                  }
                },
              ),

              // 5. Total Sales
              _KpiCard(
                title: 'Total Sales (Lifetime)',
                value: '₹${overview.totalSales.toStringAsFixed(2)}',
                subtitle: '${overview.totalBillsCount} lifetime invoices',
                icon: Icons.account_balance_wallet_rounded,
                color: const Color(0xFF10B981),
                onTap: () {
                  if (isDesktop) {
                    _onSelectDesktopDestination(7);
                  } else {
                    AppNavigator.toReports(context: context);
                  }
                },
              ),

              // 6. Total Customers
              _KpiCard(
                title: 'Total Customers',
                value: '${overview.totalCustomersCount} Members',
                subtitle: 'Registered store members',
                icon: Icons.people_alt_rounded,
                color: AppColors.tertiary,
                onTap: () {
                  if (isDesktop) {
                    _onSelectDesktopDestination(5);
                  } else {
                    AppNavigator.toCustomers(context: context);
                  }
                },
              ),

              // 7. Total Products
              _KpiCard(
                title: 'Total Products',
                value: '${overview.totalProductsCount} Products',
                subtitle: '${overview.totalStockUnits} stock items cataloged',
                icon: Icons.checkroom_rounded,
                color: const Color(0xFF6366F1),
                onTap: () {
                  if (isDesktop) {
                    _onSelectDesktopDestination(2);
                  } else {
                    setState(() => _mobileIndex = 2);
                  }
                },
              ),

              // 8. Low Stock Products
              _KpiCard(
                title: 'Low Stock Products',
                value: '${overview.lowStockCount} Items',
                subtitle: overview.lowStockCount > 0
                    ? 'Requires replenishment'
                    : 'Stock levels healthy',
                icon: Icons.warning_amber_rounded,
                color: AppColors.warning,
                onTap: () {
                  AppNavigator.toLowStock(context: context);
                },
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Embedded Interactive Sales Line Chart (Daily, Monthly, Yearly)
          const SalesLineChartCard(enableDateRangePicker: true),
          const SizedBox(height: 24),

          // Top Products and Top Customers Row
          if (isDesktop)
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: TopSellingProductsCard()),
                SizedBox(width: 16),
                Expanded(child: TopCustomersCard()),
              ],
            )
          else ...[
            const TopSellingProductsCard(),
            const SizedBox(height: 16),
            const TopCustomersCard(),
          ],

          const SizedBox(height: 28),

          // Quick Actions & Modules Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Quick Actions & Modules',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimaryLight,
                ),
              ),
              AppBadge.role(role),
            ],
          ),
          const SizedBox(height: 14),

          // Modules Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: isDesktop ? 4 : (size.width > 600 ? 2 : 1),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.6,
            children: [
              _ModuleCard(
                title: 'Billing & Checkout',
                description: 'Scan barcode, add customer, discounts, & print bills',
                icon: Icons.receipt_long_rounded,
                color: AppColors.primary,
                onTap: () {
                  if (isDesktop) {
                    _onSelectDesktopDestination(1);
                  } else {
                    setState(() => _mobileIndex = 1);
                  }
                },
              ),
              _ModuleCard(
                title: 'Product Catalog & Sizes',
                description: 'Manage 0–12Y sizes, prices, colors & barcodes',
                icon: Icons.inventory_2_rounded,
                color: AppColors.secondary,
                onTap: () {
                  if (isDesktop) {
                    _onSelectDesktopDestination(2);
                  } else {
                    setState(() => _mobileIndex = 2);
                  }
                },
              ),
              _ModuleCard(
                title: 'Stock & Inventory',
                description: 'Stock in, adjustments, audits & movement ledger',
                icon: Icons.warehouse_rounded,
                color: AppColors.tertiary,
                onTap: () {
                  if (isDesktop) {
                    _onSelectDesktopDestination(3);
                  } else {
                    AppNavigator.toStock(context: context);
                  }
                },
              ),
              _ModuleCard(
                title: 'Sales & Bills History',
                description: 'Search invoices, WhatsApp share & reprints',
                icon: Icons.history_rounded,
                color: const Color(0xFF0EA5E9),
                onTap: () {
                  if (isDesktop) {
                    _onSelectDesktopDestination(4);
                  } else {
                    setState(() => _mobileIndex = 3);
                  }
                },
              ),
              _ModuleCard(
                title: 'Customer Directory',
                description: 'Track loyalty, birthdates & purchase records',
                icon: Icons.person_search_rounded,
                color: AppColors.accent,
                onTap: () {
                  if (isDesktop) {
                    _onSelectDesktopDestination(5);
                  } else {
                    AppNavigator.toCustomers(context: context);
                  }
                },
              ),
              _ModuleCard(
                title: 'Sales & Revenue Analytics',
                description: 'Daily, monthly & yearly interactive charts',
                icon: Icons.bar_chart_rounded,
                color: const Color(0xFF8B5CF6),
                onTap: () {
                  if (isDesktop) {
                    _onSelectDesktopDestination(7);
                  } else {
                    AppNavigator.toReports(context: context);
                  }
                },
              ),
              _ModuleCard(
                title: 'Low Stock Replenishment',
                description: 'Fast stock in for products below threshold',
                icon: Icons.warning_amber_rounded,
                color: AppColors.warning,
                onTap: () {
                  AppNavigator.toLowStock(context: context);
                },
              ),
              _ModuleCard(
                title: 'Barcode Label Printing',
                description: 'Generate price tags for new arrivals',
                icon: Icons.qr_code_2_rounded,
                color: const Color(0xFF10B981),
                onTap: () {
                  if (isDesktop) {
                    _onSelectDesktopDestination(6);
                  } else {
                    AppNavigator.toLabelPrint(context: context);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// DESKTOP SIDEBAR NAV ITEM
// =============================================================================
class _SidebarNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final int? badgeCount;
  final Color badgeColor;

  const _SidebarNavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.badgeCount,
    this.badgeColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? (isDark
                      ? AppColors.primary.withValues(alpha: 0.2)
                      : AppColors.primary.withValues(alpha: 0.1))
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: isSelected
                  ? Border.all(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      width: 1,
                    )
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected
                      ? AppColors.primary
                      : (isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? AppColors.primary
                          : (isDark ? AppColors.textPrimaryDark : const Color(0xFF334155)),
                    ),
                  ),
                ),
                if (badgeCount != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$badgeCount',
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// KPI CARD WIDGET
// =============================================================================
class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimaryLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.textMutedLight),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// MODULE CARD WIDGET
// =============================================================================
class _ModuleCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ModuleCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// MORE BOTTOM SHEET TILE (FOR MOBILE)
// =============================================================================
class _MoreTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _MoreTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10.5,
                color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
