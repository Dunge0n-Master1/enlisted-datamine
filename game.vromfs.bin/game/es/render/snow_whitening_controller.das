require ecs
require math.base
require game.es.events
require DagorMath

[es(tag=render, on_appear)]
def snow_whitening_controller_appear(evt : Event; snow_whitening_controller__templateName : string;
                                     var snow_whitening_controller__controllerEid : EntityId&)
  snow_whitening_controller__controllerEid = createEntity(snow_whitening_controller__templateName)


[es(tag=render, on_disappear)]
def snow_whitening_controller_disappear(evt : Event; snow_whitening_controller__destroyerAppendTemplate : das_string const?;
                                        snow_whitening_controller__controllerEid : EntityId)
  if snow_whitening_controller__destroyerAppendTemplate != null
    addSubTemplate(snow_whitening_controller__controllerEid, string(*snow_whitening_controller__destroyerAppendTemplate))
  else
    destroyEntity(snow_whitening_controller__controllerEid)

[es(tag=render, on_appear)]
def snow_whitening_starts_destroy(evt : Event; snow_whitening_controller__rollbackSpeed : float; snow_whitening__amount : float;
                                  var game_effect__clientDestroyTimer : float&; var snow_whitening__speed : float&)
  game_effect__clientDestroyTimer = safediv(snow_whitening__amount, snow_whitening_controller__rollbackSpeed)
  snow_whitening__speed = -snow_whitening_controller__rollbackSpeed
