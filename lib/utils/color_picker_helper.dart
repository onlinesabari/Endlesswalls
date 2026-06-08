import 'package:flutter/material.dart';

class ColorPickerHelper {
  static void show({
    required BuildContext context,
    required Color initialColor,
    required Function(Color) onColorChanged,
    String title = "Select Color",
  }) {
    // Convert initial color to HSV for the sliders
    HSVColor hsv = HSVColor.fromColor(initialColor);
    double h = hsv.hue;
    double s = hsv.saturation;
    double v = hsv.value;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, 
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 24),
                  
                  // Live Preview Circle
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: HSVColor.fromAHSV(1.0, h, s, v).toColor(),
                      border: Border.all(color: Colors.white24, width: 2),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Hue Slider (The Rainbow)
                  _buildSlider(
                    label: "HUE",
                    value: h,
                    min: 0,
                    max: 360,
                    onChanged: (val) {
                      setModalState(() => h = val);
                      onColorChanged(HSVColor.fromAHSV(1.0, h, s, v).toColor());
                    },
                  ),

                  // Saturation Slider (The Intensity)
                  _buildSlider(
                    label: "SATURATION",
                    value: s,
                    min: 0,
                    max: 1,
                    onChanged: (val) {
                      setModalState(() => s = val);
                      onColorChanged(HSVColor.fromAHSV(1.0, h, s, v).toColor());
                    },
                  ),

                  // Value Slider (The Brightness)
                  _buildSlider(
                    label: "BRIGHTNESS",
                    value: v,
                    min: 0,
                    max: 1,
                    onChanged: (val) {
                      setModalState(() => v = val);
                      onColorChanged(HSVColor.fromAHSV(1.0, h, s, v).toColor());
                    },
                  ),

                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text("CONFIRM"),
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  static Widget _buildSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required Function(double) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10, letterSpacing: 1.2)),
        Slider(
          value: value,
          min: min,
          max: max,
          activeColor: Colors.white,
          inactiveColor: Colors.white10,
          onChanged: onChanged,
        ),
      ],
    );
  }
}