import 'package:cypher_sheet/proto/character.pb.dart';
import 'package:protobuf/protobuf.dart';

Character wipeUnknownFieldsWithOverlappingKnownFieldsForCharacter(
    Character character) {
  return character.rebuild((character) {
    wipeUnknownFieldsWithOverlappingKnownFields(character);
  });
}

void wipeUnknownFieldsWithOverlappingKnownFields(GeneratedMessage msg) {
  msg.unknownFields.asMap().forEach((key, value) {
    if (msg.hasField(key)) {
      msg.unknownFields.clearField(key);
    }
  });
}
