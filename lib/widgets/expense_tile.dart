import 'package:flutter/material.dart';
import '../constants/app_theme.dart';
import '../constants/categories.dart';
import '../constants/currencies.dart';
import '../models/expense.dart';

class ExpenseTile extends StatelessWidget {
  final Expense expense;
  final String baseCurrency;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const ExpenseTile({
    super.key,
    required this.expense,
    required this.baseCurrency,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final baseSymbol = getCurrencySymbol(baseCurrency);
    final originalSymbol = getCurrencySymbol(expense.currency);

    return Dismissible(
      key: Key('expense_${expense.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppTheme.stampRed.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => onDelete?.call(),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.warmWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.parchment.withValues(alpha: 0.4)),
        ),
        child: ListTile(
          onTap: onTap,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: expense.category.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(expense.category.icon,
                color: expense.category.color, size: 20),
          ),
          title: Text(
            expense.title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: AppTheme.ink,
            ),
          ),
          subtitle: Text(
            [
              if (expense.note != null && expense.note!.isNotEmpty)
                expense.note!,
              if (expense.currency != baseCurrency &&
                  expense.exchangeRate != null)
                '1 ${expense.currency} = ${expense.exchangeRate!.toStringAsFixed(2)} $baseCurrency',
            ].join('  '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: AppTheme.inkFaint),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$baseSymbol${(expense.convertedAmount ?? 0).toStringAsFixed(0)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: AppTheme.ink,
                ),
              ),
              if (expense.currency != baseCurrency)
                Text(
                  '$originalSymbol${expense.amount.toStringAsFixed(0)}',
                  style:
                      const TextStyle(fontSize: 12, color: AppTheme.inkFaint),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
