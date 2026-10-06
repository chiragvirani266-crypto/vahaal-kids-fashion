import 'package:flutter_test/flutter_test.dart';
import 'package:vahaal_kids_fashion/core/constants/app_constants.dart';

void main() {
  test('AppConstants smoke test', () {
    expect(AppConstants.appName, 'Vahaal Kids Fashion');
    expect(AppConstants.ageGroups.isNotEmpty, true);
  });
}
