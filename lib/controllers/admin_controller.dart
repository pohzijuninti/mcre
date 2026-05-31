import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/user_model.dart';
import '../models/area_role_model.dart';
import '../services/firebase_service.dart';

enum EmployeeSortType { datetime, area, role, name }

class AdminController extends GetxController {
  final FirebaseService _firebaseService = Get.find<FirebaseService>();

  var areaRoles = <AreaRoleModel>[].obs;
  var employees = <UserModel>[].obs;

  // Search and Sort State
  var searchText = ''.obs;
  var sortType = EmployeeSortType.datetime.obs;
  var isAscending = false.obs;

  var areaSearchText = ''.obs;
  var areaSortAscending = true.obs;

  @override
  void onInit() {
    super.onInit();
    // Bind streams
    areaRoles.bindStream(_firebaseService.getAreaRoles());
    employees.bindStream(_firebaseService.getEmployees());
  }

  // Reactive lists for searching and sorting
  List<AreaRoleModel> get filteredAreaRoles {
    List<AreaRoleModel> list = areaRoles.where((role) {
      final query = areaSearchText.value.toLowerCase();
      return role.name.toLowerCase().contains(query);
    }).toList();

    list.sort((a, b) {
      int comparison = a.name.toLowerCase().compareTo(b.name.toLowerCase());
      return areaSortAscending.value ? comparison : -comparison;
    });

    return list;
  }

  List<UserModel> get filteredEmployees {
    List<UserModel> list = employees.where((emp) {
      final query = searchText.value.toLowerCase();
      return emp.name.toLowerCase().contains(query) ||
          emp.email.toLowerCase().contains(query);
    }).toList();

    // Sorting
    list.sort((a, b) {
      int comparison = 0;
      switch (sortType.value) {
        case EmployeeSortType.datetime:
          comparison = (a.createdAt ?? DateTime(0)).compareTo(
            b.createdAt ?? DateTime(0),
          );
          break;
        case EmployeeSortType.area:
          comparison = (a.areas?.join(', ') ?? '').compareTo(
            b.areas?.join(', ') ?? '',
          );
          break;
        case EmployeeSortType.name:
          comparison = a.name.toLowerCase().compareTo(b.name.toLowerCase());
          break;
        case EmployeeSortType.role:
          comparison = a.role.index.compareTo(b.role.index);
          break;
      }
      return isAscending.value ? comparison : -comparison;
    });

    return list;
  }

  // Role (Area) Management
  void addAreaRole(String name) async {
    await _firebaseService.addAreaRole(name);
  }

  void updateAreaRole(String id, String prevName, String name) async {
    await _firebaseService.updateAreaRole(id, prevName, name);
  }

  void deleteAreaRole(String id) async {
    await _firebaseService.deleteAreaRole(id);
    Get.snackbar(
      'Area Deleted',
      'Area removed from database.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  // Employee Management
  void addEmployee(UserModel employee) async {
    try {
      await _firebaseService.saveUserProfile(employee);
      Get.snackbar(
        'Employee Added',
        'Profile created in database.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Failed to Add',
        e.toString().contains('wrong-password') ||
                e.toString().contains('invalid-credential')
            ? 'Email exists. You must enter their exact previous password to restore them.'
            : 'Error adding employee: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
        duration: const Duration(seconds: 4),
      );
    }
  }

  void updateEmployee(UserModel employee) async {
    await _firebaseService.updateUserProfile(employee);
    Get.snackbar(
      'Employee Updated',
      'Profile updated successfully.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  Future<void> deleteEmployee(String uid) async {
    try {
      await _firebaseService.deleteEmployee(uid);
      Get.snackbar(
        'Employee Deleted',
        'Profile removed from database.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Failed to Delete',
        'Error deleting employee: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
      );
    }
  }

  void setSearchText(String text) => searchText.value = text;

  void setSortType(EmployeeSortType type) {
    if (sortType.value == type) {
      isAscending.value = !isAscending.value;
    } else {
      sortType.value = type;
      isAscending.value = true;
    }
  }

  void setAreaSearchText(String text) => areaSearchText.value = text;

  void toggleAreaSort() => areaSortAscending.value = !areaSortAscending.value;
}
