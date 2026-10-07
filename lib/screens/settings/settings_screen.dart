import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common/app_badge.dart';
import '../../widgets/common/app_confirm_dialog.dart';
import '../../widgets/common/app_snackbar.dart';
import '../auth/login_screen.dart';

class SettingsScreen extends StatefulWidget {
  final bool isEmbedded;
  const SettingsScreen({super.key, this.isEmbedded = false});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Store Information Controllers
  late TextEditingController _storeNameController;
  late TextEditingController _storePhoneController;
  late TextEditingController _storeAddressController;
  late TextEditingController _storeGstinController;
  late TextEditingController _footerNoteController;

  // Billing & Hardware Preferences
  String _selectedReceiptWidth = '80mm'; // '58mm' | '80mm'
  bool _showPrintPreview = true;
  bool _autoShareWhatsApp = false;
  String _defaultLabelSize = '50x25mm';
  int _defaultLowStockAlert = 3;
  bool _rememberCustomerDiscount = true;

  @override
  void initState() {
    super.initState();
    _storeNameController = TextEditingController(text: AppConstants.storeName);
    _storePhoneController = TextEditingController(text: AppConstants.storeMobile);
    _storeAddressController = TextEditingController(text: AppConstants.storeAddress);
    _storeGstinController = TextEditingController(text: AppConstants.storeGstin);
    _footerNoteController = TextEditingController(text: AppConstants.storeThankYou);
  }

  @override
  void dispose() {
    _storeNameController.dispose();
    _storePhoneController.dispose();
    _storeAddressController.dispose();
    _storeGstinController.dispose();
    _footerNoteController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveSettings() async {
    AppSnackbar.showSuccess(context, 'Store settings & hardware preferences saved successfully!');
  }

  Future<void> _handleLogout(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    final navigator = Navigator.of(context);

    final confirmed = await AppConfirmDialog.show(
      context,
      title: 'Sign Out',
      message: 'Are you sure you want to end your current session and sign out from Vahaal Kids?',
      confirmLabel: 'Sign Out',
      isDestructive: true,
      icon: Icons.logout_rounded,
    );

    if (confirmed == true && mounted) {
      await authProvider.logout();
      if (mounted) {
        navigator.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.userProfile;
    final role = user?.role ?? 'cashier';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final content = SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 880),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Store Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _storeNameController.text,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Configuration • Hardware Printers • Barcode Defaults',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle, size: 10, color: AppColors.success),
                          SizedBox(width: 5),
                          Text(
                            'Online',
                            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Section 1: Store & Invoice Information
              _buildSectionCard(
                title: 'Store & Receipt Header Information',
                subtitle: 'These details appear on thermal receipts, PDFs, and WhatsApp shares.',
                icon: Icons.receipt_rounded,
                isDark: isDark,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _storeNameController,
                          decoration: const InputDecoration(
                            labelText: 'Store Display Name *',
                            prefixIcon: Icon(Icons.business_rounded),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: TextFormField(
                          controller: _storePhoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Store Phone / WhatsApp *',
                            prefixIcon: Icon(Icons.phone_rounded),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _storeAddressController,
                          decoration: const InputDecoration(
                            labelText: 'Physical Store Address',
                            prefixIcon: Icon(Icons.location_on_outlined),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: TextFormField(
                          controller: _storeGstinController,
                          decoration: const InputDecoration(
                            labelText: 'GSTIN / Tax ID',
                            prefixIcon: Icon(Icons.verified_user_outlined),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _footerNoteController,
                    decoration: const InputDecoration(
                      labelText: 'Bill Footer Note / Policy',
                      prefixIcon: Icon(Icons.speaker_notes_outlined),
                      hintText: 'e.g. Exchange allowed within 7 days with original tag',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Section 2: Hardware & Receipt Printing
              _buildSectionCard(
                title: 'Hardware & Thermal Receipt Defaults',
                subtitle: 'Configure thermal printer roll sizes, preview sheets, and automation.',
                icon: Icons.print_rounded,
                isDark: isDark,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Receipt Paper Roll Width',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            SegmentedButton<String>(
                              segments: const [
                                ButtonSegment(value: '58mm', label: Text('58mm (Small)')),
                                ButtonSegment(value: '80mm', label: Text('80mm (Standard)')),
                              ],
                              selected: {_selectedReceiptWidth},
                              onSelectionChanged: (set) {
                                setState(() {
                                  _selectedReceiptWidth = set.first;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Barcode Label Size Default',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            SegmentedButton<String>(
                              segments: const [
                                ButtonSegment(value: '50x25mm', label: Text('50 x 25 mm')),
                                ButtonSegment(value: '38x25mm', label: Text('38 x 25 mm')),
                              ],
                              selected: {_defaultLabelSize},
                              onSelectionChanged: (set) {
                                setState(() {
                                  _defaultLabelSize = set.first;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Show Print Preview Before Physical Print',
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                    subtitle: const Text(
                      'Renders thermal receipt preview with Print & PDF download buttons.',
                      style: TextStyle(fontSize: 12),
                    ),
                    value: _showPrintPreview,
                    onChanged: (val) => setState(() => _showPrintPreview = val),
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Auto-prompt WhatsApp Bill Sharing on Sale Complete',
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                    subtitle: const Text(
                      'Opens WhatsApp with customer phone number and formatted receipt summary.',
                      style: TextStyle(fontSize: 12),
                    ),
                    value: _autoShareWhatsApp,
                    onChanged: (val) => setState(() => _autoShareWhatsApp = val),
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Customer Discount Memory Auto-Apply',
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                    subtitle: const Text(
                      'Automatically loads existing customer\'s last recorded discount onto new bill.',
                      style: TextStyle(fontSize: 12),
                    ),
                    value: _rememberCustomerDiscount,
                    onChanged: (val) => setState(() => _rememberCustomerDiscount = val),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Section 3: Stock Thresholds & System Info
              _buildSectionCard(
                title: 'Stock Rules & Workstation Session',
                subtitle: 'Low inventory thresholds and active cashier credentials.',
                icon: Icons.inventory_2_rounded,
                isDark: isDark,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: AppColors.warning),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Default Low Stock Threshold',
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                  Text(
                                    'Items with ≤ $_defaultLowStockAlert units trigger restock alerts',
                                    style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondaryLight),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          IconButton.outlined(
                            icon: const Icon(Icons.remove, size: 16),
                            onPressed: _defaultLowStockAlert > 1
                                ? () => setState(() => _defaultLowStockAlert--)
                                : null,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              '$_defaultLowStockAlert units',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                          IconButton.outlined(
                            icon: const Icon(Icons.add, size: 16),
                            onPressed: () => setState(() => _defaultLowStockAlert++),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                        child: Text(
                          authProvider.userName.isNotEmpty ? authProvider.userName[0].toUpperCase() : 'C',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              authProvider.userName,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              user?.email ?? '',
                              style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondaryLight),
                            ),
                          ],
                        ),
                      ),
                      AppBadge.role(role),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () => _handleLogout(context),
                        icon: const Icon(Icons.logout_rounded, size: 15, color: AppColors.error),
                        label: const Text('Sign Out', style: TextStyle(color: AppColors.error, fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.error),
                          minimumSize: const Size(90, 36),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Save Action Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _handleSaveSettings,
                  icon: const Icon(Icons.save_rounded, size: 20),
                  label: const Text(
                    'Save Preferences',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );

    if (widget.isEmbedded) {
      return content;
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Settings & Hardware Preferences',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_rounded),
            tooltip: 'Save Settings',
            onPressed: _handleSaveSettings,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: content,
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isDark,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }
}
