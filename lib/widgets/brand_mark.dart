import 'package:flutter/material.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, required this.size});
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: Image.asset(
      'assets/logo_transparent.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    ),
  );
}
