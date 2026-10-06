import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/customer_model.dart';
import '../../../providers/customer_provider.dart';
import '../../../theme/app_colors.dart';

class CustomerPickerDialog extends StatefulWidget {
  final Customer? currentCustomer;
  final Function(Customer? customer) onSelect;

  const CustomerPickerDialog({
    super.key,
    this.currentCustomer,
    required this.onSelect,
  });

  @override
  State<CustomerPickerDialog> createState() => _CustomerPickerDialogState();
}

class _CustomerPickerDialogState extends State<CustomerPickerDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  // New Customer Form Controllers
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isCreating = false;
  String? _creationError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerProvider>().loadCustomers();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _nameController.dispose();
    _mobileController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _handleCreateCustomer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isCreating = true;
      _creationError = null;
    });

    final newCustomer = Customer(
      name: _nameController.text.trim(),
      mobile: _mobileController.text.trim(),
      address: _addressController.text.trim().isNotEmpty
          ? _addressController.text.trim()
          : null,
      lastDiscount: 0.0,
      totalPurchase: 0.0,
    );

    final customerProvider = context.read<CustomerProvider>();
    final created = await customerProvider.addCustomer(newCustomer);

    if (mounted) {
      setState(() => _isCreating = false);
      if (created != null) {
        widget.onSelect(created);
        Navigator.of(context).pop();
      } else {
        setState(() {
          _creationError = customerProvider.errorMessage ?? 'Failed to register customer.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 540,
        height: 560,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.person_search_rounded, color: AppColors.primary, size: 22),
                    SizedBox(width: 10),
                    Text(
                      'Customer Selection',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Tab Bar
            TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor:
                  isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              indicatorColor: AppColors.primary,
              tabs: const [
                Tab(
                  icon: Icon(Icons.people_alt_rounded, size: 18),
                  text: 'Existing Customer',
                ),
                Tab(
                  icon: Icon(Icons.person_add_rounded, size: 18),
                  text: '+ Register New',
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Existing Customer Search & List
                  Column(
                    children: [
                      // Search Input
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search by mobile number or name...',
                          prefixIcon: const Icon(Icons.search_rounded, size: 20),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    context.read<CustomerProvider>().setSearchQuery('');
                                  },
                                )
                              : null,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                        onChanged: (val) {
                          context.read<CustomerProvider>().setSearchQuery(val);
                        },
                      ),
                      const SizedBox(height: 10),

                      // Walk-in Option
                      ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color: widget.currentCustomer == null
                                ? AppColors.primary
                                : (isDark ? AppColors.borderDark : AppColors.borderLight),
                          ),
                        ),
                        leading: CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.primary.withAlpha(20),
                          child: const Icon(Icons.storefront_rounded,
                              size: 18, color: AppColors.primary),
                        ),
                        title: const Text(
                          'Walk-in Customer (Default)',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        subtitle: const Text(
                          'No customer loyalty tracking for this bill',
                          style: TextStyle(fontSize: 11),
                        ),
                        trailing: widget.currentCustomer == null
                            ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
                            : ElevatedButton(
                                onPressed: () {
                                  widget.onSelect(null);
                                  Navigator.of(context).pop();
                                },
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(70, 32),
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                ),
                                child: const Text('Select'),
                              ),
                        onTap: () {
                          widget.onSelect(null);
                          Navigator.of(context).pop();
                        },
                      ),
                      const Divider(height: 16),

                      // Customer List
                      Expanded(
                        child: Consumer<CustomerProvider>(
                          builder: (context, provider, _) {
                            if (provider.isLoading) {
                              return const Center(child: CircularProgressIndicator());
                            }

                            final customers = provider.customers;
                            if (customers.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.person_off_rounded,
                                        size: 36, color: AppColors.textMutedLight),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'No customers found',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    TextButton.icon(
                                      onPressed: () => _tabController.animateTo(1),
                                      icon: const Icon(Icons.add, size: 16),
                                      label: const Text('Register New Customer'),
                                    ),
                                  ],
                                ),
                              );
                            }

                            return ListView.separated(
                              itemCount: customers.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 6),
                              itemBuilder: (context, index) {
                                final customer = customers[index];
                                final isSelected = widget.currentCustomer?.id == customer.id;

                                return ListTile(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    side: BorderSide(
                                      color: isSelected
                                          ? AppColors.primary
                                          : (isDark ? AppColors.borderDark : AppColors.borderLight),
                                    ),
                                  ),
                                  leading: CircleAvatar(
                                    radius: 18,
                                    backgroundColor: AppColors.secondary.withAlpha(30),
                                    child: Text(
                                      customer.initials,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.secondary,
                                      ),
                                    ),
                                  ),
                                  title: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          customer.name,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (customer.lastDiscount > 0)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.success.withAlpha(25),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            'Last Disc: ₹${customer.lastDiscount.toStringAsFixed(0)}',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.success,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  subtitle: Text(
                                    '📱 ${customer.mobile} • Total spent: ₹${customer.totalPurchase.toStringAsFixed(2)}',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  trailing: isSelected
                                      ? const Icon(Icons.check_circle_rounded,
                                          color: AppColors.primary)
                                      : ElevatedButton(
                                          onPressed: () {
                                            widget.onSelect(customer);
                                            Navigator.of(context).pop();
                                          },
                                          style: ElevatedButton.styleFrom(
                                            minimumSize: const Size(70, 32),
                                            padding: const EdgeInsets.symmetric(horizontal: 12),
                                          ),
                                          child: const Text('Select'),
                                        ),
                                  onTap: () {
                                    widget.onSelect(customer);
                                    Navigator.of(context).pop();
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                  // Tab 2: Register New Customer Form
                  SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_creationError != null)
                            Container(
                              padding: const EdgeInsets.all(10),
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: AppColors.error.withAlpha(25),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.error.withAlpha(50)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline_rounded,
                                      size: 18, color: AppColors.error),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _creationError!,
                                      style: const TextStyle(
                                          fontSize: 12, color: AppColors.error),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const Text(
                            'Customer Name *',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              hintText: 'e.g. Priya Sharma',
                              prefixIcon: Icon(Icons.person_rounded, size: 20),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Please enter customer name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Mobile Number *',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: _mobileController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              hintText: 'e.g. 9876543210',
                              prefixIcon: Icon(Icons.phone_rounded, size: 20),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Please enter mobile number';
                              }
                              if (val.trim().length < 10) {
                                return 'Enter a valid 10-digit mobile number';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Address / City (Optional)',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: _addressController,
                            decoration: const InputDecoration(
                              hintText: 'e.g. MG Road, Surat',
                              prefixIcon: Icon(Icons.location_on_rounded, size: 20),
                            ),
                            maxLines: 2,
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 46,
                            child: ElevatedButton(
                              onPressed: _isCreating ? null : _handleCreateCustomer,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                              ),
                              child: _isCreating
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.person_add_rounded, size: 18),
                                        SizedBox(width: 8),
                                        Text('Save & Select for Current Bill'),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
