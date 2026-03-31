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
  final VoidCallback? onLeave;

  /// Called when user taps "upload to cloud" on a local trip.
  final VoidCallback? onUploadToCloud;

  const TripCard({
    super.key,
    required this.trip,
    required this.spent,
    required this.onTap,
    this.onDelete,
    this.onLeave,
    this.onUploadToCloud,
  });

  static Widget _buildCoverImage(Trip trip) {
    // Prefer local file
    if (trip.coverImagePath != null &&
        File(trip.coverImagePath!).existsSync()) {
      return Positioned.fill(
        child: Image.file(File(trip.coverImagePath!), fit: BoxFit.cover),
      );
    }
    // Fade-in from cloud URL
    if (trip.coverImageUrl != null) {
      return Positioned.fill(
        child: Image.network(
          trip.coverImageUrl!,
          fit: BoxFit.cover,
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            return AnimatedOpacity(
              opacity: frame == null ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeIn,
              child: child,
            );
          },
          errorBuilder: (context, error, stack) => const SizedBox.shrink(),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final dateFormat = DateFormat('MM/dd');
    final dateRange =
        '${dateFormat.format(trip.startDate)} - ${dateFormat.format(trip.endDate)}';
    final symbol = getCurrencySymbol(trip.baseCurrency);
    final percentage = trip.budget > 0
        ? (spent / trip.budget).clamp(0.0, 1.0)
        : 0.0;
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
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFF2A06A), Color(0xFFE8763A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  // Cover image fades in over gradient
                  _buildCoverImage(trip),
                  // Dark overlay for text readability
                  Positioned.fill(
                    child: DecoratedBox(
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
                            const Icon(
                              Icons.calendar_today,
                              size: 13,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              dateRange,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${trip.baseCurrency} → ${trip.targetCurrency}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Top-left: upload button for local trips only
                  if (trip.uuid == null)
                    Positioned(
                      top: 10,
                      left: 14,
                      child: _UploadButton(l: l, onTap: onUploadToCloud),
                    ),
                  // Top-right: [cloud icon if cloud trip] + [delete or leave]
                  if (trip.uuid != null || onDelete != null || onLeave != null)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (trip.uuid != null) ...[
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.25),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.cloud_done,
                                color: Colors.white70,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          if (onDelete != null)
                            GestureDetector(
                              onTap: onDelete,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.white70,
                                  size: 18,
                                ),
                              ),
                            ),
                          if (onLeave != null)
                            GestureDetector(
                              onTap: onLeave,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.logout,
                                  color: Colors.white70,
                                  size: 18,
                                ),
                              ),
                            ),
                        ],
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
                      const Icon(
                        Icons.access_time,
                        size: 13,
                        color: AppTheme.inkFaint,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${AppLocalizations.of(context).createdAt} ${DateFormat('yyyy/MM/dd HH:mm').format(trip.createdAt)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.inkFaint,
                        ),
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
                            backgroundColor: AppTheme.parchment.withValues(
                              alpha: 0.5,
                            ),
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
                              AppTheme.infinity,
                            ),
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

/// Top-left button for local trips: prompts upload to cloud.
class _UploadButton extends StatelessWidget {
  final AppLocalizations l;
  final VoidCallback? onTap;

  const _UploadButton({required this.l, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_upload_outlined,
              size: 12,
              color: Colors.white70,
            ),
            const SizedBox(width: 4),
            Text(
              l.uploadToCloud,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
