import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Persists images chosen by the user (camera or gallery) into the app's
/// private documents directory so they survive restarts and uninstalls
/// (on iOS) without bloating the Hive DB.
///
/// Only the resulting file path is stored — the picker XFile is considered
/// transient and is copied into a stable location owned by us.
class ImageStorageService {
  ImageStorageService._();
  static final ImageStorageService instance = ImageStorageService._();

  static const _uuid = Uuid();
  final ImagePicker _picker = ImagePicker();

  /// Open the system camera. Returns the persisted path, or null if the
  /// user cancelled / the OS denied the request.
  Future<String?> captureFromCamera({String subdir = 'images'}) async {
    try {
      final x = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 2000,
      );
      if (x == null) return null;
      return await persistFromXFile(x, subdir: subdir);
    } catch (_) {
      return null;
    }
  }

  /// Open the system gallery. Returns the persisted paths, or an empty
  /// list if the user cancelled / the OS denied the request.
  Future<List<String>> pickFromGallery({String subdir = 'images'}) async {
    try {
      final xs = await _picker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 2000,
      );
      if (xs.isEmpty) return const [];
      final out = <String>[];
      for (final x in xs) {
        out.add(await persistFromXFile(x, subdir: subdir));
      }
      return out;
    } catch (_) {
      return const [];
    }
  }

  /// Copy an [XFile] from the picker temp location into the app documents
  /// directory under `<subdir>/<uuid>.<ext>` and return the new path.
  Future<String> persistFromXFile(XFile x, {String subdir = 'images'}) async {
    final ext = _extFromName(x.name);
    final filename = '${_uuid.v4()}$ext';
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/$subdir');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    final dest = File('${dir.path}/$filename');
    await File(x.path).copy(dest.path);
    return dest.path;
  }

  /// Best-effort delete. Missing files are silently ignored.
  Future<void> deleteIfExists(String? path) async {
    if (path == null || path.isEmpty) return;
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }

  /// Copy a stored image into the OS share temp directory so the receiving
  /// app (WhatsApp, email, etc.) can read it under scoped storage.
  Future<File> copyForShare(String internalPath) async {
    final temp = await getTemporaryDirectory();
    final filename = internalPath.split(Platform.pathSeparator).last;
    final dest = File('${temp.path}/$filename');
    if (await dest.exists()) await dest.delete();
    return File(internalPath).copy(dest.path);
  }

  String _extFromName(String name) {
    final i = name.lastIndexOf('.');
    if (i < 0 || i == name.length - 1) return '.jpg';
    return name.substring(i).toLowerCase();
  }
}
