import 'package:flutter/material.dart';

class IconPickerMenu extends StatelessWidget {
  final Widget child; // What the user clicks on (e.g., an Icon or Chip)
  final Function(IconData) onIconSelected;

  IconPickerMenu({Key? key, required this.child, required this.onIconSelected}) : super(key: key);

  final Map<String, Map<String, IconData>> iconCategories = {
    'Faces & Emotion': {
      'Smile': Icons.sentiment_satisfied_alt,
      'Laugh': Icons.sentiment_very_satisfied,
      'Cool': Icons.mood,
      'Heart': Icons.favorite,
      'Fire': Icons.local_fire_department,
    },
    'Nature & Weather': {
      'Star': Icons.star,
      'Moon': Icons.nightlight_round,
      'Sun': Icons.wb_sunny,
      'Water': Icons.water_drop,
      'Flower': Icons.local_florist,
      'Tree': Icons.park,
    },
    'Tech & Objects': {
      'Rocket': Icons.rocket_launch,
      'Gamepad': Icons.sports_esports,
      'Diamond': Icons.diamond,
      'Music': Icons.music_note,
      'Bolt': Icons.bolt,
    },
    'Shapes & Symbols': {
      'Circle': Icons.circle,
      'Square': Icons.square,
      'Hexagon': Icons.hexagon,
      'Warning': Icons.warning_rounded,
    }
  };

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<IconData>(
      color: Colors.grey[900],
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: child, // Shows the "+ Add Icon" chip on the screen
      onSelected: onIconSelected,
      itemBuilder: (BuildContext context) {
        List<PopupMenuEntry<IconData>> menuItems = [];
        
        iconCategories.forEach((categoryName, icons) {
          // Add Category Header
          menuItems.add(
            PopupMenuItem<IconData>(
              enabled: false,
              child: Text(categoryName, style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
            ),
          );
          
          // Add Icons
          icons.forEach((name, iconData) {
            menuItems.add(
              PopupMenuItem<IconData>(
                value: iconData,
                child: Row(
                  children: [
                    const SizedBox(width: 8),
                    Icon(iconData, color: Colors.white, size: 20),
                    const SizedBox(width: 12),
                    Text(name, style: const TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            );
          });
          
          // Add a divider between categories
          menuItems.add(const PopupMenuDivider());
        });
        
        // Remove the very last divider to keep the bottom clean
        if (menuItems.isNotEmpty) menuItems.removeLast();
        
        return menuItems;
      },
    );
  }
}