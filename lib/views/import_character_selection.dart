import 'package:cypher_sheet/main.dart';
import 'package:cypher_sheet/state/providers/character.dart';
import 'package:cypher_sheet/state/providers/import.dart';
import 'package:cypher_sheet/state/providers/storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cypher_sheet/components/appbar.dart' as app;
import 'package:cypher_sheet/components/box.dart';
import 'package:cypher_sheet/components/scroll.dart';
import 'package:cypher_sheet/components/text.dart';
import 'package:cypher_sheet/proto/character.pb.dart';

class ImportCharacterSelectionView extends ConsumerWidget {
  const ImportCharacterSelectionView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return WillPopScope(
      onWillPop: () async {
        ref.read(importObjectProvider.notifier).state = SharedObject();
        return false;
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: AppScrollView(
              appBar: const app.AppBar(
                child: AppText(
                  "Select Character for Import",
                  align: TextAlign.left,
                ),
              ),
              slivers: [
                const SizedBox(height: 16.0),
                ...ref.watch(characterListProvider).when(
                    loading: () => const [CircularProgressIndicator()],
                    error: (err, stack) => [Text("Error: $err")],
                    data: (characters) {
                      return characters.map((metadata) => Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: SimpleCharacterListItem(
                              metadata: metadata,
                            ),
                          ));
                    }),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: AppBox(
              onTap: (() {
                ref.read(importObjectProvider.notifier).state = SharedObject();
              }),
              child: const AppText("Abort"),
            ),
          ),
        ],
      ),
    );
  }
}

class SimpleCharacterListItem extends ConsumerWidget {
  const SimpleCharacterListItem({
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
            color: Theme.of(context).colorScheme.surfaceTint,
            onTap: (() async {
              final character = await storage.getCharacter(snapshot.data!.uuid);
              ref.read(characterProvider.notifier).load(character);
              if (!context.mounted) return;
              Navigator.of(context).pushReplacementNamed(routeCharacter);
            }),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: AppText(
                    snapshot.data!.name,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
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
