import 'package:cypher_sheet/components/dialog.dart';
import 'package:cypher_sheet/components/search.dart';
import 'package:cypher_sheet/proto/character.pb.dart';
import 'package:cypher_sheet/state/providers/skills.dart';
import 'package:cypher_sheet/views/character_sheet/equipment.dart';
import 'package:cypher_sheet/views/dialogs/object/skill/create.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cypher_sheet/components/appbar.dart' as app;
import 'package:cypher_sheet/components/filterbar.dart';
import 'package:cypher_sheet/components/icon.dart';
import 'package:cypher_sheet/components/scroll.dart';
import 'package:cypher_sheet/components/skill.dart';
import 'package:cypher_sheet/components/text.dart';
import 'package:cypher_sheet/components/icons.dart';

class SkillsView extends ConsumerWidget {
  const SkillsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skills = ref.watch(filteredSkillsProvider);
    final searchActive = ref.watch(skillSearchActiveProvider);

    const iconSize = 42.0;
    return AppScrollView(
      appBar: const app.AppBar(
          child: AppText(
        "Skills",
        align: TextAlign.left,
      )),
      slivers: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: EquipmentFilter(
            filterIcons: [
              PoolFilterIcon(
                type: PoolType.intellect,
                provider: skillFilterProvider,
              ),
              PoolFilterIcon(
                type: PoolType.speed,
                provider: skillFilterProvider,
              ),
              PoolFilterIcon(
                type: PoolType.might,
                provider: skillFilterProvider,
              ),
            ],
            add: SVGBox(
              icon: AppIcons.add,
              size: iconSize,
              onTap: () {
                showAppDialog(
                  context,
                  const CreateSkill(),
                  fullscreen: true,
                );
              },
            ),
            search: SVGBox(
              icon: AppIcons.search,
              size: iconSize,
              onTap: () {
                if (searchActive) {
                  ref.read(skillSearchProvider.notifier).state = "";
                }
                ref.read(skillSearchActiveProvider.notifier).state =
                    !searchActive;
              },
            ),
          ),
        ),
        if (searchActive)
          AppSearchBar(
            onSearch: (newValue) {
              ref.read(skillSearchProvider.notifier).state = newValue;
            },
          ),
        ...skills
            .map((skill) => Padding(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                  child: SkillListItem(skill.uuid),
                ))
            .toList(growable: false)
      ],
    );
  }
}
