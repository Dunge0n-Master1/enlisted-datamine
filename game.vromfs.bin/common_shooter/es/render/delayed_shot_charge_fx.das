require ecs
require AnimV20
require GeomNodeTree
require DagorSystem
require common_shooter.events_common_shooter

[es(tag=render, on_appear)]
def delayed_shot_charge_fx_init(evt : Event;
                                eid : EntityId;
                                animchar : AnimcharBaseComponent;
                                gun_charge_fx__node : string;
                                var gun_charge_fx__nodeId : int&)
  gun_charge_fx__nodeId = geomtree_findNodeIndex(*animchar.nodeTree, gun_charge_fx__node)
  if gun_charge_fx__nodeId < 0
    logerr("[{eid}] {getEntityTemplateName(eid)}: gun_charge_fx__node {gun_charge_fx__node} not found")

def create_charge_fx(fx_template : string; gun_eid : EntityId; animchar : AnimcharBaseComponent; node_id : int; scale : float)
  if node_id < 0
    return INVALID_ENTITY_ID
  var tm : float3x4
  geomtree_getNodeWtmScalar(*animchar.nodeTree, node_id, tm)
  for i in 0..3
    tm[i] *= scale
  return createEntity(fx_template) <| $(var init : ComponentsInitializer)
    init |> set("transform", tm)
    init |> set("gun_fx__gunEid", gun_eid)
    init |> set("gun_fx__nodeId", node_id)

[es(tag=render, track=gun_charge_fx__active)]
def delayed_shot_charge_fx_shadow_client(evt : Event;
                                         eid : EntityId;
                                         animchar : AnimcharBaseComponent;
                                         gun__owner : EntityId;
                                         gun_charge_fx__active : bool;
                                         gun_charge_fx__template : string;
                                         gun_charge_fx__scale : float;
                                         gun_charge_fx__nodeId : int;
                                         var gun_charge_fx__eid : EntityId&)
  if has(gun__owner, "hero")
    return
  if !!gun_charge_fx__eid && !gun_charge_fx__active
    destroyEntity(gun_charge_fx__eid)
    gun_charge_fx__eid = INVALID_ENTITY_ID
  elif !gun_charge_fx__eid && gun_charge_fx__active
    gun_charge_fx__eid = create_charge_fx(gun_charge_fx__template, eid, animchar, gun_charge_fx__nodeId, gun_charge_fx__scale)

[es(tag=render)]
def human_gun_delayed_charge_fx(evt : CmdWeapPhysUpdate;
                                eid : EntityId;
                                animchar : AnimcharBaseComponent;
                                gun__ammo : int;
                                gun_charge_fx__template : string;
                                gun_charge_fx__scale : float;
                                gun_charge_fx__nodeId : int;
                                var gun_charge_fx__eid : EntityId&)
  let active = evt.gctrl.shoot && gun__ammo > 0
  if !!gun_charge_fx__eid && !active
    destroyEntity(gun_charge_fx__eid)
    gun_charge_fx__eid = INVALID_ENTITY_ID
  if !gun_charge_fx__eid && active
    gun_charge_fx__eid = create_charge_fx(gun_charge_fx__template, eid, animchar, gun_charge_fx__nodeId, gun_charge_fx__scale)

[es(tag=render, on_disappear)]
def delayed_shot_charge_fx_destroy(evt : Event; gun_charge_fx__eid : EntityId)
  destroyEntity(gun_charge_fx__eid)