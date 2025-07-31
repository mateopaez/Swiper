import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:swiper/pages/trash_bin.dart';
import 'dart:typed_data';

void main() {
  runApp(const PhotoCleanerApp());
}

class PhotoCleanerApp extends StatelessWidget {
  const PhotoCleanerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Photo Cleaner',
      home: const PhotoGalleryScreen(),
    );
  }
}

class PhotoGalleryScreen extends StatefulWidget {
  const PhotoGalleryScreen({super.key});

  @override
  _PhotoGalleryScreenState createState() => _PhotoGalleryScreenState();
}

class _PhotoGalleryScreenState extends State<PhotoGalleryScreen> {
  final List<AssetEntity> _trashedPhotos = [];
  List<AssetEntity> _photos = [];
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _requestPermissionAndLoadPhotos();
  }

  // Request permission and load photos from the gallery
  Future<void> _requestPermissionAndLoadPhotos() async {
    final PermissionState permission = await PhotoManager.requestPermissionExtend();
    if (permission.isAuth) {
      final albums = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        onlyAll: true,
      );
      final photos = await albums.first.getAssetListPaged(page: 0, size: 100);
      setState(() {
        _photos = photos;
      });
    } else {
      PhotoManager.openSetting();
    }
  }

  // Function to delete a photo from the gallery
  Future<void> _deletePhoto(AssetEntity entity) async {
    await PhotoManager.editor.deleteWithIds([entity.id]);
  }

  // Handle swipe actions
  void _handleSwipe(DismissDirection direction) async {
    if (_currentIndex >= _photos.length) return;

    final currentPhoto = _photos[_currentIndex];

    if (direction == DismissDirection.endToStart) {
      // Swipe left = move to trash bin
      _trashedPhotos.add(currentPhoto);
    } else if (direction == DismissDirection.startToEnd) {
      // Swipe right = keep
      // Do nothing
    }

    setState(() {
      _currentIndex++;
    });
  }

  // Function to empty the trash bin
  void _emptyTrashBin() {
    setState(() {
      _trashedPhotos.clear();
    });
  }



  @override
  // Build the UI for the photo gallery
  Widget build(BuildContext context) {
    if (_photos.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Your Photos")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentIndex >= _photos.length) {
      return Scaffold(
        appBar: AppBar(title: const Text("Your Photos")),
        body: const Center(child: Text("You're done! No more photos.")),
      );
    }

    final currentPhoto = _photos[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Swipe to Clean"),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TrashBinScreen(
                    trashedPhotos: _trashedPhotos,
                    onEmptyTrash: _emptyTrashBin
                  ),
                ),
              );
            },
          )
        ],
      ),
      body: FutureBuilder<Uint8List?>(
        future: currentPhoto.originBytes,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          return Dismissible(
            key: UniqueKey(),
            direction: DismissDirection.horizontal,
            onDismissed: _handleSwipe,
            background: Container(
              color: Colors.green,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(left: 32),
              child: const Icon(Icons.check, color: Colors.white, size: 40),
            ),
            secondaryBackground: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 32),
              child: const Icon(Icons.delete, color: Colors.white, size: 40),
            ),
            child: Container(
              margin: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                image: DecorationImage(
                  image: MemoryImage(snapshot.data!),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
