import 'package:flutter/material.dart';

import '../game/mods.dart';
import '../game/race_type.dart';
import '../game/racing_game.dart';

class Hud extends StatelessWidget {
  const Hud(this.game, {super.key});

  final RacingGame game;

  static String _fmt(double s) {
    final m = s ~/ 60;
    final sec = s - m * 60;
    final secStr = sec.toStringAsFixed(2).padLeft(5, '0');
    return m > 0 ? '$m:$secStr' : sec.toStringAsFixed(2);
  }

  List<Widget> _leftPanels() {
    final type = game.raceType;
    if (type == RaceType.destruction) {
      return [
        ValueListenableBuilder<double>(
          valueListenable: game.timeLeft,
          builder: (_, t, _) =>
              _Panel(label: 'SÜRE', value: '${t.ceil()}', highlight: true),
        ),
        const SizedBox(width: 10),
        ValueListenableBuilder<int>(
          valueListenable: game.wrecks,
          builder: (_, n, _) => _Panel(label: 'DEVİRME', value: '$n'),
        ),
      ];
    }
    return [
      ValueListenableBuilder<int>(
        valueListenable: game.lap,
        builder: (_, lap, _) => _Panel(
          label: 'TUR',
          value: type.finishByLaps
              ? '${lap + 1}/${type.lapTarget}'
              : '${lap + 1}',
        ),
      ),
      const SizedBox(width: 10),
      ValueListenableBuilder<double>(
        valueListenable: game.currentLap,
        builder: (_, t, _) => _Panel(label: 'SÜRE', value: _fmt(t)),
      ),
      const SizedBox(width: 10),
      ValueListenableBuilder<double?>(
        valueListenable: game.bestLap,
        builder: (_, t, _) => _Panel(
          label: 'EN İYİ',
          value: t == null ? '--' : _fmt(t),
          highlight: true,
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: IgnorePointer(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ..._leftPanels(),
                  const Spacer(),
                  ValueListenableBuilder<int>(
                    valueListenable: game.speedKmh,
                    builder: (_, v, _) =>
                        _Panel(label: 'KM/S', value: '$v', big: true),
                  ),
                  const SizedBox(width: 44), // menü butonuna yer
                ],
              ),
              const SizedBox(height: 8),
              ValueListenableBuilder<List<Mod>>(
                valueListenable: game.modsHud,
                builder: (_, mods, _) => Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < 3; i++) ...[
                      _ModSlot(i < mods.length ? mods[i] : null),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModSlot extends StatelessWidget {
  const _ModSlot(this.mod);
  final Mod? mod;

  @override
  Widget build(BuildContext context) {
    final m = mod;
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: m?.color ?? Colors.white24, width: 2),
        boxShadow: m == null
            ? null
            : [BoxShadow(color: m.color.withValues(alpha: 0.5), blurRadius: 10)],
      ),
      child: m == null ? null : Icon(m.icon, color: m.color, size: 26),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.label,
    required this.value,
    this.highlight = false,
    this.big = false,
  });

  final String label;
  final String value;
  final bool highlight;
  final bool big;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: highlight ? const Color(0xFFFFD54F) : Colors.white24,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: highlight ? const Color(0xFFFFD54F) : Colors.white,
              fontSize: big ? 26 : 18,
              fontWeight: FontWeight.bold,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
