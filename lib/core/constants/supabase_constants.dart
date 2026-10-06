class SupabaseConstants {
  // Replace these with your Supabase project credentials
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://qumaeuukiqthnyzzrrbi.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_Ve_aw9Np1rFsBDi0Vlqw3w_AOD8a3uR',
  );

  // Table names
  static const String tableStoreProfiles = 'store_profiles';
  static const String tableUserProfiles = 'user_profiles';
  static const String tableCategories = 'categories';
  static const String tableProducts = 'products';
  static const String tableProductVariants = 'product_variants';
  static const String tableCustomers = 'customers';
  static const String tableSales = 'sales';
  static const String tableSaleItems = 'sale_items';
  static const String tablePayments = 'payments';
  static const String tableInventoryTransactions = 'inventory_transactions';
  static const String tableDiscounts = 'discounts';

  // Storage buckets
  static const String bucketProductImages = 'product-images';
  static const String bucketStoreAssets = 'store-assets';
}
