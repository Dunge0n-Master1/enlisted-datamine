require app
require ecs
require ecs.safe
require math.base
require math.random
require EnlistedNet
require DagorSystem
require common_shooter.events_common_shooter
require EnlistedWeapon
require EnlistedWeaponRender


[es(on_event=EventLevelLoaded)]
def create_shell_info_cache_es(evt : Event)
  createEntity("shell_info_cache")

[es(tag=gameClient, on_appear, REQUIRE_NOT=clientSide)]
def push_shell_fx_to_cache_es(evt : Event;
                              eid : EntityId;
                              shell_explosion_fx__default : string;
                              shell_explosion_fx__randomScale : float2 = float2(1, 1))
  query() <| $ [es] (var shell_info_cache : Object&)
    if null != (shell_info_cache["{eid}"] ?as Object)
      return
    using() <| $(var shellCache : Object#)
      shellCache |> set("fx__default", shell_explosion_fx__default)
      shellCache |> set("fx__randomScale", shell_explosion_fx__randomScale)
      shell_info_cache |> set("{eid}", shellCache)

def private spawn_effect(shell_eid : EntityId; pos : float3)
  var success = false
  query(shell_eid) <| $ [es] (shell_explosion_fx__default : string;
                              shell_explosion_fx__randomScale : float2 = float2(1, 1))
    success = true
    var tm = scale_tm <| rnd_float(shell_explosion_fx__randomScale)
    tm[3] = pos
    createEntity(shell_explosion_fx__default) <| $(var init)
      init |> set("transform", tm)

  query() <| $ [es] (var shell_info_cache : Object&)
    if success
      shell_info_cache |> erase("{shell_eid}")
      return

    let shellInfo = shell_info_cache["{shell_eid}"] ?as Object
    if shellInfo == null
      return

    let fx__default = shellInfo?.fx__default ?? ""
    if fx__default != ""
      success = true
      var tm = scale_tm <| rnd_float(shellInfo?.fx__randomScale ?? float2(1, 1))
      tm[3] = pos
      createEntity(fx__default) <| $(var init)
        init |> set("transform", tm)
    else
      logerr("Empty shell explosion fx template for [{shell_eid}]")

    shell_info_cache |> erase("{shell_eid}")
  return success

[es(tag=gameClient, REQUIRE=msg_sink)]
def shell_explode_es(shellExpl : CmdShellExplodeClient)

  detonate_shell_client(shellExpl.shellId, shellExpl.pos, shellExpl.offsetedPos,
                        shellExpl.explVictim, shellExpl.explDamageAndFatal)

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