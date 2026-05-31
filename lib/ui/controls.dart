import 'package:flutter/material.dart';

import '../game/racing_game.dart';

/// Ekran üstü dokunmatik kontroller. Sol altta direksiyon (yuvarlak),
/// sağ altta gaz/fren PEDALLARI, alt-ortada MOD kullan. Çoklu dokunuş destekli.
class Controls extends StatelessWidget {
  const Controls(this.game, {super.key});

  final RacingGame game;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Stack(
          children: [
            // Direksiyon — sol alt
            Align(
              alignment: Alignment.bottomLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  HoldButton(
                    icon: Icons.arrow_back_ios_new,
                    color: const Color(0xFF1976D2),
                    onChanged: (v) => game.btnLeft = v,
                  ),
                  const SizedBox(width: 16),
                  HoldButton(
                    icon: Icons.arrow_forward_ios,
                    color: const Color(0xFF1976D2),
                    onChanged: (v) => game.btnRight = v,
                  ),
                ],
              ),
            ),
            // Gaz / fren PEDALLARI — sağ alt
            Align(
              alignment: Alignment.bottomRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  PedalButton(
                    label: 'FREN',
                    icon: Icons.keyboard_double_arrow_down,
                    color: const Color(0xFFC62828),
                    height: 132,
                    onChanged: (v) => game.btnBrake = v,
                  ),
                  const SizedBox(width: 14),
                  PedalButton(
                    label: 'GAZ',
                    icon: Icons.keyboard_double_arrow_up,
                    color: const Color(0xFF2E7D32),
                    height: 164,
                    onChanged: (v) => game.btnGas = v,
                  ),
                ],
              ),
            ),
            // Menüye dön — sağ üst
            Align(
              alignment: Alignment.topRight,
              child: GestureDetector(
                onTap: game.onExit,
                child: Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white54, width: 1.5),
                  ),
                  child: const Icon(Icons.home_rounded,
                      color: Colors.white, size: 22),
                ),
              ),
            ),
            // MOD kullan — alt orta
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: HoldButton(
                  icon: Icons.auto_awesome,
                  color: const Color(0xFF8E24AA),
                  size: 60,
                  onChanged: (v) => game.btnUse = v,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Yuvarlak basılı-tut buton (direksiyon, mod).
class HoldButton extends StatefulWidget {
  const HoldButton({
    required this.icon,
    required this.color,
    required this.onChanged,
    this.size = 80,
    super.key,
  });

  final IconData icon;
  final Color color;
  final double size;
  final ValueChanged<bool> onChanged;

  @override
  State<HoldButton> createState() => _HoldButtonState();
}

class _HoldButtonState extends State<HoldButton> {
  bool _pressed = false;

  void _set(bool v) {
    if (_pressed == v) return;
    setState(() => _pressed = v);
    widget.onChanged(v);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color.withValues(alpha: _pressed ? 0.95 : 0.55),
          border: Border.all(color: Colors.white70, width: 2),
          boxShadow: [
            if (_pressed)
              BoxShadow(
                color: widget.color.withValues(alpha: 0.6),
                blurRadius: 18,
                spreadRadius: 2,
              ),
          ],
        ),
        child: Icon(widget.icon, color: Colors.white, size: widget.size * 0.4),
      ),
    );
  }
}

/// Dikey PEDAL şeklinde basılı-tut buton (gaz/fren).
class PedalButton extends StatefulWidget {
  const PedalButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onChanged,
    this.width = 68,
    this.height = 150,
    super.key,
  });

  final String label;
  final IconData icon;
  final Color color;
  final double width;
  final double height;
  final ValueChanged<bool> onChanged;

  @override
  State<PedalButton> createState() => _PedalButtonState();
}

class _PedalButtonState extends State<PedalButton> {
  bool _pressed = false;

  void _set(bool v) {
    if (_pressed == v) return;
    setState(() => _pressed = v);
    widget.onChanged(v);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              widget.color.withValues(alpha: _pressed ? 1.0 : 0.7),
              widget.color.withValues(alpha: _pressed ? 0.75 : 0.4),
            ],
          ),
          border: Border.all(color: Colors.white70, width: 2),
          boxShadow: [
            if (_pressed)
              BoxShadow(
                color: widget.color.withValues(alpha: 0.7),
                blurRadius: 20,
                spreadRadius: 2,
              ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(widget.icon, color: Colors.white, size: widget.width * 0.55),
            const SizedBox(height: 4),
            Text(
              widget.label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
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
