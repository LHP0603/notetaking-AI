# Firebase Cloud Messaging (FCM) Implementation Guide - Android Only

## Overview
This guide provides a complete implementation of Firebase Cloud Messaging (FCM) for receiving push notifications in the Voicely Flutter app on **Android platform only**. The implementation covers Firebase setup, Android native configuration, and handling notifications in all app states.

## Why FCM?
Firebase Cloud Messaging enables the backend to send real-time notifications to users about:
- Transcription completion
- Summarization completion
- Task status updates
- System announcements
- New messages in chatbot

## Dependencies

Add these packages to `pubspec.yaml`:

```yaml
dependencies:
  # Existing dependencies...
  
  # Firebase
  firebase_core: ^3.8.1           # Core Firebase SDK
  firebase_messaging: ^15.1.5     # FCM for push notifications
  flutter_local_notifications: ^18.0.1  # Display notifications on Android foreground
```

### Why Each Package?

| Package | Purpose |
|---------|---------|
| `firebase_core` | Initialize Firebase in the app |
| `firebase_messaging` | Receive push notifications and get FCM token |
| `flutter_local_notifications` | Display notifications when app is in foreground (Android) |

## Implementation Workflow

### Phase 1: Firebase Console & CLI Setup

#### Step 1: Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or select existing project
3. Add Android app:
   - Package name: `com.voicely.voicely_fe` (or your actual package name from `android/app/build.gradle`)
   - Download `google-services.json`
   - Place the file in `android/app/` directory

#### Step 2: Use FlutterFire CLI (Recommended)

Install FlutterFire CLI:
```bash
dart pub global activate flutterfire_cli
```

Configure Firebase automatically:
```bash
# Run in project root directory
flutterfire configure --platforms=android
```

This command will:
- Detect your Firebase project
- Configure Android platform
- Generate `lib/firebase_options.dart` with configuration
- Update Android configuration files automatically

**Output**: `lib/firebase_options.dart`
```dart
// Auto-generated file
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Web is not supported');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError('Only Android platform is supported');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIza...',
    appId: '1:123456789:android:...',
    messagingSenderId: '123456789',
    projectId: 'voicely-project',
    storageBucket: 'voicely-project.appspot.com',
  );
}
```

### Phase 2: Native Platform Configuration

#### Android Configuration

##### 1. Update `android/app/build.gradle`
The FlutterFire CLI should have added this, but verify:

```gradle
dependencies {
    // ... existing dependencies
    
    implementation platform('com.google.firebase:firebase-bom:33.7.0')
    implementation 'com.google.firebase:firebase-messaging'
}
```

##### 2. Update `android/app/src/main/AndroidManifest.xml`

Add permissions and notification metadata:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Add these permissions -->
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
    <uses-permission android:name="android.permission.VIBRATE"/>
    
    <application
        android:label="voicely_fe"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        
        <!-- Add default notification channel -->
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_channel_id"
            android:value="voicely_default_channel" />
        
        <!-- Add default notification icon -->
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_icon"
            android:resource="@drawable/ic_notification" />
        
        <!-- Add default notification color -->
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_color"
            android:resource="@color/notification_color" />
        
        <activity
            android:name=".MainActivity"
            ...>
            <!-- Add intent filter for notification clicks -->
            <intent-filter>
                <action android:name="FLUTTER_NOTIFICATION_CLICK" />
                <category android:name="android.intent.category.DEFAULT" />
            </intent-filter>
        </activity>
    </application>
</manifest>
```

##### 3. Create Notification Icon

Create `android/app/src/main/res/drawable/ic_notification.xml`:
```xml
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp"
    android:height="24dp"
    android:viewportWidth="24"
    android:viewportHeight="24">
    <path
        android:fillColor="#FFFFFF"
        android:pathData="M12,22c1.1,0 2,-0.9 2,-2h-4c0,1.1 0.89,2 2,2zM18,16v-5c0,-3.07 -1.64,-5.64 -4.5,-6.32V4c0,-0.83 -0.67,-1.5 -1.5,-1.5s-1.5,0.67 -1.5,1.5v0.68C7.63,5.36 6,7.92 6,11v5l-2,2v1h16v-1l-2,-2z"/>
</vector>
```

##### 4. Add Notification Color

Create `android/app/src/main/res/values/colors.xml`:
```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="notification_color">#3B82F6</color>
</resources>
```

### Phase 3: Understanding App States

FCM handles notifications differently based on app state:

| App State | Notification Behavior | Handler |
|-----------|----------------------|---------|
| **Foreground** (App is open) | No automatic banner. Must manually display using `flutter_local_notifications` | `FirebaseMessaging.onMessage` |
| **Background** (App is minimized) | System shows banner automatically. Can process data in background | `FirebaseMessaging.onBackgroundMessage` |
| **Terminated** (App is closed) | System shows banner automatically. Gets data when user taps notification | `FirebaseMessaging.getInitialMessage()` |

### Phase 4: Code Implementation

#### 1. Initialize Firebase in `main.dart`

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize notification service
  final notificationService = NotificationService();
  await notificationService.initialize();
  
  runApp(const MyApp());
}

// Top-level function for background message handling
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('Handling background message: ${message.messageId}');
  // You can process the message here, e.g., update local database
}
```

#### 2. Create NotificationService

Create `lib/core/services/notification_service.dart`:

```dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  // Callback for when notification is tapped
  Function(RemoteMessage)? onNotificationTap;

  Future<void> initialize() async {
    // Request permission (Android 13+)
    await _requestPermission();

    // Setup local notifications
    await _setupLocalNotifications();

    // Get FCM token
    await _getFCMToken();

    // Listen to token refresh
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      _fcmToken = newToken;
      _sendTokenToServer(newToken);
    });

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background messages (when app is terminated, user taps notification)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Check if app was opened from notification
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }

  Future<void> _requestPermission() async {
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('User granted permission: ${settings.authorizationStatus}');
  }

  Future<void> _setupLocalNotifications() async {
    // Android settings
    const androidSettings = AndroidInitializationSettings('@drawable/ic_notification');

    const initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    // Create Android notification channel
    const channel = AndroidNotificationChannel(
      'voicely_default_channel',
      'Voicely Notifications',
      description: 'Notifications for Voicely app',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> _getFCMToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();
      print('FCM Token: $_fcmToken');
      
      if (_fcmToken != null) {
        await _sendTokenToServer(_fcmToken!);
      }
    } catch (e) {
      print('Error getting FCM token: $e');
    }
  }

  Future<void> _sendTokenToServer(String token) async {
    // TODO: Implement API call to send token to backend
    // Example:
    // final repository = sl<AuthRepository>();
    // await repository.updateFCMToken(token);
    
    print('Sending FCM token to server: $token');
  }

  void _handleForegroundMessage(RemoteMessage message) {
    print('Foreground message received: ${message.messageId}');
    
    // Display notification manually when app is in foreground
    _showLocalNotification(message);
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null) {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'voicely_default_channel',
            'Voicely Notifications',
            channelDescription: 'Notifications for Voicely app',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@drawable/ic_notification',
            color: Color(0xFF3B82F6),
          ),
        ),
        payload: message.data.toString(),
      );
    }
  }

  void _handleNotificationTap(RemoteMessage message) {
    print('Notification tapped: ${message.messageId}');
    print('Data: ${message.data}');
    
    // Call the callback if set
    onNotificationTap?.call(message);
    
    // Handle navigation based on notification type
    _navigateBasedOnNotification(message);
  }

  void _onNotificationResponse(NotificationResponse response) {
    print('Notification response: ${response.payload}');
    // Handle local notification tap
  }

  void _navigateBasedOnNotification(RemoteMessage message) {
    final notificationType = message.data['notification_type'] as String?;
    final relatedId = message.data['related_id'] as String?;

    if (notificationType == null) return;

    switch (notificationType) {
      case 'transcription_complete':
      case 'audio_processed':
        if (relatedId != null) {
          // Navigate to audio detail
          // navigatorKey.currentState?.pushNamed('/audio-detail', arguments: int.parse(relatedId));
        }
        break;
      case 'summarization_complete':
        if (relatedId != null) {
          // Navigate to note/summary
        }
        break;
      // Add other cases...
    }
  }

  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
  }
}
```

#### 3. Send FCM Token to Backend

Add method to AuthRepository:

```dart
// In auth_repository.dart
abstract class AuthRepository {
  // Existing methods...
  Future<Either<Failure, bool>> updateFCMToken(String token);
}

// In auth_repository_impl.dart
@override
Future<Either<Failure, bool>> updateFCMToken(String token) async {
  if (!await networkInfo.isConnected) {
    return const Left(NetworkFailure('No internet connection'));
  }

  try {
    await remoteDataSource.updateFCMToken(token);
    return const Right(true);
  } on ServerException catch (e) {
    return Left(ServerFailure(e.message));
  }
}

// In auth_remote_data_source.dart
abstract class AuthRemoteDataSource {
  // Existing methods...
  Future<void> updateFCMToken(String token);
}

// Implementation
@override
Future<void> updateFCMToken(String token) async {
  try {
    await dio.post(
      AppConstants.updateFCMTokenEndpoint,
      data: {'fcm_token': token},
    );
  } on DioException catch (e) {
    throw _handleDioException(e, fallbackMessage: 'Failed to update FCM token');
  }
}
```

#### 4. Update AppConstants

```dart
// In app_constants.dart
class AppConstants {
  // Existing constants...
  
  // FCM
  static const String updateFCMTokenEndpoint = '/auth/fcm-token';
}
```

#### 5. Integrate in Main App

Update `main.dart` to handle navigation from notifications:

```dart
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Setup background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  // Initialize dependency injection
  await initializeDependencies();
  
  // Initialize notification service
  final notificationService = NotificationService();
  await notificationService.initialize();
  
  // Set notification tap handler
  notificationService.onNotificationTap = (message) {
    // Handle navigation
    final notificationType = message.data['notification_type'] as String?;
    final relatedId = message.data['related_id'] as String?;
    
    if (notificationType != null && relatedId != null) {
      _handleNotificationNavigation(notificationType, int.parse(relatedId));
    }
  };
  
  runApp(const MyApp());
}

void _handleNotificationNavigation(String type, int relatedId) {
  // Wait for app to be ready
  Future.delayed(const Duration(seconds: 1), () {
    final context = navigatorKey.currentContext;
    if (context == null) return;
    
    switch (type) {
      case 'transcription_complete':
      case 'audio_processed':
        // Navigate to audio detail
        // context.push('/audio/$relatedId');
        break;
      case 'summarization_complete':
        // Navigate to summary
        break;
    }
  });
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      // ... rest of config
    );
  }
}
```

## Backend Integration

### Expected Backend Endpoints

#### 1. Update FCM Token
```
POST /auth/fcm-token
```

**Request:**
```json
{
  "fcm_token": "string"
}
```

**Response:**
```json
{
  "success": true,
  "code": 200,
  "message": "FCM token updated successfully"
}
```

#### 2. Delete FCM Token (On Logout)
```
DELETE /auth/fcm-token
```

**Response:**
```json
{
  "success": true,
  "code": 200,
  "message": "FCM token removed successfully"
}
```

### Notification Payload Format

When backend sends notifications, the payload should follow this structure:

**Notification Object:**
```json
{
  "notification": {
    "title": "Transcription Complete ✅",
    "body": "Your audio 'meeting.m4a' has been transcribed successfully"
  },
  "data": {
    "notification_type": "transcription_complete",
    "related_id": "30",
    "click_action": "FLUTTER_NOTIFICATION_CLICK"
  }
}
```

## Notification Types Mapping

| Backend Type | Title Example | Navigation Target |
|--------------|---------------|-------------------|
| `transcription_complete` | "Transcription Complete ✅" | Audio Detail Screen |
| `transcription_failed` | "Transcription Failed ❌" | Audio Detail Screen |
| `summarization_complete` | "Summary Ready 📝" | Summary Tab |
| `summarization_failed` | "Summary Failed ❌" | Audio Detail Screen |
| `audio_processed` | "Audio Ready 🎵" | Audio Detail Screen |
| `task_completed` | "Task Complete ✓" | Task Detail |
| `system_announcement` | "System Update 📢" | Home Screen |

## Testing

### Test on Android Emulator
```bash
flutter run
```

### Send Test Notification from Firebase Console
1. Go to Firebase Console → Cloud Messaging
2. Click "Send your first message"
3. Enter notification title and text
4. Click "Send test message"
5. Enter your FCM token
6. Click "Test"

### Test Notification Payload
Use this curl command to test from terminal:

```bash
curl -X POST https://fcm.googleapis.com/fcm/send \
  -H "Authorization: key=YOUR_SERVER_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "to": "YOUR_FCM_TOKEN",
    "notification": {
      "title": "Test Notification",
      "body": "This is a test notification"
    },
    "data": {
      "notification_type": "transcription_complete",
      "related_id": "30"
    }
  }'
```

## Implementation Checklist

### Phase 1: Setup & Configuration
- [ ] Add dependencies to `pubspec.yaml`
- [ ] Run `flutter pub get`
- [ ] Install FlutterFire CLI: `dart pub global activate flutterfire_cli`
- [ ] Run `flutterfire configure --platforms=android`
- [ ] Verify `lib/firebase_options.dart` is generated

### Phase 2: Android Setup
- [ ] Update `android/app/build.gradle`
- [ ] Update `AndroidManifest.xml` with permissions
- [ ] Create notification icon: `ic_notification.xml`
- [ ] Create `colors.xml` with notification color
- [ ] Add notification channel metadata
- [ ] Test on Android device/emulator

### Phase 3: Code Implementation
- [ ] Create `NotificationService` class
- [ ] Initialize Firebase in `main.dart`
- [ ] Setup background message handler
- [ ] Implement foreground message handler
- [ ] Implement notification tap handler
- [ ] Add FCM token methods to AuthRepository
- [ ] Update AppConstants with FCM endpoint
- [ ] Test all three app states (foreground, background, terminated)

### Phase 4: Backend Integration
- [ ] Implement `updateFCMToken()` API call
- [ ] Send token on login
- [ ] Send token on app startup
- [ ] Clear token on logout
- [ ] Test receiving notifications from backend

### Phase 5: Navigation & UX
- [ ] Implement notification tap navigation
- [ ] Handle different notification types
- [ ] Add loading states when navigating
- [ ] Test navigation from all app states
- [ ] Add analytics tracking for notification opens

## Common Issues & Solutions

### Issue 1: No notification in foreground (Android)
**Cause**: FCM doesn't show banner in foreground

**Solution**: Use `flutter_local_notifications` to manually show notification
```dart
FirebaseMessaging.onMessage.listen((message) {
  _showLocalNotification(message);
});
```

### Issue 2: Token is null
**Cause**: Firebase not initialized or permission denied

**Solution**:
```dart
await Firebase.initializeApp();
await _firebaseMessaging.requestPermission();
final token = await _firebaseMessaging.getToken();
```

### Issue 4: Background handler not working
**Cause**: Handler must be top-level function

**Solution**:
```dart
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Must be outside any class
}
```

### Issue 5: Android 13+ not showing notifications
**Cause**: Missing runtime permission for POST_NOTIFICATIONS

**Solution**: Add permission request:
```dart
// Using permission_handler package
await Permission.notification.request();
```

## Best Practices

1. **Token Management**
   - Send token to backend on login
   - Update token on refresh
   - Clear token on logout

2. **User Experience**
   - Request permission at appropriate time (not immediately on app start)
   - Show why notifications are useful
   - Allow users to manage notification preferences

3. **Performance**
   - Don't process heavy tasks in foreground handler
   - Use background isolate for data processing
   - Cache notification data locally

4. **Security**
   - Never expose server key in client code
   - Validate notification data before processing
   - Use HTTPS for all API calls

5. **Analytics**
   - Track notification delivery rate
   - Monitor notification tap rate
   - Analyze which types perform best

## Advanced Features

### Topic Subscriptions
Subscribe users to topics for broadcast messages:

```dart
await FirebaseMessaging.instance.subscribeToTopic('all_users');
await FirebaseMessaging.instance.subscribeToTopic('premium_users');
```

### Notification Actions
Add action buttons to notifications:

```dart
const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
  'channel_id',
  'channel_name',
  actions: [
    AndroidNotificationAction(
      'view',
      'View',
      showsUserInterface: true,
    ),
    AndroidNotificationAction(
      'dismiss',
      'Dismiss',
    ),
  ],
);
```

## Resources

- [Firebase Console](https://console.firebase.google.com/)
- [FlutterFire Documentation](https://firebase.flutter.dev/docs/overview)
- [firebase_messaging Package](https://pub.dev/packages/firebase_messaging)
- [flutter_local_notifications Package](https://pub.dev/packages/flutter_local_notifications)
- [Android Push Notifications Guide](https://developer.android.com/guide/topics/ui/notifiers/notifications)

## Next Steps

After implementing FCM:
1. Test thoroughly on Android devices/emulators
2. Integrate with notification center UI
3. Add notification preferences screen
4. Implement notification history
5. Add analytics for notification engagement
6. Consider A/B testing notification content
