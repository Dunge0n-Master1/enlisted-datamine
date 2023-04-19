require ecs
require game.events_game
require DngNet

[es(tag=server, on_appear)]
def tutorial_action_kill_squad_member_es(evt : Event; var tutor_action__killSquadMember : int&)
  find_query() <| $ [es(REQUIRE=(human, heroSquad), REQUIRE_NOT=hero)] (eid : EntityId)
    if tutor_action__killSquadMember <= 0
      return true

    --tutor_action__killSquadMember
    send_net_event(eid, [[RequestSuicide]])
    return false
