import 'package:flutter/material.dart';
import 'emoji_studio.dart';
import 'vector_studio.dart';
import 'wave_studio.dart';
import 'geometry_studio.dart';
import 'aura_studio.dart'; 
import 'crystal_studio.dart';
import 'face_studio.dart';
import 'flow_studio.dart';
import 'quote_studio.dart';
import 'nature_studio.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  Widget _buildStudioCard(BuildContext context, String title, String subtitle, IconData icon, Color color, Widget destination) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => destination)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.8), color.withOpacity(0.4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white24, width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
              child: Icon(icon, color: Colors.white, size: 36),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 18),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('EndlessWalls', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Generative Design Suite", style: TextStyle(color: Colors.grey, fontSize: 14, letterSpacing: 1.2)),
            const SizedBox(height: 20),
            
            // 1. Aura Studio
            _buildStudioCard(
              context, 
              "Aura Studio", 
              "Soft glowing orbs and atmospheric bleeds", 
              Icons.vignette, 
              const Color(0xFF7B2CBF), 
              const AuraStudio()
            ),

            // 2. Crystal Studio 
            _buildStudioCard(
              context, 
              "Crystal Studio", 
              "Shattered glass and Voronoi tessellations", 
              Icons.diamond, 
              Colors.cyan, 
              const CrystalStudio()
            ),

            // 3. Geometry Studio
            _buildStudioCard(
              context, 
              "Geometry Studio", 
              "Precision shapes and glassy wireframes", 
              Icons.architecture, 
              const Color(0xFF2D6A4F), 
              const GeometryStudio()
            ),

            // 5. Face Studio (NEW)
            _buildStudioCard(
              context, 
              "Face Studio", 
              "Floating heads and radial Rangoli patterns", 
              Icons.face, 
              Colors.deepOrangeAccent, 
              const FaceStudio()
            ),

            // 6. Emoji Studio
            _buildStudioCard(
              context, 
              "Emoji Studio", 
              "Pattern designs using your favorite emojis", 
              Icons.emoji_emotions, 
              const Color(0xFFFF007F), 
              const EmojiStudio()
            ),

            // 7. Vector Studio
            _buildStudioCard(
              context, 
              "Vector Studio", 
              "Icon grids and custom color patterns", 
              Icons.category, 
              const Color(0xFF00F0FF), 
              const VectorStudio()
            ),

            // 8. Wave Studio
            _buildStudioCard(
              context, 
              "Wave Studio", 
              "Mathematical flowing lines and sine waves", 
              Icons.waves, 
              const Color(0xFFFFD700), 
              const WaveStudio()
            ),

            // 9. Flow Studio
            _buildStudioCard(
              context, 
              "Flow Studio", 
              "Swirling vector fields and fluid particles", 
              Icons.air, 
              const Color(0xFF00C9FF), 
              const FlowStudio()
            ),

            // 10. Typography Studio
            _buildStudioCard(
              context, 
              "Typography Studio", 
              "Matrix rain and scattered quotes", 
              Icons.text_fields, 
              const Color(0xFFE94057), 
              const QuoteStudio()
            ),

            // 11. Nature Studio
            _buildStudioCard(
              context, 
              "Nature Studio", 
              "Procedural trees, vines, and organic forms", 
              Icons.eco, 
              Colors.green, 
              const NatureStudio()
            ),
            
            const SizedBox(height: 40), // Bottom padding for smooth scrolling
          ],
        ),
      ),
    );
  }
}