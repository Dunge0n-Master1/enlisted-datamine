require ecs
require ecs.common
require app
require game.es.events
require DaWeaponProps
require NetPropsRegistry
require DngWeapon
require DagorDataBlock
require DagorSystem
require common_shooter.es.human.human_gun_common

def spawn_shell_impl(eid : EntityId;
                     transform : float3x4;
                     on_create__spawnActivatedShellBlk : string;
                     on_create__setVelocity : float3 const?;
                     on_create__addShellTemplate : das_string const?;
                     on_create__spawnShellTimer : float = -1.0f;
                     ownerEid : EntityId = INVALID_ENTITY_ID)
  using() <| $(var shell_props : ShellPropIds#)
    shell_props.shellId = int16(register_net_props(on_create__spawnActivatedShellBlk, "shell"))
    shell_props.damageId = int16(register_net_props(on_create__spawnActivatedShellBlk, "damage"))
    shell_props.ballisticsId = int16(register_net_props(on_create__spawnActivatedShellBlk, "ballistics")) //item.shell
    var timer = 0.0
    if on_create__spawnShellTimer < 0.0
      detonation_get_props(int(shell_props.shellId)) <| $(detonationProps : DetonationProps)
        timer = detonationProps.timer
    else
      timer = on_create__spawnShellTimer
    shell_entity_get_props(int(shell_props.shellId)) <| $(shellEntityProp : ShellEntityTypeProps)
      var physTemplName = shellEntityProp |> shell_entity_props_get_physTemplName()

      if on_create__addShellTemplate != null
        let shellTemplateName = *on_create__addShellTemplate |> string()
        physTemplName = add_sub_template_name(physTemplName, shellTemplateName)

      let startVel = (on_create__setVelocity != null
                    ? rotate(transform, *on_create__setVelocity)
                    : float3())

      create_shell_entity(physTemplName, transform, startVel,
                          ownerEid, shell_props, /*gun_props_id*/ - 1,
                          /*launchTime*/ get_sync_time(),
                          /*explTime*/ get_sync_time() + timer,
                          /*in_active*/ true,
                          /*clientSide*/ false,
                          /*rethrowerEid*/ INVALID_ENTITY_ID)

      destroyEntity(eid)


[es(tag=server, REQUIRE_NOT=activator__spawnShellAtTime)]
def spawn_shell_on_create_es(evt : EventEntityCreated;
                             eid : EntityId;
                             transform : float3x4;
                             on_create__spawnActivatedShellBlk : string;
                             on_create__setVelocity : float3 const?;
                             on_create__addShellTemplate : das_string const?;
                             on_create__spawnShellTimer : float = -1.0f;
                             ownerEid : EntityId = INVALID_ENTITY_ID)
  spawn_shell_impl(eid, transform, on_create__spawnActivatedShellBlk, on_create__setVelocity, on_create__addShellTemplate,
                   on_create__spawnShellTimer, ownerEid)

[es(tag=server, no_order)]
def spawn_shell_delayed_spawner_es(info : ecs::UpdateStageInfoAct;
                                   eid : EntityId;
                                   transform : float3x4;
                                   activator__spawnShellAtTime : float;
                                   on_create__spawnActivatedShellBlk : string;
                                   on_create__setVelocity : float3 const?;
                                   on_create__addShellTemplate : das_string const?;
                                   on_create__spawnShellTimer : float = -1.0f;
                                   ownerEid : EntityId = INVALID_ENTITY_ID)
  if activator__spawnShellAtTime > 0.f && activator__spawnShellAtTime < info.curTime
    spawn_shell_impl(eid, transform, on_create__spawnActivatedShellBlk, on_create__setVelocity, on_create__addShellTemplate,
                     on_create__spawnShellTimer, ownerEid)

[es(on_appear)]
def delayed_spawn_shell_on_create_init_timer_es(evt : Event;
                                                activator__spawnShellDelay : float;
                                                var activator__spawnShellAtTime : float&)
  activator__spawnShellAtTime = get_sync_time() + activator__spawnShellDelay
