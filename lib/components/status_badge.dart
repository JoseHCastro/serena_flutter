import 'package:flutter/material.dart';
import '../models/session_model.dart';
import '../theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  final SessionStatus status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _colors();
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingSm,
        vertical: AppTheme.spacingXs,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  (Color, Color) _colors() {
    switch (status) {
      case SessionStatus.scheduled:
        return (AppTheme.secondaryLight, AppTheme.secondaryColor);
      case SessionStatus.active:
        return (Colors.green.shade100, Colors.green.shade800);
      case SessionStatus.completed:
        return (
          AppTheme.primaryColor.withAlpha(25),
          AppTheme.primaryColor,
        );
      case SessionStatus.cancelled:
        return (AppTheme.borderColor, AppTheme.textMuted);
    }
  }
}

class SeverityBadge extends StatelessWidget {
  final String severity;

  const SeverityBadge({super.key, required this.severity});

  @override
  Widget build(BuildContext context) {
    final (bg, fg, label) = _colors();
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingSm,
        vertical: AppTheme.spacingXs,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  (Color, Color, String) _colors() {
    switch (severity) {
      case 'critical':
        return (AppTheme.errorColor.withAlpha(25), AppTheme.errorColor, 'Crítica');
      case 'high':
        return (Colors.orange.shade100, Colors.orange.shade800, 'Alta');
      case 'medium':
        return (Colors.amber.shade100, Colors.amber.shade800, 'Media');
      default:
        return (AppTheme.accentColor.withAlpha(128), Colors.brown.shade700, 'Baja');
    }
  }
}

class AnalysisStatusBadge extends StatelessWidget {
  final String status;

  const AnalysisStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (bg, fg, label, icon) = _config();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: fg),
        const SizedBox(width: 4),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingSm,
            vertical: AppTheme.spacingXs,
          ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  (Color, Color, String, IconData) _config() {
    switch (status) {
      case 'completed':
        return (
          Colors.green.shade100,
          Colors.green.shade800,
          'Análisis listo',
          Icons.check_circle_outline,
        );
      case 'processing':
        return (
          AppTheme.secondaryLight,
          AppTheme.secondaryColor,
          'Procesando...',
          Icons.hourglass_top,
        );
      case 'failed':
        return (
          AppTheme.errorColor.withAlpha(25),
          AppTheme.errorColor,
          'Error en análisis',
          Icons.error_outline,
        );
      default:
        return (
          AppTheme.borderColor,
          AppTheme.textMuted,
          'Sin analizar',
          Icons.pending_outlined,
        );
    }
  }
}
