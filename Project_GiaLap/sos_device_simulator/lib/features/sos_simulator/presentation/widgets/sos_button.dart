import 'package:flutter/material.dart';

/// Large, prominent red SOS button used to trigger an emergency alert.
class SosButton extends StatelessWidget {
  final VoidCallback onPressed;

  const SosButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final buttonSize = size.width < 360 ? 160.0 : 200.0;

    return Material(
      elevation: 8,
      shape: const CircleBorder(),
      color: Colors.red,
      shadowColor: Colors.redAccent,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: buttonSize,
          height: buttonSize,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(
                  Icons.emergency,
                  color: Colors.white,
                  size: 64,
                ),
                SizedBox(height: 8),
                Text(
                  'SOS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
