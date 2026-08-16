import 'package:flutter/material.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';
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
        body: LiquidGlassView(
          backgroundWidget: const MovingFlowBackground(),
          child: const SafeArea(
            child: Align(
              alignment: Alignment.centerLeft,
              child: GlassSidebar(),
            ),
          ),
        ),
      ),
    );
  }
}




