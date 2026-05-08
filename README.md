# ProgressBuddy - iOS Workout Tracker

A premium, lightweight workout tracking application built with SwiftUI, Core Data, and Firebase. Designed for simplicity, performance, and complete data ownership.

---

## 🌟 Why Workout Tracker?

In a world of bloated fitness apps filled with subscriptions, ads, and forced social networks, **Workout Tracker** stands out by focusing on what actually matters: your progress.

### The "Lightweight" Advantage
- **Minimal Footprint**: No unnecessary assets or background processes.
- **Privacy First**: Your data is stored locally by default. No hidden tracking or analytics.
- **Account-Free**: Backup and sync your data using a simple unique ID—no email or password required.
- **Bring Your Own Cloud**: Use your own Firebase project for backups, ensuring you own your data infrastructure.

### Key Benefits
- **Zero Friction**: Start logging your workout in seconds with a streamlined UI.
- **Visual Clarity**: Beautifully integrated charts and a custom calendar view to visualize your journey.
- **Robust Sync**: Securely backup your data to the cloud and restore it across devices seamlessly.
- **iCloud Integrated**: Uses Apple Keychain with iCloud synchronization to securely store your cloud credentials. This ensures your app automatically remembers your settings even if you delete and reinstall the app.

---

## 📱 Screenshots

<p align="center">
  <img src="App_Icon_Reference/screenshots/home.png" width="200" alt="Home Screen">
  <img src="App_Icon_Reference/screenshots/workout.png" width="200" alt="Workout Tracking">
  <img src="App_Icon_Reference/screenshots/progress.png" width="200" alt="Progress Charts">
  <img src="App_Icon_Reference/screenshots/widgets.png" width="200" alt="iOS Widgets">
</p>

## ✨ Key Features

- **Fluid UI**: Apple-inspired design with smooth transitions and haptic feedback.
- **Workout Splits**: Create and manage custom workout splits (Push/Pull/Legs, etc.).
- **Smart Tracking**: Support for Strength Training, Cardio (with optional seconds), Flexibility, and Bodyweight exercises.
- **Progress Visualization**: Dynamic charts powered by Swift Charts to track your gains over time.
- **Cloud Sync**: Optional Firebase integration to back up your data and sync across devices.
- **Apple Integration**: Keychain-backed credentials and native iOS Widgets.
- **Tab State Preservation**: Never lose your in-progress workout log when switching tabs.
- **"Click Back"**: Quickly return to root views by tapping the active tab icon.

## 🧩 iOS Widgets

ProgressBuddy includes two native widgets to keep you motivated and informed:
1. **Workout Calendar**: View your recent workout history and upcoming schedule at a glance.
2. **Motivational Quotes**: Stay inspired with daily fitness quotes directly on your home screen.

## 🛠 Setup & Installation

### Prerequisites
- **Mac** running macOS.
- **Xcode 15+** installed.
- **iOS Device** (iOS 17.0+) or Simulator.

### Option 1: Development (Xcode)
## Step 1
1. Clone the repository.
2. Open `WorkoutTracker.xcodeproj` in Xcode.
3. Configure your **Development Team** in Signing & Capabilities for both the app and widget targets.
4. Press `Cmd + R` to Build and Run.

## Step 2: Configure Signing & Capabilities (Required for Physical Devices)
To run the app on your physical iPhone, you must sign it with your Apple ID:
1. In the Xcode Project Navigator (left sidebar), select the **WorkoutTracker** project (the blue icon at the top).
2. Select the **WorkoutTracker** target under the "Targets" section.
3. Go to the **Signing & Capabilities** tab.
4. Click **Add Account...** and sign in with your Apple ID (if you haven't already).
5. In the **Team** dropdown, select your name (e.g., "Your Name (Personal Team)").
6. **Bundle Identifier**: Ensure this is unique. If you get an error, change it slightly (e.g., add your initials: `com.yourname.WorkoutTracker.custom`).

## Step 3: Connect & Run on Your Local Device
1. Connect your iPhone to your Mac using a USB-C or Lightning cable.
2. In the Xcode toolbar (at the top), click on the device selector (next to the Play button) and select your **physical iPhone**.
3. Press **Cmd + R** (or click the Play button) to build and install.
4. **Trust the App**: On your iPhone, you will likely see a "Untrusted Developer" popup.
   - Go to **Settings > General > VPN & Device Management**.
   - Tap on your Apple ID under "Developer App".
   - Tap **Trust [Your Apple ID]**.
5. Launch the app from your home screen!

---

### Option 2: Sideloading (.ipa)
## 🏗 Building the .ipa

You can generate a distributable `.ipa` file using Fastlane:

```bash
# Install dependencies
bundle install

# Build the .ipa (includes main app and widgets)
bundle exec fastlane build_ipa
```

Alternatively, use Xcode:
1. Product > Archive.
2. Distribute App > Custom > Export.

## Step 3: Install .ipa
If you have an `.ipa` file, you can install it using **Sideloadly**:
1. Download [Sideloadly](https://sideloadly.io/).
2. Connect your iPhone to your Mac/PC.
3. Drag the `WorkoutTracker.ipa` into Sideloadly.
4. Enter your Apple ID and click **Start**.
5. Once installed, go to **Settings > General > VPN & Device Management** on your iPhone and trust your developer profile.


## 🔥 Firebase Configuration

This app uses a "Dynamic Configuration" approach. Instead of hardcoding a `GoogleService-Info.plist`, you can configure your own Firebase project directly within the app settings.

### 1. Create a Firebase Project
1. Go to the [Firebase Console](https://console.firebase.google.com/).
2. Create a new project named "Workout Tracker".
3. Add an **iOS App** to the project. (You can use any bundle ID, e.g., `com.yourname.WorkoutTracker`).
4. Enable **Firestore Database** in test mode or with appropriate security rules.

### 2. Enter Credentials in App
1. Launch the app on your device/simulator.
2. Navigate to the **Settings** tab.
3. Expand the **Firebase Project Credentials** section.
4. Copy and paste the following from your Firebase project settings:
   - **API Key**
   - **Project ID**
   - **Google App ID**
   - **GCM Sender ID**
5. Tap **Save & Connect**.

## 🔒 Security & Privacy

- **Data Privacy**: Your workout data stays on your device (Core Data) unless you explicitly enable Firebase Sync.
- **Secure Storage**: Firebase credentials are stored securely in the Apple Keychain with iCloud sync support.

---

## Build with
- **Language**: Swift 5.9+
- **Framework**: SwiftUI
- **Persistence**: Core Data
- **Backend**: Firebase Firestore
- **Security**: Apple Keychain (SecItem)
- **Animations**: Lottie for iOS
- **Charts**: Swift Charts Framework

---

## 📄 License
This project is for personal use and demonstration. Check the repository for specific license details.

---
*Created by Shivam Goel*