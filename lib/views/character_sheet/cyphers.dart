import 'package:cypher_sheet/components/dialog.dart';
import 'package:cypher_sheet/components/search.dart';
import 'package:cypher_sheet/components/separator.dart';
import 'package:cypher_sheet/proto/character.pb.dart';
import 'package:cypher_sheet/state/providers/character.dart';
import 'package:cypher_sheet/state/providers/cyphers.dart';
import 'package:cypher_sheet/views/dialogs/cypher_limit.dart';
import 'package:cypher_sheet/views/dialogs/object/artifact/create.dart';
import 'package:cypher_sheet/views/dialogs/object/cypher/create.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cypher_sheet/components/appbar.dart' as app;
import 'package:cypher_sheet/components/box.dart';
import 'package:cypher_sheet/components/cypher.dart';
import 'package:cypher_sheet/components/filterbar.dart';
import 'package:cypher_sheet/components/icon.dart';
import 'package:cypher_sheet/components/scroll.dart';
import 'package:cypher_sheet/components/text.dart';
import 'package:cypher_sheet/components/icons.dart';

class CyphersView extends ConsumerWidget {
  const CyphersView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cyphersFiltered = ref.watch(cypherFilterProvider);
    final activeCyphers = ref.watch(filteredCyphersProvider(true));
    final inactiveCyphers = ref.watch(filteredCyphersProvider(false));

    final artifactsFiltered = ref.watch(artifactFilterProvider);
    final activeArtifacts = ref.watch(filteredArtifactsProvider(true));
    final inactiveArtifacts = ref.watch(filteredArtifactsProvider(false));

    final searchActive = ref.watch(cypherAndArtifactSearchActiveProvider);
    final createActive = ref.watch(createCypherAndArtifactSelectorActive);

    final cypherLimit =
        ref.watch(characterProvider.select((value) => value.cypherLimit));

    return AppScrollView(
      appBar: app.AppBar(
          child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const AppText(
            "Cyphers",
            align: TextAlign.left,
          ),
          AppBox(
            onTap: () {
              showAppDialog(context, const CypherLimitEdit());
            },
            borderRadius: 8,
            customPadding:
                const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
            color: Theme.of(context).colorScheme.surface,
            child: AppText("Limit: $cypherLimit",
                style: Theme.of(context)
                    .textTheme
                    .bodySmall!
                    .copyWith(letterSpacing: -1),
                align: TextAlign.center),
          )
        ],
      )),
      slivers: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: FittedBox(
            fit: BoxFit.contain,
            child: FilterBar(
              filters: [
                SVGBoxLabeled(
                  icon: AppIcons.cypher,
                  label: "Cyphers",
                  active: cyphersFiltered,
                  onTap: () {
                    ref.read(cypherFilterProvider.notifier).state =
                        !cyphersFiltered;
                  },
                ),
                SVGBoxLabeled(
                    icon: AppIcons.artifact,
                    label: "Artifacts",
                    active: artifactsFiltered,
                    onTap: () {
                      ref.read(artifactFilterProvider.notifier).state =
                          !artifactsFiltered;
                    }),
              ],
              add: SVGBox(
                icon: AppIcons.add,
                onTap: () {
                  ref
                      .read(createCypherAndArtifactSelectorActive.notifier)
                      .state = !createActive;
                },
              ),
              search: SVGBox(
                icon: AppIcons.search,
                onTap: () {
                  if (searchActive) {
                    ref.read(cypherAndArtifactSearchProvider.notifier).state =
                        "";
                  }
                  ref
                      .read(cypherAndArtifactSearchActiveProvider.notifier)
                      .state = !searchActive;
                },
              ),
            ),
          ),
        ),
        if (createActive)
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: FittedBox(
              fit: BoxFit.contain,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SVGBoxLabeled(
                    icon: AppIcons.cypher,
                    label: "Create Cypher",
                    active: false,
                    onTap: () {
                      ref
                          .read(createCypherAndArtifactSelectorActive.notifier)
                          .state = false;
                      showAppDialog(
                        context,
                        const CreateCypher(),
                        fullscreen: true,
                      );
                    },
                  ),
                  const SizedBox(width: 8.0),
                  SVGBoxLabeled(
                      icon: AppIcons.artifact,
                      label: "Create Artifact",
                      active: false,
                      onTap: () {
                        ref
                            .read(
                                createCypherAndArtifactSelectorActive.notifier)
                            .state = false;
                        showAppDialog(
                          context,
                          const CreateArtifact(),
                          fullscreen: true,
                        );
                      }),
                ],
              ),
            ),
          ),
        if (searchActive)
          AppSearchBar(onSearch: (newValue) {
            ref.read(cypherAndArtifactSearchProvider.notifier).state = newValue;
          }),
        ...activeCyphers
            .map((cypher) => Padding(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                  child: CypherListItem(
                    type: CypherType.cypher,
                    uuid: cypher.uuid,
                  ),
                ))
            .toList(growable: false),
        ...activeArtifacts
            .map((artifact) => Padding(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                  child: CypherListItem(
                    type: CypherType.artifact,
                    uuid: artifact.uuid,
                  ),
                ))
            .toList(growable: false),
        if (inactiveCyphers.isNotEmpty || inactiveArtifacts.isNotEmpty)
          const ListSeparator(text: "Inactive"),
        ...inactiveCyphers
            .map((cypher) => Padding(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                  child: CypherListItem(
                    type: CypherType.cypher,
                    uuid: cypher.uuid,
                  ),
                ))
            .toList(growable: false),
        ...inactiveArtifacts
            .map((artifact) => Padding(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                  child: CypherListItem(
                    type: CypherType.artifact,
                    uuid: artifact.uuid,
                  ),
                ))
            .toList(growable: false),
      ],
    );
  }
}
