import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../services/firebase_service.dart';
import '../services/cloudinary_service.dart';
import '../models/content_model.dart';
import '../models/user_model.dart';
import 'auth_controller.dart';
import 'dart:io';

class EmployeeController extends GetxController {
  final FirebaseService _firebaseService = FirebaseService();
  final AuthController _authController = Get.find<AuthController>();
  final CloudinaryService _cloudinaryService = CloudinaryService();

  // Observable state
  final RxList<ContentModel> _allContent = <ContentModel>[].obs;
  final RxList<UserModel> allUsers = <UserModel>[].obs;
  final RxString searchQuery = ''.obs;

  // Filters
  final RxString filterDate =
      'Filter by date'.obs; // 'Filter by date', 'Newest', 'Oldest'
  final RxString filterOwnership = 'All'.obs; // 'All', 'My Content', 'Others'
  final RxString filterArea = 'All'.obs;

  @override
  void onInit() {
    super.onInit();
    _allContent.bindStream(_firebaseService.getContentStream());
    allUsers.bindStream(_firebaseService.getAllUsers());
  }

  // Filtered List
  List<ContentModel> get filteredContent {
    List<ContentModel> filtered = _allContent.toList();

    // Search
    if (searchQuery.value.isNotEmpty) {
      filtered = filtered.where((c) {
        final query = searchQuery.value.toLowerCase();
        final textMatch = c.text?.toLowerCase().contains(query) ?? false;
        final authorMatch = c.authorName.toLowerCase().contains(query);
        final areaMatch = c.area.any(
          (area) => area.toLowerCase().contains(query),
        );
        final dateMatch = _searchableDates(
          c.createdAt,
        ).any((date) => date.toLowerCase().contains(query));
        return textMatch || authorMatch || areaMatch || dateMatch;
      }).toList();
    }

    // Ownership Filter
    final currentUserId = _authController.currentUser.value?.id;
    if (filterOwnership.value == 'My Content') {
      filtered = filtered.where((c) => c.authorId == currentUserId).toList();
    } else if (filterOwnership.value == 'Others') {
      filtered = filtered.where((c) => c.authorId != currentUserId).toList();
    }

    // Area Filter
    if (filterArea.value != 'All') {
      filtered = filtered
          .where((c) => c.area.contains(filterArea.value))
          .toList();
    }

    // Date Sorting
    if (filterDate.value == 'Oldest') {
      filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    } else {
      filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return filtered;
  }

  List<String> _searchableDates(DateTime date) {
    return [
      DateFormat('MMM dd, yyyy - hh:mm a').format(date),
      DateFormat('MMM dd, yyyy').format(date),
      DateFormat('dd MMM').format(date),
      DateFormat('d MMM').format(date),
      DateFormat('dd MMM yyyy').format(date),
      DateFormat('d MMM yyyy').format(date),
      DateFormat('yyyy-MM-dd').format(date),
      DateFormat('dd/MM/yyyy').format(date),
      DateFormat('MM/dd/yyyy').format(date),
    ];
  }

  // List of unique areas for the dropdown
  List<String> get availableAreas {
    final Set<String> areas = {'All'};
    for (var content in _allContent) {
      areas.addAll(content.area);
    }
    return areas.toList();
  }

  Future<void> addContent({
    required String text,
    List<File>? imageFiles,
    required String selectedArea,
  }) async {
    final user = _authController.currentUser.value;
    if (user == null) return;

    List<String> imageUrls = [];
    if (imageFiles != null && imageFiles.isNotEmpty) {
      for (var file in imageFiles) {
        String? url = await _cloudinaryService.uploadImage(file);
        if (url != null) {
          imageUrls.add(url);
        }
      }
    }

    final newContent = ContentModel(
      id: '', // Generated in FirebaseService
      text: text,
      imageUrls: imageUrls.isNotEmpty ? imageUrls : null,
      authorId: user.id,
      authorName: user.name,
      authorRole: user.role.toString().split('.').last,
      area: [selectedArea],
      createdAt: DateTime.now(),
    );

    await _firebaseService.addContent(newContent);
  }

  Future<void> updateContent(String id, String newText) async {
    await _firebaseService.updateContent(id, newText, null);
  }

  Future<void> deleteContent(String id) async {
    await _firebaseService.deleteContent(id);
  }

  Future<void> addComment(
    String contentId,
    String text, {
    File? imageFile,
  }) async {
    final user = _authController.currentUser.value;
    if (user == null) return;

    String? imageUrl;
    if (imageFile != null) {
      imageUrl = await _cloudinaryService.uploadImage(imageFile);
    }

    final comment = CommentModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      imageUrl: imageUrl,
      authorId: user.id,
      authorName: user.name,
      createdAt: DateTime.now(),
    );

    await _firebaseService.addComment(contentId, comment);
  }

  // Statistics
  Map<String, int> getContentDistributionByArea() {
    final Map<String, int> distribution = {};
    for (var content in _allContent) {
      if (content.area.isEmpty) {
        distribution['Unknown'] = (distribution['Unknown'] ?? 0) + 1;
      } else {
        for (var area in content.area) {
          distribution[area] = (distribution[area] ?? 0) + 1;
        }
      }
    }
    return distribution;
  }
}
