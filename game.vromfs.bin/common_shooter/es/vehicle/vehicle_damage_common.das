module vehicle_damage_common shared

require ecs
require app
require dm
require EnlistedDm
require DagorMath
require game.es.vehicle.vehicle_events

def vehicle_start_burn_part(vehicle_eid : EntityId;
                            part_id : int;
                            offender : EntityId;
                            damage_model : DamageModel;
                            fire_damage__fireParamsPreset : string;
                            var fire_damage__isBurn : bool&;
                            var fire_damage : FireDamageComponent&)
  let collNodeId = damage_model.dmData |> get_collision_node_id(part_id)
  using <| $(var desc : StartBurnDesc#)
    desc.offender = offender
    desc.fireParamsId = get_fire_params_id(fire_damage__fireParamsPreset)
    if desc.fireParamsId < 0
      desc.fireParamsId = 0

    desc.nodeId = int(damage_model.collisionData.collNodeIdToGeomNodeId[collNodeId])
    desc.atTime = double(get_sync_time())
    desc.partId = part_id

    let center = float3(0.f, 0.f, 0.f)
    dm_calcRadius(desc, BSphere3(center, 0.5f), 0.5f)
    fire_component_startBurn(fire_damage, vehicle_eid, desc)

  fire_damage__isBurn = true
  sendEvent(vehicle_eid, [[EventOnPartDamageEffects offender=offender, partId=part_id, effects=1 << int(DamageEffectType DM_EFFECT_FIRE)]])
