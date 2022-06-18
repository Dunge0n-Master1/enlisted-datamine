require ecs
require enlisted.events_enlisted


[es(tag=server, on_appear, track=placeable_item__ownerEid)]
def apply_more_medpacks_perk_on_medbox_creation(evt : Event;
                                                placeable_item__ownerEid : EntityId;
                                                var useful_box__useCount : int&)
  query(placeable_item__ownerEid) <| $ [es] (entity_mods__medicMedboxPacksMult : float)
    useful_box__useCount = int(float(useful_box__useCount) * entity_mods__medicMedboxPacksMult)
