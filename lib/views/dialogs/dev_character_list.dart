import 'package:cypher_sheet/components/scroll.dart';
import 'package:cypher_sheet/proto/character.pb.dart';
import 'package:cypher_sheet/state/providers/character.dart';
import 'package:cypher_sheet/state/providers/import.dart';
import 'package:cypher_sheet/state/providers/inventories.dart';
import 'package:cypher_sheet/state/providers/storage.dart';
import 'package:cypher_sheet/views/dialogs/share_character.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cypher_sheet/components/box.dart';
import 'package:cypher_sheet/components/dialog.dart';
import 'package:cypher_sheet/components/text.dart';
import 'package:cypher_sheet/testdata.dart';

class DevCharacterList extends ConsumerWidget {
  const DevCharacterList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storage = ref.watch(storageProvider);
    return AppScrollView(
      slivers: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: AppText(
            "Developer Tools",
            align: TextAlign.left,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
        AppBox(
          onTap: () async {
            storage.createCharacter(finch);
            ref.invalidate(characterListProvider);
          },
          child: const Padding(
            padding: EdgeInsets.only(left: 16.0),
            child: AppText("Add Test Data"),
          ),
        ),
        const SizedBox(height: 28.0),
        AppBox(
          onTap: () {
            showAppDialog(context, const ImportCharacter());
          },
          child: const AppText("Import Character"),
        ),
        const SizedBox(height: 28.0),
        AppBox(
          onTap: () {
            showAppDialog(
                context,
                const Scaffold(
                  body: LicensePage(),
                ));
          },
          child: const AppText("Show Licenses"),
        ),
        const SizedBox(height: 28.0),
        AppBox(
          onTap: () {
            closeDialog(context);
            ref.read(importObjectProvider.notifier).state = SharedObject(
              uuid: "test-uuid",
              cypher: Cypher(
                uuid: "test-uuid",
                name: "Test Cypher",
                active: false,
              ),
            );
          },
          child: const AppText("Import Test Cypher"),
        ),
        const SizedBox(height: 28.0),
        AppBox(
          onTap: () {
            closeDialog(context);
            ref.read(importObjectProvider.notifier).state = SharedObject(
              uuid: "test-uuid2",
              artifact: Artifact(
                uuid: "test-uuid2",
                name: "Test Artifact",
                active: true,
              ),
            );
          },
          child: const AppText("Import Test Artifact"),
        ),
        const SizedBox(height: 28.0),
        AppBox(
          onTap: () {
            closeDialog(context);
            ref.read(importObjectProvider.notifier).state = SharedObject(
              uuid: "test-uuid3",
              item: Item(
                  path: ItemPath(
                    inventory: inventoryNameSelf,
                    parent: null,
                    self: "test-uuid3",
                  ),
                  name: "Test Item",
                  shortDescription: "Imported"),
            );
          },
          child: const AppText("Import Test Item"),
        ),
        const SizedBox(height: 28.0),
        AppBox(
          onTap: () {
            closeDialog(context);
            ref.read(importObjectProvider.notifier).state = SharedObject(
              uuid: "test-uuid4",
              ability: Ability(
                uuid: "test-uuid4",
                name: "Test Ability",
                enabler: true,
              ),
            );
          },
          child: const AppText("Import Test Ability"),
        ),
        const SizedBox(height: 28.0),
        AppBox(
          onTap: () {
            closeDialog(context);
            ref.read(importObjectProvider.notifier).state = SharedObject(
              uuid: "test-uuid5",
              skill: Skill(
                uuid: "test-uuid5",
                name: "Test Skill",
                level: SkillLevel.inability,
              ),
            );
          },
          child: const AppText("Import Test Skill"),
        ),
        const SizedBox(height: 28.0),
        AppBox(
          onTap: () {
            closeDialog(context);
            ref.read(importObjectProvider.notifier).state = SharedObject(
              uuid: "test-uuid6",
              note: Note(
                uuid: "test-uuid6",
                title: "Test Note",
                shortDescription: "Foo",
                type: NoteType.item,
              ),
            );
          },
          child: const AppText("Import Test Note"),
        ),
        const SizedBox(height: 28.0),
        AppBox(
          onTap: (() {
            closeDialog(context);
          }),
          child: const AppText("Close"),
        ),
      ],
    );
  }
}
