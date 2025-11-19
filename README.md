# powerful_students

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

## Firebase / Firestore Setup

Group rooms now persist on Cloud Firestore. Before running the app you must:

1. Install the Firebase CLI and log in: `npm install -g firebase-tools && firebase login`.
2. Create or select a Firebase project: `firebase projects:create powerful-students` (or use an existing one).
3. Run `flutterfire configure` from the repo root to refresh `firebase_options.dart` with your project's ids.
4. Enable Firestore in the Firebase Console.
5. Apply basic security rules so rooms can only be mutated by members:

   ```text
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /rooms/{roomId} {
         allow read, write: if true; // tighten as needed
       }
     }
   }
   ```

6. Run `flutter pub get`, then `flutter run`.

### Manual QA

- Create a room on device A, note the code, and verify a Firestore `rooms/{code}` document exists with your member id.
- Join the same room from device B using the code and confirm `members` updates in Firestore and the UI shows the connected count.
- Leave from each device and ensure the document is deleted when the last member exits.

## Contributor Guide

Review the repository conventions in [AGENTS.md](AGENTS.md) before opening a pull request.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
