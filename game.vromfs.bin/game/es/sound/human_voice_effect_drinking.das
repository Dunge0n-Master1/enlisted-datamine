require ecs
require ecs.safe
require human_sounds.modules.human_voice_effect_common
require strings


[es(tag=sound, on_appear, before=human_voice_effect_on_change, track=human_inventory__entityToUse)]
def human_voice_effect_drinking(evt : Event;
                                [[shared_comp]] net_sound__descs : Object;
                                human_inventory__entityToUse : EntityId;
                                var human_voice_effect__activeEffects : Object&)
  var isDrinking = false
  ecs::query(human_inventory__entityToUse) <| $ [es] (item__usingSoundType : string = ""; item__lootSoundType : string)
    let path = empty(item__usingSoundType) ? "using_{item__lootSoundType}" : item__usingSoundType
    let obj = net_sound__descs[path] ?as Object
    isDrinking = obj?.isDrinking ?? false
  set_human_voice_effect("drink", isDrinking, human_voice_effect__activeEffects)