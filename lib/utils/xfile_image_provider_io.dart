import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:image_picker/image_picker.dart';

/// IO-safe [ImageProvider] for an [XFile].
ImageProvider xFileImageProvider(XFile file) {
  return FileImage(File(file.path));
}

