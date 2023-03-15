options no_aot
require ecs
require DagorConsole
require EnlistedNet
require game.utils.hero
require game.es.net_console_macro

[net_console_cmd(name="engineer.unlock_all_building", hint="Unlock all engineer buildings. Hero must have a building tool")]
def engineer_unlock_all_cmd([[net_hero]] hero_eid : EntityId)
  query(hero_eid) <| $ [es] (human_weap__gunEids : EidList; squad_member__squad : EntityId)
    for gunEid in human_weap__gunEids
      query(gunEid) <| $ [es] (previewTemplate : StringList)
        query(squad_member__squad) <| $ [es] (var buildings__unlockIds : IntList)
          buildings__unlockIds |> clear()
          for i in range(length(previewTemplate))
            buildings__unlockIds |> push(i)

[net_console_cmd(name="engineer.add_resource")]
def engineer_resupple_resource_cmd(count : float = 100.0f; [[net_hero]] hero_eid : EntityId)
  query(hero_eid) <| $ [es] (var stockOfBuilderCapabilities : float&)
    stockOfBuilderCapabilities += count

[net_console_cmd(name="engineer.fast_build")]
def engineer_instant_build_cmd([[net_hero]] hero_eid : EntityId)
  query(hero_eid) <| $ [es] (var entity_mods__timeToBuildMul : float&)
    entity_mods__timeToBuildMul = 100.0
