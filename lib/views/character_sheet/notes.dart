import 'package:cypher_sheet/components/dialog.dart';
import 'package:cypher_sheet/components/filterbar.dart';
import 'package:cypher_sheet/components/icon.dart';
import 'package:cypher_sheet/components/icons.dart';
import 'package:cypher_sheet/components/note.dart';
import 'package:cypher_sheet/components/search.dart';
import 'package:cypher_sheet/extensions/note.dart';
import 'package:cypher_sheet/proto/character.pb.dart';
import 'package:cypher_sheet/state/providers/notes.dart';
import 'package:cypher_sheet/views/dialogs/object/note/create.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cypher_sheet/components/appbar.dart' as app;
import 'package:cypher_sheet/components/scroll.dart';
import 'package:cypher_sheet/components/text.dart';

class NotesView extends ConsumerWidget {
  const NotesView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(filteredNotesProvider);
    final searchActive = ref.watch(noteSearchActiveProvider);
    return AppScrollView(
      appBar: const app.AppBar(
          child: AppText(
        "Notes",
        align: TextAlign.left,
      )),
      slivers: <Widget>[
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: FilterBar(
            filters: const [],
            add: SVGBox(
              icon: AppIcons.add,
              onTap: () {
                showAppDialog(
                  context,
                  const CreateNote(),
                  fullscreen: true,
                );
              },
            ),
            search: SVGBox(
              icon: AppIcons.search,
              onTap: () {
                if (searchActive) {
                  ref.read(noteSearchProvider.notifier).state = "";
                }
                ref.read(noteSearchActiveProvider.notifier).state =
                    !searchActive;
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: FilterBar(wrap: true, filters: [
            ...NoteType.values
                .map((type) => SVGBoxLabeled(
                      icon: type.toIcon(),
                      label: type.toLabel(),
                      iconSize: 24,
                      customLabelStyle: Theme.of(context).textTheme.labelLarge,
                      active: ref.watch(noteFilterProvider).isTypeActive(type),
                      onTap: () {
                        ref
                            .watch(noteFilterProvider.notifier)
                            .toggleFilter(type);
                      },
                    ))
                .toList(growable: false),
          ]),
        ),
        if (searchActive)
          AppSearchBar(
            onSearch: (newValue) {
              ref.read(noteSearchProvider.notifier).state = newValue;
            },
          ),
        ...notes
            .map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: NoteListItem(uuid: e.uuid),
                ))
            .toList(growable: false),
      ],
    );
  }
}
