import 'package:flutter/widgets.dart';
import 'package:share_plus/share_plus.dart';

import '../models/post.dart';
import 'image_storage_service.dart';

/// Builds a friendly share payload for a [Post] and opens the OS share
/// sheet. The body text is bilingual (Bangla / English), and the first
/// attached image (if any) is copied into the OS temp directory so it
/// can be read by the receiving app under scoped storage.
class PostShareService {
  PostShareService._();
  static final PostShareService instance = PostShareService._();

  Future<ShareResult> sharePost(
    Post p, {
    required bool isBangla,
    Rect? sharePositionOrigin,
  }) async {
    final text = _buildText(p, isBangla: isBangla);

    final files = <XFile>[];
    final hero = p.heroImagePath;
    if (hero != null && hero.isNotEmpty) {
      try {
        final copied = await ImageStorageService.instance.copyForShare(hero);
        files.add(XFile(copied.path, mimeType: 'image/jpeg', name: copied.uri.pathSegments.last));
      } catch (_) {
        // ignore — sharing will fall back to text-only
      }
    }

    return Share.shareXFiles(
      files,
      text: text,
      subject: p.title.isEmpty ? 'Daily Utility post' : p.title,
      sharePositionOrigin: sharePositionOrigin,
    );
  }

  String _buildText(Post p, {required bool isBangla}) {
    final tagsLine = p.tags.isEmpty ? '' : '\n\n#${p.tags.join(' #')}';
    final titleLine = isBangla ? 'Daily Utility পোস্ট — ${p.title}' : 'Daily Utility post — ${p.title}';
    final body = p.body.trim();
    if (body.isEmpty) {
      return '$titleLine$tagsLine';
    }
    return '$titleLine\n\n$body$tagsLine';
  }

  /// Returns the share-text only (used by tests, widgets that preview the
  /// share sheet, etc.).
  String buildText(Post p, {required bool isBangla}) => _buildText(p, isBangla: isBangla);
}
