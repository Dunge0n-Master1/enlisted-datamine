require ecs
require PhysMat
require DaWeapons
require ecs.common
require debug.logerr_once
require BallisticsProps
require EnlistedWeaponRender
require common_shooter.events_common_shooter
require weapon_sounds.modules.weapon_sounds_events

def private spawn_effect(gun_eid : EntityId; launch_desc : LaunchDesc; norm : float3; pos : float3; mat_id : int; rendinstIdx : int)
  var success = false
  query(gun_eid) <| $ [es] (gun__shell_prop_ids : GunShellPropIds; [[shared_comp]] gun_hit_fx__info : Array; gun_hit_fx__default : string)
    var tm : float3x4
    identity(tm)
    tm[1] = normalize(norm)
    tm[2] = normalize(cross(float3(1, 0, 0), tm[1]))
    tm[0] = normalize(cross(tm[1], tm[2]))
    tm[3] = pos

    var shellIndex = -1
    for i in iter_range(gun__shell_prop_ids)
      if launch_desc.shellId.shellId == gun__shell_prop_ids[i].shellId
        shellIndex = i
        break

    if uint(shellIndex) >= uint(length(gun_hit_fx__info))
      logerr_once("Can't find correct shell for gun {getEntityTemplateName(gun_eid)}")
      return

    let matName = get_material_name(get_material(mat_id))
    var fxName = gun_hit_fx__default
    var obj = get_ecs_object(gun_hit_fx__info[shellIndex])
    if obj != null
      success = true
      obj = get_ecs_object(*obj, matName)
      if obj != null
        fxName = get_string(*obj, "fx", fxName)

      if (rendinstIdx == 0)//landmesh has rendinstIdx=0
        createEntity("hit_fx_readback_info") <| $(init)
          init |> set("transform", tm)
          init |> set("hit_fx_name", fxName)
      else
        createEntity(fxName) <| $(init)
          init |> set("transform", tm)
  return success

[unused_argument(gunEid, scene_hit_place__rendinstIdx), es(tag=gameClient, REQUIRE=launch_desc)]
def projectile_hit_scene_es(evt : EventProjectileHitScene; launch_desc : LaunchDesc)
  if int(launch_desc.shellId.shellId) < 0
    return
  if !evt.sceneIntersectionsExceeded || (evt.shouldStop && evt.allowDetonation)
    //if !spawn_effect(gunEid, launch_desc, evt.norm, evt.pos, evt.matId, evt.rendinstIdx)
    let vel = float3()
    on_shell_hit_scene_fx(int(launch_desc.shellId.shellId), evt.matId, evt.pos, vel, evt.norm)

[unused_argument(gunEid, scene_hit_place__rendinstIdx), es(tag=render)]
def fx_on_shell_explosion_es(evt : CmdShellExplosionFx;
                             eid : EntityId;
                             gunEid : EntityId;
                             scene_hit_place__matId : int;
                             scene_hit_place__pos : float3;
                             scene_hit_place__norm : float3;
                             scene_hit_place__rendinstIdx : int;
                             projectile_ballistics_props : ProjectileProps;
                             launch_desc : LaunchDesc)
  if int(launch_desc.shellId.shellId) < 0
    return
  //if !spawn_effect(gunEid, launch_desc, scene_hit_place__norm, scene_hit_place__pos, scene_hit_place__matId, scene_hit_place__rendinstIdx)
  let vel = float3()
  on_shell_hit_scene_fx(int(launch_desc.shellId.shellId), scene_hit_place__matId, scene_hit_place__pos, vel, scene_hit_place__norm)

  sendEventImmediate(eid, [[CmdPlayProjectileHitSceneSound
    pos=scene_hit_place__pos,
    pmid=scene_hit_place__matId,
    caliber=projectile_ballistics_props.caliber,
    ricochet=0.,
    exploded=true
  ]])
