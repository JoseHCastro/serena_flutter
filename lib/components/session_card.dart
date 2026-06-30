import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/session_model.dart';
import '../theme/app_theme.dart';
import 'status_badge.dart';

class SessionCard extends StatelessWidget {
  final SessionModel session;
  final VoidCallback? onTap;

  const SessionCard({super.key, required this.session, this.onTap});

  @override
  Widget build(BuildContext context) {
    final dateStr = _formatDate(session.scheduledAt);
    final patientName = session.patient?.fullName ?? 'Paciente';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingXs,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        side: const BorderSide(color: AppTheme.borderColor),
      ),
      color: AppTheme.surfaceColor,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withAlpha(15),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: const Icon(
                  Icons.video_camera_front_outlined,
                  color: AppTheme.primaryColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppTheme.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patientName,
                      style: Theme.of(context).textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 12,
                          color: AppTheme.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            dateStr,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  StatusBadge(status: session.status),
                  const SizedBox(height: 6),
                  const Icon(
                    Icons.chevron_right,
                    color: AppTheme.textMuted,
                    size: 18,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return DateFormat('dd MMM yyyy, HH:mm').format(dt);
    } catch (_) {
      return iso;
    }
  }
}
