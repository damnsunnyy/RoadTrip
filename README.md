# RoadTrip

RoadTrip is an early SwiftUI iOS prototype for coordinating small motorcycle group rides. Riders can create a ride, share a short join code, see the group roster, and share live locations with members through Firebase Firestore and MapKit.

## Prototype scope

- SwiftUI screens for creating and joining a ride
- Six-character invite codes and a six-rider cap
- Firestore-backed ride and rider state
- Core Location updates and a MapKit group view
- Ride leader/member actions and live updates

This is an in-progress prototype, not a production-ready safety or emergency-response service. Location sharing should only be enabled with clear consent from every rider and suitable Firestore security rules.

## Configure Firebase

The Firebase client configuration is deliberately excluded from this repository. Create an iOS app in your Firebase project, download `GoogleService-Info.plist`, and add it to the `RoadTrip` app target in Xcode. The project uses Firebase Firestore through Swift Package Manager.

Before using a real Firebase project, configure and verify Firestore rules to limit ride reads and writes to authorized riders. Do not rely on the client app to enforce access control.

## Open the app

1. Open `RoadTrip.xcodeproj` in Xcode.
2. Resolve the Swift Package dependencies.
3. Add your Firebase configuration to the app target.
4. Select an iOS simulator or device and run the `RoadTrip` scheme.

Location updates require location permission and work best on a physical device. The current prototype requests foreground location access; verify the permission description and lifecycle behavior before distribution.

## Stack

SwiftUI · Firebase Firestore · Core Location · MapKit
