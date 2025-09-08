import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:local_auth/local_auth.dart';
import 'package:flutter_tts/flutter_tts.dart';

// Enum to manage the steps of the payment process
enum PaymentStep {
  idle,
  listeningForNumber,
  listeningForAmount,
  confirming,
}

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
  PaymentStep _currentStep = PaymentStep.idle;
  String _statusMessage = 'Press the button to start payment';
  String _detectedNumber = '';
  String _detectedAmount = '';

  @override
  void initState() {
    super.initState();
    // Start the payment flow automatically when the screen loads.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initiatePaymentFlow();
    });
  }

  /// 1. Starts the entire multi-step payment flow.
  Future<void> _initiatePaymentFlow() async {
    if (_currentStep != PaymentStep.idle) return;
    _listenForNumber();
  }

  /// 2. Asks for and listens for the 10-digit phone number.
  Future<void> _listenForNumber() async {
    setState(() {
      _currentStep = PaymentStep.listeningForNumber;
      _statusMessage = "Please say the 10-digit phone number...";
    });
    await _flutterTts.speak("Please say the 10-digit phone number");

    bool available = await _speech.initialize();
    if (available) {
      _speech.listen(onResult: (result) {
        if (result.finalResult) {
          _processNumber(result.recognizedWords);
        }
      });
    } else {
      _resetFlow("Speech recognition not available.");
    }
  }

  /// 3. Processes the recognized text to find a number.
  void _processNumber(String command) {
    final RegExp numRegExp = RegExp(r'\b\d{10}\b');
    final Match? match = numRegExp.firstMatch(command.replaceAll(' ', ''));

    if (match != null) {
      _detectedNumber = match.group(0)!;
      // Move to the next step: listening for the amount
      _listenForAmount();
    } else {
      _resetFlow("Did not recognize a 10-digit number. Please try again.");
    }
  }

  /// 4. Asks for and listens for the payment amount.
  Future<void> _listenForAmount() async {
    setState(() {
      _currentStep = PaymentStep.listeningForAmount;
      _statusMessage = "Now, please state the amount...";
    });
    await _flutterTts.speak("Now, please state the amount");

    bool available = await _speech.initialize();
    if (available) {
      _speech.listen(onResult: (result) {
        if (result.finalResult) {
          _processAmount(result.recognizedWords);
        }
      });
    } else {
      _resetFlow("Speech recognition not available.");
    }
  }

  /// 5. Processes the recognized text to find an amount and confirms.
  Future<void> _processAmount(String command) async {
    final RegExp numRegExp = RegExp(r'\d+(\.\d+)?');
    final Match? match = numRegExp.firstMatch(command);

    if (match != null) {
      _detectedAmount = match.group(0)!;
      setState(() {
        _currentStep = PaymentStep.confirming;
        _statusMessage =
            "Paying $_detectedAmount to $_detectedNumber. Please confirm.";
      });

      await _flutterTts
          .speak("Paying $_detectedAmount to the given Number. Please authenticate.");

      if (mounted) {
        await _authenticateAndFinalize();
      }
    } else {
      _resetFlow("Could not recognize an amount. Please try again.");
    }
  }

  /// 6. Triggers biometric auth and finalizes the transaction.
  Future<void> _authenticateAndFinalize() async {
    try {
      bool authenticated = await _auth.authenticate(
        localizedReason:
            'Confirm payment of $_detectedAmount to $_detectedNumber',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      final message = authenticated
          ? 'Successful Payment to $_detectedNumber.'
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
      await _flutterTts.speak("Authentication error.");
      print(e);
    } finally {
      // Reset the flow regardless of success or failure
      _resetFlow();
    }
  }

  /// Resets the payment state and provides user feedback if necessary.
  void _resetFlow([String? message]) {
    if (message != null) {
      _flutterTts.speak(message);
    }
    setState(() {
      _currentStep = PaymentStep.idle;
      _statusMessage = 'Press the button to start a new payment';
      _detectedNumber = '';
      _detectedAmount = '';
    });
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isListening = _currentStep == PaymentStep.listeningForNumber ||
        _currentStep == PaymentStep.listeningForAmount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pay by Number', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurple,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isListening
                    ? Icons.multitrack_audio
                    : Icons.mobile_friendly,
                size: 80,
                color: isListening ? Colors.redAccent : Colors.deepPurple,
              ),
              const SizedBox(height: 20),
              // Main status text
              Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 40),
              // Secondary details display
              if (_detectedNumber.isNotEmpty)
                Text(
                  "Number: $_detectedNumber",
                  style: const TextStyle(fontSize: 18, color: Colors.grey),
                ),
              if (_detectedAmount.isNotEmpty)
                Text(
                  "Amount: $_detectedAmount",
                  style: const TextStyle(fontSize: 18, color: Colors.grey),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.large(
        onPressed:
            _currentStep == PaymentStep.idle ? _initiatePaymentFlow : null,
        backgroundColor:
            _currentStep == PaymentStep.idle ? Colors.deepPurple : Colors.grey,
        child: Icon(
          isListening ? Icons.mic : Icons.play_arrow,
          color: Colors.white,
          size: 40,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}


