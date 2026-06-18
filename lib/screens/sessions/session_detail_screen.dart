import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../components/app_top_bar.dart';
import '../../components/status_badge.dart';
import '../../models/session_model.dart';
import '../../models/analysis_model.dart';
import '../../providers/sessions_provider.dart';
import '../../providers/biometric_provider.dart';
import '../../theme/app_theme.dart';

class SessionDetailScreen extends ConsumerStatefulWidget {
  final String sessionId;

  const SessionDetailScreen({super.key, required this.sessionId});

  @override
  ConsumerState<SessionDetailScreen> createState() =>
      _SessionDetailScreenState();
}

class _SessionDetailScreenState extends ConsumerState<SessionDetailScreen> {
  bool _uploading = false;
  double _uploadProgress = 0;
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(sessionDetailProvider(widget.sessionId));
    final jobState =
        ref.watch(biometricAnalysisProvider(widget.sessionId));

    return Scaffold(
      appBar: AppTopBar(
        title: 'Detalle de sesión',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(sessionDetailProvider(widget.sessionId));
              ref.read(biometricAnalysisProvider(widget.sessionId).notifier)
                  .refresh();
            },
          ),
        ],
      ),
      body: sessionState.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryColor)),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (session) => _buildBody(context, session, jobState),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    SessionModel session,
    AsyncValue<BiometricJobModel?> jobState,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status + date header
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        session.patient?.fullName ?? 'Paciente',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    StatusBadge(status: session.status),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingSm),
                _InfoRow(
                  icon: Icons.calendar_today_outlined,
                  text: _formatDate(session.scheduledAt),
                ),
                if (session.startedAt != null)
                  _InfoRow(
                    icon: Icons.play_circle_outline,
                    text: 'Inicio: ${_formatDate(session.startedAt!)}',
                  ),
                if (session.endedAt != null)
                  _InfoRow(
                    icon: Icons.stop_circle_outlined,
                    text: 'Fin: ${_formatDate(session.endedAt!)}',
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),

          // Session control buttons
          if (session.status == SessionStatus.scheduled)
            _ActionButton(
              icon: Icons.play_arrow_rounded,
              label: 'Iniciar sesión',
              color: Colors.green.shade700,
              onPressed: () => _startSession(),
            ),
          if (session.status == SessionStatus.active)
            _ActionButton(
              icon: Icons.stop_rounded,
              label: 'Finalizar sesión',
              color: AppTheme.errorColor,
              onPressed: () => _showEndDialog(session),
            ),
          const SizedBox(height: AppTheme.spacingMd),

          // Notes
          if (session.notes != null && session.notes!.isNotEmpty) ...[
            Text('Notas', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppTheme.spacingSm),
            _SectionCard(
              child: Text(
                session.notes!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: AppTheme.spacingMd),
          ],

          // Video section
          Text('Video de la sesión',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppTheme.spacingSm),
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (session.videoUrl != null) ...[
                  Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 18,
                      ),
                      const SizedBox(width: AppTheme.spacingSm),
                      Expanded(
                        child: Text(
                          'Video subido correctamente',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: Colors.green.shade700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                ],
                if (_uploading) ...[
                  const Text('Subiendo video...'),
                  const SizedBox(height: AppTheme.spacingSm),
                  LinearProgressIndicator(
                    value: _uploadProgress > 0 ? _uploadProgress : null,
                    color: AppTheme.primaryColor,
                    backgroundColor: AppTheme.secondaryLight,
                  ),
                ] else
                  ElevatedButton.icon(
                    onPressed: () => _pickAndUploadVideo(session.id),
                    icon: const Icon(Icons.upload_file, size: 18),
                    label: Text(session.videoUrl != null
                        ? 'Reemplazar video'
                        : 'Subir video'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: AppTheme.primaryContrast,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),

          // Analysis section
          Text('Análisis emocional',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppTheme.spacingSm),
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                jobState.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Error: $e'),
                  data: (job) => _buildAnalysisSection(
                    context,
                    session,
                    job,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingXl),
        ],
      ),
    );
  }

  Widget _buildAnalysisSection(
    BuildContext context,
    SessionModel session,
    BiometricJobModel? job,
  ) {
    final hasVideo = session.videoUrl != null;
    final jobStatus = job?.status.name ?? 'none';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            AnalysisStatusBadge(status: jobStatus),
          ],
        ),
        if (job?.errorMessage != null) ...[
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            job!.errorMessage!,
            style: const TextStyle(color: AppTheme.errorColor, fontSize: 12),
          ),
        ],
        const SizedBox(height: AppTheme.spacingMd),
        if (!hasVideo)
          const Text(
            'Sube un video para poder analizar la sesión.',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
          )
        else if (job == null ||
            job.status == AnalysisJobStatus.failed) ...[
          ElevatedButton.icon(
            onPressed: () => _triggerAnalysis(),
            icon: const Icon(Icons.psychology_outlined, size: 18),
            label: const Text('Analizar video'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.secondaryColor,
              foregroundColor: AppTheme.primaryContrast,
            ),
          ),
        ] else if (job.status == AnalysisJobStatus.completed) ...[
          ElevatedButton.icon(
            onPressed: () =>
                context.go('/sessions/${session.id}/analysis'),
            icon: const Icon(Icons.bar_chart, size: 18),
            label: const Text('Ver resultados'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: AppTheme.primaryContrast,
            ),
          ),
        ] else
          const Text(
            'El análisis está en progreso. Actualiza para ver el estado.',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
          ),
      ],
    );
  }

  Future<void> _startSession() async {
    try {
      await ref.read(sessionsProvider.notifier).startSession(widget.sessionId);
      ref.invalidate(sessionDetailProvider(widget.sessionId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sesión iniciada')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al iniciar: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _showEndDialog(SessionModel session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Finalizar sesión'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('¿Deseas finalizar esta sesión?'),
            const SizedBox(height: AppTheme.spacingMd),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                hintText: 'Notas finales (opcional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Finalizar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await ref.read(sessionsProvider.notifier).endSession(
            widget.sessionId,
            notes: _notesController.text.isNotEmpty
                ? _notesController.text
                : null,
          );
      ref.invalidate(sessionDetailProvider(widget.sessionId));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sesión finalizada')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorColor),
      );
    }
  }

  Future<void> _pickAndUploadVideo(String sessionId) async {
    final picker = ImagePicker();
    final picked = await picker.pickVideo(source: ImageSource.gallery);
    if (picked == null || !mounted) return;

    final file = File(picked.path);
    setState(() {
      _uploading = true;
      _uploadProgress = 0;
    });

    try {
      await ref.read(sessionsProvider.notifier).uploadVideo(
            sessionId,
            file,
            onProgress: (sent, total) {
              if (total > 0 && mounted) {
                setState(() => _uploadProgress = sent / total);
              }
            },
          );
      ref.invalidate(sessionDetailProvider(sessionId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Video subido exitosamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error al subir video: $e'),
              backgroundColor: AppTheme.errorColor),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _triggerAnalysis() async {
    try {
      await ref
          .read(biometricAnalysisProvider(widget.sessionId).notifier)
          .triggerAnalysis();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Análisis iniciado. Puede tardar unos minutos.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error al iniciar análisis: $e'),
              backgroundColor: AppTheme.errorColor),
        );
      }
    }
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return DateFormat('dd/MM/yyyy HH:mm').format(dt);
    } catch (_) {
      return iso;
    }
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: child,
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppTheme.spacingXs),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppTheme.textMuted),
          const SizedBox(width: AppTheme.spacingXs),
          Text(text, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
        ),
      ),
    );
  }
}
