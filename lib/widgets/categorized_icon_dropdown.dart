import 'package:flutter/material.dart';

class CategorizedIconDropdown extends StatelessWidget {
  final String selectedIconName;
  final Function(String, IconData) onIconSelected;

  CategorizedIconDropdown({
    Key? key,
    required this.selectedIconName,
    required this.onIconSelected,
  }) : super(key: key);

  // --- We moved the massive library safely out of the main screen! ---
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
    // Flatten our categories into a list of DropdownMenuItems
    List<DropdownMenuItem<String>> iconDropdownItems = [];
    iconCategories.forEach((categoryName, icons) {
      iconDropdownItems.add(
        DropdownMenuItem(
          value: null, 
          enabled: false,
          child: Text(categoryName, style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
        ),
      );
      icons.forEach((name, iconData) {
        iconDropdownItems.add(
          DropdownMenuItem(
            value: name,
            child: Row(
              children: [
                const SizedBox(width: 16),
                Icon(iconData, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Text(name),
              ],
            ),
          ),
        );
      });
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Choose Icon", style: TextStyle(color: Colors.grey, fontSize: 12)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(12)),
          child: DropdownButton<String>(
            value: selectedIconName,
            isExpanded: true,
            underline: const SizedBox(),
            dropdownColor: Colors.grey[900],
            items: iconDropdownItems,
            onChanged: (String? newName) {
              if (newName == null) return; // User tapped a category header
              
              // Find the IconData and pass it back to the parent
              for (var category in iconCategories.values) {
                if (category.containsKey(newName)) {
                  onIconSelected(newName, category[newName]!);
                  break;
                }
              }
            },
          ),
        ),
      ],
    );
  }
}