import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt; // Import speech_to_text
import 'package:visionpay/screens/paynumber_screen.dart';
import 'package:visionpay/screens/scan_pay_screen.dart';


Future<void> main() async {
  // Ensure that plugin services are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Obtain a list of the available cameras on the device.
  final cameras = await availableCameras();
  final firstCamera = cameras.first;

  runApp(MyApp(camera: firstCamera));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.camera});

  final CameraDescription camera;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VisionPay',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: Colors.grey[100],
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: HomeScreen(camera: camera),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.camera});

  final CameraDescription camera;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _pageIndex = 0;
  final GlobalKey<CurvedNavigationBarState> _bottomNavigationKey = GlobalKey();

  // Pages for the bottom navigation bar
  late final List<Widget> _pages;

  // Speech-to-text variables for the home screen
  late stt.SpeechToText _speech;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    // Initialize the speech instance for the home screen
    _speech = stt.SpeechToText();
    
    _pages = [
      // Pass the camera object to the grid page
      HomeScreenGrid(camera: widget.camera),
      // Placeholder pages for other tabs
      const Center(child: Text('History Page', style: TextStyle(fontSize: 24, color: Colors.black54))),
      const Center(child: Text('Settings Page', style: TextStyle(fontSize: 24, color: Colors.black54))),
    ];
  }

  @override
  void dispose() {
    _speech.stop(); // Ensure speech is stopped when widget is disposed
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Allows the body to go behind the transparent nav bar
      appBar: AppBar(
        title: const Text(
          'VisionPay',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.deepPurple,
        elevation: 5,
        actions: [
          // Only show the microphone button on the Home Page (index 0)
          if (_pageIndex == 0)
            IconButton(
              icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
              color: Colors.white,
              tooltip: 'Tap to speak command',
              onPressed: _listen, // Call the listening function
            ),
        ],
      ),
      // The body now switches based on the selected page index
      body: _pages[_pageIndex],
      bottomNavigationBar: CurvedNavigationBar(
        key: _bottomNavigationKey,
        index: 0,
        height: 60.0,
        // The icons for the navigation bar
        items: const <Widget>[
          Icon(Icons.home, size: 30, color: Colors.white),
          Icon(Icons.history, size: 30, color: Colors.white),
          Icon(Icons.settings, size: 30, color: Colors.white),
        ],
        color: Colors.deepPurple,
        buttonBackgroundColor: Colors.deepPurple,
        backgroundColor: Colors.transparent, // Make it transparent to show body behind
        animationCurve: Curves.easeInOut,
        animationDuration: const Duration(milliseconds: 400),
        onTap: (index) {
          setState(() {
            _pageIndex = index;
          });
        },
        letIndexChange: (index) => true,
      ),
    );
  }

  /// --- Speech Recognition and Command Handling Logic ---

  /// Handles starting and stopping the speech listener
  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (status) {
          print('onStatus: $status');
          // Automatically stop listening when speech ends
          if (status == 'notListening') {
            setState(() => _isListening = false);
          }
        },
        onError: (error) {
           print('onError: $error');
           setState(() => _isListening = false);
        },
      );

      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (result) {
            // Check the final recognized words and process the command
            if (result.finalResult && result.recognizedWords.isNotEmpty) {
              _handleCommand(result.recognizedWords);
            }
          },
        );
      }
    } else {
       // If user taps the button while already listening, stop it.
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  /// Processes the recognized text and navigates to the correct screen
  void _handleCommand(String command) {
    String lowerCommand = command.toLowerCase();
    Widget? screenToNavigate; // Nullable widget to hold the target screen

    print('Command received: $command'); // For debugging

    // Check for keywords to navigate
    if (lowerCommand.contains('scan') || lowerCommand.contains('qr')) {
      screenToNavigate = ScanAndPayScreen(camera: widget.camera);
    } else if (lowerCommand.contains('number') || lowerCommand.contains('pay number')) {
      screenToNavigate = const PayContactsScreen();
    // } else if (lowerCommand.contains('bank') || lowerCommand.contains('transfer')) {
    //   screenToNavigate = const BankTransferScreen();
    // } else if (lowerCommand.contains('balance') || lowerCommand.contains('check balance')) {
    //   screenToNavigate = const CheckBalanceScreen();
    }

    // If a match was found, push the new screen
    if (screenToNavigate != null && mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => screenToNavigate!),
      );
    } else {
      // Optional: Give feedback if the command wasn't understood
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Command not recognized: '$command'")),
      );
    }
  }
}

// --- HomeScreenGrid Widget (No Changes) ---
// This widget remains the same as before.
class HomeScreenGrid extends StatelessWidget {
  const HomeScreenGrid({super.key, required this.camera});

  final CameraDescription camera;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
        children: <Widget>[
          _buildGridButton(context, 'Scan & Pay', Icons.qr_code_scanner),
          _buildGridButton(context, 'Pay a Number', Icons.contacts),
          _buildGridButton(context, 'Bank Transfer', Icons.account_balance),
          _buildGridButton(context, 'Check Balance', Icons.wallet_outlined),
        ],
      ),
    );
  }

  Widget _buildGridButton(BuildContext context, String title, IconData icon) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.deepPurple,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        elevation: 4,
        shadowColor: Colors.grey.withValues(alpha: .2),
        padding: const EdgeInsets.all(16),
      ),
      onPressed: () {
        Widget screen;
        switch (title) {
          case 'Scan & Pay':
            screen = ScanAndPayScreen(camera: camera);
            break;
          case 'Pay Contacts':
            screen = const PayContactsScreen();
            break;
          // case 'Bank Transfer':
          //   screen = const BankTransferScreen();
          //   break;
          // case 'Check Balance':
          //   screen = const CheckBalanceScreen();
          //   break;
          default:
            return;
        }
        Navigator.of(context).push(MaterialPageRoute(builder: (context) => screen));
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(icon, size: 40.0),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}