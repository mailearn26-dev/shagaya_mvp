import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadProductImage({
    required File file,
    required String productId,
  }) async {
    final ext = _guessExtension(file.path);
    final name = const Uuid().v4();

    final ref = _storage.ref().child('products/$productId/$name.$ext');

    print('Bucket: ${_storage.bucket}');
    print('Full path: ${ref.fullPath}');

    final metadata = SettableMetadata(contentType: _contentType(ext));
    await ref.putFile(file, metadata);

    return ref.getDownloadURL();
  }

  String _guessExtension(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'png';
    if (lower.endsWith('.webp')) return 'webp';
    return 'jpg';
    }

  String _contentType(String ext) {
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }
}
