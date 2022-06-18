require app
require ecs
require EnlistedNet
require common_shooter.events_common_shooter
require EnlistedWeapon
require EnlistedWeaponRender


[es(tag=gameClient, REQUIRE=msg_sink)]
def shell_explode_es(shellExpl : CmdShellExplodeClient)

  detonate_shell_client(shellExpl.shellId, shellExpl.pos, shellExpl.offsetedPos,
                        shellExpl.explVictim, shellExpl.explDamageAndFatal)

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