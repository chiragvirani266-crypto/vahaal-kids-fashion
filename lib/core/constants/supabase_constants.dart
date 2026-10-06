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
  static const String tableProfiles = 'profiles';
  static const String tableProducts = 'products';
  static const String tableProductVariants = 'product_variants';
  static const String tableCustomers = 'customers';
  static const String tableBills = 'bills';
  static const String tableBillItems = 'bill_items';
  static const String tableStockTransactions = 'stock_transactions';

  // Storage buckets
  static const String bucketProductImages = 'product-images';
  static const String bucketStoreAssets = 'store-assets';
}
