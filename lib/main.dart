import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'game/audio.dart';
import 'game/race_type.dart';
import 'game/racing_game.dart';
import 'ui/controls.dart';
import 'ui/garage_screen.dart';
import 'ui/hud.dart';
import 'ui/menu_screen.dart';
import 'ui/results_overlay.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  await audio.init();
  runApp(const ArabaApp());
}

class ArabaApp extends StatelessWidget {
  const ArabaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Neon Rush',
      debugShowCheckedModeBanner: false,
      home: AppFlow(),
    );
  }
}

enum _Screen { menu, garage, select, racing }

class AppFlow extends StatefulWidget {
  const AppFlow({super.key});

  @override
  State<AppFlow> createState() => _AppFlowState();
}

class _AppFlowState extends State<AppFlow> {
  _Screen _screen = _Screen.menu;
  RaceType _type = RaceType.lap;
  String _carAsset = 'car.png';

  void _click() => audio.sfx('click.wav', volume: 0.5);

  @override
  Widget build(BuildContext context) {
    switch (_screen) {
      case _Screen.menu:
        return MenuScreen(
          onPlay: () {
            _click();
            setState(() => _screen = _Screen.select);
          },
          onGarage: () {
            _click();
            setState(() => _screen = _Screen.garage);
          },
        );
      case _Screen.garage:
        return GarageScreen(
          selected: _carAsset,
          onSelect: (a) {
            _click();
            setState(() {
              _carAsset = a;
              _screen = _Screen.menu;
            });
          },
          onBack: () {
            _click();
            setState(() => _screen = _Screen.menu);
          },
        );
      case _Screen.select:
        return RaceSelectScreen(
          onSelect: (t) {
            _click();
            setState(() {
              _type = t;
              _screen = _Screen.racing;
            });
          },
          onBack: () {
            _click();
            setState(() => _screen = _Screen.menu);
          },
        );
      case _Screen.racing:
        return GameScreen(
          raceType: _type,
          carAsset: _carAsset,
          onExit: () => setState(() => _screen = _Screen.menu),
        );
    }
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({
    required this.raceType,
    required this.carAsset,
    required this.onExit,
    super.key,
  });

  final RaceType raceType;
  final String carAsset;
  final VoidCallback onExit;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final RacingGame _game = RacingGame(
    raceType: widget.raceType,
    onExit: widget.onExit,
    playerCarAsset: widget.carAsset,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameWidget<RacingGame>(
        game: _game,
        overlayBuilderMap: {
          'hud': (context, game) => Hud(game),
          'controls': (context, game) => Controls(game),
          'results': (context, game) => ResultsOverlay(game),
        },
        initialActiveOverlays: const ['hud', 'controls'],
      ),
    );
  }
}
