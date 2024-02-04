import 'package:cypher_sheet/proto/character.pb.dart';

abstract class CharacterStorage {
  Future<List<Future<CharacterMetadata>>> listCharacters();

  void createCharacter(Character character);

  Future<Character> getCharacter(String uuid);
  Future<CharacterMetadata> getCharacterMetadata(String uuid);
  Future<List<int>> getCharacterRevisions(String uuid);

  Future<int> writeLatestCharacterRevision(Character character);

  void deleteCharacter(String uuid);
  void deleteCharacterRevision(String uuid, int revision);
}
