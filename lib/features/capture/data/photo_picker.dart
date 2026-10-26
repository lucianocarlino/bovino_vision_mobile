import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

enum PhotoSource { camera, gallery }

/// A photo chosen by the operator, already shrunk by the picker.
class PickedPhoto {
  const PickedPhoto({required this.bytes, required this.filename, required this.contentType});

  final Uint8List bytes;
  final String filename;
  final String contentType;
}

/// Content type the API accepts (image/jpeg, image/png, image/webp), from the file extension.
String contentTypeFor(String filename) {
  final dot = filename.lastIndexOf('.');
  final extension = dot < 0 ? '' : filename.substring(dot + 1).toLowerCase();
  return switch (extension) {
    'png' => 'image/png',
    'webp' => 'image/webp',
    _ => 'image/jpeg',
  };
}

abstract class PhotoPicker {
  /// Null when the operator cancels.
  Future<PickedPhoto?> pick(PhotoSource source);
}

/// Camera and gallery through `image_picker`. The web shrinks photos to 1600 px / JPEG 0.85
/// before the upload; the picker does the same.
class ImagePickerPhotoPicker implements PhotoPicker {
  const ImagePickerPhotoPicker();

  static const maxSide = 1600.0;
  static const quality = 85;

  @override
  Future<PickedPhoto?> pick(PhotoSource source) async {
    final file = await ImagePicker().pickImage(
      source: source == PhotoSource.camera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: maxSide,
      maxHeight: maxSide,
      imageQuality: quality,
    );
    if (file == null) return null;
    final name = file.name.isEmpty ? 'captura.jpg' : file.name;
    return PickedPhoto(bytes: await file.readAsBytes(), filename: name, contentType: contentTypeFor(name));
  }
}

/// Overridable defaults of the capture feature; tests replace them to avoid the platform
/// plugin and real waiting.
abstract final class CaptureSettings {
  static PhotoPicker photoPicker = const ImagePickerPhotoPicker();

  /// Time between polls of `GET /capturas/{id}` while an estimation runs.
  static Duration pollInterval = const Duration(seconds: 1);
}
