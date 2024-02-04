import 'dart:async';

import 'package:cypher_sheet/state/providers/character.dart';
import 'package:cypher_sheet/state/providers/storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cypher_sheet/proto/character.pb.dart';

class CharacterMetadataNotifier
    extends AutoDisposeAsyncNotifier<CharacterMetadata> {
  CharacterMetadataNotifier() : super();
  // CharacterMetadataNotifier()
  //     : super(CharacterMetadata().freeze() as CharacterMetadata);

  @override
  FutureOr<CharacterMetadata> build() async {
    final storage = ref.watch(storageProvider);
    final uuid = ref.watch(currentUUIDProvider);
    final metadata = await storage.getCharacterMetadata(uuid);
    return metadata.freeze() as CharacterMetadata;
  }
}
