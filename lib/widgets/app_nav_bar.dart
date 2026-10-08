import 'package:flutter/material.dart';

class AppNavBar extends StatelessWidget {
  const AppNavBar({
    super.key,
    required this.selected,
    required this.onSelected,
  });
  final int selected;
  final ValueChanged<int> onSelected;

  static const accent = Color(0xff155bb2);
  static const inactive = Color(0xff6b7788);
  static const selectedSurface = Color(0xffe8f1fb);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
    child: Material(
      color: Colors.white,
      elevation: 2,
      shadowColor: const Color(0x180d2b4d),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 68,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            item(Icons.home, 'Home', 0),
            item(Icons.receipt_long_outlined, 'Reports', 1),
            item(Icons.qr_code_scanner, 'Scan', 2),
            item(Icons.notifications_none, 'Notifications', 3),
            item(Icons.person_outline, 'Profile', 4),
          ],
        ),
      ),
    ),
  );

  Widget item(IconData icon, String label, int index) {
    final isSelected = selected == index;
    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: InkWell(
        onTap: () => onSelected(index),
        borderRadius: BorderRadius.circular(16),
        splashColor: accent.withAlpha(24),
        highlightColor: accent.withAlpha(12),
        child: SizedBox(
          width: 64,
          height: 64,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutBack,
                width: isSelected ? 42 : 38,
                height: 32,
                decoration: BoxDecoration(
                  color: isSelected ? selectedSurface : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: AnimatedScale(
                  scale: isSelected ? 1.12 : 1,
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutBack,
                  child: Icon(
                    icon,
                    size: 21,
                    color: isSelected ? accent : inactive,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                style: TextStyle(
                  fontSize: isSelected ? 11 : 10,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? accent : inactive,
                  letterSpacing: 0.0,
                ),
                child: Text(label, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
