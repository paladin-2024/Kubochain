import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kubochain/core/constants/app_colors.dart';

void main() {
  group('AppColors', () {
    test('primary color is defined', () {
      expect(AppColors.primary, isA<Color>());
    });

    test('success color is defined', () {
      expect(AppColors.success, isA<Color>());
    });

    test('error color is defined', () {
      expect(AppColors.error, isA<Color>());
    });
  });
}
