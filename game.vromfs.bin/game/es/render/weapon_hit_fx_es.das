require ecs
require ecs.safe
require PhysMat
require DaWeapons
require ecs.common
require debug.logerr_once
require Dacoll
require BallisticsProps
require EnlistedWeaponRender
require BloodPuddels
require EnlistedWeapon
require AnimV20
require DagorMath
require CollRes
require math.base
require common_shooter.es.render.blood_common
require common_shooter.es.weapon.weaponry_fx_common
require common_shooter.events_common_shooter
require weapon_sounds.modules.weapon_sounds_events
require enlisted.events_enlisted
require Dacoll
require Ballistics
require strings
require daslib/sort_boost
require EnlistedDm
require common_shooter.dm_events


def spawn_effect_aux(norm : float3; pos : float3; coll_type : int; fx_name : string)
  if empty(fx_name) || fx_name == "-"
    return

  let tm = calc_effect_tm(pos, norm)

  if (coll_type == int(CollType ETF_LMESH))
    createEntity("hit_fx_readback_info") <| $(init)
      init |> set("transform", tm)
      init |> set("hit_fx_name", fx_name)
  else
    createEntity(fx_name) <| $(init)
      init |> set("transform", tm)


def spawn_effect_bomb(launch_desc : LaunchDesc;
                      norm : float3;
                      pos : float3;
                      coll_type : int;
                      mat_id : int;
                      exploded : bool;
                      should_stop : bool;
                      is_under_water : bool;
                      vel : float3)
  var posAdjusted : float3

  if is_under_water
    //Don't spawn effect if the bomb hit the floor under water without exploding
    if !exploded && should_stop
      return true

    //Otherwise, effect should spawn at water level
    var waterLevel = 0.0
    traceht_water(pos, waterLevel)
    posAdjusted = float3(pos.x, waterLevel, pos.z)
  else
    posAdjusted = pos

  let fxInfo = get_bomb_fx_info(launch_desc, exploded, vel)

  if fxInfo == null
    return false

  let fxName = get_bomb_fx_name(*fxInfo, is_under_water, mat_id)

  if fxName == null
    if get_DAGOR_DBGLEVEL() > 0
      logerr_once("Can't find relevant default effect when spawning vfx for a bomb")
    return false

  spawn_effect_aux(norm, posAdjusted, coll_type, string(*fxName))
  return true


def spawn_effect_firearm(effect_group_name : string;
                         norm : float3;
                         pos : float3;
                         mat_id : int;
                         coll_type : int;
                         bullet_type_id : int;
                         should_stop : bool;
                         ricochet : bool)
  let fxName = get_firearm_fx_name(effect_group_name, mat_id, bullet_type_id, should_stop, ricochet)
  let success = fxName != ""
  if success
    spawn_effect_aux(norm, pos, coll_type, fxName)

  return success

def spawn_effect(effect_group_name : string;
                 is_bomb : bool;
                 launch_desc : LaunchDesc;
                 norm : float3;
                 pos : float3;
                 mat_id : int;
                 coll_type : int;
                 bullet_type_id : int;
                 is_under_water : bool;
                 exploded : bool = true;
                 vel : float3 = float3(0.0, 0.0, 0.0);
                 should_stop : bool = true;
                 ricochet : bool = false)
  let matIdAdjusted = mat_id < 0 ? 0 : mat_id

  if is_bomb && bullet_type_id < 0
    return spawn_effect_bomb(launch_desc, norm, pos, coll_type, matIdAdjusted, exploded, should_stop,
                             is_under_water, vel)

  if should_stop && exploded && is_under_water
    return true

  return spawn_effect_firearm(effect_group_name, norm, pos, matIdAdjusted, coll_type, bullet_type_id, should_stop, ricochet)

[es(tag=render)]
def projectile_hit_scene_es(evt : EventProjectileHitScene;
                            launch_desc : LaunchDesc;
                            dm_projectile_state : ProjectileState;
                            projectile__effectGroupName : string;
                            projectile__isUnderwater : bool;
                            projectile__exploded : bool;
                            projectile__isBomb : bool = false)
  if int(launch_desc.shellId.shellId) < 0
    return
  if !evt.sceneIntersectionsExceeded || (evt.shouldStop && evt.allowDetonation)
    let success = spawn_effect(projectile__effectGroupName, projectile__isBomb, launch_desc, evt.norm, evt.pos, evt.matId, evt.collType,
                               dm_projectile_state.projectileTypePropsId, projectile__isUnderwater, projectile__exploded,
                               evt.vel, evt.shouldStop, evt.ricochetAngle != 0.0)
    if !success
      let vel = float3()
      on_shell_hit_scene_fx(int(launch_desc.shellId.shellId), evt.matId, evt.pos, vel, evt.norm)

[es(tag=render)]
def fx_on_shell_explosion_es(evt : CmdShellExplosionFx;
                             eid : EntityId;
                             scene_hit_place__matId : int;
                             scene_hit_place__pos : float3;
                             scene_hit_place__norm : float3;
                             scene_hit_place__collType : int;
                             projectile_ballistics_props : ProjectileProps;
                             launch_desc : LaunchDesc;
                             dm_projectile_state : ProjectileState;
                             projectile__effectGroupName : string;
                             projectile__isUnderwater : bool;
                             projectile__isBomb : bool = false)
  if int(launch_desc.shellId.shellId) < 0
    return
  let success = spawn_effect(projectile__effectGroupName, projectile__isBomb, launch_desc, scene_hit_place__norm, scene_hit_place__pos, scene_hit_place__matId,
                             scene_hit_place__collType, dm_projectile_state.projectileTypePropsId, projectile__isUnderwater)
  if !success
    let vel = float3()
    on_shell_hit_scene_fx(int(launch_desc.shellId.shellId), scene_hit_place__matId, scene_hit_place__pos, vel, scene_hit_place__norm)

  sendEventImmediate(eid, [[CmdPlayProjectileHitSceneSound
    pos=scene_hit_place__pos,
    pmid=scene_hit_place__matId,
    caliber=projectile_ballistics_props.caliber,
    ricochet=0.,
    exploded=true
  ]])

def spawn_human_binded_fx(fx_tm : float3x4; itm : float3x4; effect_template : string; eid : EntityId; node_coll_id : int; color_mult : E3DCOLOR)
  createEntity(effect_template) <| $(var init)
    init |> set("transform", fx_tm)
    init |> set("effect__colorMult", color_mult)
    init |> set("entity_binded_effect__entity", eid)
    init |> set("entity_binded_effect__collNodeId", node_coll_id)
    init |> set("entity_binded_effect__localEmitter", itm * fx_tm)

def gen_fx_tm(pos : float3; dir : float3; scale : float)
  var tm = IDENT_TM
  tm[1] = normalize(dir)
  tm[2] = normalize(cross(float3(1, 0, 0), dir))
  tm[0] = normalize(cross(dir, tm[2]))
  for i in range(3)
    tm[i] = tm[i] * scale

  tm[3] = pos
  return tm

def human_spawn_blood_fx(victim_eid : EntityId; flesh_effect_group_name : string; is_bomb : bool; launch_desc : LaunchDesc;
                         mat_id : int; coll_node_id : int; blood_splash : HitBloodType;
                         pos : float3; dir : float3; scale : float; norm : float3; exploded : bool)
  var success = false
  if !is_blood_enabled()
    return true

  query(victim_eid) <| $ [es] (transform : float3x4; animchar : AnimcharBaseComponent; collres : CollisionResource)
    var nodeTm : float3x4
    collres_get_collision_node_tm(collres, coll_node_id, transform, animchar.nodeTree, nodeTm)

    var obj : Object const?

    if is_bomb
      obj = get_bomb_fx_info(launch_desc, exploded, /*vel*/ float3())?.info ?as Object
      if obj == null
        return
      obj = get_fx_for_mat(*obj, mat_id)
    else
      find_query() <| $ [es] (global_hit_fx__fleshEffectGroups : Object)
        obj = global_hit_fx__fleshEffectGroups[flesh_effect_group_name] ?as Object
        return true

    if obj == null
      return

    let fxSection = (blood_splash == HitBloodType TWO_SIDE ? "kill" : "wound")
    let fxName = get_string(obj, "{fxSection}Fx", "")
    if fxName == ""
      logerr("human_spawn_blood_fx: Couldn't get effect {fxSection} via provided flesh_effect_group_name: {flesh_effect_group_name}")
      return

    success = true
    let sideFx = get_string(obj, "{fxSection}SideFx", "")
    let exitFx = get_string(obj, "{fxSection}ExitFx", "")
    let bloodColor = get_blood_color()
    let itm = inverse(nodeTm)
    spawn_human_binded_fx(gen_fx_tm(pos, -dir, scale), itm, fxName, victim_eid, coll_node_id, bloodColor);
    let reflectedDir = dir - 2. * dot(norm, dir) * norm
    if sideFx != "" && length_sq(reflectedDir) > 1e-5f
      spawn_human_binded_fx(gen_fx_tm(pos, ((normalize(reflectedDir) + norm) * 0.5f), scale), itm, sideFx, victim_eid, coll_node_id, bloodColor)

    if blood_splash != HitBloodType TWO_SIDE || exitFx == ""
      return
    let t = 2.
    let tracePos = pos + 2. * dir
    let invDir = -dir
    collres_traceray(collres, transform, animchar.nodeTree, tracePos, invDir, t, true) <| $ [unused_argument(_)] (find : bool; isects : CollResIntersectionsType#)
      if find
        let exitNodeId = int(isects[length(isects) - 1].collisionNodeId)
        spawn_human_binded_fx(gen_fx_tm(pos + (2.0f - t) * dir, dir, scale), itm, exitFx, victim_eid, exitNodeId, bloodColor);

  return success

[es(tag=render)]
def on_shell_hit_entity_fx_es(evt : OnShellHitEntityFx;
                              launch_desc : LaunchDesc;
                              dm_projectile_state : ProjectileState;
                              projectile__fleshEffectGroupName : string;
                              projectile__effectGroupName : string;
                              projectile__isUnderwater : bool;
                              projectile__exploded : bool;
                              projectile__isBomb : bool = false)
  if evt.bloodSplash != HitBloodType NONE
    human_spawn_blood_fx(evt.victimEid, projectile__fleshEffectGroupName, projectile__isBomb, launch_desc, evt.pmid,
                         evt.nodeCollId, evt.bloodSplash, evt.pos, evt.dir, /*scale*/ 1., evt.norm, projectile__exploded)

  if evt.directHit
    let success = spawn_effect(projectile__effectGroupName, projectile__isBomb, launch_desc, evt.norm, evt.pos, evt.pmid,
                               int(CollType ETF_RI), dm_projectile_state.projectileTypePropsId, projectile__isUnderwater, projectile__exploded,
                               /*vel*/ float3(), /*should_stop*/ evt.stopped)
    if !success
      on_shell_hit_entity_fx(evt.shellId, evt.pos, evt.dir, evt.pmid, evt.norm, evt.bloodSplash,
                             evt.victimEid, evt.nodeCollId, evt.withSound)
      return

  if evt.bloodSplash == HitBloodType TWO_SIDE
    create_blood_puddle_emitter(evt.victimEid, evt.nodeCollId)
  elif evt.bloodSplash == HitBloodType ONE_SIDE
    add_hit_blood_effect(evt.pos, evt.dir)

//This is for ricochetting off vehicles only!
//Ricochetting off other surfaces is taken care of in projectile_hit_scene_es
[es(tag=render)]
def on_ricochet_vehicle_fx_es(evt : EventOnRicochet; transform : float3x4)
  let pos = transform * evt.localHitPos
  let norm = rotate(transform, evt.localNormal)

  query(evt.projectileEid) <| $ [es] (launch_desc : LaunchDesc;
                                      dm_projectile_state : ProjectileState;
                                      projectile__effectGroupName : string;
                                      projectile__isUnderwater : bool;
                                      projectile__exploded : bool;
                                      projectile__isBomb : bool = false)
    spawn_effect(projectile__effectGroupName, projectile__isBomb, launch_desc, norm, pos, get_material_id("steel"), int(CollType ETF_RI),
                 dm_projectile_state.projectileTypePropsId, projectile__isUnderwater, projectile__exploded,
                 /*vel*/ float3(), /*should_stop*/ false, /*ricochet*/ true)
