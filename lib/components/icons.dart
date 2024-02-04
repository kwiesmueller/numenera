enum AppIcons {
  add,
  remove,
  search,
  up,
  down,
  close,
  none,

  skills,
  abilities,
  stats,
  cypher,
  artifact,
  equipment,
  recovery,
  advanceTier,
  database,
  notes,

  intellect,
  speed,
  might,

  trained,
  specialized,
  inability,

  weapon,
  clothing,
  tool,
  self,
  backpack,
  home,
  armor,
  money,
  io,
  oddity,
  material,
  ammo,
  plan,
  other,

  location,
  character,
  item,
  quest,

  edit,
  deleteForever,
  share,
  import,
  cloudSync,
  link,
  unlink,
  devMode;

  @override
  String toString() => name[0].toUpperCase() + name.substring(1);
}

String iconName(AppIcons from) {
  switch (from) {
    case AppIcons.add:
      return "add";
    case AppIcons.remove:
      return "remove";
    case AppIcons.search:
      return "search";
    case AppIcons.up:
      return "keyboard_arrow_up";
    case AppIcons.down:
      return "keyboard_arrow_down";
    case AppIcons.close:
      return "close";
    case AppIcons.none:
      return "hide_source";
    case AppIcons.skills:
      return "webhook";
    case AppIcons.abilities:
      return "recent_actors";
    case AppIcons.stats:
      return "self_improvement";
    case AppIcons.cypher:
      return "api";
    case AppIcons.artifact:
      return "token";
    case AppIcons.equipment:
      return "storage";
    case AppIcons.recovery:
      return "self_improvement";
    case AppIcons.advanceTier:
      return "rocket_launch";
    case AppIcons.database:
      return "blur_on";
    case AppIcons.notes:
      return "description";
    case AppIcons.intellect:
      return "psychology_filled";
    case AppIcons.speed:
      return "speed";
    case AppIcons.might:
      return "fitness_center";
    case AppIcons.trained:
      return "keyboard_arrow_up";
    case AppIcons.specialized:
      return "keyboard_double_arrow_up";
    case AppIcons.inability:
      return "keyboard_double_arrow_down";
    case AppIcons.weapon:
      return "swords";
    case AppIcons.clothing:
      return "laundry";
    case AppIcons.tool:
      return "handyman";
    case AppIcons.self:
      return "accessibility";
    case AppIcons.backpack:
      return "backpack";
    case AppIcons.home:
      return "home";
    case AppIcons.armor:
      return "shield";
    case AppIcons.money:
      return "payments";
    case AppIcons.io:
      return "diamond";
    case AppIcons.oddity:
      return "glyphs";
    case AppIcons.material:
      return "diamond";
    case AppIcons.ammo:
      return "glyphs";
    case AppIcons.plan:
      return "flowsheet";
    case AppIcons.other:
      return "glyphs";
    case AppIcons.location:
      return "location_on";
    case AppIcons.character:
      return "person";
    case AppIcons.item:
      return "category";
    case AppIcons.quest:
      return "task_alt";
    case AppIcons.edit:
      return "edit";
    case AppIcons.deleteForever:
      return "delete_forever";
    case AppIcons.share:
      return "share";
    case AppIcons.import:
      return "system_update_alt";
    case AppIcons.cloudSync:
      return "cloud_sync";
    case AppIcons.link:
      return "link";
    case AppIcons.unlink:
      return "link_off";
    case AppIcons.devMode:
      return "developer_mode";
  }
}
