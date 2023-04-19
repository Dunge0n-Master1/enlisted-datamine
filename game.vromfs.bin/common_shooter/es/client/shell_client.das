require app
require ecs
require ecs.safe
require ecs.common
require math.base
require DngNet
require DagorMath
require common_shooter.events_common_shooter
require common_shooter.es.weapon.shell_fx_common
require DngWeapon
require DngWeaponRender
require Dacoll
require enlisted.events_enlisted
require DngPhysObj
require strings

def private spawn_effect_aux(pos : float3;
                             fx_name : string)
  if empty(fx_name)
    return false

  var tm = IDENT_TM
  tm[3] = pos

  let eid = createEntity(fx_name) <| $(var init)
    init |> set("transform", tm)

  return eid != INVALID_ENTITY_ID

def private spawn_effect(fx_info_eid : EntityId; pos : float3)
  var isUnderWater = false
  let posAdjusted = get_adjusted_pos_for_effect(pos, isUnderWater)

  let fxName = get_fx_name_based_on_floor(posAdjusted, fx_info_eid, isUnderWater)
  return spawn_effect_aux(posAdjusted, fxName)

[es(tag=gameClient, REQUIRE=msg_sink)]
def shell_explode_es(shellExpl : CmdShellExplodeClient)
  detonate_shell_client(shellExpl.shellId, shellExpl.pos, shellExpl.offsetedPos,
                        shellExpl.explVictim, shellExpl.explDamageAndFatal, shellExpl.shellEid)

  if shellExpl.fxInfoEid != INVALID_ENTITY_ID
    spawn_effect(shellExpl.fxInfoEid, shellExpl.pos)

  find_query() <| $ [es(REQUIRE=msg_sink)] (eid : EntityId)
    sendEventImmediate(
      eid,
      [[EventOnShellExploded
        explPos=shellExpl.pos,
        shellId=shellExpl.shellId.shellId,
        damageId=shellExpl.shellId.damageId,
        ballisticsId=shellExpl.shellId.ballisticsId,
        gunPropsId=shellExpl.gunPropsId,
        owner=shellExpl.offender]])
    return true

[es(tag=render, track=shell__isUnderwater)]
def shell_water_splash_es(evt : Event;
                          phys_obj_net_phys : PhysObjActor;
                          shell__isUnderwater : bool;
                          shell__waterImpactFx : string;
                          shell__waterImpactFxSpeedSqLimit = 0.01)
  if shell__isUnderwater
    let vel = phys_obj_net_phys.phys.currentState.velocity
    if length_sq(vel) > shell__waterImpactFxSpeedSqLimit //to avoid multiple triggers on shallow water
                                                         //or if the water surface is dynamic
      spawn_effect_aux(float3(phys_obj_net_phys.phys.currentState.location.P), shell__waterImpactFx)