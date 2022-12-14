require ecs
require game.es.events
require danetlibs.native_dasevents.main.native_events


[es(tag=server, before=useful_box_use_finish_es, REQUIRE=resourceBox)]
def resource_box_use_es(evt : CmdUseUsefulBox;
                        var useful_box__successUse : bool&;
                        resource_box__stockCount : float = 20f)
  query(evt.requesterEid) <| $ [es] (var stockOfBuilderCapabilities : float&)
    useful_box__successUse ||= stockOfBuilderCapabilities < resource_box__stockCount
    if useful_box__successUse
      stockOfBuilderCapabilities = resource_box__stockCount

[es(tag=server, after=resource_box_use_es, before=useful_box_use_finish_es, REQUIRE=resourceBox)]
def resource_box_use_finish_es(evt : CmdUseUsefulBox; useful_box__successUse : bool)
  if !useful_box__successUse
    sendEvent(evt.requesterEid, [[CmdHeroLogEvent event="resource_full", text="resupply/resource_full"]])
