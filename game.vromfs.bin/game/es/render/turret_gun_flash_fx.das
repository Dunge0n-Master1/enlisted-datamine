require ecs
require ecs.safe
require ecs.common
require ecs.soa_template
require math.base
require strings
require fx
require AnimV20
require GeomNodeTree
require DaWeapons
require DagorSystem
require enlisted.events_enlisted


[soa_template]
struct TurretGunFx
  turret_gun_fx__fxTemplate : string
  turret_gun_fx__nodeId : int


def get_mult_tm(scale : float)
  var multTm = IDENT_TM
  multTm[0] = float3(0.0, scale,  0.0)
  multTm[1] = float3(scale, 0.0,  0.0)
  multTm[2] = float3(0.0, 0.0, -scale)
  return multTm


[soa_es, es(tag=render, before=clear_gun_launch_events_es, after=after_guns_update_sync)]
def turret_gun_flash_fx_inserter_es(info : ParallelUpdateFrameDelayed;
                                    eid : EntityId;
                                    animchar : AnimcharBaseComponent;
                                    turretGunFx : TurretGunFx_SOA;
                                    turret_control__gunEids : EidList;
                                    [[shared_comp]] turret_gun_flash_fx__flashFxScale : Array)
  for gunEid, gunFx, fxScale in turret_control__gunEids, turretGunFx, turret_gun_flash_fx__flashFxScale
    if gunFx.turret_gun_fx__nodeId < 0 || empty(gunFx.turret_gun_fx__fxTemplate)
      continue

    query(gunEid) <| $ [es] (gun_launch_events : GunLaunchEvents)
      for _launchEvent in gun_launch_events.launchEvents
        var tm : float3x4
        geomtree_getNodeWtmScalar(*animchar.nodeTree, gunFx.turret_gun_fx__nodeId, tm)

        tm = tm * get_mult_tm(fxScale ?? 1.0)

        let flashEid = createEntity(add_sub_template_name(string(gunFx.turret_gun_fx__fxTemplate),
            "turret_gun_flash_fx")) <| $(var init : ComponentsInitializer)
          set(init, "transform", tm)
          set(init, "gun_flash_fx__gunEid", eid)
          set(init, "gun_flash_fx__nodeId", gunFx.turret_gun_fx__nodeId)


[soa_es, es(tag=render, on_appear)]
def turret_gun_flash_fx_created_es(evt : Event;
                                   animchar : AnimcharBaseComponent;
                                   [[shared_comp]] turret_gun_flash_fx__flashFx : Array;
                                   [[shared_comp]] turret_gun_flash_fx__flashNodes : Array;
                                   [[shared_comp]] turret_gun_flash_fx__flashFxScale : Array;
                                   var turretGunFx : TurretGunFx_SOA)
  if length(turret_gun_flash_fx__flashNodes) != length(turret_gun_flash_fx__flashFx) || length(turret_gun_flash_fx__flashFx) != length(turret_gun_flash_fx__flashFxScale)
    logerr("Lengths of turret_gun_flash_fx__flashNodes, turret_gun_flash_fx__flashFx and turret_gun_flash_fx__flashFxScale are not match to each other")
    return

  for flashFx, flashNode in turret_gun_flash_fx__flashFx, turret_gun_flash_fx__flashNodes
    let fx = flashFx ?? ""
    let node = flashNode ?? ""
    if empty(fx) || empty(node)
      push(turretGunFx, [[TurretGunFx
        turret_gun_fx__fxTemplate="",
        turret_gun_fx__nodeId=-1
      ]])
      continue

    let fxType = get_type_by_name(fx)
    prefetch_effect(fxType)

    push(turretGunFx, [[TurretGunFx
      turret_gun_fx__fxTemplate=fx,
      turret_gun_fx__nodeId=geomtree_findNodeIndex(*animchar.nodeTree, node)
    ]])
