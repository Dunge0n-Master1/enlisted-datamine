require ecs
require math.base
require game.es.events
require DagorMath

[es(tag=render, on_appear)]
def volfog_snow_controller_appear(evt : Event; volfog_snow_controller__templateName : string;
                                  var volfog_snow_controller__controllerEid : EntityId&)
  volfog_snow_controller__controllerEid = createEntity(volfog_snow_controller__templateName)


[es(tag=render, on_disappear)]
def volfog_snow_controller_disappear(evt : Event; volfog_snow_controller__destroyerAppendTemplate : das_string const?;
                                     volfog_snow_controller__controllerEid : EntityId)
  if volfog_snow_controller__destroyerAppendTemplate != null
    addSubTemplate(volfog_snow_controller__controllerEid, string(*volfog_snow_controller__destroyerAppendTemplate))
  else
    destroyEntity(volfog_snow_controller__controllerEid)

[es(tag=render, on_appear)]
def volfog_snow_controller_starts_destroy(evt : Event; volfog_snow_controller__rollbackIntensitySpeed : float; volfog_snow__intensity : float;
                                          var game_effect__clientDestroyTimer : float&; var volfog_snow__intensitySpeed : float&)
  game_effect__clientDestroyTimer = safediv(volfog_snow__intensity, volfog_snow_controller__rollbackIntensitySpeed)
  volfog_snow__intensitySpeed = -volfog_snow_controller__rollbackIntensitySpeed
