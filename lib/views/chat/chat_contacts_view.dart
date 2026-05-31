import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/chat_controller.dart';
import 'chat_room_view.dart';

class ChatContactsView extends StatelessWidget {
  ChatContactsView({super.key});

  final ChatController controller = Get.find<ChatController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Contact'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Obx(() {
        final contacts = controller.contacts;
        if (contacts.isEmpty) {
          return const Center(child: Text('No contacts available.'));
        }

        return ListView.builder(
          itemCount: contacts.length,
          itemBuilder: (context, index) {
            final user = contacts[index];
            final roleName =
                user.role.toString().split('.').last.capitalizeFirst ?? '';

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.teal,
                backgroundImage: user.picture != null
                    ? NetworkImage(user.picture!)
                    : null,
                child: user.picture == null
                    ? Text(
                        user.name.isNotEmpty
                            ? user.name[0].toUpperCase()
                            : 'Ad',
                        style: const TextStyle(color: Colors.white),
                      )
                    : null,
              ),
              title: Text(
                user.name.isNotEmpty ? user.name : 'Admin',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(roleName),
              onTap: () async {
                try {
                  Get.dialog(
                    const Center(child: CircularProgressIndicator()),
                    barrierDismissible: false,
                  );
                  final roomId = await controller.startOrGetChat(user);
                  Get.back(); // close dialog
                  Get.off(
                    () => ChatRoomView(
                      roomId: roomId,
                      peerName: user.name,
                      peerPicture: user.picture,
                    ),
                  );
                } catch (e) {
                  Get.back();
                  Get.snackbar('Error', 'Failed to start chat: $e');
                }
              },
            );
          },
        );
      }),
    );
  }
}
