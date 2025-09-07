import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_tts/flutter_tts.dart'; // Import flutter_tts

class ScanAndPayScreen extends StatefulWidget {
  const ScanAndPayScreen({
    super.key,
    required this.camera,
  });

  final CameraDescription camera;

  @override
  State<ScanAndPayScreen> createState() => _ScanAndPayScreenState();
}

class _ScanAndPayScreenState extends State<ScanAndPayScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  // Plugin Instances
  final LocalAuthentication _auth = LocalAuthentication();
  final FlutterTts _flutterTts = FlutterTts(); // Add FlutterTts instance

  // State Management
  bool _isScreenAuthenticated = false; // Tracks if the screen itself is unlocked

  @override
  void initState() {
    super.initState();
    // Start the authentication process to unlock the screen view
    _authenticateScreen();

    // Initialize camera controller
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.medium,
    );
    _initializeControllerFuture = _controller.initialize();

    // Set up TTS completion handler to trigger payment authentication
    _flutterTts.setCompletionHandler(() {
      _authenticatePayment();
    });
  }

  /// Authenticates the user to unlock and view the camera screen.
  Future<void> _authenticateScreen() async {
    try {
      bool authenticated = await _auth.authenticate(
        localizedReason: 'Scan your fingerprint to access the camera',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
      if (mounted) {
        setState(() {
          _isScreenAuthenticated = authenticated;
        });
      }
    } on PlatformException catch (e) {
      print(e);
      // Handle error (e.g., user has no biometrics set up)
    }
  }

  /// This is called when the user taps the camera button to initiate a payment.
  void _initiatePayment() {
    // Show feedback that the process has started
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Processing payment...')),
    );
    // Speak the confirmation message. The TTS completion handler will trigger authentication.
    _flutterTts.speak("Paying to Reliance Digital");
  }

  /// Triggers biometric authentication for the payment itself.
  Future<void> _authenticatePayment() async {
    try {
      bool authenticated = await _auth.authenticate(
        localizedReason: 'Confirm payment to Reliance Digital',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (mounted) {
        final message = authenticated
            ? 'Success! Payment to Reliance Digital authorized.'
            : 'Authentication failed. Payment cancelled.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: authenticated ? Colors.green : Colors.red,
          ),
        );
      }
    } on PlatformException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error during authentication: ${e.message}")),
      );
    }
  }


  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan & Pay', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurple,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      // Conditionally build the UI based on initial screen authentication
      body: _isScreenAuthenticated ? _buildCameraPreview() : _buildAuthPrompt(),
    );
  }

  /// Widget to show if the user has NOT unlocked the screen yet.
  Widget _buildAuthPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.fingerprint, size: 80, color: Colors.deepPurple),
          const SizedBox(height: 20),
          const Text(
            'Authentication Required',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'Please scan your fingerprint to continue.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            icon: const Icon(Icons.fingerprint),
            label: const Text('Authenticate'),
            onPressed: _authenticateScreen, // Allow user to retry
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// Widget to show once the user has unlocked the screen.
  Widget _buildCameraPreview() {
    return FutureBuilder<void>(
      future: _initializeControllerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 300,
                  height: 300,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15.0),
                    child: CameraPreview(_controller),
                  ),
                ),
                Positioned(
                  bottom: 10,
                  child: FloatingActionButton(
                    onPressed: _initiatePayment, // Call the new payment flow
                    backgroundColor: Colors.deepPurple,
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 30),
                  ),
                ),
              ],
            ),
          );
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}
