import 'package:flutter/material.dart';

/// Overlay nút thao tác nổi trên bản đồ.
class MapActionOverlay extends StatelessWidget {
  final VoidCallback onCall;
  final VoidCallback onRing;
  final VoidCallback onDirections;

  const MapActionOverlay({
    super.key,
    required this.onCall,
    required this.onRing,
    required this.onDirections,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 24,
      left: 16,
      right: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildFab(Icons.phone, Colors.green, onCall),
          const SizedBox(width: 16),
          _buildFab(Icons.notification_important, Colors.orange, onRing),
          const SizedBox(width: 16),
          _buildFab(Icons.directions, Colors.blue, onDirections),
        ],
      ),
    );
  }

  Widget _buildFab(IconData icon, Color color, VoidCallback onTap) {
    return FloatingActionButton(
      heroTag: icon.codePoint.toString(),
      onPressed: onTap,
      backgroundColor: color,
      mini: true,
      child: Icon(icon, color: Colors.white),
    );
  }
}
