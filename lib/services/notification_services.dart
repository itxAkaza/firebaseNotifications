
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:app_settings/app_settings.dart';
import 'package:firebasenotifications/screens/chat_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationServices
{

  FirebaseMessaging messaging=FirebaseMessaging.instance;
  final notificationPlugin=FlutterLocalNotificationsPlugin();


  Future<void> initNotification(BuildContext context)async
  {
    //initialize setting
    const initSettingAndroid=AndroidInitializationSettings("@mipmap/ic_launcher");

    const initSettingIOS=DarwinInitializationSettings(
        requestAlertPermission: true,
        requestSoundPermission: true,
        requestBadgePermission: true
    );


    const initSetting=InitializationSettings(
        android: initSettingAndroid,
        iOS: initSettingIOS
    );

    //plugin active
    await notificationPlugin.initialize(
      settings: initSetting,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null) {
          // Decode the String payload back into a Map
          Map<String, dynamic> data = jsonDecode(response.payload!);
          handleMessage(context, data); // Send to unified router
        }
      },

    );



  }

  NotificationDetails notificationDetails()
  {

    AndroidNotificationChannel channel=AndroidNotificationChannel(
        "high_importance_channel",
        "Daily Notification Firebase",
      importance: Importance.max


    );

    return  NotificationDetails(
        android: AndroidNotificationDetails(
          //channelId → Internal unique key. it must be unique. if yo made multilpe then andriod will ignore the second an duse the first one
          // channelName → Shown to the user in system settings.
          channel.id.toString(),
          channel.name.toString(),
          // channelDescription → Explains purpose (helps user decide whether to enable/disable).
          channelDescription: "Daily Notification Channel",
          importance: Importance.high,
          priority: Priority.max,
          playSound: true,
          ticker: "ticker"
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true
        )

    );

  }


  Future<void> showNotification(RemoteMessage message) async {
    // 1. Safely check if the notification actually exists inside the box!
    if (message.notification != null) {
      await notificationPlugin.show(
        id: 0,
        title:  message.notification!.title,
        body:  message.notification!.body,
       notificationDetails:  notificationDetails(),
        payload: jsonEncode(message.data)
      );

      // we pass the payload manual. from init . as it expect one string. we encode it and then show.

    }
  }

  void firebaseinit(BuildContext context){
    FirebaseMessaging.onMessage.listen((message){

      print(message.notification!.title.toString());
      print(message.notification!.body.toString());
      print(message.data.toString());
      print(message.data["type"].toString());

      if(Platform.isAndroid)
        {

          showNotification(message);

        }
      else
        {
          showNotification(message);

        }

    });
  }

  void requestNotificationPermissions()async
  {
    NotificationSettings settings= await messaging.requestPermission(
      alert: true,//requests permission to display a visual notification on the user's screen (like a banner at the top of the phone).
      announcement: true,//Requests permission for Siri to automatically read the notification out loud if the user is wearing AirPods or using a compatible device
      badge: true,
      carPlay: true,//Requests permission to display notifications on the car's screen when the user's phone is connected to Apple CarPlay.
      criticalAlert: true,//Requests permission to send high-priority alerts that bypass the mute switch and Do Not Disturb mode
      provisional: true,//Requests permission for "quiet" notifications. On iOS, provisional notifications don't show a popup asking the user for permission. Instead, they bypass the lock screen banners and go straight to the Notification Center quietly. The user can then decide later if they want to keep them or turn them off.
      sound: true
    );

    if(settings.authorizationStatus==AuthorizationStatus.authorized)
      {
        print("permission granted");

      }
    else if (settings.authorizationStatus== AuthorizationStatus.provisional)
        {
          print("permission granted provisional");

        }
    else
      {
        AppSettings.openAppSettings(
          type: AppSettingsType.notification
        );
        print("permission Denied");

      }
  }

  Future<String> getDeviceToken()async
  {
    String? token=await messaging.getToken();
    return token!;
    //Think of an FCM token like a mailing address for a specific device.
    // When your backend server (or a Firebase Cloud Function) wants to send a push notification to a specific user (for example, "You have a new friend request"), it says to Firebase: "Hey, send this message to the device with this FCM token."
    // messaging.getToken(): Reaches out to Firebase servers and generates a unique, long string of characters specifically for this app installation on this exact phone
  }

  void isTokenRefresh()async
  {
    //As I mentioned earlier, FCM tokens are not permanent. Think of it like a user's phone number. If they change their phone number, you can't text their old one anymore.
    //If you don't listen for these changes, your database will have the old, dead token, and your user will stop receiving notifications. The onTokenRefresh stream listens in the background and says, "Hey! Firebase just gave this device a new token! Update your database!"
    messaging.onTokenRefresh.listen((event)
    {
      event.toString();

    });
  }

  // in this method. when the app is in bac or termiante.
  // the shown is handle by the os it sles. so we dont have to show by ourself. just it is if the
  //notifiaction have a data then this is called and the pyalod is being handled.
  Future<void> setupInteractMessage(BuildContext context)async
  {

    //when app is terminated
    RemoteMessage ? initalMessage=await FirebaseMessaging.instance.getInitialMessage();
    if(initalMessage!=null)
      {
        handleMessage(context, initalMessage.data);
      }

    // when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((onData)
    {
      handleMessage(context, onData.data);
    });


  //   The Two Tap Functions Explained
  //   The reason we need two different functions here is because the phone’s processor handles a "sleeping" app very differently than a "dead" app.
  //
  // FirebaseMessaging.instance.getInitialMessage()
  //
  // The State: The app is completely KILLED (Terminated).
  //
  // How it works: When the user taps the notification, the phone has to boot your app up from zero. As the app turns on, this function looks back in time and asks, "Wait, did a notification tap cause me to wake up just now?" If yes, it grabs that specific message so you can route the user immediately upon startup.
  //
  // FirebaseMessaging.onMessageOpenedApp.listen()
  //
  // The State: The app is MINIMIZED (Background).
  //
  // How it works: The app is already alive, just paused in the background. Because it is alive, it can actively listen to a stream. When the user taps the notification, this stream instantly fires, bringing the app to the front and executing your navigation code.

  }


  // 6. UNIFIED ROUTER (The Steering Wheel)
  void handleMessage(BuildContext context, Map<String, dynamic> data) {
    if (data["type"] == "msj") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ChatScreen(id: data["id"] ?? "0")),
      );
    }
  }


  // void handleMessage(BuildContext context, RemoteMessage message)
  // {
  //
  //   if(message.data["type"]=="msj")
  //     {
  //       Navigator.push(context, MaterialPageRoute(
  //           builder: (context)=>ChatScreen(id: message.data["id"],))
  //       );
  //     }
  //
  // }





}