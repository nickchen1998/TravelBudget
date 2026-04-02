import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

enum PaymentMethod {
  cash,
  creditCard,
  debitCard,
  mobilePay,
  transitCard,
}

extension PaymentMethodExtension on PaymentMethod {
  String localizedName(BuildContext context) {
    final l = AppLocalizations.of(context);
    switch (this) {
      case PaymentMethod.cash:
        return l.payCash;
      case PaymentMethod.creditCard:
        return l.payCreditCard;
      case PaymentMethod.debitCard:
        return l.payDebitCard;
      case PaymentMethod.mobilePay:
        return l.payMobile;
      case PaymentMethod.transitCard:
        return l.payTransit;
    }
  }

  IconData get icon {
    switch (this) {
      case PaymentMethod.cash:
        return Icons.payments_outlined;
      case PaymentMethod.creditCard:
        return Icons.credit_card;
      case PaymentMethod.debitCard:
        return Icons.credit_card_outlined;
      case PaymentMethod.mobilePay:
        return Icons.phone_iphone;
      case PaymentMethod.transitCard:
        return Icons.directions_transit;
    }
  }

  Color get color {
    switch (this) {
      case PaymentMethod.cash:
        return const Color(0xFF7A9A6D); // moss
      case PaymentMethod.creditCard:
        return const Color(0xFFE8763A); // orange
      case PaymentMethod.debitCard:
        return const Color(0xFF4A7B96); // tag blue
      case PaymentMethod.mobilePay:
        return const Color(0xFF9B7BAA); // plum
      case PaymentMethod.transitCard:
        return const Color(0xFFCDA64F); // amber
    }
  }
}
