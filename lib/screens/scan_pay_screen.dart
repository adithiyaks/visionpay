import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

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
  final FlutterTts _flutterTts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();

  // State Management
  bool _isProcessingPayment = false;
  bool _isListeningForAmount = false;
  String _recognizedAmount = '';
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.high,
    );
    _initializeControllerFuture = _controller.initialize();
  }

  /// 1. Starts the entire payment flow.
  Future<void> _initiatePayment() async {
    if (_isProcessingPayment) return;
    setState(() {
      _isProcessingPayment = true;
      _statusMessage = "Please state the amount...";
    });

    await _flutterTts.speak("Please state the amount");
    _listenForAmount();
  }

  /// 2. Listens for the user to speak the amount.
  void _listenForAmount() async {
    bool available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'notListening' && _isListeningForAmount) {
          // If listening stops prematurely without a result, reset.
          _resetPaymentFlow("Did not catch that. Please try again.");
        }
      },
      onError: (error) => _resetPaymentFlow("Speech recognition error."),
    );

    if (available) {
      setState(() => _isListeningForAmount = true);
      _speech.listen(onResult: (result) {
        if (result.finalResult) {
          setState(() => _isListeningForAmount = false);
          _processAmount(result.recognizedWords);
        }
      });
    } else {
      _resetPaymentFlow("Speech recognition not available.");
    }
  }

  /// 3. Processes the recognized text to find a number and continue the flow.
  Future<void> _processAmount(String recognizedText) async {
    // A simple regex to extract numbers from the recognized text.
    final RegExp numRegExp = RegExp(r'\d+(\.\d+)?');
    final Match? match = numRegExp.firstMatch(recognizedText);

    if (match != null) {
      _recognizedAmount = match.group(0)!;
      setState(() {
        _statusMessage = "Confirming payment of $_recognizedAmount...";
      });

      await _flutterTts.speak("Paying $_recognizedAmount to Reliance Digital");

      if (mounted) {
        await _authenticatePayment();
      }
      _resetPaymentFlow(); // Reset after completion
    } else {
      _resetPaymentFlow("Could not recognize an amount. Please try again.");
    }
  }

  /// 4. Triggers biometric authentication for the payment.
  Future<void> _authenticatePayment() async {
    try {
      bool authenticated = await _auth.authenticate(
        localizedReason:
            'Confirm payment of $_recognizedAmount to Reliance Digital',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      final message = authenticated
          ? 'Success! Payment of $_recognizedAmount to Reliance Digital is Done.'
          : 'Authentication failed. Payment cancelled.';

      await _flutterTts.speak(message);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: authenticated ? Colors.green : Colors.red,
          ),
        );
      }
    } on PlatformException catch (e) {
      final errorMessage = "Authentication error: ${e.message}";
      await _flutterTts.speak(errorMessage);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    }
  }

  /// Resets the payment state and provides user feedback.
  void _resetPaymentFlow([String? message]) {
    if (message != null) {
      _flutterTts.speak(message);
    }
    setState(() {
      _isProcessingPayment = false;
      _isListeningForAmount = false;
      _statusMessage = '';
      _recognizedAmount = '';
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _flutterTts.stop();
    _speech.stop();
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
      body: _buildCameraPreview(),
    );
  }

  /// Widget that builds the camera view and payment button.
  Widget _buildCameraPreview() {
    return FutureBuilder<void>(
      future: _initializeControllerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 80.0),
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 350,
                    height: 400,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20.0),
                      child: CameraPreview(_controller),
                    ),
                  ),
                  // This overlay shows the status when listening for an amount
                  if (_isProcessingPayment)
                    Container(
                      width: 350,
                      height: 400,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isListeningForAmount
                                ? Icons.mic
                                : Icons.hourglass_empty,
                            color: Colors.white,
                            size: 60,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            _statusMessage,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  Positioned(
                    bottom: 10,
                    child: FloatingActionButton(
                      onPressed: _isProcessingPayment ? null : _initiatePayment,
                      backgroundColor:
                          _isProcessingPayment ? Colors.grey : Colors.deepPurple,
                      child: _isProcessingPayment
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Icon(Icons.camera_alt,
                              color: Colors.white, size: 40),
                    ),
                  ),
                ],
              ),
            ),
          );
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}

