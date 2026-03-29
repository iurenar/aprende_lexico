
import 'package:flutter/foundation.dart';

@immutable
class AvatarModel {
  final String id;
  final String name;
  final String previewImage;

  const AvatarModel({
    required this.id,
    required this.name,
    required this.previewImage,
  });
}

