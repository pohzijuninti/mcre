import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/admin_controller.dart';

class AreaManagementView extends StatelessWidget {
  const AreaManagementView({super.key});

  @override
  Widget build(BuildContext context) {
    final AdminController adminController = Get.find<AdminController>();

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAreaDialog(context),
        child: const Icon(Icons.add_location_alt),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (val) => adminController.setAreaSearchText(val),
                    decoration: InputDecoration(
                      hintText: 'Search areas...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Obx(
                  () => IconButton(
                    icon: Icon(
                      adminController.areaSortAscending.value
                          ? Icons.sort_by_alpha
                          : Icons.sort_by_alpha_outlined,
                      color: Colors.teal,
                    ),
                    onPressed: () => adminController.toggleAreaSort(),
                    tooltip: 'Toggle Sort Order',
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Obx(() {
              final list = adminController.filteredAreaRoles;
              if (list.isEmpty) {
                return const Center(child: Text('No areas found.'));
              }
              return ListView.builder(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                itemCount: list.length,
                itemBuilder: (context, index) {
                  final area = list[index];
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      title: Text(
                        area.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _showAreaDialog(
                              context,
                              areaId: area.id,
                              currentName: area.name,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => {
                              adminController.deleteAreaRole(area.id),
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  void _showAreaDialog(
    BuildContext context, {
    String? areaId,
    String? currentName,
  }) {
    final controller = TextEditingController(text: currentName);
    final AdminController adminController = Get.find<AdminController>();

    Get.defaultDialog(
      title: areaId == null ? 'Add Area' : 'Edit Area',
      content: TextField(
        controller: controller,
        decoration: const InputDecoration(labelText: 'Area Name (e.g., Area1)'),
      ),
      textConfirm: 'Save',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      onConfirm: () {
        if (controller.text.isNotEmpty) {
          if (areaId == null) {
            adminController.addAreaRole(controller.text);
          } else {
            adminController.updateAreaRole(areaId, currentName!, controller.text);
          }
          Get.back();
        }
      },
    );
  }
}
