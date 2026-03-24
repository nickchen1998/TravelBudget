import 'package:flutter/material.dart';
import '../constants/app_theme.dart';
import '../constants/currencies.dart';
import '../l10n/app_localizations.dart';

class BudgetProgressBar extends StatelessWidget {
  final double budget;
  final double spent;
  final String currencyCode;

  const BudgetProgressBar({
    super.key,
    required this.budget,
    required this.spent,
    required this.currencyCode,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = budget > 0 ? (spent / budget).clamp(0.0, 1.0) : 0.0;
    final isOverBudget = spent > budget && budget > 0;
    final symbol = getCurrencySymbol(currencyCode);

    Color progressColor;
    if (isOverBudget) {
      progressColor = AppTheme.stampRed;
    } else if (percentage > 0.8) {
      progressColor = AppTheme.amber;
    } else {
      progressColor = AppTheme.moss;
    }

    if (budget <= 0) {
      // No budget: single row, prominent spent amount
      return Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.orangeSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.account_balance_wallet_outlined,
                color: AppTheme.orange, size: 22),
          ),
          const SizedBox(width: 14),
          Text(
            '$symbol${spent.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.parchment.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              AppLocalizations.of(context).noBudget,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.inkFaint,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      );
    }

    // Has budget: single row with progress
    return Column(
      children: [
        Row(
          children: [
            // Spent amount
            Expanded(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isOverBudget
                          ? AppTheme.stampRed.withValues(alpha: 0.1)
                          : AppTheme.orangeSoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.account_balance_wallet_outlined,
                      color: isOverBudget ? AppTheme.stampRed : AppTheme.orange,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$symbol${spent.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: isOverBudget ? AppTheme.stampRed : AppTheme.ink,
                        ),
                      ),
                      Text(
                        isOverBudget
                            ? '${AppLocalizations.of(context).overspent} $symbol${(spent - budget).toStringAsFixed(0)}'
                            : '${AppLocalizations.of(context).remaining} $symbol${(budget - spent).toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isOverBudget
                              ? AppTheme.stampRed
                              : AppTheme.inkFaint,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Budget label
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '/ $symbol${budget.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.inkFaint,
                  ),
                ),
                Text(
                  '${(percentage * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: progressColor,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: percentage,
            minHeight: 8,
            backgroundColor: AppTheme.parchment.withValues(alpha: 0.5),
            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
          ),
        ),
      ],
    );
  }
}
