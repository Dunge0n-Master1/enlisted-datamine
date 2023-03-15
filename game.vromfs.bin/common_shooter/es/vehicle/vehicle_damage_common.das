module vehicle_damage_common shared

require ecs
require app
require dm
require DmFire
require EnlistedDm
require DagorMath
require game.es.vehicle.vehicle_events

def vehicle_start_burn_part(vehicle_eid : EntityId;
                            part_id : int;
                            offender : EntityId;
                            gun_props_id : int;
                            shell_id : int;
                            damage_model : DamageModel;
                            fire_damage__fireParamsPreset : string;
                            var fire_damage__isBurn : bool&;
                            var fire_damage__gunPropsId : int&;
                            var fire_damage__shellId : int&;
                            var fire_damage : FireDamageComponent&)
  let collNodeId = damage_model.dmData |> get_collision_node_id(part_id)
  using() <| $(var desc : StartBurnDesc#)
    desc.offender = fire_damage__isBurn && !!fire_damage.offender ? fire_damage.offender : offender
    desc.fireParamsId = get_fire_params_id(fire_damage__fireParamsPreset)
    if desc.fireParamsId < 0
      desc.fireParamsId = 0

    startburndesc_setNodeId(desc, collisiondata_getGeomNodeIdByCollNode(damage_model.collisionData, collNodeId))
    desc.atTime = double(get_sync_time())
    desc.partId = part_id

    let center = float3(0.f, 0.f, 0.f)
    dm_calcRadius(desc, BSphere3(center, 0.5f), 0.5f)
    fire_component_startBurn(fire_damage, vehicle_eid, desc)

  if !fire_damage__isBurn
    fire_damage__isBurn = true
    fire_damage__gunPropsId = gun_props_id
    fire_damage__shellId = shell_id
  sendEvent(vehicle_eid, [[EventOnPartDamageEffects offender=offender, partId=part_id, effects=1 << int(DamageEffectType DM_EFFECT_FIRE),
                                                    gunPropsId=gun_props_id, shellId=shell_id]])
