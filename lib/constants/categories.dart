import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

enum ExpenseCategory {
  food,
  clothing,
  lodging,
  transport,
  education,
  entertainment,
}

extension ExpenseCategoryExtension on ExpenseCategory {
  String get label {
    switch (this) {
      case ExpenseCategory.food:
        return '食';
      case ExpenseCategory.clothing:
        return '衣';
      case ExpenseCategory.lodging:
        return '住';
      case ExpenseCategory.transport:
        return '行';
      case ExpenseCategory.education:
        return '育';
      case ExpenseCategory.entertainment:
        return '樂';
    }
  }

  String get displayName {
    switch (this) {
      case ExpenseCategory.food:
        return '飲食';
      case ExpenseCategory.clothing:
        return '服飾';
      case ExpenseCategory.lodging:
        return '住宿';
      case ExpenseCategory.transport:
        return '交通';
      case ExpenseCategory.education:
        return '教育';
      case ExpenseCategory.entertainment:
        return '娛樂';
    }
  }

  String localizedName(BuildContext context) {
    final l = AppLocalizations.of(context);
    switch (this) {
      case ExpenseCategory.food:
        return l.catFood;
      case ExpenseCategory.clothing:
        return l.catClothing;
      case ExpenseCategory.lodging:
        return l.catLodging;
      case ExpenseCategory.transport:
        return l.catTransport;
      case ExpenseCategory.education:
        return l.catEducation;
      case ExpenseCategory.entertainment:
        return l.catEntertainment;
    }
  }

  IconData get icon {
    switch (this) {
      case ExpenseCategory.food:
        return Icons.restaurant;
      case ExpenseCategory.clothing:
        return Icons.checkroom;
      case ExpenseCategory.lodging:
        return Icons.hotel;
      case ExpenseCategory.transport:
        return Icons.directions_car;
      case ExpenseCategory.education:
        return Icons.school;
      case ExpenseCategory.entertainment:
        return Icons.sports_esports;
    }
  }

  Color get color {
    switch (this) {
      case ExpenseCategory.food:
        return const Color(0xFFE8763A); // orange
      case ExpenseCategory.clothing:
        return const Color(0xFF9B7BAA); // plum
      case ExpenseCategory.lodging:
        return const Color(0xFF4A7B96); // tag blue
      case ExpenseCategory.transport:
        return const Color(0xFF7A9A6D); // moss
      case ExpenseCategory.education:
        return const Color(0xFFCDA64F); // amber
      case ExpenseCategory.entertainment:
        return const Color(0xFFD44B3C); // stamp red
    }
  }
}
