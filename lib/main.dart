import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebasenotifications/screens/home_screen.dart';
import 'package:flutter/material.dart';


import 'firebase_options.dart';

void main() async{

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const MyApp());
}

@pragma("vm:entry-point")
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message)async
{
  await Firebase.initializeApp();
  print(message.notification!.title.toString());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});


  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: .fromSeed(seedColor: Colors.deepPurple),
      ),
      home: HomeScreen(),
    );
  }
}



































// 1. How the Pop-Up Appears (The Android Magic Trick)
// When your app is killed, Flutter is dead. flutter_local_notifications is dead. Your Dart code does absolutely nothing to draw that visual pop-up on the screen.
//
// So, who draws it and how does it know the priority?
// Google Play Services (built into the Android OS) catches the incoming message and handles the UI completely natively. Here is the step-by-step of how it works:
//
// The Setup (Past): Remember when we added initNotification() and told you to run the app once? In that function, we told the Android OS: "Hey Android, create a permanent channel in your system called high_importance_channel and give it Maximum Priority." 2. The Memory: Android saves this channel in the phone's deep system settings permanently. Even if you kill the app, Android remembers that high_importance_channel exists and demands a pop-up.
//
// The Arrival (Present): A Firebase message arrives while the app is killed.
//
// The Handshake: Google Play Services catches it, looks at your AndroidManifest.xml, and reads this line:
// <meta-data android:name="com.google.firebase.messaging.default_notification_channel_id" android:value="high_importance_channel" />
//
// The Execution: Play Services says, "Ah! The app wants me to put this message into high_importance_channel." It checks the Android system, sees that channel has Maximum Priority, and the Android OS itself draws the pop-up on the screen. Flutter didn't do it. Android did it using the instructions you left behind in the OS memory and the Manifest!
//
// 2. What is onBackgroundMessage?
// If Android is drawing the visual pop-up, what is the point of FirebaseMessaging.onBackgroundMessage?
//
// When Android draws the notification on the screen, it also secretly kicks the Flutter engine and says, "Hey, wake up a tiny background worker, I have some hidden data for you." The onBackgroundMessage function is that tiny worker. It is NOT for drawing the UI. It is strictly for handling hidden data behind the scenes.
//
// Example: You receive a message saying "New Friend Request." Android draws the pop-up natively. Meanwhile, onBackgroundMessage wakes up silently in the background, takes the user's ID from the Firebase payload, and saves it to your phone's local SQLite database so it's ready when you actually open the app.
//
// 3. What does @pragma("vm:entry-point") mean?
// This is a direct command to the Flutter compiler.
//
// When you build your app for release (like putting it on the Play Store), Flutter uses a tool called "Tree Shaking." It looks at your code and says, "I'm going to delete any function that is never called to make the app size smaller."
//
// Because _firebaseMessagingBackgroundHandler is triggered by the Android OS in the background, the Flutter compiler looks at your Dart code, doesn't see you calling it anywhere, and tries to delete it!
//
// @pragma is Latin for "Instruction" or "Command".
//
// "vm:entry-point" means "Virtual Machine Entry Point".
//
// By writing @pragma("vm:entry-point"), you are screaming at the compiler: "DO NOT DELETE THIS FUNCTION! The Android Operating System is going to use it as a backdoor to enter the app while it is closed!"
//
// Summary
// Foreground: Flutter draws the UI using flutter_local_notifications.
//
// Background/Killed: Android OS draws the UI natively using the Manifest and saved Channel settings. Flutter only wakes up to process raw data using the @pragma backdoor.
//
// Make sense? If you are ready, would you like me to show you how to write the code that listens for when the user actually taps on that notification, so you can navigate them to a specific
