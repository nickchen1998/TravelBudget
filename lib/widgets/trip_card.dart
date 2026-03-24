import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_theme.dart';
import '../constants/currencies.dart';
import '../l10n/app_localizations.dart';
import '../models/trip.dart';

class TripCard extends StatelessWidget {
  final Trip trip;
  final double spent;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const TripCard({
    super.key,
    required this.trip,
    required this.spent,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MM/dd');
    final dateRange =
        '${dateFormat.format(trip.startDate)} - ${dateFormat.format(trip.endDate)}';
    final symbol = getCurrencySymbol(trip.baseCurrency);
    final percentage =
        trip.budget > 0 ? (spent / trip.budget).clamp(0.0, 1.0) : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.warmWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.parchment.withValues(alpha: 0.6)),
        boxShadow: AppTheme.cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover image or warm gradient
            Container(
              height: 130,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: trip.coverImagePath == null
                    ? const LinearGradient(
                        colors: [Color(0xFFF2A06A), Color(0xFFE8763A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                image: trip.coverImagePath != null
                    ? DecorationImage(
                        image: FileImage(File(trip.coverImagePath!)),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withValues(alpha: 0.35),
                          Colors.transparent,
                        ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.center,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 14,
                    left: 18,
                    right: 18,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trip.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today,
                                size: 13, color: Colors.white70),
                            const SizedBox(width: 4),
                            Text(dateRange,
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 13)),
                            const SizedBox(width: 14),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${trip.baseCurrency} → ${trip.targetCurrency}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (onDelete != null)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: onDelete,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.25),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.delete_outline,
                              color: Colors.white70, size: 18),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Budget info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${AppLocalizations.of(context).spent} $symbol${spent.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: AppTheme.ink,
                        ),
                      ),
                      trip.budget > 0
                          ? Text(
                              '/ $symbol${trip.budget.toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: AppTheme.inkFaint,
                                fontSize: 14,
                              ),
                            )
                          : const Text(
                              '/ ∞',
                              style: TextStyle(
                                color: AppTheme.infinity,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.access_time,
                          size: 13, color: AppTheme.inkFaint),
                      const SizedBox(width: 4),
                      Text(
                        '${AppLocalizations.of(context).createdAt} ${DateFormat('yyyy/MM/dd HH:mm').format(trip.createdAt)}',
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.inkFaint),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: trip.budget > 0
                        ? LinearProgressIndicator(
                            value: percentage,
                            minHeight: 7,
                            backgroundColor:
                                AppTheme.parchment.withValues(alpha: 0.5),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              spent > trip.budget
                                  ? AppTheme.stampRed
                                  : percentage > 0.8
                                      ? AppTheme.amber
                                      : AppTheme.moss,
                            ),
                          )
                        : const LinearProgressIndicator(
                            value: 1.0,
                            minHeight: 7,
                            backgroundColor: AppTheme.infinitySoft,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                AppTheme.infinity),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
