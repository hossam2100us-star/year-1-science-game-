import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const ScienceAdventureApp());
}

class ScienceAdventureApp extends StatelessWidget {
  const ScienceAdventureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Science Adventure',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFFF8EC),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2170B5)),
      ),
      home: const SetupWelcomeScreen(),
    );
  }
}

/// A Phase 0 device check, not the onboarding or a curriculum activity.
class SetupWelcomeScreen extends StatefulWidget {
  const SetupWelcomeScreen({super.key});

  @override
  State<SetupWelcomeScreen> createState() => _SetupWelcomeScreenState();
}

class _SetupWelcomeScreenState extends State<SetupWelcomeScreen> {
  bool _tapped = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Science Adventure',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF174F7F),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: const Color(0xFF2170B5),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _tapped
                              ? Icons.star_rounded
                              : Icons.waving_hand_rounded,
                          size: 64,
                          color: const Color(0xFF174F7F),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _tapped
                              ? 'Your screen is ready!'
                              : 'Hello, scientist!',
                          textAlign: TextAlign.center,
                          semanticsLabel: _tapped
                              ? 'Your screen is ready!'
                              : 'Hello, scientist!',
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF174F7F),
                          ),
                        ),
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed: () => setState(() => _tapped = !_tapped),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(220, 64),
                            backgroundColor: const Color(0xFF174F7F),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                          ),
                          icon: const Icon(Icons.touch_app_rounded, size: 28),
                          label: Text(
                            _tapped ? 'Try again' : 'Try a tap',
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Offline • Phone & tablet • Setup preview',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 22, color: Color(0xFF174F7F)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
