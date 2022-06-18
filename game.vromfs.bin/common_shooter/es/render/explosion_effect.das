require ecs
require math.base
require common_shooter.events_common_shooter

[es(tag=render)]
def explosion_effect(evt : CmdShellExplodeFx)
  createEntity(evt.effectTemplate) <| $(var init : ComponentsInitializer)
    var tm = IDENT_TM
    tm[3] = evt.position
    init |> set("transform", tm)