import 'package:flutter/material.dart';
import 'moving_flow_background.dart';
import 'glass_sidebar.dart';

void main() {
  runApp(const SuperWaveApp());
}

class SuperWaveApp extends StatelessWidget {
  const SuperWaveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SuperWave',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Background layer — the glass will blur/refract this
            const MovingFlowBackground(),
            // Glass sidebar floating on top
            const SafeArea(
              child: Align(
                alignment: Alignment.centerLeft,
                child: GlassSidebar(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
