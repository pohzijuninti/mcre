import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/admin_controller.dart';
import '../../models/user_model.dart';

class EmployeeManagementView extends StatelessWidget {
  const EmployeeManagementView({super.key});

  @override
  Widget build(BuildContext context) {
    final AdminController adminController = Get.find<AdminController>();

    return RefreshIndicator(
      onRefresh: () async {
        adminController.onInit();
      },
      child: Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showEmployeeDialog(context),
          child: const Icon(Icons.person_add),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: (val) => adminController.setSearchText(val),
                      decoration: InputDecoration(
                        hintText: 'Search employees...',
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
                    () => PopupMenuButton<EmployeeSortType>(
                      icon: Icon(
                        Icons.sort,
                        color: adminController.isAscending.value
                            ? Colors.blue
                            : Colors.red,
                      ),
                      onSelected: (type) => adminController.setSortType(type),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: EmployeeSortType.datetime,
                          child: Text('Sort by Date'),
                        ),
                        const PopupMenuItem(
                          value: EmployeeSortType.area,
                          child: Text('Sort by Area'),
                        ),
                        const PopupMenuItem(
                          value: EmployeeSortType.name,
                          child: Text('Sort by Name'),
                        ),
                        const PopupMenuItem(
                          value: EmployeeSortType.role,
                          child: Text('Sort by Role'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Obx(() {
                final list = adminController.filteredEmployees;
                if (list.isEmpty) {
                  return const Center(child: Text('No employees found.'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final emp = list[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: emp.picture != null
                              ? NetworkImage(emp.picture!)
                              : null,
                          child: emp.picture == null
                              ? const Icon(Icons.person)
                              : null,
                        ),
                        title: Text(
                          emp.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(emp.email),
                            Text(
                              '${emp.role.name.capitalizeFirst} • ${emp.areas?.join(', ') ?? "No Area"} • ${emp.nationality ?? "Unknown"}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () =>
                                  _showEmployeeDialog(context, employee: emp),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () =>
                                  _showDeleteConfirmation(context, emp),
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
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, UserModel employee) {
    Get.defaultDialog(
      title: 'Delete Employee',
      middleText: 'Are you sure you want to delete ${employee.name}?',
      textConfirm: 'Delete',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () async {
        final adminController = Get.find<AdminController>();
        Get.back();
        await adminController.deleteEmployee(employee.id);
      },
    );
  }

  void _showEmployeeDialog(BuildContext context, {UserModel? employee}) {
    final nameController = TextEditingController(text: employee?.name);
    final emailController = TextEditingController(text: employee?.email);
    final passwordController = TextEditingController();
    final nationalityController = TextEditingController(
      text: employee?.nationality,
    );

    final AdminController adminController = Get.find<AdminController>();

    var selectedUserRole = (employee?.role ?? UserRole.employee).obs;
    var selectedAreas = (employee?.areas ?? []).obs;

    Get.defaultDialog(
      title: employee == null ? 'Add Employee' : 'Edit Employee',
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            if (employee == null)
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
              ),
            TextField(
              controller: nationalityController,
              decoration: const InputDecoration(
                labelText: 'Nationality (e.g., China)',
              ),
            ),
            const SizedBox(height: 16),
            Obx(
              () => DropdownButtonFormField<UserRole>(
                value: selectedUserRole.value,
                decoration: const InputDecoration(labelText: 'Job Role'),
                items:
                    [
                          UserRole.employer,
                          UserRole.manager,
                          UserRole.supervisor,
                          UserRole.employee,
                        ]
                        .map(
                          (r) => DropdownMenuItem(
                            value: r,
                            child: Text(r.name.capitalizeFirst!),
                          ),
                        )
                        .toList(),
                onChanged: (val) => selectedUserRole.value = val!,
              ),
            ),
            const SizedBox(height: 8),
            const SizedBox(height: 8),
            const Text(
              'Areas',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Obx(
              () => Wrap(
                spacing: 8.0,
                children: adminController.areaRoles.map((r) {
                  final isSelected = selectedAreas.contains(r.name);
                  return FilterChip(
                    label: Text(r.name),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        selectedAreas.add(r.name);
                      } else {
                        selectedAreas.remove(r.name);
                      }
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
      textConfirm: 'Save',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      onConfirm: () {
        if (nameController.text.isNotEmpty && emailController.text.isNotEmpty) {
          if (employee == null) {
            // Creation mode
            if (passwordController.text.isEmpty) {
              Get.snackbar('Error', 'Password is required for new employees');
              return;
            }
            final newEmp = UserModel(
              id: '', // Will be set by FirebaseService
              name: nameController.text,
              role: selectedUserRole.value,
              areas: selectedAreas.toList(),
              nationality: nationalityController.text,
              email: emailController.text,
              password: passwordController.text,
            );
            adminController.addEmployee(newEmp);
          } else {
            // Update mode
            final updatedEmp = employee.copyWith(
              name: nameController.text,
              email: emailController.text,
              role: selectedUserRole.value,
              areas: selectedAreas.toList(),
              nationality: nationalityController.text,
            );
            adminController.updateEmployee(updatedEmp);
          }
          Get.back();
        }
      },
    );
  }
}
