require ecs
require ecs.safe
require ecs.common
require app
require game.es.events
require game.es.awards_common
require DagorMath

def is_heal_award_available_by_limit(uses_info : Object; max_uses_per_minute : int; target_eid : EntityId; cur_time : float)
  let uses = uses_info["{target_eid}"] ?as Object
  let time = uses?.time ?? 0.
  let count = uses?.count ?? 0
  return cur_time - time > 60. || count < max_uses_per_minute

def increase_heal_count(var uses_info : Object&; target_eid : EntityId; cur_time : float)
  let key = "{target_eid}"
  let uses = uses_info[key] ?as Object
  let time = uses?.time ?? 0.
  let count = uses?.count ?? 0
  let shouldResetTime = cur_time - time > 60.
  uses_info |> push_to_object(key) <| $(var info : Object#)
    info |> set("time", shouldResetTime ? cur_time : time)
    info |> set("count", shouldResetTime ? 1 : count + 1)

def on_heal_award(healer : EntityId; target_player : EntityId; target_squad : EntityId; stat : string; target_hp : float; target_max_hp : float; item_heal_amount : float)
  query(healer) <| $ [es] (squad_member__squad : EntityId;
                           squad_member__playerEid : EntityId;
                           entity_mods__healAmountTargetMult : float;
                           guid : string)
    assume healerSquadEid = squad_member__squad
    assume healerPlayer = squad_member__playerEid
    if healerSquadEid != INVALID_ENTITY_ID && healerSquadEid == target_squad
      return
    query(healerPlayer) <| $ [es] (heal_awards__awardPerPlayerPerMinute : int;
                                   heal_awards__minAdditionalAwardByHeal : float;
                                   heal_awards__maxAdditionalAwardByHeal : float;
                                   var heal_awards__healUses : Object&)
      let time = get_sync_time()
      if is_heal_award_available_by_limit(heal_awards__healUses, heal_awards__awardPerPlayerPerMinute, target_player, time)
        increase_heal_count(heal_awards__healUses, target_player, time)

        let srcItemHealAmount = safediv(entity_mods__healAmountTargetMult, item_heal_amount)
        let targetDamageRate = (target_max_hp - target_hp) * srcItemHealAmount
        if entity_mods__healAmountTargetMult > 1.0 && targetDamageRate >= heal_awards__minAdditionalAwardByHeal
          send_award_stat(squad_member__playerEid, guid, stat, min(targetDamageRate, heal_awards__maxAdditionalAwardByHeal))
        else
          send_award_stat(squad_member__playerEid, guid, stat)

def on_revive_award(healer : EntityId; target_squad : EntityId)
  query(healer) <| $ [es] (squad_member__squad : EntityId;
                           squad_member__playerEid : EntityId;
                           entity_mods__healAmountTargetMult : float;
                           guid : string)
    assume healerPlayer = squad_member__playerEid
    if squad_member__squad == INVALID_ENTITY_ID || squad_member__squad != target_squad
      send_award_stat(squad_member__playerEid, guid, "reviveAssists")
      if entity_mods__healAmountTargetMult > 1.0
        query(healerPlayer) <| $ [es] (revive_awards__additionalHealAward : float)
          send_award_stat(squad_member__playerEid, guid, "healAssists", revive_awards__additionalHealAward)

[es(tag=server)]
def revive_award_es(evt : EventOnLootItemUsed;
                    item__reviveAmount : float;
                    item__lastOwner : EntityId)
  query(evt.target) <| $ [es] (squad_member__squad : EntityId; isDowned : bool)
    if isDowned && item__reviveAmount > 0.
      on_revive_award(item__lastOwner, squad_member__squad)

[es(tag=server)]
def heal_award_es(evt : EventOnLootItemUsed;
                  item__healAmount : float;
                  item__lastOwner : EntityId)
  query(evt.target) <| $ [es] (hitpoints__hp : float;
                               hitpoints__maxHp : float;
                               squad_member__squad : EntityId;
                               squad_member__playerEid : EntityId;
                               isDowned : bool)
    if !isDowned && item__healAmount > 0.
      on_heal_award(item__lastOwner, squad_member__playerEid, squad_member__squad, "healAssists", hitpoints__hp, hitpoints__maxHp, item__healAmount)
