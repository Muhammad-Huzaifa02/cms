import 'package:flutter/services.dart';

enum NotificationChannel { sms, whatsApp }

/// Customer Notification Service for automated SMS & WhatsApp receipts and alerts.
class CustomerNotificationService {
  /// Generates a standardized, professional customer onboarding receipt.
  static String buildWelcomeMessage({
    required String accountTitle,
    required String accountNumber,
    required String accountType,
    required String ibnNo,
  }) {
    return 'Dear $accountTitle, your customer record has been registered successfully in CMS. '
        'Account Number: $accountNumber ($accountType), IBAN: $ibnNo. '
        'Thank you for banking with us.';
  }

  /// Generates a profile update alert notification.
  static String buildUpdateMessage({
    required String accountTitle,
    required String accountNumber,
  }) {
    return 'Dear $accountTitle, your customer record for Account $accountNumber has been updated in CMS. '
        'If you did not request this update, please contact the branch.';
  }

  /// Formats a phone number for international WhatsApp link (e.g. 923001234567).
  static String normalizeWhatsAppPhone(String phone) {
    var raw = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (raw.startsWith('0')) {
      raw = '92${raw.substring(1)}';
    } else if (!raw.startsWith('92')) {
      raw = '92$raw';
    }
    return raw;
  }
}
