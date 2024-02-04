import 'package:cypher_sheet/proto/character.pb.dart';
import 'package:cypher_sheet/state/character.dart';
import 'package:cypher_sheet/state/providers/inventories.dart';
import 'package:cypher_sheet/state/providers/items.dart';
import 'package:cypher_sheet/state/providers/storage.dart';
import 'package:cypher_sheet/state/metadata.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final characterListProvider = FutureProvider((ref) {
  final storage = ref.watch(storageProvider);
  return storage.listCharacters();
});

final characterProvider =
    NotifierProvider<CharacterNotifier, Character>(CharacterNotifier.new);

// other character providers without a need for more complicated logic go here

final progressProvider = Provider((ref) {
  return ref.watch(characterProvider.select((value) => value.progress));
});

final advancementsProvider = Provider((ref) {
  return ref.watch(progressProvider.select((value) => value.advancements));
});

final recoveryProvider = Provider((ref) {
  return ref.watch(characterProvider.select((value) => value.recovery));
});

final damageProvider = Provider((ref) {
  return ref.watch(characterProvider.select((value) => value.damage));
});

final armorProvider = Provider((ref) {
  return ref
      .watch(itemsProvider)
      .where((element) => element.path.inventory == inventoryNameSelf)
      .fold<int>(0, (value, element) => value + element.armor);
});

final valueProvider = Provider((ref) {
  return ref
      .watch(itemsProvider)
      .fold<double>(0, (value, element) => value + element.value);
});

final currentUUIDProvider = StateProvider((ref) => "");

final metadataProvider = AsyncNotifierProvider.autoDispose<
    CharacterMetadataNotifier,
    CharacterMetadata>(CharacterMetadataNotifier.new);
