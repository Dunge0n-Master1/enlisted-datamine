require ecs
require strings
require EnlistedPhysObj
require game.es.events
require game.events_game
require DagorMath
require AnimV20
require GeomNodeTree
require GamePhys

[es(tag=server, on_appear)]
def train_attachment_init(evt : Event;
                          eid : EntityId;
                          train__attachments : Array;
                          transform : float3x4)
  for attachment in train__attachments
    let attachmentObj = get_ecs_object(attachment)
    if attachmentObj == null
      continue
    let attachmentTemplate = attachmentObj |> get_string("template", "")
    if empty(attachmentTemplate)
      continue
    let finalTemplate = "{attachmentTemplate}+train_attachment"
    createEntity(finalTemplate) <| $(var init)
      init |> set("transform", transform)
      init |> set("train_attachment__parentEid", eid)
      let componetsObj = attachmentObj |> get_ecs_object("components")
      if componetsObj != null
        for kv in *componetsObj
          init |> set(kv.key, kv.value)

[es(on_appear, before=train_attachment_update_pos)]
def train_attachment_attach_to_parent(evt : Event;
                                      train_attachment__parentEid : EntityId;
                                      train_attachment__node : string;
                                      train_attachment__attachTm : float3x4;
                                      var train_attachment__localTm : float3x4)
  query(train_attachment__parentEid) <| $ [es] (animchar : AnimcharBaseComponent; transform : float3x4)
    let nodeId = geomtree_findNodeIndex(*animchar.nodeTree, train_attachment__node)
    if nodeId >= 0
      let nodeWpos = *animchar.nodeTree |> geomtree_getNodeWpos(nodeId)
      let invTransform = inverse(transform)
      train_attachment__localTm = train_attachment__attachTm
      train_attachment__localTm[3] += invTransform * nodeWpos


[es(tag=server, on_appear, REQUIRE=train_attachment__parentEid)]
def train_attachment_init_skip_update(evt : Event; var phys_obj_net_phys : PhysObjActor&)
  phys_obj_net_phys.phys.skipUpdateOnSleep = true

[es(tag=server)]
def train_attachment_update_pos_server(evt : CmdPostPhysUpdate;
                                       train_attachment__parentEid : EntityId;
                                       train_attachment__localTm : float3x4;
                                       var phys_obj_net_phys aka attach_phys_obj_net_phys : PhysObjActor&)
  query(train_attachment__parentEid) <| $ [es] (transform : float3x4; phys_obj_net_phys aka parent_phys_obj_net_phys : PhysObjActor)
    assume attachState = attach_phys_obj_net_phys.phys.currentState
    let updatedTm = transform * train_attachment__localTm
    attachState.isSleep = true
    attachState.velocity = parent_phys_obj_net_phys.phys.currentState.velocity
    attachState.location.P = DPoint3(updatedTm[3])
    attachState.location.O |> orient_setYP0(updatedTm[0])

[es(tag=netClient, after=(phys_obj_phys_es, move_secondary_cart_client_es))]
def train_attachment_update_pos(info : UpdateStageInfoAct;
                                train_attachment__parentEid : EntityId;
                                train_attachment__localTm : float3x4;
                                var transform aka attachment_transform : float3x4)
  query(train_attachment__parentEid) <| $ [es] (transform aka train_transform : float3x4)
    attachment_transform[3] = train_transform * train_attachment__localTm[3]

[es(tag=netClient)]
def train_attachment_update_pos_phys(evt : CmdUpdateRemoteShadow;
                                     train_attachment__parentEid : EntityId;
                                     train_attachment__localTm : float3x4;
                                     var phys_obj_net_phys aka attach_phys_obj_net_phys : PhysObjActor&)
  query(train_attachment__parentEid) <| $ [es] (transform : float3x4)
    assume attachState = attach_phys_obj_net_phys.phys.currentState
    let updatedTm = transform * train_attachment__localTm
    attachState.location.P = DPoint3(updatedTm[3])
    attachState.location.O |> orient_setYP0(updatedTm[0])

    attach_phys_obj_net_phys.phys.visualLocation.P = attachState.location.P
    attach_phys_obj_net_phys.phys.visualLocation.O = attachState.location.O
