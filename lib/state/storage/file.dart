import 'dart:developer';
import 'dart:io';

import 'package:cypher_sheet/proto/character.pb.dart';
import 'package:cypher_sheet/state/storage/storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:protobuf/protobuf.dart';
import 'package:uuid/uuid.dart';
// Fixnum is needed for int64 support: https://developers.google.com/protocol-buffers/docs/reference/dart-generated#int64-fields
// ignore: depend_on_referenced_packages
import 'package:fixnum/fixnum.dart';

class LocalCharacterStorage implements CharacterStorage {
  @override
  void createCharacter(Character character) {
    _writeCharacterRevision(character, 0);
  }

  @override
  Future<Character> getCharacter(String uuid) async {
    final revisions = await getCharacterRevisions(uuid);
    return _readCharacterRevision(uuid, revisions.last);
  }

  @override
  Future<CharacterMetadata> getCharacterMetadata(String uuid) async {
    final characterDirectory = await _getCharacterDirectory(uuid);
    final revisions = await getCharacterRevisions(uuid);
    final storageSize = await _getCharacterStorageSizeBytes(uuid);

    final metadataFile =
        File(p.join(characterDirectory.path, _metadataFilename));
    if (!metadataFile.existsSync()) {
      log("no metadata file found at ${metadataFile.path}");
      return CharacterMetadata(
          uuid: uuid, name: "<unknown>", revisions: revisions);
    }

    CharacterMetadata metadata =
        CharacterMetadata.fromBuffer(metadataFile.readAsBytesSync());
    metadata.revisions.clear();
    metadata.revisions.addAll(revisions);
    metadata.storageSize = storageSize;

    return metadata;
  }

  @override
  Future<List<Future<CharacterMetadata>>> listCharacters() async {
    final charactersDirectory = await _getCharactersDirectory();
    // Every character has its own sub-directory that contains the stored revisions
    // of that character
    final characterUUIDs = charactersDirectory
        .listSync(recursive: false)
        .map((dir) => p.basename(dir.path));

    final characters = characterUUIDs.map(
      (uuid) => getCharacterMetadata(uuid),
    );

    return characters.toList();
  }

  @override
  Future<int> writeLatestCharacterRevision(Character character) async {
    final revisions = await getCharacterRevisions(character.uuid);

    late int newRevision;
    if (revisions.isNotEmpty) {
      final currentRevision = revisions.last;
      newRevision = currentRevision + 1;
    } else {
      // create a initial revision if none exists yet
      newRevision = 0;
    }

    _writeCharacterRevision(character, newRevision);

    return newRevision;
  }

  @override
  void deleteCharacter(String uuid) async {
    final characterDirectory = await _getCharacterDirectory(uuid);

    log("deleting character $uuid");
    characterDirectory.deleteSync(recursive: true);
  }

  @override
  void deleteCharacterRevision(String uuid, int revision) async {
    final characterDirectory = await _getCharacterDirectory(uuid);

    log("deleting character revision $uuid#${revision.toString()}");
    File(p.join(characterDirectory.path, revision.toString())).deleteSync();
  }

  @override
  Future<List<int>> getCharacterRevisions(String uuid) async {
    final characterDirectory = await _getCharacterDirectory(uuid);

    final uuids = characterDirectory
        .listSync(recursive: false)
        .map((file) => p.basename(file.path))
        .where((fileName) => fileName != _metadataFilename)
        .map((revision) => int.tryParse(revision) ?? 0)
        .toList();
    uuids.sort(((a, b) => a.compareTo(b)));

    return uuids;
  }

  // methods specific to this storage type

  Future<int> getCharacterRevisionStorageSizeBytes(
      String uuid, int revision) async {
    final characterDirectory = await _getCharacterDirectory(uuid);

    return File(p.join(characterDirectory.path, revision.toString()))
        .lengthSync();
  }

  // storage helpers below

  void _writeCharacterRevision(Character character, int revision) async {
    if (character.uuid.isEmpty) {
      character = character.rebuild((character) => character.uuid = _uuid.v4());
    }

    final characterDirectory = await _getCharacterDirectory(character.uuid);

    _writeCharacterMetadata(
        characterDirectory,
        CharacterMetadata(
          uuid: character.uuid,
          name: character.name,
          revisions: [],
          lastUpdated: Int64(DateTime.now().millisecondsSinceEpoch),
        ));

    final revisionFile =
        File(p.join(characterDirectory.path, revision.toString()));
    log("writing revision file ${revisionFile.path}");
    await revisionFile.writeAsBytes(character.writeToBuffer());
  }

  Future<void> _writeCharacterMetadata(
      Directory characterDirectory, CharacterMetadata metadata) async {
    final metadataFile =
        File(p.join(characterDirectory.path, _metadataFilename));
    log("writing metadata file ${metadataFile.path}");
    await metadataFile.writeAsBytes(metadata.writeToBuffer());
  }

  Future<String> _readLatestCharacterRevisionRaw(String uuid) async {
    final revisions = await getCharacterRevisions(uuid);
    return _readCharacterRevisionRaw(uuid, revisions.last);
  }

  Future<Character> _readCharacterRevision(String uuid, int revisionID) async {
    final characterDirectory = await _getCharacterDirectory(uuid);

    final revision =
        File(p.join(characterDirectory.path, revisionID.toString()));

    return Character.fromBuffer(revision.readAsBytesSync());
  }

  Future<String> _readCharacterRevisionRaw(String uuid, int revisionID) async {
    final characterDirectory = await _getCharacterDirectory(uuid);

    final revision =
        File(p.join(characterDirectory.path, revisionID.toString()));

    return revision.readAsBytesSync().toString();
  }

  Future<int> _getCharacterRevisionStorageSizeBytes(
      String uuid, int revision) async {
    final characterDirectory = await _getCharacterDirectory(uuid);

    return File(p.join(characterDirectory.path, revision.toString()))
        .lengthSync();
  }

  Future<int> _getCharacterStorageSizeBytes(String uuid) async {
    final characterDirectory = await _getCharacterDirectory(uuid);

    int bytes = 0;
    characterDirectory.listSync(recursive: false).forEach((element) {
      if (element is File) {
        bytes += element.lengthSync();
      }
    });

    return bytes;
  }

  Future<Directory> _getCharacterDirectory(String uuid) async {
    final charactersDirectory = await _getCharactersDirectory();
    // We store each character in a directory named after its uuid
    return Directory(p.join(charactersDirectory.path, uuid))
        .create(recursive: true);
  }

  Future<Directory> _getCharactersDirectory() async {
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    // We store all characters in a directory called characters
    return Directory(p.join(appDocDir.path, "characters"))
        .create(recursive: true);
  }

  static const String _metadataFilename = "metadata";

  static const _uuid = Uuid();
}
