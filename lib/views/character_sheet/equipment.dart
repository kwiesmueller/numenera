import 'package:cypher_sheet/components/dialog.dart';
import 'package:cypher_sheet/components/search.dart';
import 'package:cypher_sheet/components/separator.dart';
import 'package:cypher_sheet/extensions/item.dart';
import 'package:cypher_sheet/state/providers/character.dart';
import 'package:cypher_sheet/state/providers/inventories.dart';
import 'package:cypher_sheet/state/providers/items.dart';
import 'package:cypher_sheet/views/dialogs/money.dart';
import 'package:cypher_sheet/views/dialogs/object/item/create.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cypher_sheet/components/appbar.dart' as app;
import 'package:cypher_sheet/components/custom_dropdown.dart'
    as custom_dropdown;
import 'package:cypher_sheet/components/box.dart';
import 'package:cypher_sheet/components/equipment.dart';
import 'package:cypher_sheet/components/filterbar.dart';
import 'package:cypher_sheet/components/icon.dart';
import 'package:cypher_sheet/components/scroll.dart';
import 'package:cypher_sheet/components/text.dart';
import 'package:cypher_sheet/components/icons.dart';
import 'package:cypher_sheet/proto/character.pb.dart';

class EquipmentView extends ConsumerWidget {
  const EquipmentView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventories = ref.watch(filteredInventoriesProvider);

    final widgets = <Widget>[
      ...equipmentFilters(ref),
      const SizedBox(
        height: 8.0,
      ),
      for (var inventory in inventories) ...[
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: ListSeparator(
            text: inventory.name,
            alignment: Alignment.centerLeft,
            rightOnTap: () {
              showAppDialog(
                  context,
                  CreateItem(
                    path: ItemPath(inventory: inventory.uuid),
                  ));
            },
          ),
        ),
        ...buildInventory(
          context,
          ref,
          inventory.uuid,
        ),
      ],
    ];

    return AppScrollView(
      appBar: const app.AppBar(
          child: AppText(
        "Equipment",
        align: TextAlign.left,
      )),
      slivers: widgets,
    );
  }

  List<Widget> buildInventory(
      BuildContext context, WidgetRef ref, String uuid) {
    final items = ref.watch(filteredItemsProvider(uuid));

    bool hasMaterials = false;
    List<Widget> itemWidgets = List.empty(growable: true);
    for (var item in items) {
      if (item.types.contains(ItemType.material)) {
        hasMaterials = true;
        continue;
      }
      itemWidgets.add(EquipmentItem(item.path));
    }
    if (hasMaterials) {
      itemWidgets.add(EquipmentItem.virtual(
        Item(
          path: ItemPath(inventory: uuid),
          name: "Materials",
          types: [ItemType.material],
          subItemType: ItemType.material,
        ),
        inventory: uuid,
      ));
    }
    return itemWidgets;
  }
}

List<Widget> equipmentFilters(WidgetRef ref) {
  return [
    const EquipmentMainFilter(),
    const ItemTypeFilter(),
    const InventoryFilter(),
    if (ref.watch(itemSearchActiveProvider))
      AppSearchBar(onSearch: (search) {
        ref.read(itemSearchProvider.notifier).state = search;
      }),
  ];
}

class EquipmentMainFilter extends ConsumerWidget {
  const EquipmentMainFilter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchActive = ref.watch(itemSearchActiveProvider);
    return EquipmentFilter(
      filterIcons: [
        SVGBoxLabeled(
          icon: AppIcons.armor,
          label: ref.watch(armorProvider).toString(),
          active: ref.watch(itemFilterProvider).isTypeExclusive(ItemType.armor),
          onTap: () {
            ref
                .read(itemFilterProvider.notifier)
                .toggleExclusive(ItemType.armor);
          },
        ),
        SVGBoxLabeled(
          icon: AppIcons.money,
          label: removeZeroDecimals(
                  ref.watch(characterProvider.select((value) => value.money)))
              .toString(),
          active: false,
          onTap: () {
            showAppDialog(context, const MoneyEdit());
          },
        ),
        SVGBoxLabeled(
          icon: AppIcons.io,
          label: ref.watch(valueProvider).floor().toString(),
          active:
              ref.watch(itemFilterProvider).isTypeExclusive(ItemType.material),
          onTap: () {
            ref
                .read(itemFilterProvider.notifier)
                .toggleExclusive(ItemType.material);
          },
        ),
      ],
      add: const SizedBox(
        width: 30,
      ),
      search: SVGBox(
        icon: AppIcons.search,
        onTap: () {
          if (searchActive) {
            ref.read(itemSearchProvider.notifier).state = "";
          }
          ref.read(itemSearchActiveProvider.notifier).state = !searchActive;
        },
      ),
    );
  }
}

class ItemTypeFilter extends ConsumerWidget {
  const ItemTypeFilter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return EquipmentFilter(
      filterIcons: [
        ItemFilterIcon(
          type: ItemType.weapon,
          provider: itemFilterProvider,
          size: 30,
        ),
        ItemFilterIcon(
          type: ItemType.clothing,
          provider: itemFilterProvider,
          size: 30,
        ),
        ItemFilterIcon(
          type: ItemType.tool,
          provider: itemFilterProvider,
          size: 30,
        ),
      ],
      dropdown: AppDropdown<ItemType>(
        menuWidth: 180,
        options: ItemType.values
            .map(
              (e) => AppDropdownItemValue<ItemType>(
                value: e,
                onTap: () {},
                widget: ProviderScope(
                  parent: ProviderScope.containerOf(context),
                  child: ItemTypeDropdownItem(type: e),
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class InventoryFilter extends ConsumerWidget {
  const InventoryFilter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return EquipmentFilter(
        filterIcons: [
          SVGBox(
            icon: AppIcons.self,
            active: ref
                .watch(inventoryFilterProvider)
                .isTypeActive(inventoryNameSelf),
            onTap: () {
              ref
                  .read(inventoryFilterProvider.notifier)
                  .toggleInventory(inventoryNameSelf);
            },
          ),
          SVGBox(
            icon: AppIcons.backpack,
            active: ref
                .watch(inventoryFilterProvider)
                .isTypeActive(inventoryNameBackpack),
            onTap: () {
              ref
                  .read(inventoryFilterProvider.notifier)
                  .toggleInventory(inventoryNameBackpack);
            },
          ),
          SVGBox(
            icon: AppIcons.home,
            active: ref
                .watch(inventoryFilterProvider)
                .isTypeActive(inventoryNameHome),
            onTap: () {
              ref
                  .read(inventoryFilterProvider.notifier)
                  .toggleInventory(inventoryNameHome);
            },
          ),
        ],
        dropdown: AppDropdown<String>(
          menuWidth: 180,
          options: ref
              .watch(inventoriesProvider)
              .map(
                (e) => AppDropdownItemValue<String>(
                  value: e.uuid,
                  onTap: () {},
                  widget: ProviderScope(
                    parent: ProviderScope.containerOf(context),
                    child: InventoryDropdownItem(uuid: e.uuid),
                  ),
                ),
              )
              .toList(growable: false),
        ));
  }
}

class ItemTypeDropdownItem extends ConsumerWidget {
  const ItemTypeDropdownItem({super.key, required this.type});

  final ItemType type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppDropdownIconItem(
        icon: type.toIcon(),
        label: type.toLabel(),
        onTap: () {
          ref.read(itemFilterProvider.notifier).toggleFilter(type);
        },
        active: ref.watch(itemFilterProvider).isTypeActive(type));
  }
}

class AppDropdownItem extends ConsumerWidget {
  const AppDropdownItem({
    super.key,
    required this.child,
    required this.onTap,
  });

  final Widget child;
  final Function() onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 300),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Container(
        constraints: const BoxConstraints.expand(),
        child: AppBox(
          flat: true,
          onTapGesture: onTap,
          customPadding: const EdgeInsets.symmetric(
            horizontal: 16,
          ),
          child: child,
        ),
      ),
    );
  }
}

class AppDropdownIconItem extends ConsumerWidget {
  const AppDropdownIconItem({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    required this.active,
  });

  final AppIcons icon;
  final String label;
  final Function() onTap;
  final bool active;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 300),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Container(
        constraints: const BoxConstraints.expand(),
        child: AppBox(
          flat: true,
          onTapGesture: onTap,
          customPadding: const EdgeInsets.symmetric(
            horizontal: 16,
          ),
          child: SVGBoxLabeled(
            flat: true,
            icon: icon,
            label: label,
            iconSize: 28,
            customPadding:
                const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            customLabelStyle: Theme.of(context).textTheme.labelLarge,
            active: active,
          ),
        ),
      ),
    );
  }
}

class InventoryDropdownItem extends ConsumerWidget {
  const InventoryDropdownItem({super.key, required this.uuid});

  final String uuid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventory = ref.watch(inventoryProvider(uuid));
    final icon = iconForUUID(uuid);
    if (icon != null) {
      return AppDropdownIconItem(
        icon: icon,
        label: inventory.name,
        onTap: () {
          ref.read(inventoryFilterProvider.notifier).toggleInventory(uuid);
        },
        active: ref.watch(inventoryFilterProvider).isTypeActive(uuid),
      );
    }

    return AppDropdownItem(
        child: AppText(
          inventory.name,
          style: Theme.of(context).textTheme.labelLarge,
        ),
        onTap: () {
          ref.read(inventoryFilterProvider.notifier).toggleInventory(uuid);
        });
  }

  AppIcons? iconForUUID(String uuid) {
    switch (uuid) {
      case inventoryNameSelf:
        return AppIcons.home;
      case inventoryNameBackpack:
        return AppIcons.backpack;
      case inventoryNameHome:
        return AppIcons.home;
      default:
        return null;
    }
  }
}

class EquipmentFilter extends StatelessWidget {
  const EquipmentFilter({
    super.key,
    this.filterIcons = const [],
    this.dropdown,
    this.add,
    this.search,
  });

  final List<Widget> filterIcons;
  final Widget? dropdown;
  final Widget? add;
  final Widget? search;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: FittedBox(
        fit: BoxFit.contain,
        child: FilterBar(
          filters: [
            ...filterIcons,
            if (dropdown != null) dropdown!,
          ],
          add: add,
          search: search,
        ),
      ),
    );
  }
}

class AppDropdownItemValue<T> {
  final T value;
  final Function() onTap;
  final Widget widget;

  AppDropdownItemValue({
    required this.value,
    required this.onTap,
    required this.widget,
  });
}

class AppDropdown<T> extends StatelessWidget {
  const AppDropdown({
    super.key,
    required this.options,
    this.menuWidth,
  });

  final List<AppDropdownItemValue<T>> options;
  final double? menuWidth;

  @override
  Widget build(BuildContext context) {
    return AppBox(
      padding: 0,
      constraints:
          const BoxConstraints(maxHeight: 46, minWidth: 185, maxWidth: 185),
      child: custom_dropdown.DropdownButtonHideUnderline(
          child: custom_dropdown.DropdownButton(
              // TODO: reduce the width of the dropdown button by removing the right
              // padding in the items: https://github.com/flutter/flutter/issues/25151
              icon: const AppIcon(AppIcons.down),
              focusColor: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              value: null,
              menuWidth: menuWidth,
              isExpanded: true,
              hint: Padding(
                padding: const EdgeInsets.all(8.0),
                child: AppText(
                  "More",
                  style: Theme.of(context).textTheme.bodySmall,
                  align: TextAlign.left,
                ),
              ),
              items: options
                  .map((e) => custom_dropdown.DropdownMenuItem<T>(
                        value: e.value,
                        enabled: false,
                        alignment: Alignment.centerRight,
                        child: e.widget,
                      ))
                  .toList(growable: false),
              onChanged: (newValue) {})),
    );
  }
}
