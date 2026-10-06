import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/validators.dart';
import '../../models/customer_model.dart';
import '../../providers/customer_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';

class EditCustomerScreen extends StatefulWidget {
  final Customer customer;

  const EditCustomerScreen({super.key, required this.customer});

  @override
  State<EditCustomerScreen> createState() => _EditCustomerScreenState();
}

class _EditCustomerScreenState extends State<EditCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _mobileController;
  late TextEditingController _addressController;
  late TextEditingController _discountController;

  @override
  void initState() {
    super.initState();
    final c = widget.customer;
    _nameController = TextEditingController(text: c.name);
    _mobileController = TextEditingController(text: c.mobile);
    _addressController = TextEditingController(text: c.address ?? '');
    _discountController = TextEditingController(text: c.lastDiscount.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _addressController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdate() async {
    final provider = context.read<CustomerProvider>();
    provider.clearError();

    if (!_formKey.currentState!.validate()) return;

    final cleanMobile = _mobileController.text.trim();
    if (cleanMobile.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 10-digit mobile number.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final discount = double.tryParse(_discountController.text.trim()) ?? 0.0;

    final updated = widget.customer.copyWith(
      name: _nameController.text.trim(),
      mobile: cleanMobile,
      address: _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
      lastDiscount: discount,
    );

    final success = await provider.updateCustomer(updated);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Customer updated successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CustomerProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Edit Customer Profile',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Error Alert
              if (provider.errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.errorBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.error.withAlpha(80)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          provider.errorMessage!,
                          style: const TextStyle(color: AppColors.error, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : AppColors.cardLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Customer Information',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    // Name
                    AppTextField(
                      controller: _nameController,
                      label: 'Full Name *',
                      prefixIcon: Icons.person_outline_rounded,
                      validator: (val) => Validators.validateRequired(val, 'Customer name'),
                    ),
                    const SizedBox(height: 16),

                    // Mobile
                    AppTextField(
                      controller: _mobileController,
                      label: 'Mobile Phone Number *',
                      prefixIcon: Icons.phone_iphone_rounded,
                      keyboardType: TextInputType.phone,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Mobile number is required';
                        }
                        if (val.trim().length < 10) {
                          return 'Mobile number must be at least 10 digits';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Address
                    AppTextField(
                      controller: _addressController,
                      label: 'Address / Location (Optional)',
                      prefixIcon: Icons.location_on_outlined,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),

                    // Last Discount
                    AppTextField(
                      controller: _discountController,
                      label: 'Last Discount Applied (${AppConstants.currencySymbol})',
                      prefixIcon: Icons.discount_outlined,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              AppButton(
                text: 'Save Changes',
                icon: Icons.check_circle_outline_rounded,
                isLoading: provider.isLoading,
                onPressed: _handleUpdate,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
