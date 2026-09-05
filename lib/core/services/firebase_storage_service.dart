import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class FirebaseStorageService {
  FirebaseStorage? _storageInstance;

  FirebaseStorage? get _storage {
    if (_storageInstance != null) return _storageInstance;
    try {
      _storageInstance = FirebaseStorage.instanceFor(
        bucket: 'gs://gracegrid-c7367.firebasestorage.app',
      );
      return _storageInstance;
    } catch (e) {
      try {
        _storageInstance = FirebaseStorage.instance;
        return _storageInstance;
      } catch (e2) {
        debugPrint('FirebaseStorage instance not available: $e2');
        return null;
      }
    }
  }

  Future<String?> uploadPostImage({
    required XFile imageFile,
    required String userId,
  }) async {
    try {
      final storage = _storage;
      if (storage == null) {
        debugPrint('FirebaseStorage storage instance is null');
        return null;
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final safeName = imageFile.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
      final path = 'feed_images/${userId.replaceAll(' ', '_')}/${timestamp}_$safeName';
      final ref = storage.ref().child(path);

      UploadTask uploadTask;
      final bytes = await imageFile.readAsBytes();
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {'uploadedBy': userId},
      );

      if (kIsWeb) {
        uploadTask = ref.putData(bytes, metadata);
      } else {
        if (imageFile.path.isNotEmpty && !kIsWeb && File(imageFile.path).existsSync()) {
          uploadTask = ref.putFile(File(imageFile.path), metadata);
        } else {
          uploadTask = ref.putData(bytes, metadata);
        }
      }

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      debugPrint('FirebaseStorage image uploaded successfully to $path! URL: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('FirebaseStorageService upload error: $e');
      return null;
    }
  }
}
