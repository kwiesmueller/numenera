import 'package:cypher_sheet/state/storage/file.dart';
import 'package:cypher_sheet/state/storage/storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final storageProvider = StateProvider<CharacterStorage>((ref) {
  if (!kIsWeb) {
    return LocalCharacterStorage();
  } else {
    throw UnimplementedError();
  }
});
