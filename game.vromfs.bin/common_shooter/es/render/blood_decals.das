require ecs
require ecs.extra_set
require common_shooter.events_common_shooter
require common_shooter.es.render.blood_common
require danetlibs.blood_decals.render.blood_decals_common


[es(tag=gameClient, REQUIRE=msg_sink)]
def shell_explode_create_blood_decals(shellExpl : CmdShellExplodeClient)
  if is_blood_enabled()
    createEntity("blood_decal_manager") <| $(var init : ComponentsInitializer)
      var list : array<EntityId>
      for i, eid in iter_range(shellExpl.explVictim), shellExpl.explVictim
        let isFatalHit = (int(shellExpl.explDamageAndFatal[i]) & 1) == 1
        if isFatalHit
          list |> push(eid)
      init |> set("blood_decal_manager__fromPos", shellExpl.pos)
      init |> set("blood_decal_manager__targets", list)

