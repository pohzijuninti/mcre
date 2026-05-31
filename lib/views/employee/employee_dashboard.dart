import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../controllers/auth_controller.dart';
import 'content_feed_view.dart';
import 'statistics_view.dart';
import '../chat/chat_list_view.dart';

class EmployeeDashboard extends StatelessWidget {
  final AuthController authController = Get.find<AuthController>();

  EmployeeDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        drawer: _buildDrawer(context),
        appBar: AppBar(
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          title: const Text('Staff Portal'),
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(icon: Icon(Icons.feed), text: 'Feed'),
              Tab(icon: Icon(Icons.pie_chart), text: 'Stats'),
              Tab(icon: Icon(Icons.chat), text: 'Chats'),
            ],
          ),
        ),
        body: TabBarView(
          children: [ContentFeedView(), StatisticsView(), ChatListView()],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final user = authController.currentUser.value;
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Colors.teal),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundImage: user?.picture != null
                      ? NetworkImage(user!.picture!)
                      : null,
                  child: user?.picture == null
                      ? const Icon(Icons.person, size: 36)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? 'Unknown',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildAreasText(user?.areas),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('My Profile'),
            onTap: () {
              Get.back(); // Close drawer
              _showProfileDialog(context);
            },
          ),
          const Spacer(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.lock_reset),
            title: const Text('Change Password'),
            onTap: () {
              Get.back(); // Close drawer
              _showChangePasswordDialog(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () => authController.logout(),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildAreasText(List<String>? areas) {
    if (areas == null || areas.isEmpty) {
      return const Text(
        'No Area Assigned',
        style: TextStyle(color: Colors.white70),
      );
    }

    return Flexible(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: areas
              .map(
                (area) => Text(
                  area,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  void _showProfileDialog(BuildContext context) {
    Get.defaultDialog(
      title: 'My Profile',
      content: Obx(() {
        final user = authController.currentUser.value;
        return Column(
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.teal,
                  backgroundImage: user?.picture != null
                      ? NetworkImage(user!.picture!)
                      : null,
                  child: user?.picture == null
                      ? const Icon(Icons.person, size: 40, color: Colors.white)
                      : null,
                ),
                CircleAvatar(
                  radius: 15,
                  backgroundColor: Colors.white,
                  child: authController.isLoading.value
                      ? const Padding(
                          padding: EdgeInsets.all(4.0),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(
                            Icons.camera_alt,
                            size: 15,
                            color: Colors.teal,
                          ),
                          onPressed: () async {
                            final picker = ImagePicker();
                            final pickedFile = await picker.pickImage(
                              source: ImageSource.gallery,
                            );
                            if (pickedFile != null) {
                              authController.updateProfilePicture(
                                File(pickedFile.path),
                              );
                            }
                          },
                        ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              user?.name ?? 'Unknown',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Role: ${user?.role.toString().split('.').last.capitalizeFirst ?? "N/A"}',
              style: const TextStyle(fontSize: 18, color: Colors.teal),
            ),
          ],
        );
      }),
      textConfirm: 'Close',
      confirmTextColor: Colors.white,
      buttonColor: Colors.teal,
      onConfirm: () => Get.back(),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final TextEditingController oldPasswordController = TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    Get.defaultDialog(
      title: 'Change Password',
      content: Column(
        children: [
          const Text('Enter your current and new password below.'),
          const SizedBox(height: 16),
          TextField(
            controller: oldPasswordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Current Password',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.lock_outline),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: newPasswordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'New Password',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.lock),
            ),
          ),
        ],
      ),
      textConfirm: 'Update',
      confirmTextColor: Colors.white,
      buttonColor: Colors.teal,
      textCancel: 'Cancel',
      onConfirm: () {
        if (oldPasswordController.text.isNotEmpty &&
            newPasswordController.text.isNotEmpty) {
          authController.updatePassword(
            oldPasswordController.text,
            newPasswordController.text,
          );
          Get.back(); // close dialog
        } else {
          Get.snackbar(
            'Error',
            'Passwords cannot be empty',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Get.theme.colorScheme.errorContainer,
            colorText: Get.theme.colorScheme.onErrorContainer,
          );
        }
      },
    );
  }
}
