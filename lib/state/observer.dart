import 'dart:developer';

import 'package:cypher_sheet/state/providers/character.dart';
import 'package:cypher_sheet/state/storage/storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cypher_sheet/proto/character.pb.dart';
import 'package:json_diff/json_diff.dart';

class Persister extends ProviderObserver {
  const Persister(this.storage) : super();

  final CharacterStorage storage;
  @override
  void didUpdateProvider(
    ProviderBase provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) async {
    if (provider != characterProvider) {
      return;
    }
    if (previousValue == null || newValue == null) {
      log("ignoring change with null initialValue");
      return;
    }

    if (previousValue is! Character || newValue is! Character) {
      log("ignoring non character types ${previousValue.runtimeType}/${newValue.runtimeType}");
      return;
    }

    final previousCharacter = previousValue;
    if (previousCharacter.uuid.isEmpty) {
      log("ignoring change with initial empty character");
      return;
    }

    final newCharacter = newValue;
    if (newCharacter.uuid.isEmpty) {
      log("ignoring change with new empty character");
      return;
    }

    log("persisting change to character");

    final differ =
        JsonDiffer(previousValue.writeToJson(), newValue.writeToJson());
    DiffNode diff = differ.diff();
    log("diff: $diff");

    final newRevision =
        await storage.writeLatestCharacterRevision(newCharacter);
    log("wrote update for character resulting in new revision $newRevision");
  }
}
