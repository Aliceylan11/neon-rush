import 'package:flutter/material.dart';

import '../game/race_type.dart';
import '../game/racing_game.dart';

/// Yarış bitince gösterilen sonuç ekranı (Flame overlay).
class ResultsOverlay extends StatelessWidget {
  const ResultsOverlay(this.game, {super.key});

  final RacingGame game;

  static String _fmt(double s) {
    final m = s ~/ 60;
    final sec = s - m * 60;
    return '$m:${sec.toStringAsFixed(2).padLeft(5, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final type = game.raceType;
    final destruction = type == RaceType.destruction;
    final accent = type.color;

    return Container(
      color: Colors.black.withValues(alpha: 0.72),
      child: Center(
        child: Container(
          width: 340,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: const Color(0xFF120A24),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: accent, width: 2),
            boxShadow: [
              BoxShadow(color: accent.withValues(alpha: 0.4), blurRadius: 28),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                destruction ? 'SÜRE DOLDU' : 'YARIŞ BİTTİ',
                style: TextStyle(
                  color: accent,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                type.title,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 20),
              if (destruction)
                _Stat(
                    label: 'DEVİRDİĞİN RAKİP',
                    value: '${game.wrecks.value}',
                    color: accent)
              else ...[
                _Stat(
                    label: 'TOPLAM SÜRE',
                    value: _fmt(game.totalTime),
                    color: accent),
                const SizedBox(height: 10),
                _Stat(
                  label: 'EN İYİ TUR',
                  value: game.bestLap.value == null
                      ? '--'
                      : _fmt(game.bestLap.value!),
                  color: const Color(0xFFFFD54F),
                ),
              ],
              const SizedBox(height: 26),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _Btn(
                    label: 'TEKRAR',
                    icon: Icons.replay,
                    color: accent,
                    onTap: game.restart,
                  ),
                  const SizedBox(width: 14),
                  _Btn(
                    label: 'MENÜ',
                    icon: Icons.home_rounded,
                    color: Colors.white70,
                    onTap: game.onExit,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 12,
            letterSpacing: 1.5,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 34,
            fontWeight: FontWeight.bold,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _Btn extends StatelessWidget {
  const _Btn({
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: color, width: 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
