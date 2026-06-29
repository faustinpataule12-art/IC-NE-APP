import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'editor_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // Header
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.accentDim,
                  border: Border.all(color: AppTheme.accent.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(child: Text('🎨', style: TextStyle(fontSize: 22))),
              ),
              const SizedBox(height: 16),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'ICÔNE-APP ',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.accent,
                      ),
                    ),
                    TextSpan(
                      text: 'by NPS',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.accent,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Personnalise l\'icône et le splash screen\nde n\'importe quel APK.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppTheme.textMuted,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),

              // Feature cards
              _FeatureCard(
                emoji: '📦',
                title: 'Sélectionner un APK',
                desc: 'Choisis l\'APK que tu veux modifier depuis ton stockage',
              ),
              const SizedBox(height: 12),
              _FeatureCard(
                emoji: '🖼️',
                title: 'Nouvelle icône',
                desc: 'Remplace l\'icône dans toutes les résolutions automatiquement',
              ),
              const SizedBox(height: 12),
              _FeatureCard(
                emoji: '✨',
                title: 'Splash Screen',
                desc: 'Personnalise l\'écran de démarrage — image, couleur, logo',
              ),
              const SizedBox(height: 12),
              _FeatureCard(
                emoji: '⚙️',
                title: 'Recompile & Signe',
                desc: 'L\'APK est recompilé et signé automatiquement',
              ),

              const Spacer(),

              // Start button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EditorScreen()),
                  ),
                  child: const Text('COMMENCER'),
                ),
              ),
              const SizedBox(height: 20),

              // Footer
              Center(
                child: Column(
                  children: [
                    Text(
                      'NPS.NELSON',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11,
                        color: AppTheme.accent,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'nelsonpataule11@gmail.com',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10,
                        color: AppTheme.textMuted,
                      ),
                    ),
                    Text(
                      'WhatsApp : +243 981 083 202',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String desc;

  const _FeatureCard({required this.emoji, required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
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
                  title,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  desc,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppTheme.textMuted,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
