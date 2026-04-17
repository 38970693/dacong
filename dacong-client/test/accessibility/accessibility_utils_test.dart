import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dacong_client/core/accessibility/accessibility_utils.dart';

void main() {
  group('AccessibilityUtils', () {
    group('calculateContrastRatio', () {
      test('should calculate correct contrast ratio for black and white', () {
        final ratio = AccessibilityUtils.calculateContrastRatio(
          Colors.black,
          Colors.white,
        );
        expect(ratio, closeTo(21.0, 0.1));
      });

      test('should calculate correct contrast ratio for same colors', () {
        final ratio = AccessibilityUtils.calculateContrastRatio(
          Colors.blue,
          Colors.blue,
        );
        expect(ratio, closeTo(1.0, 0.1));
      });

      test('should be symmetric', () {
        final ratio1 = AccessibilityUtils.calculateContrastRatio(
          Colors.black,
          Colors.white,
        );
        final ratio2 = AccessibilityUtils.calculateContrastRatio(
          Colors.white,
          Colors.black,
        );
        expect(ratio1, equals(ratio2));
      });
    });

    group('meetsContrastRequirement', () {
      test('should pass for black text on white background', () {
        final meets = AccessibilityUtils.meetsContrastRequirement(
          Colors.black,
          Colors.white,
        );
        expect(meets, isTrue);
      });

      test('should fail for light gray text on white background', () {
        final meets = AccessibilityUtils.meetsContrastRequirement(
          Colors.grey[300]!,
          Colors.white,
        );
        expect(meets, isFalse);
      });

      test('should have lower requirement for large text', () {
        final color1 = Colors.grey[600]!;
        final color2 = Colors.white;

        final meetsLarge = AccessibilityUtils.meetsContrastRequirement(
          color1,
          color2,
          isLargeText: true,
        );

        // 大文本应该通过
        expect(meetsLarge, isTrue);
      });
    });

    group('ensureMinTouchTargetSize', () {
      test('should not change size if already meets minimum', () {
        final size = const Size(50, 50);
        final result = AccessibilityUtils.ensureMinTouchTargetSize(size);
        expect(result, equals(size));
      });

      test('should increase width if below minimum', () {
        final size = const Size(30, 50);
        final result = AccessibilityUtils.ensureMinTouchTargetSize(size);
        expect(result.width, equals(44.0));
        expect(result.height, equals(50.0));
      });

      test('should increase height if below minimum', () {
        final size = const Size(50, 30);
        final result = AccessibilityUtils.ensureMinTouchTargetSize(size);
        expect(result.width, equals(50.0));
        expect(result.height, equals(44.0));
      });

      test('should increase both dimensions if both below minimum', () {
        final size = const Size(20, 30);
        final result = AccessibilityUtils.ensureMinTouchTargetSize(size);
        expect(result.width, equals(44.0));
        expect(result.height, equals(44.0));
      });
    });

    group('generateSemanticLabel', () {
      test('should generate label with only required field', () {
        final label = AccessibilityUtils.generateSemanticLabel(
          label: 'Button',
        );
        expect(label, equals('Button'));
      });

      test('should include value when provided', () {
        final label = AccessibilityUtils.generateSemanticLabel(
          label: 'Button',
          value: 'Submit',
        );
        expect(label, equals('Button, Submit'));
      });

      test('should include hint when provided', () {
        final label = AccessibilityUtils.generateSemanticLabel(
          label: 'Button',
          hint: 'Double tap to activate',
        );
        expect(label, equals('Button, Double tap to activate'));
      });

      test('should include all fields when provided', () {
        final label = AccessibilityUtils.generateSemanticLabel(
          label: 'Button',
          value: 'Submit',
          hint: 'Double tap to activate',
        );
        expect(label, equals('Button, Submit, Double tap to activate'));
      });

      test('should skip empty value', () {
        final label = AccessibilityUtils.generateSemanticLabel(
          label: 'Button',
          value: '',
          hint: 'Hint',
        );
        expect(label, equals('Button, Hint'));
      });
    });
  });
}
