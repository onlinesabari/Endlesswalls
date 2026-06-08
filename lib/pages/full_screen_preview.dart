import 'dart:io';
import 'package:flutter/material.dart';
import 'package:wallpaper_manager_plus/wallpaper_manager_plus.dart';
import '../services/wallpaper_handler.dart';

class FullScreenPreview extends StatefulWidget {
  final File imageFile;
  const FullScreenPreview({Key? key, required this.imageFile}) : super(key: key);

  @override
  State<FullScreenPreview> createState() => _FullScreenPreviewState();
}

class _FullScreenPreviewState extends State<FullScreenPreview> {
  bool isWorking = false;

  Future<void> _handleSetWallpaper() async {
    setState(() => isWorking = true);
    try {
      await WallpaperHandler.setWallpaper(widget.imageFile, WallpaperManagerPlus.homeScreen);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Wallpaper Applied!')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => isWorking = false);
    }
  }

  Future<void> _handleSaveToGallery() async {
    setState(() => isWorking = true);
    try {
      await WallpaperHandler.saveToGallery(widget.imageFile);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved to Photos!')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => isWorking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(widget.imageFile, fit: BoxFit.cover),
          
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top Bar with Exit Button
              Container(
                padding: const EdgeInsets.only(top: 50, left: 16),
                alignment: Alignment.topLeft,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black54, Colors.transparent],
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  ),
                ),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 32),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              
              // Bottom Bar with Action Buttons
              Container(
                padding: const EdgeInsets.fromLTRB(24, 40, 24, 40),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Colors.black87],
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white54),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: isWorking ? null : _handleSaveToGallery,
                        icon: const Icon(Icons.download),
                        label: const Text('SAVE'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: isWorking ? null : _handleSetWallpaper,
                        child: isWorking
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                            : const Text('SET WALLPAPER', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ],
      ),
    );
  }
}