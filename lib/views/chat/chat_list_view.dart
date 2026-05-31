import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/chat_controller.dart';
import 'chat_contacts_view.dart';
import 'chat_room_view.dart';

class ChatListView extends StatelessWidget {
  ChatListView({super.key});

  final ChatController controller = Get.find<ChatController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        final rooms = controller.myChatRooms
            .where((room) => room.lastMessage != null)
            .toList();
        if (rooms.isEmpty) {
          return const Center(child: Text('No recent chats.'));
        }
        return ListView.builder(
          itemCount: rooms.length,
          itemBuilder: (context, index) {
            final room = rooms[index];
            final peerName = controller.getPeerName(room);
            final peerPicture = controller.getPeerUser(room)?.picture;
            final timeStr = room.lastMessageTime != null
                ? DateFormat('hh:mm a').format(room.lastMessageTime!)
                : '';

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.teal,
                backgroundImage: peerPicture != null && peerPicture.isNotEmpty
                    ? NetworkImage(peerPicture)
                    : null,
                child: peerPicture == null || peerPicture.isEmpty
                    ? Text(
                        peerName.isNotEmpty ? peerName[0].toUpperCase() : 'Ad',
                        style: const TextStyle(color: Colors.white),
                      )
                    : null,
              ),
              title: Text(
                peerName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                room.lastMessage ?? 'No messages yet',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Text(
                timeStr,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              onTap: () {
                Get.to(
                  () => ChatRoomView(
                    roomId: room.id,
                    peerName: peerName,
                    peerPicture: peerPicture,
                  ),
                );
              },
            );
          },
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Get.to(() => ChatContactsView());
        },
        backgroundColor: Colors.teal,
        child: const Icon(Icons.chat),
      ),
    );
  }
}
