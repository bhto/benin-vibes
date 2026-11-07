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
    [AppColors.green, Color(0xFF1C8A53)],
    AppColors.yellow,
    Icons.headphones_rounded,
  ),
  _Slide(
    'Découvre les artistes d\'ici',
    'Suis tes artistes préférés et repère les nouveaux talents de Cotonou à Parakou.',
    [AppColors.red, Color(0xFFA3303F)],
    AppColors.yellow,
    Icons.mic_external_on_rounded,
  ),
  _Slide(
    'Crée ta bibliothèque, écoute partout',
    'Garde tes favoris, crée tes playlists et télécharge pour écouter sans connexion.',
    [AppColors.yellow, Color(0xFFC9A400)],
    AppColors.green,
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
        duration: const Duration(milliseconds: 400),
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
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 12, top: 4),
                child: AnimatedOpacity(
                  opacity: _isLast ? 0 : 1,
                  duration: const Duration(milliseconds: 200),
                  child: TextButton(
                    onPressed: _isLast ? null : _finish,
                    child: const Text('Passer', style: TextStyle(color: Colors.white70)),
                  ),
                ),
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
                        DiscSleeve(
                          active: i == _index,
                          sleeveColors: s.sleeve,
                          labelColor: s.label,
                          icon: s.icon,
                        ),
                        const SizedBox(height: 36),
                        Text(
                          s.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          s.subtitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 15, color: Colors.white70, height: 1.4),
                        ),
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
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 8,
                  width: active ? 26 : 8,
                  decoration: BoxDecoration(
                    color: active ? AppColors.yellow : Colors.white24,
                    borderRadius: BorderRadius.circular(8),
                  ),
                );
              }),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
              child: FilledButton(
                onPressed: _next,
                child: Text(_isLast ? 'Commencer' : 'Suivant'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
