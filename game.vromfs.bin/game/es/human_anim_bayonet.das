require ecs
require PhysVars

[es(on_appear, tag=render, before=anim_phys_init_es)]
def human_anim_bayonet_init(evt : Event; var human_anim__isBayonetAttachedVarId : int&; var phys_vars : PhysVars)
  human_anim__isBayonetAttachedVarId = registerVar(phys_vars, "is_bayonet_attached", 0.0)

[es(on_appear, track=human_weap__currentGunEid, tag=render, before=human_anim_es, after=human_anim_bayonet_init)]
def human_anim_bayonet(evt : Event;
                       human_anim__isBayonetAttachedVarId : int; var phys_vars : PhysVars;
                       human_weap__currentGunEid : EntityId;
                       human_weap__currentGunModEids : EidList)
  var hasBayonet = false
  query(human_weap__currentGunEid) <| $ [es] (gun__integratedBayonet : bool)
    hasBayonet = gun__integratedBayonet
  if !hasBayonet
    for gunMod in human_weap__currentGunModEids
      if has(gunMod, "gunAttachable__isBayonet")
        hasBayonet = true
  setVar(phys_vars, human_anim__isBayonetAttachedVarId, hasBayonet ? 1.0 : 0.0)

[es(on_appear, tag=render, track=gun__owner, after=human_anim_bayonet_init)]
def human_anim_bayonet_gun_owner_changed(evt : Event;
                                         eid : EntityId;
                                         gun__owner : EntityId;
                                         gun__integratedBayonet = false)
  query(gun__owner) <| $ [es] (var phys_vars : PhysVars;
                               human_weap__currentGunEid : EntityId;
                               human_weap__currentGunModEids : EidList;
                               human_anim__isBayonetAttachedVarId : int)
    if human_weap__currentGunEid == eid && human_anim__isBayonetAttachedVarId != -1
      var hasBayonet = gun__integratedBayonet
      if !hasBayonet
        for gunMod in human_weap__currentGunModEids
          if has(gunMod, "gunAttachable__isBayonet")
            hasBayonet = true
      setVar(phys_vars, human_anim__isBayonetAttachedVarId, hasBayonet ? 1.0f : 0.0f)

[es(on_appear, tag=render, track=slot_attach__attachedTo, REQUIRE=gunAttachable__isBayonet, after=human_anim_bayonet_init)]
def human_anim_bayonet_attached(evt : Event;
                                slot_attach__attachedTo : EntityId)
  query(slot_attach__attachedTo) <| $ [es] (gun__owner : EntityId)
    query(gun__owner) <| $ [es] (human_weap__currentGunEid : EntityId;
                                 human_anim__isBayonetAttachedVarId : int;
                                 var phys_vars : PhysVars)
      if human_weap__currentGunEid == slot_attach__attachedTo && human_anim__isBayonetAttachedVarId != -1
        setVar(phys_vars, human_anim__isBayonetAttachedVarId, 1.0f)
