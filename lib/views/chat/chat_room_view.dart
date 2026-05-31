import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../controllers/chat_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../models/chat_model.dart';

class ChatRoomView extends StatefulWidget {
  final String roomId;
  final String peerName;
  final String? peerPicture;

  const ChatRoomView({
    super.key,
    required this.roomId,
    required this.peerName,
    this.peerPicture,
  });

  @override
  State<ChatRoomView> createState() => _ChatRoomViewState();
}

class _ChatRoomViewState extends State<ChatRoomView> {
  final ChatController chatController = Get.find<ChatController>();
  final AuthController authController = Get.find<AuthController>();
  final TextEditingController _textController = TextEditingController();
  File? _selectedImage;
  bool _isUploading = false;

  void _sendMessage() async {
    final text = _textController.text;
    if (text.trim().isNotEmpty || _selectedImage != null) {
      setState(() {
        _isUploading = true;
      });
      await chatController.sendMessage(
        widget.roomId,
        text,
        imageFile: _selectedImage,
      );
      setState(() {
        _isUploading = false;
        _selectedImage = null;
      });
      _textController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(() {
          final room = chatController.getRoomById(widget.roomId);
          final peerUser = room != null
              ? chatController.getPeerUser(room)
              : null;
          final peerName = widget.peerName.isNotEmpty
              ? widget.peerName
              : peerUser?.name ?? 'Admin';
          final peerPicture = _validPicture(widget.peerPicture)
              ? widget.peerPicture
              : peerUser?.picture;

          return Row(
            children: [
              _buildAvatar(
                name: peerName,
                picture: peerPicture,
                radius: 16,
                backgroundColor: Colors.white,
                fallbackColor: Colors.teal,
                fontSize: 14,
              ),
              const SizedBox(width: 10),
              Text(peerName),
            ],
          );
        }),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessageModel>>(
              stream: chatController.getMessagesStream(widget.roomId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text('No messages here yet. Say hi!'),
                  );
                }

                final messages = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  reverse:
                      false, // In a real WhatsApp, we might reverse and sort descending. We sorted ascending, so scroll to bottom needed, or we just rely on standard list.
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final currentUser = authController.currentUser.value;
                    final currentUserId = currentUser?.id;
                    final isMe = msg.senderId == currentUserId;
                    final timeStr = DateFormat('hh:mm a').format(msg.createdAt);
                    final room = chatController.getRoomById(widget.roomId);
                    final peerUser = room != null
                        ? chatController.getPeerUser(room)
                        : null;
                    final senderName = isMe
                        ? currentUser?.name ?? ''
                        : widget.peerName.isNotEmpty
                        ? widget.peerName
                        : peerUser?.name ?? 'Admin';
                    final senderPicture = isMe
                        ? currentUser?.picture
                        : _validPicture(widget.peerPicture)
                        ? widget.peerPicture
                        : peerUser?.picture;

                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (!isMe) ...[
                            _buildAvatar(
                              name: senderName,
                              picture: senderPicture,
                            ),
                            const SizedBox(width: 8),
                          ],
                          Flexible(
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? Colors.teal[100]
                                    : Colors.grey[200],
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(16),
                                  topRight: const Radius.circular(16),
                                  bottomLeft: isMe
                                      ? const Radius.circular(16)
                                      : const Radius.circular(0),
                                  bottomRight: isMe
                                      ? const Radius.circular(0)
                                      : const Radius.circular(16),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: isMe
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
                                children: [
                                  if (msg.imageUrl != null)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 8.0,
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          msg.imageUrl!,
                                          height: 150,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  if (msg.text.isNotEmpty)
                                    Text(
                                      msg.text,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  const SizedBox(height: 4),
                                  Text(
                                    timeStr,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (isMe) ...[
                            const SizedBox(width: 8),
                            _buildAvatar(
                              name: senderName,
                              picture: senderPicture,
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_selectedImage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0, left: 16.0),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      _selectedImage!,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: -10,
                    right: -10,
                    child: IconButton(
                      icon: const Icon(
                        Icons.cancel,
                        color: Colors.red,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          _selectedImage = null;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.image, color: Colors.teal),
                onPressed: () async {
                  final picker = ImagePicker();
                  final pickedFile = await picker.pickImage(
                    source: ImageSource.gallery,
                  );
                  if (pickedFile != null) {
                    setState(() {
                      _selectedImage = File(pickedFile.path);
                    });
                  }
                },
              ),
              Expanded(
                child: TextField(
                  controller: _textController,
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[200],
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                  ),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                backgroundColor: Colors.teal,
                child: _isUploading
                    ? const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.send, color: Colors.white),
                        onPressed: _sendMessage,
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool _validPicture(String? picture) {
    return picture != null && picture.isNotEmpty;
  }

  Widget _buildAvatar({
    required String name,
    String? picture,
    double radius = 14,
    Color backgroundColor = Colors.teal,
    Color fallbackColor = Colors.white,
    double fontSize = 12,
  }) {
    final hasPicture = _validPicture(picture);

    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      backgroundImage: hasPicture ? NetworkImage(picture!) : null,
      child: hasPicture
          ? null
          : Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'Ad',
              style: TextStyle(
                color: fallbackColor,
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }
}
