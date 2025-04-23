#!/bin/bash

# Set the simulator device - use a recent iPhone model
SIMULATOR="iPhone 15"

# Find available iPhone simulators
echo "Available simulators:"
xcrun simctl list devices | grep "iPhone"

# Clean the project first to remove any cached build artifacts
echo "Cleaning the project..."
xcodebuild -project WorkoutTracker.xcodeproj -scheme WorkoutTracker clean

# Build and run the app in the simulator
echo "Building and running WorkoutTracker on $SIMULATOR..."
xcodebuild -project WorkoutTracker.xcodeproj -scheme WorkoutTracker -destination "platform=iOS Simulator,name=$SIMULATOR" build

# Launch the simulator
echo "Launching simulator..."
open -a Simulator

# Give the simulator some time to start
sleep 5

# Get the bundle ID (you may need to update this to match your app's bundle ID)
BUNDLE_ID="com.example.WorkoutTracker"

# Install and launch the app
echo "Installing and launching the app..."
xcrun simctl install booted "build/Debug-iphonesimulator/WorkoutTracker.app"
xcrun simctl launch booted $BUNDLE_ID 