import 'package:cypher_sheet/components/dialog.dart';
import 'package:cypher_sheet/components/filterbar.dart';
import 'package:cypher_sheet/components/icon.dart';
import 'package:cypher_sheet/components/icons.dart';
import 'package:cypher_sheet/components/search.dart';
import 'package:cypher_sheet/proto/character.pb.dart';
import 'package:cypher_sheet/state/providers/abilities.dart';
import 'package:cypher_sheet/views/character_sheet/equipment.dart';
import 'package:cypher_sheet/views/dialogs/object/ability/create.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cypher_sheet/components/ability.dart';
import 'package:cypher_sheet/components/appbar.dart' as app;
import 'package:cypher_sheet/components/scroll.dart';
import 'package:cypher_sheet/components/text.dart';

class AbilitiesView extends ConsumerWidget {
  const AbilitiesView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final abilities = ref.watch(filteredAbilitiesProvider);
    final widgets = abilities
        .map((ability) => Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
              child: AbilityListItem(ability.uuid),
            ))
        .toList(growable: false);

    final searchActive = ref.watch(abilitySearchActiveProvider);

    const iconSize = 42.0;
    return AppScrollView(
      appBar: const app.AppBar(
          child: AppText(
        "Abilities",
        align: TextAlign.left,
      )),
      slivers: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: EquipmentFilter(
            filterIcons: [
              PoolFilterIcon(
                type: PoolType.intellect,
                provider: abilityFilterProvider,
              ),
              PoolFilterIcon(
                type: PoolType.speed,
                provider: abilityFilterProvider,
              ),
              PoolFilterIcon(
                type: PoolType.might,
                provider: abilityFilterProvider,
              ),
              const SizedBox(width: 28.0)
            ],
            add: SVGBox(
              icon: AppIcons.add,
              size: iconSize,
              onTap: () {
                showAppDialog(
                  context,
                  const CreateAbility(),
                  fullscreen: true,
                );
              },
            ),
            search: SVGBox(
              icon: AppIcons.search,
              size: iconSize,
              onTap: () {
                if (searchActive) {
                  ref.read(abilitySearchProvider.notifier).state = "";
                }
                ref.read(abilitySearchActiveProvider.notifier).state =
                    !searchActive;
              },
            ),
          ),
        ),
        if (searchActive)
          AppSearchBar(
            onSearch: (newValue) {
              ref.read(abilitySearchProvider.notifier).state = newValue;
            },
          ),
        ...widgets,
      ],
    );
  }
}
