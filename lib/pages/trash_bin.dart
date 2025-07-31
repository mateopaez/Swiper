import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

class TrashBinScreen extends StatelessWidget {
  final List<AssetEntity> trashedPhotos;
  final VoidCallback onEmptyTrash;
  
  // Constructor to accept trashed photos and a callback for emptying the trash
  const TrashBinScreen({
    super.key,
    required this.trashedPhotos,
    required this.onEmptyTrash});

  Future<void> _confirmAndDelete(BuildContext context) async {
    if (trashedPhotos.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Photos'),
        content: const Text('Are you sure you want to permanently delete these photos?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await PhotoManager.editor.deleteWithIds(trashedPhotos.map((e) => e.id).toList());
      onEmptyTrash();
      Navigator.pop(context);
      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(content: Text('Photos permanently deleted')),
      // );
    }
  }

  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Trash Bin"),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: () => _confirmAndDelete(context),
          ),
        ],
      ),
      body: trashedPhotos.isEmpty
          ? const Center(child: Text("Trash bin is empty."))
          : GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,),
              itemCount: trashedPhotos.length,
              itemBuilder: (_, index) {
                return FutureBuilder<Uint8List?>(
                  future: trashedPhotos[index].thumbnailDataWithSize(ThumbnailSize(200, 200)) as Future<Uint8List?>?,
                  builder: (_, snapshot) {
                    if (!snapshot.hasData) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Image.memory(
                        snapshot.data!,
                        fit: BoxFit.cover,
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}