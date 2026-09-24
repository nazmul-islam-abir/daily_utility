import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

/// What kind of post the user wrote. Bilingual labels and Material icons
/// are looked up in the UI via `PostCategoryMeta`.
enum PostCategory { diary, thoughts, recipe, travel, general }

class PostCategoryMeta {
  final String bn;
  final String en;
  final IconData icon;
  const PostCategoryMeta(this.bn, this.en, this.icon);
}

const Map<PostCategory, PostCategoryMeta> kPostCategoryMeta = {
  PostCategory.diary: PostCategoryMeta('ডায়েরি', 'Diary', Icons.menu_book_rounded),
  PostCategory.thoughts: PostCategoryMeta('চিন্তা', 'Thoughts', Icons.psychology_rounded),
  PostCategory.recipe: PostCategoryMeta('রেসিপি', 'Recipe', Icons.restaurant_rounded),
  PostCategory.travel: PostCategoryMeta('ভ্রমণ', 'Travel', Icons.flight_takeoff_rounded),
  PostCategory.general: PostCategoryMeta('সাধারণ', 'General', Icons.edit_note_rounded),
};

/// Stable string key used inside the JSON backup payload.
String postCategoryKey(PostCategory c) => c.name;
PostCategory postCategoryFromKey(String? key) {
  for (final v in PostCategory.values) {
    if (v.name == key) return v;
  }
  return PostCategory.general;
}

/// Hand-written adapter — ordinal storage keeps the box file compact and
/// avoids locale-dependent string differences.
class PostCategoryAdapter extends TypeAdapter<PostCategory> {
  @override
  final int typeId = 20;

  @override
  PostCategory read(BinaryReader reader) {
    final i = reader.readByte();
    return PostCategory.values[i.clamp(0, PostCategory.values.length - 1)];
  }

  @override
  void write(BinaryWriter writer, PostCategory obj) {
    writer.writeByte(obj.index);
  }
}

/// A user-authored blog-style post. Stored in the `posts` Hive box. Image
/// bytes live on disk; this model only carries absolute file paths.
///
/// Fields 0..9 are the original schema. Fields 10..16 add social-media
/// style engagement counters and an optional author avatar path so the
/// feed card can render an FB/IG-style header without an extra prefs
/// lookup. Older payloads (without 10..16) still load cleanly because
/// every new read is null-coalesced.
class Post extends HiveObject {
  String id;
  String title;
  String body;
  PostCategory category;
  List<String> tags;
  int colorValue;
  List<String> imagePaths;
  bool pinned;
  DateTime createdAt;
  DateTime updatedAt;
  bool liked;
  int likes;
  int comments;
  int impressions;
  String? authorName;
  String? authorAvatarPath;

  Post({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.tags,
    required this.colorValue,
    required this.imagePaths,
    required this.pinned,
    required this.createdAt,
    required this.updatedAt,
    this.liked = false,
    this.likes = 0,
    this.comments = 0,
    this.impressions = 0,
    this.authorName,
    this.authorAvatarPath,
  });

  /// First attached image, used as the hero thumbnail in the list and as
  /// the attachment when sharing.
  String? get heroImagePath => imagePaths.isNotEmpty ? imagePaths.first : null;

  /// Number of additional images after the hero (used for the "+N" badge).
  int get extraImageCount => imagePaths.length > 1 ? imagePaths.length - 1 : 0;
}

class PostAdapter extends TypeAdapter<Post> {
  @override
  final int typeId = 19;

  @override
  Post read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Post(
      id: fields[0] as String,
      title: fields[1] as String,
      body: (fields[2] as String?) ?? '',
      category: postCategoryFromKey(fields[3] as String?),
      tags: ((fields[4] as List?) ?? const []).cast<String>(),
      colorValue: (fields[5] as int?) ?? 0xFFE11D48,
      imagePaths: ((fields[6] as List?) ?? const []).cast<String>(),
      pinned: (fields[7] as bool?) ?? false,
      createdAt: fields[8] as DateTime,
      updatedAt: (fields[9] as DateTime?) ?? (fields[8] as DateTime),
      liked: (fields[10] as bool?) ?? false,
      likes: (fields[11] as int?) ?? 0,
      comments: (fields[12] as int?) ?? 0,
      impressions: (fields[13] as int?) ?? 0,
      authorName: fields[14] as String?,
      authorAvatarPath: fields[15] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Post obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.body)
      ..writeByte(3)
      ..write(postCategoryKey(obj.category))
      ..writeByte(4)
      ..write(obj.tags)
      ..writeByte(5)
      ..write(obj.colorValue)
      ..writeByte(6)
      ..write(obj.imagePaths)
      ..writeByte(7)
      ..write(obj.pinned)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.updatedAt)
      ..writeByte(10)
      ..write(obj.liked)
      ..writeByte(11)
      ..write(obj.likes)
      ..writeByte(12)
      ..write(obj.comments)
      ..writeByte(13)
      ..write(obj.impressions)
      ..writeByte(14)
      ..write(obj.authorName)
      ..writeByte(15)
      ..write(obj.authorAvatarPath);
  }
}
