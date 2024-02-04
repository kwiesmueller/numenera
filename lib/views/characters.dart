import 'package:cypher_sheet/extensions/metadata.dart';
import 'package:cypher_sheet/main.dart';
import 'package:cypher_sheet/state/providers/character.dart';
import 'package:cypher_sheet/state/providers/storage.dart';
import 'package:cypher_sheet/views/dialogs/edit_character_meta.dart';
import 'package:cypher_sheet/views/scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cypher_sheet/components/appbar.dart' as app;
import 'package:cypher_sheet/components/box.dart';
import 'package:cypher_sheet/components/dialog.dart';
import 'package:cypher_sheet/components/icon.dart';
import 'package:cypher_sheet/components/icons.dart';
import 'package:cypher_sheet/components/scroll.dart';
import 'package:cypher_sheet/components/text.dart';
import 'package:cypher_sheet/proto/character.pb.dart';
import 'package:cypher_sheet/views/dialogs/create_character.dart';
import 'package:cypher_sheet/views/dialogs/dev_character_list.dart';

class CharactersView extends ConsumerWidget {
  const CharactersView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppScaffold(
      body: AppScrollView(
        appBar: app.AppBar(
            child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppText(
              "Characters",
              align: TextAlign.left,
            ),
            AppBox(
              onTap: () {
                showAppDialog(context, const DevCharacterList());
              },
              flat: true,
              padding: 4,
              child: const AppIcon(AppIcons.devMode),
            ),
          ],
        )),
        slivers: [
          const SizedBox(height: 16.0),
          AppText(
            """
Note: You are using a work-in-progress build of this app.
Features may not work as intended or your data may not be persisted correctly.
Please keep a paper backup of your character.
    
You can report feedback to app-feedback@kwiesmueller.dev.
            """,
            maxLines: 10,
            style: Theme.of(context).textTheme.labelLarge,
            align: TextAlign.left,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16.0),
          ...ref.watch(characterListProvider).when(
              loading: () => const [CircularProgressIndicator()],
              error: (err, stack) => [Text("Error: $err")],
              data: (characters) {
                return characters.map((metadata) => Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: CharacterListItem(
                        metadata: metadata,
                      ),
                    ));
              }),
          AppBox(
            onTap: () {
              showAppDialog(
                context,
                const CreateCharacter(),
                fullscreen: true,
              );
            },
            flat: true,
            child: const AppText("Create Character"),
          ),
        ],
      ),
    );
  }
}

class CharacterListItem extends ConsumerWidget {
  const CharacterListItem({
    super.key,
    required this.metadata,
  });

  final Future<CharacterMetadata> metadata;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storage = ref.watch(storageProvider);
    return FutureBuilder(
      future: metadata,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return AppBox(
            color: Theme.of(context).colorScheme.surface,
            onTap: (() async {
              ref.read(currentUUIDProvider.notifier).state =
                  snapshot.data!.uuid;
              final character = await storage.getCharacter(snapshot.data!.uuid);
              ref.read(characterProvider.notifier).load(character);
              
              if (!context.mounted) return;
              Navigator.of(context).pushReplacementNamed(routeCharacter);
            }),
            customPadding: const EdgeInsets.only(left: 16, bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 16, bottom: 8.0),
                      child: AppText(
                        snapshot.data!.name,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                    const Spacer(),
                    AppBox(
                      onTap: () {
                        ref.read(currentUUIDProvider.notifier).state =
                            snapshot.data!.uuid;
                        showAppDialog(
                          context,
                          const EditCharacterMeta(),
                          fullscreen: true,
                        );
                      },
                      flat: true,
                      padding: 16,
                      child: const AppIcon(AppIcons.edit, size: 26),
                    )
                  ],
                ),
                AppText(
                  "Last updated @ ${DateTime.fromMillisecondsSinceEpoch(snapshot.data!.lastUpdated.toInt()).toIso8601String()}",
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                AppText(
                  "${snapshot.data!.revisions.length.toString()} active revision${snapshot.data!.revisions.length > 1 ? "s" : ""} @ ${formatBytes(snapshot.data!.storageSize)}",
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(
                  height: 8,
                )
              ],
            ),
          );
        }
        if (snapshot.hasError) {
          return AppBox(
            child: AppText(
              snapshot.error.toString(),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          );
        }
        return const CircularProgressIndicator();
      },
    );
  }
}
