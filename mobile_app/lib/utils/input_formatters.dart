import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Formats numeric input with proper thousand separators and decimal handling
class NumberInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat.decimalPattern();
  final int? maxDecimalPlaces;
  final bool allowDecimals;

  NumberInputFormatter({
    this.maxDecimalPlaces = 2,
    this.allowDecimals = true,
  });

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // If user clears the field
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Remove all non-digit and non-decimal characters
    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9.]'), '');

    // Handle decimal places
    if (allowDecimals && digitsOnly.contains('.')) {
      final parts = digitsOnly.split('.');
      if (parts.length > 2) {
        // Remove extra decimal points
        digitsOnly = '${parts[0]}.${parts.sublist(1).join('')}';
      }
      
      // Limit decimal places
      if (maxDecimalPlaces != null && parts.length == 2 && parts[1].length > maxDecimalPlaces!) {
        digitsOnly = '${parts[0]}.${parts[1].substring(0, maxDecimalPlaces!)}';
      }
    } else if (!allowDecimals) {
      // Remove decimal point if not allowed
      digitsOnly = digitsOnly.replaceAll('.', '');
    }

    // If empty after cleaning, return empty
    if (digitsOnly.isEmpty) {
      return newValue.copyWith(text: '');
    }

    try {
      String formatted;
      if (allowDecimals && digitsOnly.contains('.')) {
        final parts = digitsOnly.split('.');
        final integerPart = int.parse(parts[0]);
        final decimalPart = parts[1];
        formatted = '${_formatter.format(integerPart)}.${decimalPart}';
      } else {
        final number = int.parse(digitsOnly);
        formatted = _formatter.format(number);
      }

      // Calculate cursor position
      final cursorPosition = formatted.length;
      
      return TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: cursorPosition),
      );
    } catch (e) {
      // If parsing fails, return the old value
      return oldValue;
    }
  }
}

/// Formats card number input with proper spacing (1234 5678 9012 3456)
class CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Remove all non-digit characters
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    
    // Limit to 16 digits
    final limitedDigits = digitsOnly.length > 16 
        ? digitsOnly.substring(0, 16) 
        : digitsOnly;
    
    // Add spaces every 4 digits
    final formatted = StringBuffer();
    for (int i = 0; i < limitedDigits.length; i++) {
      if (i > 0 && i % 4 == 0) {
        formatted.write(' ');
      }
      formatted.write(limitedDigits[i]);
    }
    
    final formattedText = formatted.toString();
    
    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}

/// Formats expiry date input (MM/YY)
class ExpiryDateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Remove all non-digit characters
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    
    // Limit to 4 digits
    final limitedDigits = digitsOnly.length > 4 
        ? digitsOnly.substring(0, 4) 
        : digitsOnly;
    
    String formatted = limitedDigits;
    
    // Add slash after MM
    if (limitedDigits.length >= 2) {
      formatted = '${limitedDigits.substring(0, 2)}/${limitedDigits.substring(2)}';
    }
    
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Formats phone number input
class PhoneNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Remove all non-digit characters
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    
    // Limit to 11 digits for Nigerian numbers
    final limitedDigits = digitsOnly.length > 11 
        ? digitsOnly.substring(0, 11) 
        : digitsOnly;
    
    String formatted = limitedDigits;
    
    // Format as +234 XXX XXX XXXX
    if (limitedDigits.length >= 4) {
      if (limitedDigits.startsWith('0')) {
        // Convert 0XXXXXXXXXX to +234XXXXXXXXX
        final withoutLeadingZero = limitedDigits.substring(1);
        if (withoutLeadingZero.length >= 3) {
          formatted = '+234 ${withoutLeadingZero.substring(0, 3)}';
          if (withoutLeadingZero.length > 3) {
            formatted += ' ${withoutLeadingZero.substring(3, withoutLeadingZero.length > 6 ? 6 : withoutLeadingZero.length)}';
          }
          if (withoutLeadingZero.length > 6) {
            formatted += ' ${withoutLeadingZero.substring(6)}';
          }
        }
      } else {
        // Format as is with spaces
        formatted = limitedDigits.substring(0, 3);
        if (limitedDigits.length > 3) {
          formatted += ' ${limitedDigits.substring(3, limitedDigits.length > 6 ? 6 : limitedDigits.length)}';
        }
        if (limitedDigits.length > 6) {
          formatted += ' ${limitedDigits.substring(6)}';
        }
      }
    }
    
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
