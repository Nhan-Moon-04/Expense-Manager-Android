/**
 * Firebase Cloud Functions for Expense Manager
 * 
 * CORE PURPOSE: Send REAL FCM push notifications when admin creates notifications.
 * 
 * WHY THIS IS NEEDED:
 * Before: Admin writes Firestore doc → Client listens via snapshot → Shows local notification
 *   Problem: When app is killed, snapshot listener dies → NO notifications
 * 
 * After: Admin writes Firestore doc → Cloud Function triggers → Sends FCM push → 
 *   Google Play Services delivers notification directly → Works even when app is KILLED
 *   (This is how Zalo, banking apps, Locket Gold work)
 * 
 * DEPLOYMENT:
 *   1. cd functions
 *   2. npm install
 *   3. firebase deploy --only functions
 * 
 * REQUIREMENTS:
 *   - Firebase Blaze plan (pay-as-you-go) - required for Cloud Functions
 *   - User documents must have 'fcmToken' field (saved by the Flutter client app)
 */

const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

// Initialize Firebase Admin
initializeApp();

const db = getFirestore();
const messaging = getMessaging();

/**
 * Trigger: When a new notification document is created in 'notifications' collection.
 * Action: Send an FCM push notification to the target user's device.
 * 
 * This is the KEY function that makes notifications work when app is killed.
 * The FCM message includes a 'notification' field, which means:
 *   - Android system handles display automatically (no app code needed)
 *   - Google Play Services delivers it even if the app is killed
 *   - The notification appears in the system tray just like Zalo/banking apps
 */
exports.sendNotificationOnCreate = onDocumentCreated(
  "notifications/{notificationId}",
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) {
      console.log("No data associated with the event");
      return;
    }

    const notificationData = snapshot.data();
    const userId = notificationData.userId;
    const title = notificationData.title || "Thông báo";
    const body = notificationData.message || "";
    const type = notificationData.type || "system";
    const notificationId = event.params.notificationId;

    console.log(`New notification for user ${userId}: ${title}`);

    // Get user's FCM token from their document
    try {
      const userDoc = await db.collection("users").doc(userId).get();
      
      if (!userDoc.exists) {
        console.log(`User ${userId} not found`);
        return;
      }

      const userData = userDoc.data();
      const fcmToken = userData.fcmToken;

      if (!fcmToken) {
        console.log(`No FCM token for user ${userId}`);
        return;
      }

      // Build FCM message with NOTIFICATION payload
      // KEY: The 'notification' field makes Android system display it automatically
      // even when the app is killed. This is the secret sauce.
      const message = {
        token: fcmToken,
        
        // NOTIFICATION payload - displayed by Android system automatically
        // Works when app is: foreground, background, OR killed
        notification: {
          title: title,
          body: body,
        },
        
        // DATA payload - available to the app when it processes the notification
        data: {
          notificationId: notificationId,
          type: type,
          userId: userId,
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
        
        // Android-specific configuration
        android: {
          // HIGH priority ensures delivery even in Doze mode
          priority: "high",
          
          notification: {
            // Must match the channel created in Flutter and AndroidManifest.xml
            channelId: "fcm_high_importance_channel",
            priority: "max",
            defaultSound: true,
            defaultVibrateTimings: true,
            // Show on lock screen
            visibility: "PUBLIC",
            // Notification icon (uses the one in AndroidManifest.xml)
            icon: "@mipmap/ic_launcher",
            // Color
            color: "#374785",
          },
          
          // TTL: how long to keep trying to deliver (24 hours)
          ttl: "86400s",
        },
      };

      // Send the FCM message
      const response = await messaging.send(message);
      console.log(`FCM sent successfully to user ${userId}: ${response}`);
      
    } catch (error) {
      // Handle invalid/expired tokens
      if (error.code === "messaging/invalid-registration-token" ||
          error.code === "messaging/registration-token-not-registered") {
        console.log(`Invalid FCM token for user ${userId}, removing...`);
        await db.collection("users").doc(userId).update({
          fcmToken: null,
          fcmTokenUpdatedAt: null,
        });
      } else {
        console.error(`Error sending FCM to user ${userId}:`, error);
      }
    }
  }
);

/**
 * Trigger: When a notification is created with type 'promotion' or sent to topic
 * Action: Send to 'all_users' topic for broadcast notifications
 * 
 * Topic messages are delivered to ALL subscribed devices, even if killed.
 * Users are subscribed to 'all_users' topic in FCMService.initialize()
 */
exports.sendBroadcastNotification = onDocumentCreated(
  "admin_notifications/{notificationId}",
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;

    const data = snapshot.data();
    const title = data.title || "Thông báo";
    const body = data.body || "";

    console.log(`Broadcasting notification: ${title}`);

    try {
      // Send to 'all_users' topic - reaches ALL devices subscribed to this topic
      const message = {
        topic: "all_users",
        
        notification: {
          title: title,
          body: body,
        },
        
        data: {
          type: "broadcast",
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
        
        android: {
          priority: "high",
          notification: {
            channelId: "fcm_high_importance_channel",
            priority: "max",
            defaultSound: true,
            defaultVibrateTimings: true,
            visibility: "PUBLIC",
            icon: "@mipmap/ic_launcher",
            color: "#374785",
          },
          ttl: "86400s",
        },
      };

      const response = await messaging.send(message);
      console.log(`Broadcast FCM sent: ${response}`);
      
    } catch (error) {
      console.error("Error sending broadcast FCM:", error);
    }
  }
);
