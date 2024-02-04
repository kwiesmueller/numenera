import 'package:cypher_sheet/components/equipment.dart';
import 'package:cypher_sheet/extensions/advancements.dart';
import 'package:cypher_sheet/extensions/damage.dart';
import 'package:cypher_sheet/extensions/pool.dart';
import 'package:cypher_sheet/extensions/recovery.dart';
import 'package:cypher_sheet/state/providers/storage.dart';
import 'package:cypher_sheet/state/storage/migrations/initialize_inventories.dart';
import 'package:cypher_sheet/state/storage/migrations/wipe_unknown_field_overlap.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cypher_sheet/extensions/color.dart';
import 'package:cypher_sheet/proto/character.pb.dart';
import 'package:protobuf/protobuf.dart';
import 'package:uuid/uuid.dart';

class CharacterNotifier extends Notifier<Character> {
  CharacterNotifier() : super();

  @override
  Character build() {
    return Character().freeze() as Character;
  }

  void load(Character character) {
    character = character.freeze() as Character;
    for (var migration in <Character Function(Character)>[
      initializeInventories,
      wipeUnknownFieldsWithOverlappingKnownFieldsForCharacter,
    ]) {
      character = migration(character);
    }
    state = character;
  }

  void reset() {
    state = Character().freeze() as Character;
  }

  void create({
    required String name,
    required String descriptor,
    required String type,
    required String focus,
    required Color color,
  }) {
    state = Character(
      name: name,
      descriptor: descriptor,
      type: type,
      focus: focus,
      color: characterColorFromColor(color),
      progress: Progress(
        tier: 1,
        advancements: Advancements().freeze() as Advancements,
      ).freeze() as Progress,
      stats: Stats(
        intellect: Stat(type: PoolType.intellect).freeze() as Stat,
        speed: Stat(type: PoolType.speed).freeze() as Stat,
        might: Stat(type: PoolType.might).freeze() as Stat,
      ).freeze() as Stats,
      damage: Damage().freeze() as Damage,
      recovery: Recovery().freeze() as Recovery,
    ).freeze() as Character;
    ref.watch(storageProvider).createCharacter(state);
  }

  void updateMetadata({
    required String name,
    required String descriptor,
    required String type,
    required String focus,
    required Color color,
  }) {
    state = state.rebuild((character) {
      character.name = name;
      character.descriptor = descriptor;
      character.type = type;
      character.focus = focus;
      character.color = characterColorFromColor(color);
    });
  }

  void toggleRecovery(Recover recover) {
    state = state.rebuild(
      (character) {
        character.recovery = character.recovery.rebuild((recoveries) {
          recoveries.toggle(recover);
        });
      },
    );
  }

  void editRecoveryBonus(int bonus) {
    final current = state.recovery.bonus;
    if (bonus == current) {
      return;
    }

    state = state.rebuild(
      (character) {
        character.recovery = character.recovery.rebuild((recoveries) {
          recoveries.bonus = bonus;
        });
      },
    );
  }

  void addRecoveryBonus(int add) {
    if (add == 0) {
      return;
    }

    state = state.rebuild(
      (character) {
        character.recovery = character.recovery.rebuild((recoveries) {
          recoveries.bonus += add;
        });
      },
    );
  }

  void toggleDamageImpaired() {
    state = state.rebuild(
      (character) {
        character.damage = character.damage.rebuild((damage) {
          damage.toggleImpaired();
        });
      },
    );
  }

  void toggleDamageDebilitated() {
    state = state.rebuild(
      (character) {
        character.damage = character.damage.rebuild((damage) {
          damage.toggleDebilitated();
        });
      },
    );
  }

  void addToPool(PoolType pool, int add) {
    if (add == 0) {
      return;
    }
    state = state.rebuild((character) {
      character.stats = character.stats.rebuild((stats) {
        stats.updateStat(
            pool,
            stats.getStatForPool(pool).rebuild((stat) {
              stat.addToPool(add);
            }));
      });
    });
  }

  void editPool(PoolType pool, int value) {
    final current = state.stats.getStatForPool(pool).pool;
    if (value == current) {
      return;
    }
    state = state.rebuild((character) {
      character.stats = character.stats.rebuild((stats) {
        stats.updateStat(
            pool,
            stats.getStatForPool(pool).rebuild((stat) {
              stat.pool = value;
            }));
      });
    });
  }

  void editEdge(PoolType pool, int value) {
    final current = state.stats.getStatForPool(pool).edge;
    if (value == current) {
      return;
    }
    state = state.rebuild((character) {
      character.stats = character.stats.rebuild((stats) {
        stats.updateStat(
            pool,
            stats.getStatForPool(pool).rebuild((stat) {
              stat.edge = value;
            }));
      });
    });
  }

  void editCap(PoolType pool, int value) {
    final current = state.stats.getStatForPool(pool).cap;
    if (value == current) {
      return;
    }
    state = state.rebuild((character) {
      character.stats = character.stats.rebuild((stats) {
        stats.updateStat(
            pool,
            stats.getStatForPool(pool).rebuild((stat) {
              stat.cap = value;
            }));
      });
    });
  }

  void editMaxEffort(int value) {
    final current = state.progress.maxEffort;
    if (value == current) {
      return;
    }
    state = state.rebuild((character) {
      character.progress = character.progress.rebuild((progress) {
        progress.maxEffort = value;
      });
    });
  }

  void editFreeXP(int value) {
    final current = state.progress.freeXp;
    if (value == current) {
      return;
    }
    state = state.rebuild((character) {
      character.progress = character.progress.rebuild((progress) {
        progress.freeXp = value;
      });
    });
  }

  void editTotalXP(int value) {
    final current = state.progress.totalXp;
    if (value == current) {
      return;
    }
    state = state.rebuild((character) {
      character.progress = character.progress.rebuild((progress) {
        progress.totalXp = value;
      });
    });
  }

  void addXP(int value) {
    if (value == 0) {
      return;
    }
    state = state.rebuild((character) {
      character.progress = character.progress.rebuild((progress) {
        progress.totalXp += value;
        progress.freeXp += value;
      });
    });
  }

  void spendXP(int value) {
    if (value == 0) {
      return;
    }
    state = state.rebuild((character) {
      character.progress = character.progress.rebuild((progress) {
        // we don't remove totalXp as it is meant to record total "gained" xp
        progress.freeXp -= value;
      });
    });
  }

  void resetAllPools() {
    state = state.rebuild((character) {
      character.stats = character.stats.rebuild((stats) {
        stats.resetAllPools();
      });
    });
  }

  void recoverAllPools({
    int addIntellect = 0,
    int addSpeed = 0,
    int addMight = 0,
  }) {
    state = state.rebuild((character) {
      character.stats = character.stats.rebuild((stats) {
        stats.recoverAllPools(
          addIntellect: addIntellect,
          addSpeed: addSpeed,
          addMight: addMight,
        );
      });
    });
  }

  void editTier(int value) {
    final current = state.progress.tier;
    if (value == current) {
      return;
    }
    state = state.rebuild((character) {
      character.progress = character.progress.rebuild((progress) {
        progress.tier = value;
      });
    });
  }

  void advanceTier(int value) {
    if (value == 0) {
      return;
    }
    state = state.rebuild((character) {
      character.progress = character.progress.rebuild((progress) {
        progress.tier += value;
        progress.advancements = Advancements();
      });
      character.recovery = character.recovery.rebuild((recoveries) {
        recoveries.bonus += value;
      });
    });
  }

  void toggleAdvancement(Advancement advancement) {
    state = state.rebuild(
      (character) {
        character.progress = character.progress.rebuild((progress) {
          progress.advancements = progress.advancements.rebuild((advancements) {
            final newValue = advancements.toggleAdvancement(advancement);
            if (newValue) {
              progress.freeXp -= progress.advancements.xpPerAdvancement();
            } else {
              progress.freeXp += progress.advancements.xpPerAdvancement();
            }
          });
        });
      },
    );
  }

  void addAbility(Ability ability) {
    if (ability.uuid.isEmpty) {
      ability.uuid = _uuid.v4();
    }
    state = state.rebuild((character) {
      character.abilities.add(ability.freeze() as Ability);
    });
  }

  void updateAbility(Ability ability) {
    if (ability.uuid.isEmpty) {
      addAbility(ability);
      return;
    }
    state = state.rebuild((character) {
      final abilities = character.abilities
          .where((element) => element.uuid != ability.uuid)
          .toList();
      character.abilities.clear();
      character.abilities.addAll(
        [...abilities, ability],
      );
    });
  }

  void deleteAbility(String uuid) {
    if (uuid.isEmpty) {
      return;
    }
    state = state.rebuild((character) {
      final abilities =
          character.abilities.where((element) => element.uuid != uuid).toList();
      character.abilities.clear();
      character.abilities.addAll(abilities);
    });
  }

  void editCypherLimit(int value) {
    final current = state.cypherLimit;
    if (value == current) {
      return;
    }
    state = state.rebuild((character) {
      character.cypherLimit = value;
    });
  }

  void addCypher(Cypher cypher) {
    if (cypher.uuid.isEmpty) {
      cypher.uuid = _uuid.v4();
    }
    state = state.rebuild((character) {
      character.cyphers.add(cypher.freeze() as Cypher);
    });
  }

  void updateCypher(Cypher cypher) {
    if (cypher.uuid.isEmpty) {
      addCypher(cypher);
      return;
    }
    state = state.rebuild((character) {
      final cyphers = character.cyphers
          .where((element) => element.uuid != cypher.uuid)
          .toList();
      character.cyphers.clear();
      character.cyphers.addAll(
        [...cyphers, cypher],
      );
    });
  }

  void deleteCypher(String uuid) {
    if (uuid.isEmpty) {
      return;
    }
    state = state.rebuild((character) {
      final cyphers =
          character.cyphers.where((element) => element.uuid != uuid).toList();
      character.cyphers.clear();
      character.cyphers.addAll(cyphers);
    });
  }

  void addArtifact(Artifact artifact) {
    if (artifact.uuid.isEmpty) {
      artifact.uuid = _uuid.v4();
    }
    state = state.rebuild((character) {
      character.artifacts.add(artifact.freeze() as Artifact);
    });
  }

  void updateArtifact(Artifact artifact) {
    if (artifact.uuid.isEmpty) {
      addArtifact(artifact);
      return;
    }
    state = state.rebuild((character) {
      final artifacts = character.artifacts
          .where((element) => element.uuid != artifact.uuid)
          .toList();
      character.artifacts.clear();
      character.artifacts.addAll(
        [...artifacts, artifact],
      );
    });
  }

  void deleteArtifact(String uuid) {
    if (uuid.isEmpty) {
      return;
    }
    state = state.rebuild((character) {
      final artifacts =
          character.artifacts.where((element) => element.uuid != uuid).toList();
      character.artifacts.clear();
      character.artifacts.addAll(artifacts);
    });
  }

  void addSkill(Skill skill) {
    if (skill.uuid.isEmpty) {
      skill.uuid = _uuid.v4();
    }
    state = state.rebuild((character) {
      character.skills.add(skill.freeze() as Skill);
    });
  }

  void updateSkill(Skill skill) {
    if (skill.uuid.isEmpty) {
      addSkill(skill);
      return;
    }
    state = state.rebuild((character) {
      final skills = character.skills
          .where((element) => element.uuid != skill.uuid)
          .toList();
      character.skills.clear();
      character.skills.addAll(
        [...skills, skill],
      );
    });
  }

  void deleteSkill(String uuid) {
    if (uuid.isEmpty) {
      return;
    }
    state = state.rebuild((character) {
      final skills =
          character.skills.where((element) => element.uuid != uuid).toList();
      character.skills.clear();
      character.skills.addAll(skills);
    });
  }

  void addItem(Item item) {
    if (item.path.self.isEmpty) {
      item.path.self = _uuid.v4();
    }
    state = state.rebuild((character) {
      character.items.add(item);
      character.items.sort((a, b) => a.name.compareTo(b.name));
    });
  }

  void updateItem(Item item) {
    if (item.path.self.isEmpty) {
      addItem(item);
      return;
    }
    state = state.rebuild((character) {
      final items = character.items
          .where((element) => element.path.self != item.path.self)
          .toList(growable: false);
      character.items.clear();
      character.items.addAll([
        ...items,
        item,
      ]);
      character.items.sort((a, b) => a.name.compareTo(b.name));
    });
  }

  void moveItem(Item movedItem) {
    if (movedItem.path.self.isEmpty) {
      addItem(movedItem);
      return;
    }
    state = state.rebuild((character) {
      List<Item> otherItems = List.empty(growable: true);
      List<Item> subItems = List.empty(growable: true);
      for (var item in character.items) {
        if (item.path.self == movedItem.path.self) {
          continue;
        }
        if (item.path.parent == movedItem.path.self) {
          final movedSubItem = item.rebuild((item) {
            item.path = item.path.rebuild((path) {
              path.inventory = movedItem.path.inventory;
            });
          });
          subItems.add(movedSubItem);
          continue;
        }
        otherItems.add(item);
      }

      character.items.clear();
      character.items.addAll([
        ...otherItems,
        ...subItems,
        movedItem,
      ]);
      character.items.sort((a, b) => a.name.compareTo(b.name));
    });
  }

  void addItemAmount(Item item, double add) {
    if (item.path.self.isEmpty) {
      return;
    }
    state = state.rebuild((character) {
      final items = character.items
          .where((element) => element.path != item.path)
          .toList(growable: false);
      character.items.clear();
      character.items.addAll([
        ...items,
        item.rebuild((item) {
          item.amount += add;
        }),
      ]);
      character.items.sort((a, b) => a.name.compareTo(b.name));
    });
  }

  void updateItemAmount(Item item, double amount) {
    if (item.path.self.isEmpty) {
      return;
    }
    state = state.rebuild((character) {
      final items = character.items
          .where((element) => element.path != item.path)
          .toList(growable: false);
      character.items.clear();
      character.items.addAll([
        ...items,
        item.rebuild((item) {
          item.amount = amount;
        }),
      ]);
      character.items.sort((a, b) => a.name.compareTo(b.name));
    });
  }

  void deleteItem(String uuid) {
    if (uuid.isEmpty || uuid == virtualItemUUID) {
      return;
    }
    state = state.rebuild((character) {
      final items = state.items
          .where((element) =>
              element.path.self != uuid && element.path.parent != uuid)
          .toList(growable: false);
      character.items.clear();
      character.items.addAll([
        ...items,
      ]);
      character.items.sort((a, b) => a.name.compareTo(b.name));
    });
  }

  void addNote(Note note) {
    if (note.uuid.isEmpty) {
      note.uuid = _uuid.v4();
    }
    state = state.rebuild((character) {
      character.notes.add(note.freeze() as Note);
    });
  }

  void updateNote(Note note) {
    if (note.uuid.isEmpty) {
      addNote(note);
      return;
    }
    state = state.rebuild((character) {
      final notes = character.notes
          .where((element) => element.uuid != note.uuid)
          .toList();
      character.notes.clear();
      character.notes.addAll(
        [...notes, note],
      );
    });
  }

  void deleteNote(String uuid) {
    if (uuid.isEmpty) {
      return;
    }
    state = state.rebuild((character) {
      final notes =
          character.notes.where((element) => element.uuid != uuid).toList();
      character.notes.clear();
      character.notes.addAll(notes);
    });
  }

  void editMoney(double value) {
    final current = state.money;
    if (value == current) {
      return;
    }
    state = state.rebuild((character) {
      character.money = value;
    });
  }

  void addMoney(double add) {
    if (add == 0) {
      return;
    }
    state = state.rebuild((character) {
      character.money += add;
    });
  }

  static const _uuid = Uuid();
}
