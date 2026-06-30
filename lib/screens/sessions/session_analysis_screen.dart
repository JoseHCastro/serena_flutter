import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../components/app_top_bar.dart';
import '../../components/emotion_chart.dart';
import '../../core/constants/api_constants.dart';
import '../../models/analysis_model.dart';
import '../../providers/biometric_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

class SessionAnalysisScreen extends ConsumerWidget {
  final String sessionId;

  const SessionAnalysisScreen({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobState = ref.watch(biometricAnalysisProvider(sessionId));
    final snapshotsState = ref.watch(snapshotsProvider(sessionId));

    return Scaffold(
      appBar: AppTopBar(
        title: 'Resultados de análisis',
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'Descargar PDF',
            onPressed: () => _downloadPdf(context, ref),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.primaryColor,
        onRefresh: () async {
          ref.invalidate(snapshotsProvider(sessionId));
          ref.read(biometricAnalysisProvider(sessionId).notifier).refresh();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary card from job result
              jobState.when(
                loading: () => const LinearProgressIndicator(
                    color: AppTheme.primaryColor),
                error: (e, _) => Text('Error: $e'),
                data: (job) => job != null
                    ? _SummaryCard(job: job)
                    : const SizedBox.shrink(),
              ),
              const SizedBox(height: AppTheme.spacingLg),

              // Emotion timeline chart
              snapshotsState.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppTheme.primaryColor),
                ),
                error: (e, _) => Text('Error al cargar timeline: $e'),
                data: (snapshots) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (snapshots.isNotEmpty) ...[
                      _buildFramesSection(context, snapshots),
                      EmotionTimelineChart(snapshots: snapshots),
                      const SizedBox(height: AppTheme.spacingXl),
                      EmotionAverageChart(snapshots: snapshots),
                      const SizedBox(height: AppTheme.spacingLg),
                    ] else
                      const Center(
                        child: Text('Sin datos de timeline disponibles'),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: AppTheme.spacingXl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFramesSection(BuildContext context, List<EmotionalSnapshot> snapshots) {
    final frames = snapshots.where((s) => s.frameUrl != null).toList();
    if (frames.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Capturas de expresiones (Fotogramas)',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppTheme.spacingMd),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: frames.length,
            itemBuilder: (context, index) {
              final f = frames[index];
              return Container(
                width: 120,
                margin: const EdgeInsets.only(right: AppTheme.spacingMd),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: Image.network(
                                f.frameUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => const Center(
                                  child: Icon(Icons.broken_image,
                                      color: AppTheme.textMuted, size: 24),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 4,
                              right: 4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.black.withAlpha(160),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${f.timestampOffset.toStringAsFixed(1)}s',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(AppTheme.spacingSm),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _emotionLabel(f.dominantEmotion),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${(f.confidence * 100).toStringAsFixed(0)}% conf.',
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppTheme.spacingXl),
      ],
    );
  }

  String _emotionLabel(String emotion) {
    const labels = {
      'happiness': 'Felicidad',
      'sadness': 'Tristeza',
      'anger': 'Ira',
      'fear': 'Miedo',
      'disgust': 'Asco',
      'surprise': 'Sorpresa',
      'neutral': 'Neutral',
    };
    return labels[emotion.toLowerCase()] ?? emotion;
  }

  Future<void> _downloadPdf(BuildContext context, WidgetRef ref) async {
    final storage = ref.read(secureStorageProvider);
    final token = await storage.getAccessToken();
    if (token == null) return;

    final url = '${ApiConstants.baseUrl}${ApiConstants.sessionPdf(sessionId)}';
    final uri = Uri.parse(url);

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo abrir el PDF. Verifica la sesión.'),
          ),
        );
      }
    }
  }
}

class _SummaryCard extends StatelessWidget {
  final BiometricJobModel job;

  const _SummaryCard({required this.job});

  @override
  Widget build(BuildContext context) {
    final summary = job.resultSummary;
    final frameCount = summary?['frame_count'] as int?;
    final dominant = summary?['dominant_emotion'] as String?;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumen del análisis',
            style: TextStyle(
              color: AppTheme.secondaryLight,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          if (dominant != null) ...[
            Text(
              _emotionLabel(dominant),
              style: const TextStyle(
                color: AppTheme.primaryContrast,
                fontSize: 28,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Text(
              'Emoción dominante',
              style: TextStyle(
                color: AppTheme.secondaryLight,
                fontSize: 13,
              ),
            ),
          ],
          if (frameCount != null) ...[
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              '$frameCount fotogramas analizados',
              style: const TextStyle(
                color: AppTheme.primaryContrast,
                fontSize: 14,
              ),
            ),
          ],
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            'Completado: ${_formatDate(job.updatedAt)}',
            style: const TextStyle(
              color: AppTheme.secondaryLight,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _emotionLabel(String emotion) {
    const labels = {
      'happiness': 'Felicidad',
      'sadness': 'Tristeza',
      'anger': 'Enojo',
      'fear': 'Miedo',
      'disgust': 'Asco',
      'surprise': 'Sorpresa',
      'neutral': 'Neutral',
    };
    return labels[emotion] ?? emotion;
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

