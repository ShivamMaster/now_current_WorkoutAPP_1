# 🏋️‍♂️ Workout Tracker iOS

A professional, high-performance, and **lightweight** workout tracking application built for iOS. Designed for simplicity, privacy, and full control over your data.

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

## 🚀 Features

- **Workout Logging**: Track exercises, sets, reps, and weights with ease.
- **Dynamic Calendar**: A color-coded calendar view that tracks your workout splits (Push, Pull, Legs, etc.).
- **Progress Analytics**: Interactive charts powered by Swift Charts to monitor strength and volume trends.
- **Cloud Backup & Restore**: One-tap backup to Firebase Firestore.
- **Data Retention Policies**: Choose how long to keep data locally to save device space while keeping everything safe in the cloud.
- **"Click Back" Navigation**: A premium navigation feature allowing you to instantly return to the root view by tapping the active tab icon.
- **Dark Mode Support**: A sleek, system-integrated dark interface for late-night sessions.
- **Customizable Units**: Toggle between Metric (kg) and Imperial (lbs) units.

---

## 🛠 Setup & Installation

### Prerequisites
- **Mac** running macOS (latest version recommended).
- **Xcode** (latest version).
- **iOS Device or Simulator** (iOS 16.0+).

### Getting Started

#### 1. Open the Project
1. Clone this repository to your local machine.
2. Open the `WorkoutTracker.xcodeproj` file in Xcode.
3. Select your target device (iPhone or Simulator).
4. Press `Cmd + R` to Build and Run.

#### 2. Configure Signing & Capabilities (Required for Physical Devices)
To run the app on your physical iPhone, you must sign it with your Apple ID:
1. In the Xcode Project Navigator (left sidebar), select the **WorkoutTracker** project (the blue icon at the top).
2. Select the **WorkoutTracker** target under the "Targets" section.
3. Go to the **Signing & Capabilities** tab.
4. Click **Add Account...** and sign in with your Apple ID (if you haven't already).
5. In the **Team** dropdown, select your name (e.g., "Your Name (Personal Team)").
6. **Bundle Identifier**: Ensure this is unique. If you get an error, change it slightly (e.g., add your initials: `com.yourname.WorkoutTracker.custom`).

#### 3. Connect & Run on Your Local Device
1. Connect your iPhone to your Mac using a USB-C or Lightning cable.
2. In the Xcode toolbar (at the top), click on the device selector (next to the Play button) and select your **physical iPhone**.
3. Press **Cmd + R** (or click the Play button) to build and install.
4. **Trust the App**: On your iPhone, you will likely see a "Untrusted Developer" popup.
   - Go to **Settings > General > VPN & Device Management**.
   - Tap on your Apple ID under "Developer App".
   - Tap **Trust [Your Apple ID]**.
5. Launch the app from your home screen!

---

## 🔥 Firebase Configuration

This app uses a unique "Dynamic Configuration" approach. Instead of hardcoding a `GoogleService-Info.plist`, you can configure your own Firebase project directly within the app settings.

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
6. (Optional) Choose **Save to Keychain**: This securely stores your credentials in your encrypted iCloud Keychain. Even if you delete the app or get a new iPhone, the app will automatically detect your credentials on first launch.

### 3. Backup & Restore
Once connected, simply enter a **Unique User ID** (can be anything you choose) to backup or restore your data to your private Firestore instance.

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