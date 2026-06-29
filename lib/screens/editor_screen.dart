import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../theme/app_theme.dart';
import '../services/apk_service.dart';
import 'result_screen.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  String? _apkPath;
  String? _apkName;
  File? _newIcon;
  File? _splashImage;
  File? _splashLogo;
  Color _splashBgColor = const Color(0xFF0D0F14);
  bool _isProcessing = false;
  int _currentStep = 0;
  String _statusMsg = '';

  Future<void> _pickApk() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['apk'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _apkPath = result.files.single.path;
        _apkName = result.files.single.name;
      });
    }
  }

  Future<void> _pickIcon() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery);
    if (img != null) setState(() => _newIcon = File(img.path));
  }

  Future<void> _pickSplashImage() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery);
    if (img != null) setState(() => _splashImage = File(img.path));
  }

  Future<void> _pickSplashLogo() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery);
    if (img != null) setState(() => _splashLogo = File(img.path));
  }

  void _pickColor() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text('Couleur du splash', style: GoogleFonts.jetBrainsMono(color: AppTheme.accent)),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: _splashBgColor,
            onColorChanged: (c) => setState(() => _splashBgColor = c),
            enableAlpha: false,
            hexInputBar: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: TextStyle(color: AppTheme.accent)),
          ),
        ],
      ),
    );
  }

  Future<void> _process() async {
    if (_apkPath == null) {
      _showSnack('Sélectionne d\'abord un APK !');
      return;
    }
    if (_newIcon == null && _splashImage == null && _splashLogo == null) {
      _showSnack('Sélectionne au moins une icône ou un splash !');
      return;
    }

    setState(() {
      _isProcessing = true;
      _statusMsg = 'Décompilation de l\'APK...';
      _currentStep = 0;
    });

    try {
      final service = ApkService();

      final outputPath = await service.processApk(
        apkPath: _apkPath!,
        newIcon: _newIcon,
        splashImage: _splashImage,
        splashLogo: _splashLogo,
        splashBgColor: _splashBgColor,
        onProgress: (step, msg) {
          setState(() {
            _currentStep = step;
            _statusMsg = msg;
          });
        },
      );

      if (!mounted) return;
      setState(() => _isProcessing = false);

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ResultScreen(outputPath: outputPath)),
      );
    } catch (e) {
      setState(() => _isProcessing = false);
      _showSnack('Erreur : $e');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.inter()),
        backgroundColor: AppTheme.danger,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ÉDITEUR APK'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isProcessing ? _buildProcessing() : _buildEditor(),
    );
  }

  Widget _buildProcessing() {
    final steps = [
      'Décompilation de l\'APK...',
      'Remplacement des icônes...',
      'Modification du splash screen...',
      'Recompilation...',
      'Signature de l\'APK...',
      'Finalisation...',
    ];
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                color: AppTheme.accent,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              _statusMsg,
              style: GoogleFonts.jetBrainsMono(color: AppTheme.accent, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ...List.generate(steps.length, (i) => _StepRow(
              label: steps[i],
              state: i < _currentStep
                  ? _StepState.done
                  : i == _currentStep
                      ? _StepState.active
                      : _StepState.pending,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildEditor() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step 1: APK
          _SectionTitle(number: '01', title: 'SÉLECTIONNER L\'APK'),
          const SizedBox(height: 12),
          _PickerCard(
            emoji: '📦',
            label: _apkName ?? 'Aucun APK sélectionné',
            subtitle: _apkPath != null ? 'APK chargé avec succès' : 'Appuie pour choisir un fichier .apk',
            isSelected: _apkPath != null,
            onTap: _pickApk,
          ),
          const SizedBox(height: 28),

          // Step 2: Icon
          _SectionTitle(number: '02', title: 'NOUVELLE ICÔNE'),
          const SizedBox(height: 12),
          _ImagePickerCard(
            emoji: '🖼️',
            label: 'Icône de l\'application',
            subtitle: 'Remplace dans toutes les tailles (48→192px)',
            image: _newIcon,
            onTap: _pickIcon,
          ),
          const SizedBox(height: 28),

          // Step 3: Splash
          _SectionTitle(number: '03', title: 'SPLASH SCREEN'),
          const SizedBox(height: 12),
          _ImagePickerCard(
            emoji: '🌅',
            label: 'Image de fond',
            subtitle: 'Image plein écran au démarrage',
            image: _splashImage,
            onTap: _pickSplashImage,
          ),
          const SizedBox(height: 12),
          _ImagePickerCard(
            emoji: '✨',
            label: 'Logo centré',
            subtitle: 'Logo affiché au centre du splash',
            image: _splashLogo,
            onTap: _pickSplashLogo,
          ),
          const SizedBox(height: 12),
          _ColorPickerCard(
            color: _splashBgColor,
            onTap: _pickColor,
          ),
          const SizedBox(height: 36),

          // Process button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _process,
              child: const Text('⚙️  MODIFIER L\'APK'),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '* L\'APK sera décompilé, modifié, recompilé et signé automatiquement.',
            style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─── Widgets ───────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String number;
  final String title;
  const _SectionTitle({required this.number, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          number,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 11,
            color: AppTheme.accent,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 12,
            color: AppTheme.textMuted,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

class _PickerCard extends StatelessWidget {
  final String emoji;
  final String label;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _PickerCard({
    required this.emoji,
    required this.label,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.accent.withOpacity(0.4) : AppTheme.border,
          ),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 12,
                      color: isSelected ? AppTheme.accent : AppTheme.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle : Icons.add_circle_outline,
              color: isSelected ? AppTheme.accent : AppTheme.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _ImagePickerCard extends StatelessWidget {
  final String emoji;
  final String label;
  final String subtitle;
  final File? image;
  final VoidCallback onTap;

  const _ImagePickerCard({
    required this.emoji,
    required this.label,
    required this.subtitle,
    required this.image,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: image != null ? AppTheme.accent.withOpacity(0.4) : AppTheme.border,
          ),
        ),
        child: Row(
          children: [
            if (image != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(image!, width: 44, height: 44, fit: BoxFit.cover),
              )
            else
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.accentDim,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(child: Text(emoji, style: const TextStyle(fontSize: 22))),
              ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 12,
                      color: image != null ? AppTheme.accent : AppTheme.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
            Icon(
              image != null ? Icons.check_circle : Icons.add_circle_outline,
              color: image != null ? AppTheme.accent : AppTheme.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorPickerCard extends StatelessWidget {
  final Color color;
  final VoidCallback onTap;

  const _ColorPickerCard({required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.border),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Couleur de fond',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 12,
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '#${color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
                    style: GoogleFonts.jetBrainsMono(fontSize: 11, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
            const Icon(Icons.color_lens_outlined, color: AppTheme.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}

enum _StepState { pending, active, done }

class _StepRow extends StatelessWidget {
  final String label;
  final _StepState state;

  const _StepRow({required this.label, required this.state});

  @override
  Widget build(BuildContext context) {
    final color = state == _StepState.done
        ? AppTheme.accent
        : state == _StepState.active
            ? AppTheme.textPrimary
            : AppTheme.textMuted;
    final icon = state == _StepState.done
        ? '✅'
        : state == _StepState.active
            ? '⏳'
            : '○';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 10),
          Text(
            label,
            style: GoogleFonts.jetBrainsMono(fontSize: 12, color: color),
          ),
        ],
      ),
    );
  }
}
