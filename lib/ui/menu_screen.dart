import 'package:flutter/material.dart';

import '../game/race_type.dart';

const _bg = BoxDecoration(
  gradient: LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF07021A), Color(0xFF1B0B3A), Color(0xFF3E1C64)],
  ),
);

/// Ana menü: başlık + BAŞLA.
class MenuScreen extends StatelessWidget {
  const MenuScreen({
    required this.onPlay,
    required this.onGarage,
    super.key,
  });

  final VoidCallback onPlay;
  final VoidCallback onGarage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: _bg,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const _NeonTitle('NEON RUSH'),
              const SizedBox(height: 8),
              Text(
                'arcade combat racing',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 16,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 48),
              _NeonButton(
                label: 'BAŞLA',
                icon: Icons.play_arrow_rounded,
                color: const Color(0xFF49F2FF),
                onTap: onPlay,
              ),
              const SizedBox(height: 18),
              _NeonButton(
                label: 'GARAJ',
                icon: Icons.directions_car_filled,
                color: const Color(0xFFFF3DAE),
                onTap: onGarage,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Yarış tipi seçim ekranı.
class RaceSelectScreen extends StatelessWidget {
  const RaceSelectScreen({
    required this.onSelect,
    required this.onBack,
    super.key,
  });

  final ValueChanged<RaceType> onSelect;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: _bg,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: onBack,
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'YARIŞ TİPİ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    alignment: WrapAlignment.center,
                    children: [
                      for (final t in RaceType.values)
                        _RaceCard(type: t, onTap: () => onSelect(t)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RaceCard extends StatelessWidget {
  const _RaceCard({required this.type, required this.onTap});
  final RaceType type;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 190,
        height: 150,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: type.color, width: 2),
          boxShadow: [
            BoxShadow(color: type.color.withValues(alpha: 0.35), blurRadius: 16),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(type.icon, color: type.color, size: 44),
            const SizedBox(height: 10),
            Text(
              type.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              type.desc,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NeonTitle extends StatelessWidget {
  const _NeonTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 56,
        fontWeight: FontWeight.w900,
        letterSpacing: 6,
        shadows: [
          Shadow(color: Color(0xFFFF3DAE), blurRadius: 24),
          Shadow(color: Color(0xFF49F2FF), blurRadius: 40),
        ],
      ),
    );
  }
}

class _NeonButton extends StatelessWidget {
  const _NeonButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 44, vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: color, width: 2.5),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 20),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 26,
                fontWeight: FontWeight.bold,
                letterSpacing: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
