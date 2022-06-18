require ecs

[es(track=possessedByPlr, on_appear)]
def update_spectating_on_bots_es(evt : Event;
                                 possessedByPlr : EntityId;
                                 var isSpectatable : bool&)
  isSpectatable = !!possessedByPlr