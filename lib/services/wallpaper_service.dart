import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:wallpaper_manager_plus/wallpaper_manager_plus.dart';
import 'package:gal/gal.dart';

class WallpaperService {
  static String generateUrl(String emojis, Color bg, int density, int size, String rotation) {
    // 1. Convert the background color to a Hex string
    String bgHex = bg.value.toRadixString(16).substring(2, 8).toUpperCase();
    
    // 2. Encode the emojis so they safely travel through the URL (e.g., handles spaces/special characters)
    String encodedEmojis = Uri.encodeComponent(emojis);
    
    // 3. Add a timestamp to bypass caching when generating a new image
    int timestamp = DateTime.now().millisecondsSinceEpoch;
    
    return "https://vahanlog.ploxpop.com/api/wallpaper/doodle?emojis=$encodedEmojis&bg=$bgHex&density=$density&size=$size&rotation=$rotation&t=$timestamp";
  }

  static Future<void> setWallpaper(String url, int location) async {
    var file = await DefaultCacheManager().getSingleFile(url);
    await WallpaperManagerPlus().setWallpaper(file, location);
  }

  static Future<void> saveToGallery(String url) async {
    var file = await DefaultCacheManager().getSingleFile(url);
    bool hasAccess = await Gal.hasAccess();
    if (!hasAccess) await Gal.requestAccess();
    await Gal.putImage(file.path);
  }
}