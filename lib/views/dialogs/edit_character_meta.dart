import 'package:cypher_sheet/components/icon.dart';
import 'package:cypher_sheet/components/icons.dart';
import 'package:cypher_sheet/extensions/metadata.dart';
import 'package:cypher_sheet/state/providers/character.dart';
import 'package:cypher_sheet/state/providers/storage.dart';
import 'package:cypher_sheet/state/storage/file.dart';
import 'package:cypher_sheet/views/dialogs/share_character.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cypher_sheet/components/box.dart';
import 'package:cypher_sheet/components/dialog.dart';
import 'package:cypher_sheet/components/text.dart';

class EditCharacterMeta extends ConsumerWidget {
  const EditCharacterMeta({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storage = ref.watch(storageProvider);
    final asyncMetadata = ref.watch(metadataProvider);
    return asyncMetadata.when(
      data: (metadata) => Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Row(
            children: [
              AppText(
                "Edit Character",
                align: TextAlign.left,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const Spacer(),
              AppBox(
                padding: 4,
                flat: true,
                onTap: () {
                  showAppDialog(context, ShareCharacter(uuid: metadata.uuid));
                },
                child: const AppIcon(AppIcons.share),
              ),
            ],
          ),
        ),
        AppText(
          metadata.uuid,
          style: Theme.of(context).textTheme.labelMedium,
          align: TextAlign.left,
        ),
        AppText(
          "Last updated @ ${DateTime.fromMillisecondsSinceEpoch(metadata.lastUpdated.toInt()).toIso8601String()}",
          style: Theme.of(context).textTheme.labelMedium,
          align: TextAlign.left,
        ),
        AppText(
          "${metadata.revisions.length.toString()} active revision${metadata.revisions.length > 1 ? "s" : ""} @ ${formatBytes(metadata.storageSize)}",
          style: Theme.of(context).textTheme.labelMedium,
          align: TextAlign.left,
        ),
        const SizedBox(height: 16.0),
        AppText(
          "Revisions",
          style: Theme.of(context).textTheme.bodyMedium,
          align: TextAlign.left,
        ),
        const SizedBox(height: 16.0),
        Expanded(
          child: FutureBuilder(
              future: storage.getCharacterRevisions(metadata.uuid),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return CustomScrollView(
                    primary: true,
                    scrollBehavior:
                        const ScrollBehavior().copyWith(scrollbars: false),
                    slivers: [
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (BuildContext context, int index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: RevisionListItem(
                                  // metadata: metadata,
                                revision: snapshot.data![index],
                              ),
                            );
                          },
                          childCount: snapshot.data!.length,
                        ),
                        ),
                        SliverList.list(
                          children: [
                            AppBox(
                              onTap: () {
                                showConfirmDialog(
                                    context,
                                    AppText(
                                        "Warning\nThis will permanently delete character\n${metadata.name}",
                                        maxLines: 4,
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelLarge), () {
                                  storage.deleteCharacter(metadata.uuid);
                                  ref.invalidate(characterListProvider);
                                  closeDialog(context);
                                });
                              },
                              color: Theme.of(context).colorScheme.error,
                              child: const AppText("Delete Character"),
                            )
                          ],
                        ),
                    ]);
              }
              if (snapshot.hasError) {
                return AppText(
                  snapshot.error.toString(),
                  style: Theme.of(context).textTheme.bodySmall,
                );
              }
              return const CircularProgressIndicator();
            },
          ),
        ),
        const SizedBox(height: 28.0),
        AppBox(
            onTap: (() {
            closeDialog(context);
          }),
          child: const AppText("Close"),
        ),
      ],
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stackTrace) => Text("Error: $err"),
    );
  }
}

class RevisionListItem extends ConsumerWidget {
  const RevisionListItem({super.key, required this.revision});

  final int revision;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storage = ref.watch(storageProvider);
    final asyncMetadata = ref.watch(metadataProvider);
    return asyncMetadata.when(
      data: (metadata) => AppBox(
      customPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AppText(
            revision.toString(),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(width: 10),
            if (storage is LocalCharacterStorage)
          FutureBuilder(
                future: storage.getCharacterRevisionStorageSizeBytes(
                    metadata.uuid, revision),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return AppText(
                  "@ ${formatBytes(snapshot.data!)}",
                  style: Theme.of(context).textTheme.bodySmall,
                );
              }
              if (snapshot.hasError) {
                return AppText(
                  snapshot.error.toString(),
                  style: Theme.of(context).textTheme.bodySmall,
                );
              }
              return const CircularProgressIndicator();
            },
          ),
          const Spacer(),
          AppBox(
              onTap: () {
                showConfirmDialog(
                    context,
                    AppText(
                        "Warning\nThis will permanently delete revision\n${metadata.uuid}#${revision.toString()}",
                        maxLines: 5,
                        style: Theme.of(context).textTheme.labelLarge), () {
                    storage.deleteCharacterRevision(metadata.uuid, revision);
                  ref.invalidate(characterListProvider);
                  closeDialog(context);
                  showAppDialog(
                    context,
                      const EditCharacterMeta(),
                    fullscreen: true,
                  );
                });
              },
              padding: 0,
              child: const AppIcon(
                AppIcons.deleteForever,
                size: 26,
              ))
        ],
      ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Text("$error"),
    );
  }
}

void showConfirmDialog(
    BuildContext context, Widget text, Function() onConfirm) {
  showAppDialog(
      context,
      Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          text,
          const SizedBox(height: 28.0),
          AppBox(
            onTap: () {
              closeDialog(context);
              onConfirm();
            },
            color: Theme.of(context).colorScheme.error,
            child: const AppText("Confirm"),
          ),
          const SizedBox(height: 28.0),
          AppBox(
            onTap: () {
              closeDialog(context);
            },
            child: const AppText("Cancel"),
          ),
        ],
      ));
}
