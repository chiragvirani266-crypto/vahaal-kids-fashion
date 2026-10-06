import 'package:flutter/material.dart';
import 'bill_list_screen.dart';

/// Backward-compatible alias for BillListScreen
class BillHistoryScreen extends StatelessWidget {
  const BillHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const BillListScreen();
  }
}
