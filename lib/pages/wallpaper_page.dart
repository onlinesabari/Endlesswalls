import 'package:flutter/material.dart';
import 'emoji_studio.dart';
import 'vector_studio.dart';
import 'wave_studio.dart';

class WallpaperScreen extends StatelessWidget {
  const WallpaperScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Creator Studio', style: TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: "EMOJIS", icon: Icon(Icons.emoji_emotions)),
              Tab(text: "VECTOR ICONS", icon: Icon(Icons.category)),
              Tab(text: "WAVES", icon: Icon(Icons.waves)),
            ],
          ),
        ),
        body: const TabBarView(
          physics: NeverScrollableScrollPhysics(), // Prevents accidental swiping while using sliders
          children: [
            EmojiStudio(),
            VectorStudio(),
            WaveStudio(),
          ],
        ),
      ),
    );
  }
}