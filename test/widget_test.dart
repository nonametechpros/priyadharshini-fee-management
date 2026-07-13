import 'package:flutter_test/flutter_test.dart';

import 'package:priyadarsini_fee_app/theme/app_theme.dart';

void main() {
  test('AppTheme.light builds a valid ThemeData', () {
    final theme = AppTheme.light;

    expect(theme.colorScheme.primary, AppColors.brandRed);
    expect(theme.useMaterial3, isTrue);
  });
}
