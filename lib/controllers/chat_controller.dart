import 'package:get/get.dart';
import 'dart:io';
import '../services/firebase_service.dart';
import '../services/cloudinary_service.dart';
import '../models/chat_model.dart';
import '../models/user_model.dart';
import 'auth_controller.dart';

class ChatController extends GetxController {
  final FirebaseService _firebaseService = Get.find<FirebaseService>();
  final AuthController _authController = Get.find<AuthController>();
  final CloudinaryService _cloudinaryService = CloudinaryService();

  // Streams
  final RxList<UserModel> allUsers = <UserModel>[].obs;
  final RxList<ChatRoomModel> myChatRooms = <ChatRoomModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    final user = _authController.currentUser.value;
    if (user != null) {
      allUsers.bindStream(_firebaseService.getAllUsers());
      myChatRooms.bindStream(_firebaseService.getUserChatRooms(user.id));
    }
  }

  // Get users for contact list, excluding current user
  List<UserModel> get contacts {
    final currentUserId = _authController.currentUser.value?.id;
    return allUsers.where((u) => u.id != currentUserId).toList();
  }

  Stream<List<ChatMessageModel>> getMessagesStream(String roomId) {
    return _firebaseService.getChatMessages(roomId);
  }

  Future<String> startOrGetChat(UserModel peer) async {
    final currentUser = _authController.currentUser.value;
    if (currentUser == null) throw Exception('Not logged in');

    return await _firebaseService.getOrCreateChatRoom(
      currentUser.id,
      currentUser.name,
      peer.id,
      peer.name,
    );
  }

  Future<void> sendMessage(
    String roomId,
    String text, {
    File? imageFile,
  }) async {
    if (text.trim().isEmpty && imageFile == null) return;

    final currentUser = _authController.currentUser.value;
    if (currentUser == null) return;

    String? imageUrl;
    if (imageFile != null) {
      imageUrl = await _cloudinaryService.uploadImage(imageFile);
    }

    final msg = ChatMessageModel(
      id: '',
      roomId: roomId,
      senderId: currentUser.id,
      text: text.trim(),
      imageUrl: imageUrl,
      createdAt: DateTime.now(),
    );

    await _firebaseService.sendMessage(roomId, msg);
  }

  String getPeerName(ChatRoomModel room) {
    final currentUserId = _authController.currentUser.value?.id;
    final peerId = room.users.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
    //if usernames[peerId] is not null or ""
    if (room.userNames[peerId] != null && room.userNames[peerId] != '') {
      return room.userNames[peerId]!;
    } else {
      return 'Admin';
    }
  }

  UserModel? getPeerUser(ChatRoomModel room) {
    final currentUserId = _authController.currentUser.value?.id;
    final peerId = room.users.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
    if (peerId.isEmpty) return null;

    for (final user in allUsers) {
      if (user.id == peerId) return user;
    }
    return null;
  }

  ChatRoomModel? getRoomById(String roomId) {
    for (final room in myChatRooms) {
      if (room.id == roomId) return room;
    }
    return null;
  }
}
