require ecs
require AnimV20
require DagorSystem
require GeomNodeTree
require strings
require Gun

def turret_ammo_init_impl(turret__owner : EntityId;
                          gun__shootNodeEmitterGenFmt : string;
                          gun__maxAmmo : int;
                          var gun__shootNodeIds : IntList;
                          var gun__shellsAmmoEids : EidList)
  if gun__maxAmmo > 0
    query(turret__owner) <| $ [es] (animchar : AnimcharBaseComponent)
      resize(gun__shellsAmmoEids, gun__maxAmmo)
      resize(gun__shootNodeIds, gun__maxAmmo)
      for i in range(gun__maxAmmo)
        let nodeName = format(gun__shootNodeEmitterGenFmt, i + 1)
        let nodeId = geomtree_findNodeIndex(*animchar.nodeTree, nodeName)
        if nodeId < 0
          logerr("Turret shoot node '{nodeName}' not found. Vehicle {turret__owner} <{getEntityTemplateName(turret__owner)}>")
        gun__shootNodeIds[i] = nodeId


[es(on_appear, tag=server, REQUIRE_NOT=deadEntity, on_event=CmdResolveTurrets, before=turret_gun_es, after=turret_control_init_es, REQUIRE_NOT=resolvedTurret)]
def turret_ammo_init_es(evt : Event;
                        turret__owner : EntityId;
                        gun__shootNodeEmitterGenFmt : string;
                        gun__maxAmmo : int;
                        var gun__shootNodeIds : IntList;
                        var gun__shellsAmmoEids : EidList)
  turret_ammo_init_impl(turret__owner, gun__shootNodeEmitterGenFmt, gun__maxAmmo, gun__shootNodeIds, gun__shellsAmmoEids)

[es(on_appear, tag=server, REQUIRE_NOT=deadEntity)]
def turret_ammo_create_on_tank_init(evt : Event;
                                    turret_control__gunEids : EidList)
  for gunEid in turret_control__gunEids
    query(gunEid) <| $ [es] (turret__owner : EntityId;
                             gun__shootNodeEmitterGenFmt : string;
                             gun__maxAmmo : int;
                             var gun__shootNodeIds : IntList;
                             var gun__shellsAmmoEids : EidList)
      turret_ammo_init_impl(turret__owner, gun__shootNodeEmitterGenFmt, gun__maxAmmo, gun__shootNodeIds, gun__shellsAmmoEids)

[es(on_disappear, tag=server)]
def destroy_visible_ammo_for_turret(evt : Event;
                                    gun__shellsAmmoEids : EidList)
  for shellItemEid in gun__shellsAmmoEids
    destroyEntity(shellItemEid)

[es(on_appear, tag=server, REQUIRE=deadEntity)]
def turret_ammo_destroy_on_death(evt : Event;
                                 turret_control__gunEids : EidList)
  for gunEid in turret_control__gunEids
    query(gunEid) <| $ [es] (var gun__shellsAmmoEids : EidList)
      for shellItemEid in gun__shellsAmmoEids
        destroyEntity(shellItemEid)
        shellItemEid = INVALID_ENTITY_ID

[es(on_appear, tag=server, REQUIRE_NOT=deadEntity, on_event=CmdResolveTurrets, track=gun__ammo, after=turret_ammo_init_es, before=turret_gun_es)]
def turret_ammo_ammo_change_es(evt : Event;
                               turret__owner : EntityId;
                               gun__shootNodeEmitterGenFmt : string;
                               gun__shootNodeItemTemplate : string;
                               gun__ammo : int;
                               gun__maxAmmo : int;
                               var gun__shootNodeName : das_string;
                               var gun__shellsAmmoEids : EidList)
  let curShellAmmoId = gun__maxAmmo - gun__ammo
  for i, shellItemEid in range(0, gun__maxAmmo), gun__shellsAmmoEids
    if i < curShellAmmoId
      if !!shellItemEid
        destroyEntity(shellItemEid)
        shellItemEid = INVALID_ENTITY_ID
    else //resupply or server didn't approve the shot
      if !shellItemEid
        let nodeName = format(gun__shootNodeEmitterGenFmt, i + 1)
        if i == curShellAmmoId
          gun__shootNodeName := nodeName
        shellItemEid = createEntity(gun__shootNodeItemTemplate) <| $(init)
          init |> set("slot_attach__slotName", nodeName)
          init |> set("slot_attach__attachedTo", turret__owner)


[es(on_appear, REQUIRE_NOT=deadEntity, on_event=CmdResolveTurrets, track=(gun__ammo, gun__shootNodeIds), after=turret_ammo_ammo_change_es, before=turret_gun_es)]
def turret_ammo_emmiter_change_es(evt : Event;
                                  turret__owner : EntityId;
                                  gun__ammo : int;
                                  gun__maxAmmo : int;
                                  gun__shootNodeIds : IntList;
                                  var gun : Gun;
                                  var turret__emitterNodeId : int&)
  let curShellAmmoId = gun__maxAmmo - gun__ammo
  if gun__maxAmmo > 0 && curShellAmmoId < gun__maxAmmo && length(gun__shootNodeIds) > 0
    turret__emitterNodeId = gun__shootNodeIds[curShellAmmoId]
    query(turret__owner) <| $ [es] (animchar : AnimcharBaseComponent)
      let geomNodeTree = animchar.nodeTree
      if geomNodeTree != null
        gun |> gun_loadShootNode(turret__emitterNodeId, *geomNodeTree)