import 'dart:io';
import 'package:flutter/material.dart';
import '../services/wallpaper_handler.dart';
import '../widgets/wallsuccess.dart';

class WallpaperActions {
  static void showApplyMenu({
    required BuildContext context,
    required File? imageFile,
    required Function(bool) onLoading,
  }) {
    if (imageFile == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text("Wallpaper Options", 
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              ),
              _buildTile(context, Icons.home, "Set on Home Screen", 1, imageFile, onLoading),
              _buildTile(context, Icons.lock, "Set on Lock Screen", 2, imageFile, onLoading),
              _buildTile(context, Icons.devices, "Set on Both", 3, imageFile, onLoading),
              const Divider(color: Colors.white10),
              _buildSaveTile(context, imageFile, onLoading),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  static Widget _buildTile(BuildContext context, IconData icon, String label, int id, File file, Function(bool) onLoading) {
    return ListTile(
      leading: Icon(icon, color: Colors.blueAccent),
      title: Text(label, style: const TextStyle(color: Colors.white)),
      onTap: () {
        Navigator.pop(context);
        _executeApply(context, file, id, onLoading);
      },
    );
  }

  static Widget _buildSaveTile(BuildContext context, File file, Function(bool) onLoading) {
    return ListTile(
      leading: const Icon(Icons.download, color: Colors.greenAccent),
      title: const Text("Save to Gallery", style: TextStyle(color: Colors.white)),
      onTap: () async {
        Navigator.pop(context);
        onLoading(true);
        await WallpaperHandler.saveToGallery(file);
        onLoading(false);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Saved to Gallery!")));
        }
      },
    );
  }

  static Future<void> _executeApply(BuildContext context, File file, int id, Function(bool) onLoading) async {
    onLoading(true);
    try {
      await WallpaperHandler.setWallpaper(file, id);
      if (context.mounted) {
        final entry = OverlayEntry(builder: (context) => const SuccessOverlay());
        Overlay.of(context).insert(entry);
        await Future.delayed(const Duration(seconds: 2));
        entry.remove();
      }
    } finally {
      onLoading(false);
    }
  }
}