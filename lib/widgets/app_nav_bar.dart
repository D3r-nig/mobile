import 'package:flutter/material.dart';

class AppNavBar extends StatelessWidget {
  const AppNavBar({
    super.key,
    required this.selected,
    required this.onSelected,
  });
  final int selected;
  final ValueChanged<int> onSelected;

  static const accent = Color(0xff3937e8);
  static const inactive = Color(0xff171717);
  static const selectedSurface = Color(0xffeef0ff);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
    child: Material(
      color: Colors.white,
      elevation: 4,
      shadowColor: Colors.black12,
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(18),
        topRight: Radius.circular(18),
      ),
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

  Widget item(IconData icon, String label, int index) => GestureDetector(
    onTap: () => onSelected(index),
    child: SizedBox(
      width: 60,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: selected == index ? 1 : 0),
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOut,
            builder: (context, emphasis, child) => AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOut,
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color.lerp(
                  Colors.transparent,
                  selectedSurface,
                  emphasis,
                ),
              ),
              alignment: Alignment.center,
              child: Icon(
                icon,
                size: 20 + emphasis * 2,
                color: Color.lerp(inactive, accent, emphasis),
              ),
            ),
          ),
          const SizedBox(height: 2),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOut,
            style: TextStyle(
              fontSize: 8,
              fontWeight: selected == index ? FontWeight.w700 : FontWeight.w500,
              color: selected == index ? accent : inactive,
              letterSpacing: 0.0,
            ),
            child: Text(label, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    ),
  );
}
