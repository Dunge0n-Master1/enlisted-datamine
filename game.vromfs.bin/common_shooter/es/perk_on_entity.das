require ecs
require game.es.events

[es(on_appear, tag=server)]
def perk_on_entity_init(evt : Event; game_effect__perk__target : EntityId; game_effect__perkName : string)
  sendEvent(game_effect__perk__target, [[CmdChangePlayerPerk perkName=game_effect__perkName, active=true]])

// TODO: check if we have already same perk applied on target and only deactivate if we have 0 of such perks active
[es(on_disappear, tag=server)]
def perk_on_entity_deinit(evt : Event; game_effect__perk__target : EntityId; game_effect__perkName : string)
  sendEvent(game_effect__perk__target, [[CmdChangePlayerPerk perkName=game_effect__perkName, active=false]])

[es(no_order, tag=server)]
def perk_on_entity_update(info : UpdateStageInfoAct; eid : EntityId; game_effect__perk__endAtTime : float)
  if info.curTime > game_effect__perk__endAtTime
    destroyEntity(eid)

