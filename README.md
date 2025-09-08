# VisionPay: Voice & Gesture Controlled Payments

VisionPay is a modern, proof-of-concept **Flutter application** designed to explore a seamless, hands-free payment experience.  
It integrates **voice commands**, **swipe gestures**, and **biometric security** to allow users to navigate and perform transactions with ease.  

This project is built for **visually impaired users** and for anyone seeking a faster, more intuitive way to manage payments.

---

## ✨ Features

- **Biometric Security**  
  App is locked on startup, requiring Fingerprint or Face Authentication to open. Sensitive screens are also individually secured.

- **Voice-Controlled Navigation**  
  Long-press anywhere on the home screen to activate the microphone and navigate by speaking commands like  
  `"Scan and Pay"` or `"Check Balance"`.

- **Gesture Navigation**  
  On the home screen:  
  - Swipe right → instantly open **Scan & Pay**  
  - Swipe left → open **Pay by Number**  

- **Conversational Payments**  
  - **Scan & Pay**: Microphone auto-activates to ask for the amount, then confirms with biometrics.  
  - **Pay by Number**: A multi-step voice-guided process asks for the phone number and amount before final biometric confirmation.  

- **Modern UI/UX**  
  Sleek, animated, and intuitive screens for checking account balance, viewing transaction history, and performing bank transfers.  

- **Native Integration**  
  Utilizes platform-native features for haptic feedback, camera access, and biometric security.

---

## 🛠️ Setup and Installation

Follow these instructions to get the **VisionPay** project running locally.

### Prerequisites
- Install the [Flutter SDK](https://docs.flutter.dev/get-started/install).  
- Have an Android device or emulator ready.  

### Step 1: Clone the Repository
```bash
  git clone git@github.com:<username>/visionpay.git
  cd visionpay
```

### Step 2: Install Dependencies

```bash
  flutter pub get
```

### Step 3: Run the Application

Connect your Android device (or start an emulator) and run:
```bash
  flutter run
```

### 📁 Project Structure
```bash
visionpay/
├── lib/
│   ├── main.dart               # App entry point
│   ├── home_screen.dart        # Main screen: nav, lock logic, voice/gesture handling
│   ├── screens/
│   │   ├── scan_pay_screen.dart
│   │   ├── paynumber_screen.dart
│   │   ├── account_screen.dart
│   │   ├── bank_transfer_screen.dart
│   │   └── transactions_screen.dart

```
---
### 🚀 Future Scope:
- Multi-language voice support
- QR code + NFC integration
- Cloud backup for transaction history
---
