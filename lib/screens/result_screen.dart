import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/app_theme.dart';

class ResultScreen extends StatelessWidget {
  final String outputPath;

  const ResultScreen({super.key, required this.outputPath});

  String get _fileName => outputPath.split('/').last;
  String get _fileSize {
    try {
      final bytes = File(outputPath).lengthSync();
      if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } catch (_) {
      return '—';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('APK MODIFIÉ')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.accentDim,
                  border: Border.all(color: AppTheme.accent.withOpacity(0.4)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Center(
                  child: Text('✅', style: TextStyle(fontSize: 36)),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                'APK MODIFIÉ AVEC SUCCÈS',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.accent,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoRow(label: 'Fichier', value: _fileName),
                  const SizedBox(height: 10),
                  _InfoRow(label: 'Taille', value: _fileSize),
                  const SizedBox(height: 10),
                  _InfoRow(label: 'Emplacement', value: 'Téléchargements'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.accentDim,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.accent.withOpacity(0.2)),
              ),
              child: Text(
                '💡 L\'APK se trouve dans ton dossier Téléchargements. Installe-le directement ou partage-le.',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 12,
                  color: AppTheme.accent,
                  height: 1.5,
                ),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => OpenFile.open(outputPath),
                child: const Text('📲  INSTALLER L\'APK'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.surface,
                  foregroundColor: AppTheme.textPrimary,
                  side: const BorderSide(color: AppTheme.border),
                ),
                onPressed: () => Share.shareXFiles([XFile(outputPath)], text: 'APK modifié par ICÔNE-APP — NPS.NELSON'),
                child: const Text('📤  PARTAGER L\'APK'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
                child: Text(
                  'Retour à l\'accueil',
                  style: GoogleFonts.jetBrainsMono(color: AppTheme.textMuted),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: GoogleFonts.jetBrainsMono(fontSize: 11, color: AppTheme.textMuted),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11,
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
