import 'package:flutter/material.dart';

class BottomNavIcon extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;
  final String text;

  const BottomNavIcon({
    super.key,
    required this.onTap,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 25, color: Colors.grey),
          Text(
            text,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
