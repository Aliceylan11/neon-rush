import 'package:flutter/material.dart';

import '../game/cars.dart';

const _bg = BoxDecoration(
  gradient: LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF07021A), Color(0xFF1B0B3A), Color(0xFF3E1C64)],
  ),
);

/// Garaj: araba seçim ekranı.
class GarageScreen extends StatelessWidget {
  const GarageScreen({
    required this.selected,
    required this.onSelect,
    required this.onBack,
    super.key,
  });

  final String selected;
  final ValueChanged<String> onSelect;
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
                      'GARAJ',
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
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        for (final skin in carSkins)
                          _CarCard(
                            skin: skin,
                            isSelected: skin.asset == selected,
                            onTap: () => onSelect(skin.asset),
                          ),
                      ],
                    ),
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

class _CarCard extends StatelessWidget {
  const _CarCard({
    required this.skin,
    required this.isSelected,
    required this.onTap,
  });

  final CarSkin skin;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 168,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: isSelected ? 0.5 : 0.3),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? skin.accent : Colors.white24,
            width: isSelected ? 3 : 1.5,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: skin.accent.withValues(alpha: 0.5), blurRadius: 20)]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 110,
              child: Image.asset('assets/images/${skin.asset}',
                  fit: BoxFit.contain, cacheWidth: 360),
            ),
            const SizedBox(height: 10),
            Text(
              skin.name,
              style: TextStyle(
                color: isSelected ? skin.accent : Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected ? skin.accent : Colors.white38,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
