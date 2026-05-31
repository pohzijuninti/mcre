import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/user_model.dart';
import '../models/area_role_model.dart';
import '../models/content_model.dart';
import '../models/chat_model.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- Roles ---
  Stream<List<AreaRoleModel>> getAreaRoles() {
    return _db.collection('roles').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return AreaRoleModel(id: doc.id, name: doc['name']);
      }).toList();
    });
  }

  Future<void> addAreaRole(String name) {
    return _db.collection('roles').add({'name': name});
  }

  Future<void> updateAreaRole(String id, String prevName, String name) async {
    //should also update the area at the user role
    final snapshot = await _db.collection('users').where('areas', arrayContains: prevName).get();
    for (var doc in snapshot.docs) {
      final data = doc.data();
      List<dynamic> areas = data['areas'] ?? [];
      final updatedAreas = areas.map((e) => e == prevName ? name : e).toList();
      await _db.collection('users').doc(doc.id).update({'areas': updatedAreas});
    }

    final snapshotOld = await _db.collection('users').where('area', isEqualTo: prevName).get();
    for (var doc in snapshotOld.docs) {
      final data = doc.data();
      List<dynamic> areas = data['areas'] ?? [];
      if (data['area'] == prevName && !areas.contains(name)) {
        areas.add(name);
      }
      await _db.collection('users').doc(doc.id).update({
        'areas': areas,
        'area': FieldValue.delete(),
      });
    }

    // Update the area in the content collection
    final contentSnapshot = await _db.collection('content').where('area', arrayContains: prevName).get();
    for (var doc in contentSnapshot.docs) {
      final data = doc.data();
      List<dynamic> contentAreas = data['area'] ?? [];
      final updatedContentAreas = contentAreas.map((e) => e == prevName ? name : e).toList();
      await _db.collection('content').doc(doc.id).update({'area': updatedContentAreas});
    }

    return _db.collection('roles').doc(id).update({'name': name});
  }

  Future<void> deleteAreaRole(String id) {
    return _db.collection('roles').doc(id).delete();
  }

  // --- Users/Employees ---
  Stream<List<UserModel>> getEmployees() {
    return _db
        .collection('users')
        .where(
          'role',
          whereIn: [
            'UserRole.manager',
            'UserRole.supervisor',
            'UserRole.employer',
            'UserRole.employee',
          ],
        )
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => UserModel.fromFirestore(doc))
              .toList();
        });
  }

  Future<void> saveUserProfile(UserModel user) async {
    final secondaryApp = await Firebase.initializeApp(
      name: 'Secondary',
      options: Firebase.app().options,
    );

    final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

    await secondaryAuth.setSettings(appVerificationDisabledForTesting: true);

    UserCredential userCredential;
    try {
      userCredential = await secondaryAuth.createUserWithEmailAndPassword(
        email: user.email,
        password: user.password!,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        // Fallback: If user exists in Auth but was deleted from Firestore,
        // we can try to sign in with the provided password to get their UID.
        userCredential = await secondaryAuth.signInWithEmailAndPassword(
          email: user.email,
          password: user.password!,
        );
      } else {
        await secondaryApp.delete();
        throw Exception(e.message ?? 'Authentication error');
      }
    } catch (e) {
      await secondaryApp.delete();
      rethrow;
    }

    final newUser = user.copyWith(
      id: userCredential.user!.uid,
      createdAt: DateTime.now(),
    );
    await _db.collection('users').doc(newUser.id).set(newUser.toJson());
    await secondaryApp.delete();
  }

  Future<void> updateUserProfile(UserModel user) async {
    await _db.collection('users').doc(user.id).update(user.toJson());
  }

  Future<void> deleteEmployee(String uid) async {
    // IMPORTANT: It is programmatically IMPOSSIBLE to delete another user by their UID
    // from the Flutter client app for security reasons. The Firebase Client SDK only
    // allows a user to delete themselves (if they are signed in).
    // Manual Way:
    // 1. Login to firebase console.
    // 2. Go to authentication.
    // 3. Delete the user.
    await _db.collection('users').doc(uid).delete();
  }

  Future<UserModel?> getUserProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserModel.fromFirestore(doc);
    }
    return null;
  }

  Future<bool> checkEmailExists(String email) async {
    final snapshot = await _db.collection('users').where('email', isEqualTo: email).get();
    return snapshot.docs.isNotEmpty;
  }

  // --- Content ---
  Stream<List<ContentModel>> getContentStream() {
    return _db
        .collection('content')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ContentModel.fromFirestore(doc))
            .toList());
  }

  Future<void> addContent(ContentModel content) async {
    final docRef = _db.collection('content').doc();
    final newContent = content.copyWith(id: docRef.id);
    await docRef.set(newContent.toJson());
  }

  Future<void> updateContent(String contentId, String newText, String? newImageUrl) async {
    await _db.collection('content').doc(contentId).update({
      'text': newText,
      if (newImageUrl != null) 'imageUrl': newImageUrl,
    });
  }

  Future<void> deleteContent(String contentId) async {
    await _db.collection('content').doc(contentId).delete();
  }

  Future<void> addComment(String contentId, CommentModel comment) async {
    final docRef = _db.collection('content').doc(contentId);
    await docRef.update({
      'comments': FieldValue.arrayUnion([comment.toJson()])
    });
  }

  // --- Chat ---
  Stream<List<UserModel>> getAllUsers() {
    return _db.collection('users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
    });
  }

  Stream<List<ChatRoomModel>> getUserChatRooms(String userId) {
    return _db
        .collection('chatRooms')
        .where('users', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      final rooms = snapshot.docs
          .map((doc) => ChatRoomModel.fromFirestore(doc))
          .toList();
      rooms.sort((a, b) {
        if (a.lastMessageTime == null && b.lastMessageTime == null) return 0;
        if (a.lastMessageTime == null) return 1;
        if (b.lastMessageTime == null) return -1;
        return b.lastMessageTime!.compareTo(a.lastMessageTime!);
      });
      return rooms;
    });
  }

  Stream<List<ChatMessageModel>> getChatMessages(String roomId) {
    return _db
        .collection('chatRooms')
        .doc(roomId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatMessageModel.fromFirestore(doc))
            .toList());
  }

  Future<String> getOrCreateChatRoom(String currentUserId, String currentUserName, String peerId, String peerName) async {
    final query1 = await _db
        .collection('chatRooms')
        .where('users', isEqualTo: [currentUserId, peerId])
        .limit(1)
        .get();

    if (query1.docs.isNotEmpty) {
      return query1.docs.first.id;
    }

    final query2 = await _db
        .collection('chatRooms')
        .where('users', isEqualTo: [peerId, currentUserId])
        .limit(1)
        .get();

    if (query2.docs.isNotEmpty) {
      return query2.docs.first.id;
    }

    // Create new room
    final docRef = _db.collection('chatRooms').doc();
    final newRoom = ChatRoomModel(
      id: docRef.id,
      users: [currentUserId, peerId],
      userNames: {currentUserId: currentUserName, peerId: peerName},
      lastMessage: null,
      lastMessageTime: null,
    );
    await docRef.set(newRoom.toJson());
    return docRef.id;
  }

  Future<void> sendMessage(String roomId, ChatMessageModel message) async {
    // Add message
    final msgRef = _db.collection('chatRooms').doc(roomId).collection('messages').doc();
    final newMsg = ChatMessageModel(
      id: msgRef.id,
      roomId: roomId,
      senderId: message.senderId,
      text: message.text,
      imageUrl: message.imageUrl,
      createdAt: message.createdAt,
    );
    await msgRef.set(newMsg.toJson());

    // Update room
    await _db.collection('chatRooms').doc(roomId).update({
      'lastMessage': message.text.isNotEmpty ? message.text : (message.imageUrl != null ? '📷 Image' : ''),
      'lastMessageTime': message.createdAt.toIso8601String(),
    });
  }
}
