import 'package:flutter/material.dart';
import 'disc_sleeve.dart';
import 'home_shell.dart';
import 'theme.dart';

class _Slide {
  final String title;
  final String subtitle;
  final List<Color> sleeve;
  final Color label;
  final IconData icon;
  const _Slide(this.title, this.subtitle, this.sleeve, this.label, this.icon);
}

const _slides = [
  _Slide(
    'Le son du Bénin dans ta poche',
    'Zinli, afrobeat, gospel, vodoun jazz… tous les sons d\'ici réunis au même endroit.',
    [Color(0xFF2FB36D), Color(0xFF0A3B27)],
    AppColors.yellow,
    Icons.headphones_rounded,
  ),
  _Slide(
    'Découvre les artistes d\'ici',
    'Suis tes artistes préférés et repère les nouveaux talents de Cotonou à Parakou.',
    [Color(0xFFE0447C), Color(0xFF54112C)],
    AppColors.yellow,
    Icons.mic_external_on_rounded,
  ),
  _Slide(
    'Crée ta bibliothèque, écoute partout',
    'Garde tes favoris, crée tes playlists et télécharge pour écouter sans connexion.',
    [Color(0xFFE8833A), Color(0xFF4E2410)],
    AppColors.greenBright,
    Icons.library_music_rounded,
  ),
];

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _controller = PageController();
  int _index = 0;

  bool get _isLast => _index == _slides.length - 1;

  void _finish() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeShell()),
    );
  }

  void _next() {
    if (_isLast) {
      _finish();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0C1D15), AppColors.bg, AppColors.bg],
                stops: [0, 0.45, 1],
              ),
            ),
          ),
          Positioned(
            top: -200,
            left: -120,
            child: IgnorePointer(
              child: Container(
                width: 420,
                height: 420,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.green.withAlpha(42),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(26, 10, 14, 0),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 9),
                      Text(
                        'BENIN VIBES',
                        style: AppText.eyebrow.copyWith(
                          color: AppColors.muted,
                          letterSpacing: 3,
                        ),
                      ),
                      const Spacer(),
                      AnimatedOpacity(
                        opacity: _isLast ? 0 : 1,
                        duration: const Duration(milliseconds: 200),
                        child: IgnorePointer(
                          ignoring: _isLast,
                          child: TextButton(
                            onPressed: _finish,
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.muted,
                            ),
                            child: const Text('Passer'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: _slides.length,
                    onPageChanged: (i) => setState(() => _index = i),
                    itemBuilder: (context, i) {
                      final s = _slides[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Spacer(),
                            DiscSleeve(
                              active: i == _index,
                              sleeveColors: s.sleeve,
                              labelColor: s.label,
                              icon: s.icon,
                            ),
                            const SizedBox(height: 34),
                            Text(
                              s.title,
                              textAlign: TextAlign.center,
                              style: AppText.display,
                            ),
                            const SizedBox(height: 14),
                            Text(
                              s.subtitle,
                              textAlign: TextAlign.center,
                              style: AppText.body,
                            ),
                            const Spacer(),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_slides.length, (i) {
                    final active = i == _index;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOutCubic,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 6,
                      width: active ? 24 : 6,
                      decoration: BoxDecoration(
                        color: active
                            ? AppColors.green
                            : Colors.white.withAlpha(38),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    );
                  }),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 26, 24, 20),
                  child: FilledButton(
                    onPressed: _next,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_isLast ? 'Commencer' : 'Suivant'),
                        const SizedBox(width: 8),
                        Icon(
                          _isLast
                              ? Icons.check_rounded
                              : Icons.arrow_forward_rounded,
                          size: 18,
                        ),
                      ],
                    ),
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
