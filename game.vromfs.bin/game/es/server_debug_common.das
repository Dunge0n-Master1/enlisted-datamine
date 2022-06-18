module server_debug_common shared
require ecs
require EnlistedNet
require game.es.events


def exec_server_cmd(message : string)
  find_query() <| $ [es(REQUIRE=msg_sink)] (eid : EntityId)
    client_send_schemeless_event(eid, typeinfo(undecorated_typename type<CmdChatMessage>)) <| $(var init : Object#)
      set(init, "mode", "team")
      set(init, "text", "/servercmd {message}")
    return true
