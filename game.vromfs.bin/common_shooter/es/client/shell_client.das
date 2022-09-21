require app
require ecs
require ecs.safe
require ecs.common
require math.base
require EnlistedNet
require DagorSystem
require common_shooter.events_common_shooter
require EnlistedWeapon
require EnlistedWeaponRender
require PhysMat
require Dacoll
require enlisted.events_enlisted

[es(on_event=EventLevelLoaded)]
def create_shell_info_cache_es(evt : Event)
  createEntity("shell_info_cache")

[es(tag=gameClient, on_disappear, REQUIRE_NOT=clientSide)]
def push_shell_fx_to_cache_es(evt : Event;
                              eid : EntityId;
                              shell_explosion_fx__infoTemplate : string)
  find_query() <| $ [es] (shell_info_cache__expirationTime : float; var shell_info_cache : Object&)
    if null != (shell_info_cache["{eid}"] ?as Object) //only happens if the shell already exploded,
                                                      //but wasn't destroyed; in this case, no need to
                                                      //keep the info about this shell in the cache
      shell_info_cache |> erase("{eid}")
      return true
    using() <| $(var shellCache : Object#)
      shellCache |> set("fx__infoTemplate", shell_explosion_fx__infoTemplate)
      shellCache |> set("expirationTime", float(get_sync_time()) + shell_info_cache__expirationTime)

      shell_info_cache |> set("{eid}", shellCache)
    return true

def private get_floor_material_name(pos : float3; fx_trace_length : float)
  var matId = 0
  var t = fx_trace_length
  tracedown_normalized(pos, t, matId, ETF_ALL)

  return get_material_name(get_material(matId))

def private get_fx_name(mat_name : string;
                        fx_default : string;
                        fx_info : Object?)
  let obj = fx_info?[mat_name] ?as Object
  return obj?.fx ?? fx_default

def private get_fx_name_based_on_floor(pos : float3;
                                       fx_trace_length : float;
                                       fx_default : string;
                                       fx_info : Object?)
  let floorMatName = get_floor_material_name(pos, fx_trace_length)
  return get_fx_name(floorMatName, fx_default, fx_info)

def private spawn_effect_aux(pos : float3;
                             fx_info_template : string)
  var fxInfoEid = getSingletonEntity("{fx_info_template}")
  if !fxInfoEid
    fxInfoEid = createEntitySync("{fx_info_template}")
  if !fxInfoEid
    logerr("Could not create entity from template {fx_info_template}")
    return false

  let fxInfoFound = query(fxInfoEid) <| $ [es] (shell_explosion_fx__traceLength : float;
                                                shell_explosion_fx__default : string;
                                                shell_explosion_fx__info : Object?)
    var tm = IDENT_TM
    tm[3] = pos
    let fxName = get_fx_name_based_on_floor(pos, shell_explosion_fx__traceLength, shell_explosion_fx__default, shell_explosion_fx__info)
    createEntity(fxName) <| $(var init)
      init |> set("transform", tm)

  return fxInfoFound

def private spawn_effect(shell_eid : EntityId; pos : float3)
  var success = false

  let shellFound = query(shell_eid) <| $ [es] (shell_explosion_fx__infoTemplate : string)
    success = spawn_effect_aux(pos, shell_explosion_fx__infoTemplate)
    find_query() <| $ [es] (var shell_info_cache : Object&)
      using() <| $(var emptyEntry : Object#)
        shell_info_cache |> set("{shell_eid}", emptyEntry) //we won't need to read the cache for this shell_eid,
                                                           //so let's create an empty entry to signal this
      return true

  if shellFound
    return success

  find_query() <| $ [es] (var shell_info_cache : Object&)
    let shellInfo = shell_info_cache["{shell_eid}"] ?as Object
    if shellInfo == null
      return true
    let fxInfoTemplate = shellInfo?.fx__infoTemplate ?? ""
    shell_info_cache |> erase("{shell_eid}")
    success = spawn_effect_aux(pos, fxInfoTemplate)
    return true

  return success

[es(tag=gameClient, REQUIRE=msg_sink)]
def shell_explode_es(shellExpl : CmdShellExplodeClient)
  detonate_shell_client(shellExpl.shellId, shellExpl.pos, shellExpl.offsetedPos,
                        shellExpl.explVictim, shellExpl.explDamageAndFatal, shellExpl.shellEid)

  if !spawn_effect(shellExpl.shellEid, shellExpl.pos)
    // spawn legacy effect
    on_shell_exploded_fx(int(shellExpl.shellId.shellId), shellExpl.pos)

  find_query() <| $ [es(REQUIRE=msg_sink)] (eid : EntityId)
    sendEventImmediate(
      eid,
      [[EventOnShellExploded
        explPos=shellExpl.pos,
        shellId=shellExpl.shellId.shellId,
        damageId=shellExpl.shellId.damageId,
        ballisticsId=shellExpl.shellId.ballisticsId,
        gunPropsId=shellExpl.gunPropsId,
        owner=shellExpl.offender]])
    return true

[es(tag=gameClient, no_order)]
def remove_expired_entries_in_shell_info_cache_es(evt : ParallelUpdateFrameDelayed;
                                                  shell_info_cache__checkInterval : float;
                                                  var shell_info_cache__nextCheckAt : float&;
                                                  var shell_info_cache : Object&)
  let curTime : float = get_sync_time()

  if curTime < shell_info_cache__nextCheckAt
    return

  shell_info_cache__nextCheckAt = curTime + shell_info_cache__checkInterval

  var expiredEntries : array<string>

  for shellInfo in shell_info_cache
    let expTime = get_ecs_object(shellInfo.value)?.expirationTime ?? 0.0
    if curTime > expTime
      expiredEntries |> push(shellInfo.key)

  for expiredEidKey in expiredEntries
    shell_info_cache |> erase(expiredEidKey)
