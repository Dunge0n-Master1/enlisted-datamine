require ecs
require inventory
require DagorMath
require Grid
require GridCollision
require math.base
require game.es.events
require enlisted.events_enlisted
require enlisted.game.es.medic_common
require game.es.human_use_action_common
require common_shooter.events_common_shooter
require game.events_game

[es(tag=server, track=hitpoints__hp, REQUIRE=human, REQUIRE_NOT=deadEntity)]
def medic_set_heal_state_es(evt : Event;
                            isDowned : bool;
                            hitpoints__hp : float;
                            hitpoints__maxHp : float;
                            medic__reviveThreshold : float = 0.2;
                            medic__healThreshold : float = 0.5;
                            var medic__healState : int&)
  let precent = hitpoints__hp / hitpoints__maxHp
  medic__healState = int(MedicHealState MHS_NONE)
  if isDowned || precent <= medic__reviveThreshold
    medic__healState = int(MedicHealState MHS_NEED_REVIVE)
  elif precent <= medic__healThreshold
    medic__healState = int(MedicHealState MHS_NEED_HEAL)

[es(tag=server, REQUIRE=human, REQUIRE_NOT=deadEntity, before=human_inventory_revive_object_es)]
def medic_heal_teammate_es(evt : CmdUse;
                           eid : EntityId;
                           isDowned : bool;
                           medic__healState : int)
  if isDowned || medic__healState == int(MedicHealState MHS_NONE)
    return
  query(evt.requesterEid) <| $ [es] (itemContainer : EidList)
    for item in itemContainer
      if has(item, "item__targetUseOnly")
        sendEvent(evt.requesterEid, [[EventUseItem item=item, target=eid]])
        return

[es(tag=gameClient, REQUIRE=hero, REQUIRE_NOT=deadEntity, before=hero_human_final_use_object_sync, after=(hero_human_use_downed_human_object_es, human_weap_update_es, human_use_action_es))]
def hero_medic_select_damaged_human_es(info : ParallelUpdateFrameDelayed;
                                       eid : EntityId;
                                       team aka hero_team : int;
                                       human__aimTm : float3x4;
                                       total_kits__targetOnlyHeal : int;
                                       human_reviver__maxDistance : float2;
                                       human_reviver__maxAngle : float;
                                       human_inventory__targetToUse : EntityId;
                                       human_inventory__entityUseEnd : float;
                                       isDowned : bool;
                                       var useActionAvailable : int&;
                                       var human_use_object__selectedObject : EntityId&;
                                       var medic__canHealSelectedSoldier : bool&)
  if total_kits__targetOnlyHeal == 0 || !!human_use_object__selectedObject || isDowned
    medic__canHealSelectedSoldier = false
    return

  var box = BBox3()
  box |> bbox3_add(human__aimTm[3])
  box |> bbox3_inflate(human_reviver__maxDistance.y)

  let wasHealing = medic__canHealSelectedSoldier && human_inventory__entityUseEnd > 0.0
  let minAngleCos = cos(deg_to_rad(human_reviver__maxAngle))
  find_entity_in_grid(ecs_hash("humans"), box, GridEntCheck BOUNDING) <| $(targetEid : EntityId; targetPos : float3)
    if targetEid == eid
      return false

    let distToSoldierSq = length_sq(targetPos - human__aimTm[3])
    let angleToEntityCos = dot(normalize((targetPos - human__aimTm[3]).xz), normalize(human__aimTm[0].xz))
    if angleToEntityCos < minAngleCos || (distToSoldierSq > square(human_reviver__maxDistance.x) && !wasHealing)
      return false

    query(targetEid) <| $ [es(REQUIRE_NOT=(hero, deadEntity), REQUIRE=human)] (team : int; medic__healState : int; isDowned : bool)
      if team == hero_team && medic__healState != int(MedicHealState MHS_NONE) && !isDowned
        human_use_object__selectedObject = targetEid
    return !!human_use_object__selectedObject

  let isHealedSoldierOutOfRange = wasHealing && human_use_object__selectedObject == INVALID_ENTITY_ID
  let isSelfHealing = human_inventory__targetToUse == eid
  if isHealedSoldierOutOfRange && !isSelfHealing
    sendEvent(eid, [[CmdMedkitUseCancel]])

  medic__canHealSelectedSoldier = !!human_use_object__selectedObject
  if medic__canHealSelectedSoldier
    useActionAvailable = int(HumanAction ACTION_NONE)



