options no_aot
require ecs
require ecs.common
require math.base
require DagorConsole
require DagorSystem

def take_off_hat(head_id : EntityId)
  var attachableHatEid = INVALID_ENTITY_ID
  query(head_id) <| $ [es] (var attaches_list : EidList&)
    for attach_eid in attaches_list
      query(attach_eid) <| $ [es] (slot_attach__slotName : das_string&)
        if slot_attach__slotName == "hat"
          destroyEntity(attach_eid)
          attachableHatEid = attach_eid
          return ;
    if (attachableHatEid != INVALID_ENTITY_ID)
      let idxInAttaches = find_index(attaches_list, attachableHatEid)
      if idxInAttaches != -1
        erase(attaches_list, idxInAttaches)

def take_on_hat(head_id : EntityId; template_name : string)
  if (head_id != INVALID_ENTITY_ID)
    var hatsCount = 0
    query(head_id) <| $ [es] (var attaches_list : EidList&)
      for attach_eid in attaches_list
        query(attach_eid) <| $ [es] (slot_attach__slotName : das_string&)
          if slot_attach__slotName == "hat"
            hatsCount++;
    if (hatsCount > 1)
      logerr("head eid {head_id} has several hats")
      return ;
    take_off_hat(head_id)
    query(head_id) <| $ [es] (var attaches_list : EidList&)
      let attachedHat = createEntity(template_name) <| $(init)
        init |> set("slot_attach__slotName", "hat")
        init |> set("slot_attach__attachedTo", head_id)
        init |> set("skeleton_attach__attachedTo", head_id)
        init |> set("skeleton_attach__attached", true)
      attaches_list |> push(attachedHat)

[console_cmd(name="create_head_prototypes", hint="heads to test attachable hats")]
def create_hat()
  var tm = IDENT_TM
  tm[3] = float3(0, 0, 0)
  createEntity("dbg_head_1") <| $(init)
    init |> set("transform", tm)
  tm[3] = float3(1, 0, 0)
  createEntity("dbg_head_2") <| $(init)
    init |> set("transform", tm)
  tm[3] = float3(0.5, 0.0, 0.0)
  createEntity("dbg_head_3") <| $(init)
    init |> set("transform", tm)

[console_cmd(name="take_on_hats", hint="take on hat")]
def wear_hat_cmd(template_name : string)
  query() <| $ [es(REQUIRE=(dbgHead, animchar__res)) ] (eid : EntityId)
    take_on_hat(eid, template_name)

[console_cmd(name="take_off_hats", hint="take off hat")]
def take_off_hat_cmd()
  query() <| $ [es(REQUIRE=(dbgHead, animchar__res)) ] (eid : EntityId)
    take_off_hat(eid)