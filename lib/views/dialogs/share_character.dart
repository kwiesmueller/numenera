import 'dart:developer';
import 'dart:io';

import 'package:cypher_sheet/components/box.dart';
import 'package:cypher_sheet/components/dialog.dart';
import 'package:cypher_sheet/components/text.dart';
import 'package:cypher_sheet/proto/character.pb.dart';
import 'package:cypher_sheet/state/providers/character.dart';
import 'package:cypher_sheet/state/providers/storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

class ShareCharacter extends ConsumerWidget {
  const ShareCharacter({super.key, required this.uuid});

  final String uuid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storage = ref.watch(storageProvider);
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppText(
          "Share Character",
          style: Theme.of(context).textTheme.bodyLarge,
          align: TextAlign.left,
        ),
        const SizedBox(height: 28.0),
        AppBox(
          onTap: () async {
            final revision = await storage.getCharacter(uuid);
            final revisionRaw = revision.writeToBuffer();
            Share.shareXFiles([XFile.fromData(revisionRaw)]);
          },
          child: const AppText(
            "Share Latest Revision",
            maxLines: 2,
          ),
        ),
        const SizedBox(height: 28.0),
        AppBox(
          onTap: () async {
            final revision = await storage.getCharacter(uuid);
            final revisionRaw = revision.writeToBuffer();
            log(revisionRaw.toString());
            log(revision.toDebugString());
          },
          child: const AppText(
            "Log Latest Revision",
            maxLines: 2,
          ),
        ),
        const SizedBox(height: 28.0),
        AppBox(
          onTap: () async {
            // final revision = await storage.getCharacter(uuid);
            // await writeCharacterRevisionToAPI("127.0.0.1:8080", revision);
          },
          child: const AppText(
            "Upload Latest Revision",
            maxLines: 2,
          ),
        ),
      ],
    );
  }
}

class ImportCharacter extends ConsumerWidget {
  const ImportCharacter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storage = ref.watch(storageProvider);
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppText(
          "Import Character",
          style: Theme.of(context).textTheme.bodyLarge,
          align: TextAlign.left,
        ),
        const SizedBox(height: 28.0),
        AppBox(
          onTap: () async {
            FilePickerResult? result = await FilePicker.platform.pickFiles();

            if (result != null) {
              File file = File(result.files.single.path!);
              final character = Character.fromBuffer(file.readAsBytesSync());
              final newRevision =
                  await storage.writeLatestCharacterRevision(character);
              log("loaded new revision $newRevision from file");
              ref.invalidate(characterListProvider);
              // ignore: use_build_context_synchronously
              if (!context.mounted) return;
              closeDialog(context);
              closeDialog(context);
            }
          },
          child: const AppText("Import Revision File"),
        ),
      ],
    );
  }
}
