const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.sendChatNotification = functions.firestore
  .document("chats/{chatId}/messages/{messageId}")
  .onCreate(async (snap, context) => {
    console.log("🔥 Triggered sendChatNotification!");
    console.log("Chat ID:", context.params.chatId, "Message ID:", context.params.messageId);
    
    const messageData = snap.data();
    console.log("Message Data:", JSON.stringify(messageData));
    
    // We don't want to notify the person who sent the message
    const senderId = messageData.senderId;
    const text = messageData.text || (messageData.imageUrl ? "Sent an image" : "New message");

    // Get the chat document to figure out who the other users are
    const chatId = context.params.chatId;
    const chatDoc = await admin.firestore().collection("chats").doc(chatId).get();
    
    if (!chatDoc.exists) return null;

    const chatData = chatDoc.data();
    const participants = chatData.members || [];
    
    // Find the receiver's ID (the person who is NOT the sender)
    const receiverId = participants.find(id => id !== senderId);
    
    if (!receiverId) return null;

    // Get the sender's profile to display their name in the notification
    const senderDoc = await admin.firestore().collection("users").doc(senderId).get();
    const senderName = senderDoc.exists ? senderDoc.data().name || senderDoc.data().phone : "Someone";

    // Get the receiver's FCM token
    const receiverDoc = await admin.firestore().collection("users").doc(receiverId).get();
    if (!receiverDoc.exists) return null;

    const fcmToken = receiverDoc.data().fcmToken;
    if (!fcmToken) {
      console.log(`User ${receiverId} does not have an FCM token.`);
      return null;
    }

    // Construct the notification payload
    const payload = {
      token: fcmToken,
      data: {
        click_action: "FLUTTER_NOTIFICATION_CLICK",
        chatId: chatId,
        senderId: senderId,
        messageId: context.params.messageId,
        title: senderName,
        body: text,
      },
      android: {
        priority: "high",
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
            alert: {
              title: senderName,
              body: text,
            }
          }
        }
      }
    };

    // Send the push notification
    try {
      await admin.messaging().send(payload);
      console.log("Notification sent successfully to", receiverId);
    } catch (error) {
      console.error("Error sending notification:", error);
    }
    
    return null;
  });
