import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

// 初始化 flutter_local_notifications
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

// 後台訊息處理
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  debugPrint("處理後台訊息: ${message.messageId}");
}

Future<void> onDidReceiveLocalNotification(int id, String? title, String? body, String? payload) async {
  // Handle the notification here
}

Future<void> onDidReceiveNotificationResponse(NotificationResponse notificationResponse) async {
  final String? payload = notificationResponse.payload;
  if (notificationResponse.payload != null) {
    debugPrint('notification payload: $payload');
  }
  await Navigator.push(
    // 使用GlobalKey來獲取navigator的context
    navigatorKey.currentState!.context,
    MaterialPageRoute<void>(builder: (context) => SecondScreen(payload)),
  );
}

// 定義一個GlobalKey來獲取navigator的context
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
void showTimedNotification() async {
  int notification_id = 1;

  await flutterLocalNotificationsPlugin.zonedSchedule(notification_id, "Title", "Description", tz.TZDateTime.now(tz.local).add(const Duration(days: 3)), const NotificationDetails(android: AndroidNotificationDetails('default_channel', 'Default Channel', channelDescription: 'This is the default channel for notifications')), androidAllowWhileIdle: true, uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime);
}

Future<void> main() async {
  // firebase 初始化
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // 設定後台訊息處理
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  // 初始化 flutter_local_notifications
  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
  const DarwinInitializationSettings initializationSettingsDarwin = DarwinInitializationSettings(onDidReceiveLocalNotification: onDidReceiveLocalNotification);
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsDarwin,
  );
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: onDidReceiveNotificationResponse, // 點擊通知後的處理
  );
  // 初始化時區
  tz.initializeTimeZones();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey, // 設置navigatorKey
      debugShowCheckedModeBanner: false,
      home: FirebaseMessagingHandler(),
    );
  }
}

class FirebaseMessagingHandler extends StatefulWidget {
  @override
  _FirebaseMessagingHandlerState createState() => _FirebaseMessagingHandlerState();
}

class _FirebaseMessagingHandlerState extends State<FirebaseMessagingHandler> {
  String _pushMessage = "沒有收到訊息";

  @override
  void initState() {
    super.initState();
    _initFirebaseMessage();
    _getToken();
  }

  void _initFirebaseMessage() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // for iOS 的權限設定
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus != AuthorizationStatus.authorized) {
      // 顯示提示Dialog
      _showMessageDialog(context, "如果不授予權限，將無法收到推播訊息進行驗證。");
    } else {
      FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
        // APP關閉時，透過原生Notification點進APP時的觸發點
        _handleMessage(message, "getInitialMessage");
      });
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        // 前景接收訊息（App裡面接收訊息）
        _handleMessage(message, "onMessage");
      });
      // 前景顯示通知（App裡面顯示通知）
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _showNotification(message);
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        // APP在背景時，點擊通知進入APP時觸發
        _handleMessage(message, "onMessageOpenedApp");
      });
    }
  }

  // 取得推播 token
  void _getToken() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    String? token = await messaging.getToken();
    if (token != null) {
      debugPrint("token: $token");
      // 重新安裝APP後，token會改變
      // 安卓：e0W9DZSIRZaw1mU-eBIz-b:APA91bGHlzbedMulQJoo4gh_MxFhmHKb99xWG_sgpFTeSNjmIHH6y6tv3yiswdXmoslU2g6tAti6V284nuLki9hI6QP7kUZGTGKoPprxLCC1AgfE0U7Dw5OYmbc_PwlBSFVW_C1WngQD
      // 蘋果：dRqHcNzkJ0gvpb_hjA02N2:APA91bHmVVXqTSClR6hQciPjA6mNQX_75dSSieUvBhl5_gYJ1czN8UI3altFGxJqAqxYLt4dIYQNGELbCbGB648eGbrbvLk-onCabBnn0NL9LKXisWhgcmh0p67M9tmSIYL587a7zv8T
      setState(() {
        String? _pushToken;
        _pushToken = token;
      });
    }
  }

  // 處理推送消息的邏輯
  void _handleMessage(RemoteMessage? message, String source) {
    if (message != null) {
      debugPrint('Got a message from $source!');
      StringBuffer stringBuffer = StringBuffer();
      stringBuffer.write("Got a message from $source! \n");
      debugPrint("data: ${message.data}");
      message.data.forEach((key, value) {
        stringBuffer.write("key: $key, value: $value \n");
      });
      setState(() {
        _pushMessage = stringBuffer.toString();
      });
    }
  }

  // 顯示提示對話框
  void _showMessageDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('提示'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('確定'),
            ),
          ],
        );
      },
    );
  }

  // 前景顯示通知
  void _showNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'default_channel', // Must match with the channel_id in AndroidManifest.xml
      'Default Channel',
      channelDescription: 'This is the default channel for notifications',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0,
      message.notification?.title,
      message.notification?.body,
      platformChannelSpecifics,
      payload: 'Default_Sound',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Messaging'),
      ),
      body: Center(
        child: Text(_pushMessage),
      ),
    );
  }
}

class SecondScreen extends StatelessWidget {
  final String? payload;

  SecondScreen(this.payload);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Second Screen"),
      ),
      body: Center(
        child: Text("Payload: $payload"),
      ),
    );
  }
}
