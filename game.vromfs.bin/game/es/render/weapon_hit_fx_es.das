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


def spawn_effect(hit_effect_descriptor : int;
                 expl_effect_descriptor : int;
                 launch_desc : LaunchDesc;
                 dm_projectile_state : ProjectileState;
                 projectile_ballistics : ProjectileBallistics;
                 norm : float3;
                 pos : float3;
                 mat_id : int;
                 coll_type : int;
                 is_under_water : bool;
                 exploded : bool = true;
                 should_stop : bool = true;
                 ricochet : bool = false)
  let fxName = get_projectile_fx_name(hit_effect_descriptor, expl_effect_descriptor,
                                      launch_desc, dm_projectile_state, projectile_ballistics, mat_id, is_under_water,
                                      exploded, should_stop, ricochet)
  if empty(fxName)
    return true

  var posAdjusted : float3

  if is_under_water
    var waterLevel = 0.0
    traceht_water(pos, waterLevel)
    posAdjusted = float3(pos.x, waterLevel, pos.z)
  else
    posAdjusted = pos

  spawn_effect_aux(norm, posAdjusted, coll_type, fxName)
  return true

[es(tag=render)]
def projectile_hit_scene_es(evt : EventProjectileHitScene;
                            launch_desc : LaunchDesc;
                            dm_projectile_state : ProjectileState;
                            projectile_ballistics : ProjectileBallistics;
                            projectile__hitEffectDescriptor : int;
                            projectile__explEffectDescriptor : int;
                            projectile__isUnderwater : bool;
                            projectile__exploded : bool)
  if int(launch_desc.shellId.shellId) < 0
    return
  if !evt.sceneIntersectionsExceeded || (evt.shouldStop && evt.allowDetonation)
    let success = spawn_effect(projectile__hitEffectDescriptor, projectile__explEffectDescriptor,
                               launch_desc, dm_projectile_state, projectile_ballistics, evt.norm, evt.pos, evt.matId, evt.collType,
                               projectile__isUnderwater, projectile__exploded, evt.shouldStop, evt.ricochetAngle != 0.0)
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
                             projectile_ballistics : ProjectileBallistics;
                             projectile__isUnderwater : bool;
                             projectile__hitEffectDescriptor : int;
                             projectile__explEffectDescriptor : int)
  if int(launch_desc.shellId.shellId) < 0
    return
  let success = spawn_effect(projectile__hitEffectDescriptor, projectile__explEffectDescriptor,
                             launch_desc, dm_projectile_state, projectile_ballistics, scene_hit_place__norm, scene_hit_place__pos, scene_hit_place__matId,
                             scene_hit_place__collType, projectile__isUnderwater)
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

def human_spawn_blood_fx(victim_eid : EntityId; coll_node_id : int; blood_splash : HitBloodType;
                         pos : float3; dir : float3; scale : float; norm : float3)
  var success = false
  if !is_blood_enabled()
    return true

  query(victim_eid) <| $ [es] (transform : float3x4; animchar : AnimcharBaseComponent; collres : CollisionResource)
    find_query() <| $ [es] (global_hit_fx__fleshEffects : Object)
      let fxSection = (blood_splash == HitBloodType TWO_SIDE ? "kill" : "wound")
      let fxName = get_string(global_hit_fx__fleshEffects, "{fxSection}Fx", "")
      if fxName == ""
        logerr("human_spawn_blood_fx: Couldn't find effect {fxSection} in global_hit_fx__fleshEffects")
        return true

      success = true
      let sideFx = get_string(global_hit_fx__fleshEffects, "{fxSection}SideFx", "")
      let exitFx = get_string(global_hit_fx__fleshEffects, "{fxSection}ExitFx", "")
      let bloodColor = get_blood_color()
      var nodeTm : float3x4
      collres_get_collision_node_tm(collres, coll_node_id, transform, animchar.nodeTree, nodeTm)
      let itm = inverse(nodeTm)
      spawn_human_binded_fx(gen_fx_tm(pos, -dir, scale), itm, fxName, victim_eid, coll_node_id, bloodColor);
      let reflectedDir = dir - 2. * dot(norm, dir) * norm
      if sideFx != "" && length_sq(reflectedDir) > 1e-5f
        spawn_human_binded_fx(gen_fx_tm(pos, ((normalize(reflectedDir) + norm) * 0.5f), scale), itm, sideFx, victim_eid, coll_node_id, bloodColor)

      if blood_splash != HitBloodType TWO_SIDE || exitFx == ""
        return true
      let t = 2.
      let tracePos = pos + 2. * dir
      let invDir = -dir
      collres_traceray(collres, transform, animchar.nodeTree, tracePos, invDir, t, true, uint8(BehaviorFlag TRACEABLE)) <| $ [unused_argument(_)] (find : bool; isects : CollResIntersectionsType#)
        if find
          let exitNodeId = int(isects[length(isects) - 1].collisionNodeId)
          spawn_human_binded_fx(gen_fx_tm(pos + (2.0f - t) * dir, dir, scale), itm, exitFx, victim_eid, exitNodeId, bloodColor);
      return true

  return success

[es(tag=render)]
def on_shell_hit_entity_fx_es(evt : OnShellHitEntityFx)
  if evt.bloodSplash != HitBloodType NONE
    human_spawn_blood_fx(evt.victimEid, evt.nodeCollId, evt.bloodSplash, evt.pos, evt.dir, /*scale*/ 1., evt.norm)

  if evt.directHit
    var success = false
    query(evt.projectileEid) <| $ [es] (launch_desc : LaunchDesc;
                                        dm_projectile_state : ProjectileState;
                                        projectile_ballistics : ProjectileBallistics;
                                        projectile__hitEffectDescriptor : int;
                                        projectile__explEffectDescriptor : int;
                                        projectile__isUnderwater : bool;
                                        projectile__exploded : bool)
      success = spawn_effect(projectile__hitEffectDescriptor, projectile__explEffectDescriptor,
                             launch_desc, dm_projectile_state, projectile_ballistics, evt.norm, evt.pos, evt.pmid,
                             int(CollType ETF_RI), projectile__isUnderwater, projectile__exploded, evt.stopped)
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
                                      projectile_ballistics : ProjectileBallistics;
                                      projectile__hitEffectDescriptor : int;
                                      projectile__explEffectDescriptor : int;
                                      projectile__isUnderwater : bool;
                                      projectile__exploded : bool)
    spawn_effect(projectile__hitEffectDescriptor, projectile__explEffectDescriptor,
                 launch_desc, dm_projectile_state, projectile_ballistics, norm, pos, get_material_id("steel"),
                 int(CollType ETF_RI), projectile__isUnderwater, projectile__exploded, /*should_stop*/ false, /*ricochet*/ true)
