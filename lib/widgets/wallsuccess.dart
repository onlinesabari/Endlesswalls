import 'package:flutter/material.dart';

class SuccessOverlay extends StatefulWidget {
  const SuccessOverlay({Key? key}) : super(key: key);

  @override
  State<SuccessOverlay> createState() => _SuccessOverlayState();
}

class _SuccessOverlayState extends State<SuccessOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    // ElasticOut creates that 'bounce' effect when the checkmark appears
    _controller = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 800)
    );
    
    _scaleAnimation = CurvedAnimation(
      parent: _controller, 
      curve: Curves.elasticOut
    );
    
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Material widget is required here because Overlay adds it to a 
    // separate layer that might not have a default theme/text style.
    return Material(
      color: Colors.transparent,
      child: Center(
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.8),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.greenAccent.withOpacity(0.5), width: 2),
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 80),
                SizedBox(height: 10),
                Text("Applied!", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
              ],
            ),
          ),
        ),
      ),
    );
  }
}