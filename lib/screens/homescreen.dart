import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:local_auth/local_auth.dart';
import 'package:visionpay/screens/account_screen.dart';
import 'package:visionpay/screens/bank_transfer.dart';
import 'package:visionpay/screens/paynumber_screen.dart';
import 'package:visionpay/screens/scan_pay_screen.dart';
import 'package:visionpay/screens/transactions_screen.dart';

// Import the screen files

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.camera});

  final CameraDescription camera;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Plugin Instances
  final LocalAuthentication _auth = LocalAuthentication();
  late stt.SpeechToText _speech;

  // State Management
  int _pageIndex = 0;
  bool _isAppAuthenticated = false; // Tracks if the entire app is unlocked
  bool _isListening = false;
  late final List<Widget> _pages;
  final GlobalKey<CurvedNavigationBarState> _bottomNavigationKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Authenticate the app on startup
    _authenticateApp();

    _speech = stt.SpeechToText();

    _pages = [
      HomePageContent(camera: widget.camera),
      const Center(
          child: Text('History Page',
              style: TextStyle(fontSize: 24, color: Colors.black54))),
      const Center(
          child: Text('Settings Page',
              style: TextStyle(fontSize: 24, color: Colors.black54))),
    ];
  }

  /// Authenticates the user to unlock and use the app.
  Future<void> _authenticateApp() async {
    try {
      bool authenticated = await _auth.authenticate(
        localizedReason: 'Please authenticate to open VisionPay',
        options: const AuthenticationOptions(
          stickyAuth: true, // The prompt will not dismiss until the app is closed
          biometricOnly: true, // Requires biometrics, no PIN fallback
        ),
      );
      if (mounted) {
        setState(() {
          _isAppAuthenticated = authenticated;
        });
        // This is the key change: The app no longer automatically listens after login.
      }
    } on PlatformException catch (e) {
      print(e);
      // Handle error, e.g., show a message that biometrics are required
    }
  }

  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Conditionally build the UI. Show the main app only if authenticated.
    return _isAppAuthenticated ? _buildMainApp() : _buildLockScreen();
  }

  /// Builds the main application UI after successful authentication.
  Widget _buildMainApp() {
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: const Text(
          'VisionPay',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.deepPurple,
        elevation: 5,
        actions: [
          if (_pageIndex == 0)
            IconButton(
              icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
              color: Colors.white,
              tooltip: 'Tap to speak command',
              onPressed: _listen,
            ),
        ],
      ),
      body: GestureDetector(
        onLongPress: () {
          // Only handle long press on the home page (index 0)
          if (_pageIndex == 0 && !_isListening) {
            // Vibrate first to give immediate feedback, then listen.
            HapticFeedback.vibrate();
            _listen();
          }
        },
        onHorizontalDragEnd: (details) {
          // Only handle swipes on the home page (index 0)
          if (_pageIndex == 0) {
            _handleSwipe(details);
          }
        },
        // This container ensures the GestureDetector covers the entire body area
        child: Container(
          color: Colors.transparent, // Invisible, but captures gestures
          child: _pages[_pageIndex],
        ),
      ),
      bottomNavigationBar: CurvedNavigationBar(
        key: _bottomNavigationKey,
        index: 0,
        height: 60.0,
        items: const <Widget>[
          Icon(Icons.home, size: 30, color: Colors.white),
          Icon(Icons.history, size: 30, color: Colors.white),
          Icon(Icons.settings, size: 30, color: Colors.white),
        ],
        color: Colors.deepPurple,
        buttonBackgroundColor: Colors.deepPurple,
        backgroundColor: Colors.transparent,
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

  /// Builds the lock screen UI shown before authentication.
  Widget _buildLockScreen() {
    return Scaffold(
      backgroundColor: Colors.deepPurple,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock, size: 80, color: Colors.white),
            const SizedBox(height: 20),
            const Text(
              'VisionPay is Locked',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            const SizedBox(height: 10),
            const Text(
              'Please authenticate to continue.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              icon: const Icon(Icons.fingerprint),
              label: const Text('Authenticate'),
              onPressed: _authenticateApp, // Allow user to retry
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.deepPurple,
              ),
            ),
          ],
        ),
      ),
    );
  }

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
        },
      );

      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (result) {
            if (result.finalResult && result.recognizedWords.isNotEmpty) {
              _handleCommand(result.recognizedWords);
            }
          },
        );
      } else {
        // Provide feedback if speech recognition is not available (e.g., permissions denied)
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Microphone permission is required for voice commands.')),
          );
        }
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  /// Handles navigation based on swipe gestures.
  void _handleSwipe(DragEndDetails details) {
    // A velocity threshold to prevent accidental swipes.
    const double minVelocity = 100.0;

    // Swipe from right to left (negative velocity) -> Go to Pay Number
    if (details.primaryVelocity! < -minVelocity) {
      Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const PayContactsScreen()));
    }
    // Swipe from left to right (positive velocity) -> Go to Scan & Pay
    else if (details.primaryVelocity! > minVelocity) {
      Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => ScanAndPayScreen(camera: widget.camera)));
    }
  }

  void _handleCommand(String command) {
    // Immediately stop the speech engine and update the UI state.
    // This ensures that the state is reset before navigating away or showing a snackbar.
    _speech.stop();
    setState(() => _isListening = false);

    String lowerCommand = command.toLowerCase();
    Widget? screenToNavigate;

    if (lowerCommand.contains('scan') || lowerCommand.contains('qr')) {
      screenToNavigate = ScanAndPayScreen(camera: widget.camera);
    } else if (lowerCommand.contains('number') ||
        lowerCommand.contains('pay number')) {
      screenToNavigate = const PayContactsScreen();
    } else if (lowerCommand.contains('balance') || lowerCommand.contains('check balance')) {
      screenToNavigate = const CheckBalanceScreen();
    }

    if (screenToNavigate != null && mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => screenToNavigate!),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Command not recognized: '$command'")),
      );
    }
  }
}

class HomePageContent extends StatelessWidget {
  const HomePageContent({super.key, required this.camera});

  final CameraDescription camera;

  @override
  Widget build(BuildContext context) {
    // This allows the content to scroll if it overflows on smaller screens
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Dynamic Header
            FadeInAnimation(
              delay: 0.5,
              child: _buildHeader(context),
            ),
            // ADDED: A clean divider for visual separation
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Divider(height: 1, thickness: 1),
            ),

            // 2. Primary Action Card
            FadeInAnimation(
              delay: 0.8,
              child: _buildPrimaryActionCard(context, camera),
            ),
            const SizedBox(height: 24),

            // 3. Section Title
            FadeInAnimation(
              delay: 1.1,
              child: Text(
                'More Options',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),

            // 4. Modernized Grid for other actions
            FadeInAnimation(
              delay: 1.4,
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16.0,
                mainAxisSpacing: 16.0,
                shrinkWrap: true, // Important for nested scrolling
                physics:
                    const NeverScrollableScrollPhysics(), // Disables grid's own scrolling
                childAspectRatio: 1.4,
                children: <Widget>[
                  _buildFeatureCard(
                    context: context,
                    title: 'Pay a Number',
                    icon: Icons.onetwothree,
                    color: Colors.orange,
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => const PayContactsScreen())),
                  ),
                  _buildFeatureCard(
                    context: context,
                    title: 'Check Balance',
                    icon: Icons.wallet_outlined,
                    color: Colors.green,
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => const CheckBalanceScreen())),
                  ),
                  _buildFeatureCard(
                    context: context,
                    title: 'Bank Transfer',
                    icon: Icons.account_balance,
                    color: Colors.blue,
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => const BankTransferScreen())),
                  ),
                  _buildFeatureCard(
                    context: context,
                    title: 'Transactions',
                    icon: Icons.history,
                    color: Colors.pink,
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => const TransactionsScreen())),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Helper Widgets for Building the UI ---

  Widget _buildHeader(BuildContext context) {
    // A simple greeting. You can make this dynamic with user data.
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Good Evening,', // Updated greeting
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
            Text(
              'Akshay Krishna', // Replace with actual user name
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const CircleAvatar(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          child: Icon(Icons.person),
        ),
      ],
    );
  }

  Widget _buildPrimaryActionCard(
      BuildContext context, CameraDescription camera) {
    return InkWell(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => ScanAndPayScreen(camera: camera))),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [Colors.deepPurple.shade400, Colors.deepPurple.shade700],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.deepPurple.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Scan & Pay',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Pay any QR code instantly',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
            const Icon(Icons.qr_code_scanner, color: Colors.white, size: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Card(
        elevation: 0,
        color: color.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40.0, color: color),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

// A simple animation widget to fade in the UI elements
class FadeInAnimation extends StatefulWidget {
  final double delay;
  final Widget child;

  const FadeInAnimation({super.key, required this.delay, required this.child});

  @override
  State<FadeInAnimation> createState() => _FadeInAnimationState();
}

class _FadeInAnimationState extends State<FadeInAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
            begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    Future.delayed(Duration(milliseconds: (300 * widget.delay).round()), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}

