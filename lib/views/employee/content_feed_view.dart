import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/employee_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../models/content_model.dart';
import '../../models/user_model.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class ContentFeedView extends StatelessWidget {
  final EmployeeController employeeController = Get.find<EmployeeController>();
  final AuthController authController = Get.find<AuthController>();

  ContentFeedView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilters(),
          Expanded(child: _buildContentList()),
        ],
      ),
      floatingActionButton: Obx(() {
        final role = authController.currentUser.value?.role;
        if (role == UserRole.employer || role == UserRole.admin) {
          return const SizedBox.shrink();
        }
        return FloatingActionButton(
          onPressed: () => _showAddContentSheet(context),
          backgroundColor: Colors.teal,
          child: const Icon(Icons.add, color: Colors.white),
        );
      }),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        onChanged: (val) => employeeController.searchQuery.value = val,
        decoration: InputDecoration(
          hintText: 'Search content, area, staff or date',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Obx(() {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildDropdown(
                value: employeeController.filterDate.value,
                items: ['Filter by date', 'Newest', 'Oldest'],
                onChanged: (val) => employeeController.filterDate.value = val!,
              ),
              const SizedBox(width: 8),
              _buildDropdown(
                value: employeeController.filterOwnership.value,
                items: ['All', 'My Content', 'Others'],
                onChanged: (val) =>
                    employeeController.filterOwnership.value = val!,
              ),
              const SizedBox(width: 8),
              _buildDropdown(
                value: employeeController.filterArea.value,
                items: employeeController.availableAreas,
                onChanged: (val) => employeeController.filterArea.value = val!,
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    // Ensure value is in items, otherwise fallback to first item
    final validValue = items.contains(value)
        ? value
        : (items.isNotEmpty ? items.first : '');
    if (validValue.isEmpty) return const SizedBox();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.teal.shade200),
      ),
      child: DropdownButton<String>(
        value: validValue,
        underline: const SizedBox(),
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildContentList() {
    return Obx(() {
      final contentList = employeeController.filteredContent;
      if (contentList.isEmpty) {
        return const Center(child: Text('No content found.'));
      }
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: contentList.length,
        itemBuilder: (context, index) {
          final content = contentList[index];
          return _buildContentCard(context, content);
        },
      );
    });
  }

  Widget _buildContentCard(BuildContext context, ContentModel content) {
    final currentUserId = authController.currentUser.value?.id;
    final isOwner = content.authorId == currentUserId;
    final dateFormat = DateFormat('MMM dd, yyyy - hh:mm a');

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Obx(() {
                  final authorList = employeeController.allUsers.where(
                    (u) => u.id == content.authorId,
                  );
                  final picture = authorList.isNotEmpty
                      ? authorList.first.picture
                      : null;
                  return CircleAvatar(
                    backgroundColor: Colors.teal.shade100,
                    backgroundImage: picture != null
                        ? NetworkImage(picture)
                        : null,
                    child: picture == null
                        ? Text(
                            content.authorName[0].toUpperCase(),
                            style: const TextStyle(color: Colors.teal),
                          )
                        : null,
                  );
                }),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        content.authorName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        _formatRole(content.authorRole),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isOwner)
                  PopupMenuButton<String>(
                    onSelected: (val) {
                      if (val == 'edit') {
                        _showEditContentSheet(context, content);
                      } else if (val == 'delete') {
                        employeeController.deleteContent(content.id);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              content.area.join(', '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            if (content.text != null && content.text!.isNotEmpty)
              Text(content.text!, style: const TextStyle(fontSize: 15)),
            if (content.imageUrls != null && content.imageUrls!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: content.imageUrls!.length,
                    itemBuilder: (context, idx) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            content.imageUrls![idx],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 200,
                                color: Colors.grey.shade200,
                                child: const Center(
                                  child: Icon(
                                    Icons.broken_image,
                                    color: Colors.grey,
                                    size: 40,
                                  ),
                                ),
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                width: 200,
                                color: Colors.grey.shade100,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    value:
                                        loadingProgress.expectedTotalBytes !=
                                            null
                                        ? loadingProgress
                                                  .cumulativeBytesLoaded /
                                              (loadingProgress
                                                      .expectedTotalBytes ??
                                                  1)
                                        : null,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dateFormat.format(content.createdAt),
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
                TextButton.icon(
                  onPressed: () => _showCommentsSheet(context, content),
                  icon: const Icon(Icons.comment, size: 18),
                  label: Text('${content.comments.length} Comments'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddContentSheet(BuildContext context) {
    final textController = TextEditingController();
    final rxImages = RxList<File>();

    final currentUser = authController.currentUser.value;
    final userAreas = currentUser?.areas?.isNotEmpty == true
        ? currentUser!.areas!
        : ['General'];
    final selectedArea = RxString(userAreas.first);

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add Content',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Obx(
                () => DropdownButtonFormField<String>(
                  value: selectedArea.value,
                  decoration: InputDecoration(
                    labelText: 'Post for Area',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  items: userAreas
                      .map(
                        (area) =>
                            DropdownMenuItem(value: area, child: Text(area)),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) selectedArea.value = val;
                  },
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: textController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'What\'s on your mind?',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      final picker = ImagePicker();
                      final pickedFiles = await picker.pickMultiImage();
                      if (pickedFiles.isNotEmpty) {
                        rxImages.addAll(pickedFiles.map((x) => File(x.path)));
                      }
                    },
                    icon: const Icon(Icons.image),
                    label: const Text('Add Image(s)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade200,
                      foregroundColor: Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Obx(
                () => rxImages.isNotEmpty
                    ? Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: rxImages
                            .map(
                              (file) => Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      file,
                                      width: 60,
                                      height: 60,
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
                                      onPressed: () => rxImages.remove(file),
                                    ),
                                  ),
                                ],
                              ),
                            )
                            .toList(),
                      )
                    : const SizedBox(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (textController.text.trim().isEmpty &&
                        rxImages.isEmpty) {
                      Get.snackbar(
                        'Error',
                        'Please enter text or select an image',
                      );
                      return;
                    }
                    Get.back();
                    Get.snackbar(
                      'Uploading',
                      'Your content is being uploaded...',
                      showProgressIndicator: true,
                      duration: const Duration(seconds: 2),
                    );
                    await employeeController.addContent(
                      text: textController.text.trim(),
                      imageFiles: rxImages.toList(),
                      selectedArea: selectedArea.value,
                    );
                    Get.snackbar('Success', 'Content added successfully');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Post Content',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  String _formatRole(String role) {
    if (role.isEmpty) return role;
    return role[0].toUpperCase() + role.substring(1).toLowerCase();
  }

  void _showEditContentSheet(BuildContext context, ContentModel content) {
    final textController = TextEditingController(text: content.text);

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Edit Content',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: textController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'What\'s on your mind?',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (textController.text.trim().isEmpty) {
                      Get.snackbar('Error', 'Text cannot be empty');
                      return;
                    }
                    Get.back();
                    await employeeController.updateContent(
                      content.id,
                      textController.text.trim(),
                    );
                    Get.snackbar('Success', 'Content updated successfully');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Update Content',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _showCommentsSheet(BuildContext context, ContentModel content) {
    final commentController = TextEditingController();
    final Rxn<File> selectedImage = Rxn<File>();

    Get.bottomSheet(
      Container(
        height: Get.height * 0.7,
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const Text(
              'Comments',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            Expanded(
              child: Obx(() {
                final currentContent = employeeController.filteredContent
                    .firstWhere(
                      (c) => c.id == content.id,
                      orElse: () => content,
                    );
                return currentContent.comments.isEmpty
                    ? const Center(child: Text('No comments yet.'))
                    : ListView.builder(
                        itemCount: currentContent.comments.length,
                        itemBuilder: (context, index) {
                          final comment = currentContent.comments[index];
                          final dateFormat = DateFormat('MMM dd, hh:mm a');
                          return ListTile(
                            leading: Obx(() {
                              final authorList = employeeController.allUsers
                                  .where((u) => u.id == comment.authorId);
                              final picture = authorList.isNotEmpty
                                  ? authorList.first.picture
                                  : null;
                              return CircleAvatar(
                                backgroundColor: Colors.teal.shade50,
                                backgroundImage: picture != null
                                    ? NetworkImage(picture)
                                    : null,
                                child: picture == null
                                    ? Text(comment.authorName[0].toUpperCase())
                                    : null,
                              );
                            }),
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  comment.authorName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  dateFormat.format(comment.createdAt),
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (comment.text.isNotEmpty) Text(comment.text),
                                if (comment.imageUrl != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        comment.imageUrl!,
                                        height: 100,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      );
              }),
            ),
            Obx(
              () => selectedImage.value != null
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  selectedImage.value!,
                                  width: 60,
                                  height: 60,
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
                                  onPressed: () => selectedImage.value = null,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  : const SizedBox(),
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
                      selectedImage.value = File(pickedFile.path);
                    }
                  },
                ),
                Expanded(
                  child: TextField(
                    controller: commentController,
                    decoration: InputDecoration(
                      hintText: 'Write a comment...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.teal),
                  onPressed: () async {
                    if (commentController.text.trim().isNotEmpty ||
                        selectedImage.value != null) {
                      Get.snackbar(
                        'Uploading',
                        'Your comment is being posted...',
                        showProgressIndicator: true,
                        duration: const Duration(seconds: 2),
                      );
                      await employeeController.addComment(
                        content.id,
                        commentController.text.trim(),
                        imageFile: selectedImage.value,
                      );
                      commentController.clear();
                      selectedImage.value = null;
                      Get.snackbar('Success', 'Comment added');
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }
}
