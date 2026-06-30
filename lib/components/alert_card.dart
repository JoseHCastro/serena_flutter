import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/alert_model.dart';
import '../theme/app_theme.dart';
import 'status_badge.dart';

class AlertCard extends StatelessWidget {
  final AlertModel alert;
  final VoidCallback? onAcknowledge;

  const AlertCard({super.key, required this.alert, this.onAcknowledge});

  @override
  Widget build(BuildContext context) {
    final dateStr = _formatDate(alert.createdAt);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingXs,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        side: BorderSide(
          color: alert.isAcknowledged
              ? AppTheme.borderColor
              : _severityColor().withAlpha(100),
          width: alert.isAcknowledged ? 1 : 1.5,
        ),
      ),
      color: AppTheme.surfaceColor,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: _severityColor(),
                  size: 18,
                ),
                const SizedBox(width: AppTheme.spacingSm),
                SeverityBadge(severity: alert.severity.name),
                const Spacer(),
                Text(
                  dateStr,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingSm),
            if (alert.patientName != null)
              Text(
                alert.patientName!,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            const SizedBox(height: 4),
            Text(
              _translateMessage(alert.message),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (!alert.isAcknowledged && onAcknowledge != null) ...[
              const SizedBox(height: AppTheme.spacingMd),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: onAcknowledge,
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Reconocer'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    side: const BorderSide(color: AppTheme.primaryColor),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingMd,
                      vertical: AppTheme.spacingXs,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
            ],
            if (alert.isAcknowledged)
              Padding(
                padding: const EdgeInsets.only(top: AppTheme.spacingSm),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle,
                        size: 14, color: AppTheme.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      'Reconocida',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _severityColor() {
    switch (alert.severity) {
      case AlertSeverity.critical:
        return AppTheme.errorColor;
      case AlertSeverity.high:
        return Colors.orange.shade700;
      case AlertSeverity.medium:
        return Colors.amber.shade700;
      case AlertSeverity.low:
        return Colors.brown.shade400;
    }
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return DateFormat('dd/MM HH:mm').format(dt);
    } catch (_) {
      return iso;
    }
  }

  String _translateMessage(String message) {
    return message
        .replaceAll('ANXIETY', 'ANSIEDAD')
        .replaceAll('STRESS', 'ESTRÉS')
        .replaceAll('High anxiety detected', 'Alta ansiedad detectada')
        .replaceAll('High stress detected', 'Alto estrés detectado')
        .replaceAll('Critical emotion', 'Emoción crítica')
        .replaceAll('detected at confidence', 'detectada con confianza')
        .replaceAll('Fear', 'Miedo')
        .replaceAll('Sadness', 'Tristeza')
        .replaceAll('Anger', 'Ira')
        .replaceAll('Happiness', 'Felicidad')
        .replaceAll('Disgust', 'Asco')
        .replaceAll('Surprise', 'Sorpresa')
        .replaceAll('Neutral', 'Neutral')
        .replaceAll('SADNESS', 'TRISTEZA')
        .replaceAll('NEUTRAL', 'NEUTRAL')
        .replaceAll('ANGER', 'IRA')
        .replaceAll('FEAR', 'MIEDO')
        .replaceAll('DISGUST', 'ASCO')
        .replaceAll('HAPPINESS', 'FELICIDAD')
        .replaceAll('SURPRISE', 'SORPRESA')
        .replaceAll('anger', 'ira')
        .replaceAll('disgust', 'asco')
        .replaceAll('fear', 'miedo')
        .replaceAll('happiness', 'felicidad')
        .replaceAll('neutral', 'neutral')
        .replaceAll('sadness', 'tristeza')
        .replaceAll('surprise', 'sorpresa')
        .replaceAll('at t=', 'a los ')
        .replaceAll('Cambio emocional abrupto de', 'Cambio emocional abrupto de')
        .replaceAll('detectada con confianza', 'detectada con confianza');
  }
}
