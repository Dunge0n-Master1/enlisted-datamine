require ecs

[es(on_appear, track=respawn_activator__active, tag=server)]
def respawn_base_group_activator(evt : Event;
                                 respawn_activator__active : bool;
                                 respawn_activator__groupId : int;
                                 respawn_activator__groupName : string;
                                 respawn_activator__team : int)
  query() <| $ [es] (respawnBaseGroup : int;
                     var active : bool&;
                     var team : int&;
                     var groupName : das_string)
    if respawnBaseGroup == respawn_activator__groupId
      team = respawn_activator__team
      active = respawn_activator__active
      groupName := respawn_activator__groupName

[es(on_event=EventEntityDestroyed, tag=server)]
def respawn_base_group_activator_destroyed(evt : Event;
                                           respawn_activator__groupId : int)
  query() <| $ [es] (respawnBaseGroup : int;
                     var active : bool&)
    if respawnBaseGroup == respawn_activator__groupId
      active = false