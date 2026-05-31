import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:io';
import '../models/user_model.dart';
import '../services/firebase_service.dart';
import '../services/cloudinary_service.dart';

class AuthController extends GetxController {
  final FirebaseService _firebaseService = Get.find<FirebaseService>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CloudinaryService _cloudinaryService = CloudinaryService();

  var currentUser = Rxn<UserModel>();
  var isLoading = false.obs;

  bool get isAdmin => currentUser.value?.role == UserRole.admin;
  bool get isLoggedIn => currentUser.value != null;

  @override
  void onInit() {
    super.onInit();
    // Listen to auth state changes
    _auth.authStateChanges().listen((User? user) async {
      if (user != null) {
        final profile = await _firebaseService.getUserProfile(user.uid);
        currentUser.value = profile;
        // Navigation removed from here to force login screen on startup
      } else {
        currentUser.value = null;
        if (Get.currentRoute != '/login') {
          Get.offAllNamed('/login');
        }
      }
    });
  }

  void login(String email, String password, String selectedRole) async {
    isLoading.value = true;
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      if (userCredential.user != null) {
        final profile = await _firebaseService.getUserProfile(userCredential.user!.uid);
        currentUser.value = profile;

        if (profile != null) {
          // Validate role mapping
          bool isRoleValid = false;
          if (selectedRole == 'Admin' && profile.role == UserRole.admin) {
            isRoleValid = true;
          } else if (selectedRole == 'Employer' && profile.role == UserRole.employer) {
            isRoleValid = true;
          } else if (selectedRole == 'Employee' &&
              (profile.role == UserRole.employee ||
                  profile.role == UserRole.manager ||
                  profile.role == UserRole.supervisor)) {
            isRoleValid = true;
          }

          if (!isRoleValid) {
            await _auth.signOut();
            currentUser.value = null;
            Get.snackbar('Login Failed', 'Role mismatch. You are not registered as $selectedRole.',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Get.theme.colorScheme.errorContainer,
                colorText: Get.theme.colorScheme.onErrorContainer);
            return;
          }

          // Route to appropriate dashboard
          if (profile.role == UserRole.admin) {
            Get.offAllNamed('/admin-dashboard');
          } else if (profile.role == UserRole.employer) {
            Get.offAllNamed('/employer-dashboard');
          } else {
            Get.offAllNamed('/employee-dashboard');
          }
        } else {
          Get.snackbar('Login Error', 'User profile not found in database.',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Get.theme.colorScheme.errorContainer,
              colorText: Get.theme.colorScheme.onErrorContainer);
        }
      }
    } on FirebaseAuthException catch (e) {
      Get.snackbar('Login Failed', e.message ?? 'Unknown error',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.errorContainer,
          colorText: Get.theme.colorScheme.onErrorContainer);
    } finally {
      isLoading.value = false;
    }
  }

  void logout() async {
    await _auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    if (email.isEmpty) {
      Get.snackbar('Error', 'Please enter your email to reset password.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.errorContainer,
          colorText: Get.theme.colorScheme.onErrorContainer);
      return;
    }
    if (!GetUtils.isEmail(email)) {
      Get.snackbar('Error', 'Please enter a valid email address.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.errorContainer,
          colorText: Get.theme.colorScheme.onErrorContainer);
      return;
    }

    isLoading.value = true;
    try {
      bool emailExists = await _firebaseService.checkEmailExists(email);
      if (!emailExists) {
        Get.snackbar('Error', 'Email not found in the database.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Get.theme.colorScheme.errorContainer,
            colorText: Get.theme.colorScheme.onErrorContainer);
        return;
      }

      await _auth.sendPasswordResetEmail(email: email);
      Get.snackbar('Success', 'Password reset link sent to your email.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.teal.shade100,
          colorText: Colors.teal.shade900);
    } on FirebaseAuthException catch (e) {
      Get.snackbar('Reset Failed', e.message ?? 'Unknown error',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.errorContainer,
          colorText: Get.theme.colorScheme.onErrorContainer);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updatePassword(String oldPassword, String newPassword) async {
    if (newPassword.isEmpty || newPassword.length < 6) {
      Get.snackbar('Error', 'Password must be at least 6 characters.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.errorContainer,
          colorText: Get.theme.colorScheme.onErrorContainer);
      return;
    }
    if (oldPassword.isEmpty) {
      Get.snackbar('Error', 'Please enter your current password.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.errorContainer,
          colorText: Get.theme.colorScheme.onErrorContainer);
      return;
    }
    isLoading.value = true;
    try {
      final user = _auth.currentUser;
      if (user != null && user.email != null) {
        AuthCredential credential = EmailAuthProvider.credential(
          email: user.email!,
          password: oldPassword,
        );
        await user.reauthenticateWithCredential(credential);

        await user.updatePassword(newPassword);
        Get.snackbar('Success', 'Password updated successfully.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.teal.shade100,
            colorText: Colors.teal.shade900);
      }
    } on FirebaseAuthException catch (e) {
      Get.snackbar('Update Failed', e.message ?? 'Unknown error',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.errorContainer,
          colorText: Get.theme.colorScheme.onErrorContainer);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateProfilePicture(File imageFile) async {
    final user = currentUser.value;
    if (user == null) return;

    isLoading.value = true;
    try {
      String? imageUrl = await _cloudinaryService.uploadImage(imageFile);
      if (imageUrl != null) {
        final updatedUser = user.copyWith(picture: imageUrl);
        await _firebaseService.updateUserProfile(updatedUser);
        currentUser.value = updatedUser; // Update local state
        Get.snackbar('Success', 'Profile picture updated successfully.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.teal.shade100,
            colorText: Colors.teal.shade900);
      } else {
        Get.snackbar('Error', 'Failed to upload image.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Get.theme.colorScheme.errorContainer,
            colorText: Get.theme.colorScheme.onErrorContainer);
      }
    } catch (e) {
      Get.snackbar('Error', 'An error occurred while updating profile picture.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.errorContainer,
          colorText: Get.theme.colorScheme.onErrorContainer);
    } finally {
      isLoading.value = false;
    }
  }
}
