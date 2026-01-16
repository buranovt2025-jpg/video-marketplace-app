import 'package:flutter/painting.dart';
import 'package:image_picker/image_picker.dart';

/// Web-safe [ImageProvider] for an [XFile].
///
/// On web, [XFile.path] is typically a blob/object URL that can be loaded via
/// [NetworkImage].
ImageProvider xFileImageProvider(XFile file) {
  return NetworkImage(file.path);
}

