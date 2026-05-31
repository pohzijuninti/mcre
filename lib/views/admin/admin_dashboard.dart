import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/admin_controller.dart';
import 'area_management_view.dart';
import 'employee_management_view.dart';
import '../chat/chat_list_view.dart';

import '../employee/content_feed_view.dart';

class AdminDashboard extends StatelessWidget {
  final AuthController authController = Get.find<AuthController>();

  AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: RefreshIndicator(
        onRefresh: () async {
          //refresh the data from area and employee
          final AdminController adminController = Get.find<AdminController>();
          adminController.onInit();
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Admin Dashboard'),
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                onPressed: () => authController.logout(),
                icon: const Icon(Icons.logout),
              ),
            ],
            bottom: const TabBar(
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
              tabs: [
                Tab(icon: Icon(Icons.feed), text: 'Feed'),
                Tab(icon: Icon(Icons.location_on), text: 'Areas'),
                Tab(icon: Icon(Icons.people), text: 'Employees'),
                Tab(icon: Icon(Icons.chat), text: 'Chats'),
              ],
            ),
          ),
          body: TabBarView(
            children: [ContentFeedView(), AreaManagementView(), EmployeeManagementView(), ChatListView()],
          ),
        ),
      ),
    );
  }
}
