require ecs
require app
require enlisted.events_enlisted
require Grid
require EnlistedWounds
require PhysDecl
require AnimV20
require ecs.common
require math.base
require enlisted.events_enlisted
require DagorMath
require GridCollision
require CollisionTraces
require danetlibs.native_dasevents.main.native_events
require common_shooter.events_common_shooter
require EnlistedDm

def apply_melee_wounds(owner : EntityId; attach_eid : EntityId; break_param : int)
  query(attach_eid) <| $ [es] (var broken_bones_nodes : BrokenBonesNodes)
    assume breakInst = broken_bones_nodes.breaks[break_param]
    breakInst.accumulatedDamage = breakInst.damageThreshold
  sendEvent(owner, [[EventOnApplyTornWound animchar_eid=attach_eid, bone_break_params_id=uint(break_param)]])

[es(REQUIRE=(melee_weapon, melee_wounds__length, attachedToParent, watchedPlayerItem))]
def hero_melee_wounds_apply_es(evt : EventOnEntityHit;
                               gun__owner : EntityId;
                               var melee_wounds__boneBreakParam : int&;
                               var melee_wounds__boneBreakEid : EntityId&;
                               var melee_wounds__boneBreakOwner : EntityId&;
                               var melee_wounds__boneBreakLatencyTarget : EntityId&)
  let hitRes = evt.hitResult
  let validDamage = (evt.damageType == int(DamageType DM_MELEE) ||
                     hitRes == int(HitResult HIT_RES_KILLED) ||
                     hitRes == int(HitResult HIT_RES_DOWNED))

  if validDamage && gun__owner == evt.offender
    if melee_wounds__boneBreakOwner == evt.victim
      apply_melee_wounds(melee_wounds__boneBreakOwner, melee_wounds__boneBreakEid, melee_wounds__boneBreakParam)
      query(melee_wounds__boneBreakOwner) <| $ [es(REQUIRE=deadEntity)] (var animchar__updatable : bool&;
                                                                         var ragdoll : PhysRagdoll)
        animchar__updatable = true
        ragdoll |> ragdoll_wakeUp()

    else
      melee_wounds__boneBreakLatencyTarget = evt.victim

    melee_wounds__boneBreakParam = -1
    melee_wounds__boneBreakOwner = INVALID_ENTITY_ID
    melee_wounds__boneBreakEid = INVALID_ENTITY_ID

[es(after=slot_attach_init_tms_es, REQUIRE=(melee_weapon, attachedToParent, watchedPlayerItem))]
def hero_melee_wounds_es(evt : ParallelUpdateFrameDelayed;
                         animchar : AnimcharBaseComponent;
                         gun__owner : EntityId;
                         var melee_wounds__boneBreakParam : int&;
                         var melee_wounds__boneBreakEid : EntityId&;
                         var melee_wounds__boneBreakOwner : EntityId&;
                         var melee_wounds__boneBreakLatencyTarget : EntityId&;
                         melee_wounds__length : float;
                         melee_wounds__offset = 0.f)
  query(gun__owner) <| $ [es] (action__running : bool)
    if !action__running
      return

    var rootTm = IDENT_TM
    animchar |> animchar_get_tm(rootTm)

    let startPos = rootTm[3] + melee_wounds__offset * rootTm[0]
    using() <| $(var intersections : IntersectedEntities#)
      var t1 = melee_wounds__length;
      trace_entities_in_grid(ecs_hash("humans"), startPos, rootTm[1], t1, melee_wounds__boneBreakOwner, intersections, SortIntersections YES)
      if length(intersections) > 0
        var intersectionsFound = false
        for isect in intersections
          if intersectionsFound
            break

          let nodeId = isect.collNodeId
          query(isect.eid) <| $ [es] (attaches_list : EidList)
            for attach_eid in attaches_list
              if intersectionsFound
                break
              query(attach_eid) <| $ [es] (var broken_bones_nodes : BrokenBonesNodes)
                for i, breakInst in iter_range(broken_bones_nodes.breaks), broken_bones_nodes.breaks
                  if find_index(breakInst.targetNodeIndexes, nodeId) != -1
                    if melee_wounds__boneBreakLatencyTarget == isect.eid
                      breakInst.accumulatedDamage = breakInst.damageThreshold
                      sendEvent(isect.eid, [[EventOnApplyTornWound animchar_eid=attach_eid, bone_break_params_id=uint(i)]])
                      melee_wounds__boneBreakLatencyTarget = INVALID_ENTITY_ID
                    else
                      melee_wounds__boneBreakOwner = isect.eid
                      melee_wounds__boneBreakParam = i
                      melee_wounds__boneBreakEid = attach_eid
                    intersectionsFound = true
                    break