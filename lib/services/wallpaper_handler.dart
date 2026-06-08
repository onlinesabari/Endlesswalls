import 'dart:io';
import 'package:wallpaper_manager_plus/wallpaper_manager_plus.dart';
import 'package:gal/gal.dart';

class WallpaperHandler {

  static const int homeScreen = 1;
  static const int lockScreen = 2;
  static const int bothScreens = 3;
  
  // Sets the wallpaper to the device
  static Future<void> setWallpaper(File imageFile, int location) async {
    await WallpaperManagerPlus().setWallpaper(imageFile, location);
  }

  // Saves the wallpaper to the user's photo gallery
  static Future<void> saveToGallery(File imageFile) async {
    bool hasAccess = await Gal.hasAccess();
    if (!hasAccess) await Gal.requestAccess();
    await Gal.putImage(imageFile.path);
  }
}