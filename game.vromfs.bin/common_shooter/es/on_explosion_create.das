require ecs
require app
require common_shooter.events_common_shooter
require math.base
require Dacoll

[es(tag=server)]
def on_explosion_create(evt : CmdShellExplode;
                        shell__owner : EntityId;
                        shell__gun_props_id : int;
                        shell__shell_id__shell_id : int;
                        on_explosion__create : StringList;
                        on_explosion__doNotCreateUnderwater : Tag const?)
  let pos = evt.position

  if on_explosion__doNotCreateUnderwater != null
    var isUnderwater = false
    let t = 0.0
    traceht_water_at_time(pos, t, get_sync_time(), isUnderwater)
    if isUnderwater
      return

  let dir = normalize_default(evt.vel, float3(0, -1, 0))

  for tmpl in on_explosion__create
    createEntity(string(tmpl)) <| $(var init)
      init |> set("on_explosion__owner", shell__owner)
      init |> set("on_explosion__gunPropsId", shell__gun_props_id)
      init |> set("on_explosion__shellId", shell__shell_id__shell_id)
      init |> set("on_explosion__pos", pos)
      init |> set("on_explosion__dir", dir)
      var tm : float3x4
      identity(tm)
      tm[3] = pos
      init |> set("transform", tm)

[es(tag=server, on_appear)]
def on_explosion_set_weapon_info(evt : Event;
                                 on_explosion__shellId : int;
                                 on_explosion__gunPropsId : int;
                                 var dmgzone__shellId : int&;
                                 var dmgzone__gunPropsId : int&)
  dmgzone__gunPropsId = on_explosion__gunPropsId
  dmgzone__shellId = on_explosion__shellId

[es(tag=server, on_appear)]
def on_explosion_set_damage_zone_offender(evt : Event;
                                          on_explosion__owner : EntityId;
                                          var dmgzone__offender : EntityId&)
  dmgzone__offender = on_explosion__owner
