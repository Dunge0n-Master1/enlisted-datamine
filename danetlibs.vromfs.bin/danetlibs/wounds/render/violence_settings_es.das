require ecs

[es(tag=gameClient, on_appear, REQUIRE=human)]
def apply_violence_settings_to_humans(evt : Event; eid : EntityId)
  query() <| $ [es] (isGoreEnabled : bool)
    if isGoreEnabled
      addSubTemplate(eid, "human_broken_bones")
    else
      removeSubTemplate(eid, "human_broken_bones")

[es(tag=gameClient, on_appear, REQUIRE=attachableBrokenBonesWear)]
def apply_violence_settings_to_attachable_wear(evt : Event; eid : EntityId)
  query() <| $ [es] (isGoreEnabled : bool)
    if isGoreEnabled
      addSubTemplate(eid, "attachable_wear_broken_bones_data")
    else
      removeSubTemplate(eid, "attachable_wear_broken_bones_data")