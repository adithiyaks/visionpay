import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:local_auth/local_auth.dart';
import 'package:flutter_tts/flutter_tts.dart';

class PayContactsScreen extends StatefulWidget {
  const PayContactsScreen({super.key});

  @override
  State<PayContactsScreen> createState() => _PayContactsScreenState();
}

class _PayContactsScreenState extends State<PayContactsScreen> {
  // Plugin Instances
  final LocalAuthentication _auth = LocalAuthentication();
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();

  // State Management
  bool _isListening = false;
  String _recognizedText = 'Press the button and say, "Pay 1234567890"';
  String _statusMessage = '';
  String _detectedNumber = '';

  @override
  void initState() {
    super.initState();
    // Set up TTS to call authenticate() after speaking completes.
    _flutterTts.setCompletionHandler(() {
      if (_detectedNumber.isNotEmpty) {
        _authenticate();
      }
    });
  }

  /// Starts or stops the speech recognition listener.
  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (status) {
          if (status == 'notListening') {
            setState(() => _isListening = false);
          }
        },
        onError: (error) {
          setState(() => _isListening = false);
          _updateStatus("Speech recognition error.");
        },
      );
      if (available) {
        setState(() {
          _isListening = true;
          _statusMessage = "Listening...";
        });
        _speech.listen(
          onResult: (result) {
            setState(() {
              _recognizedText = result.recognizedWords;
            });
            // Once speech is final, process the command.
            if (result.finalResult) {
              _processSpeechCommand(result.recognizedWords);
            }
          },
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  /// Parses the speech result to find a number and trigger TTS.
  void _processSpeechCommand(String command) {
    // Regex to find a 10-digit number.
    // Removes spaces from the command to handle numbers spoken with pauses.
    final RegExp numRegExp = RegExp(r'\b\d{10}\b');
    final Match? match = numRegExp.firstMatch(command.replaceAll(' ', ''));

    if (match != null) {
      _detectedNumber = match.group(0)!;
      final confirmationMessage = "Paying to $_detectedNumber. Please authenticate.";
      
      setState(() {
        _statusMessage = "Number detected. Confirming...";
        _recognizedText = command; // Keep the full recognized text for context
      });

      // Speak the confirmation message. The completion handler will trigger authentication.
      _flutterTts.speak(confirmationMessage);
    } else {
      _updateStatus("No 10-digit number found in the command.");
      _detectedNumber = ''; // Reset detected number
    }
  }

  /// Triggers biometric authentication.
  Future<void> _authenticate() async {
    setState(() {
      _statusMessage = "Waiting for fingerprint...";
    });
    try {
      bool authenticated = await _auth.authenticate(
        localizedReason: 'Confirm payment to $_detectedNumber',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
      if (authenticated) {
        _updateStatus("Success! Payment to $_detectedNumber authorized.", isSuccess: true);
      } else {
        _updateStatus("Authentication failed. Payment cancelled.");
      }
    } on PlatformException catch (e) {
      _updateStatus("Error during authentication: ${e.message}");
    }
  }

  /// Helper to update the status message and reset state.
  void _updateStatus(String message, {bool isSuccess = false}) {
    setState(() {
      _statusMessage = message;
      if (isSuccess) {
        _recognizedText = "Payment Complete";
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pay Contacts', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurple,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Status Icon
              Icon(
                Icons.phonelink_ring,
                size: 80,
                color: _isListening ? Colors.redAccent : Colors.deepPurple,
              ),
              const SizedBox(height: 20),

              // Recognized Text Display
              Text(
                _recognizedText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 40),

              // Status Message Display
              Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.large(
        onPressed: _listen,
        backgroundColor: _isListening ? Colors.red : Colors.deepPurple,
        child: Icon(_isListening ? Icons.mic : Icons.mic_none, color: Colors.white, size: 40),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
