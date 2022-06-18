require ecs
require math.base
require game.utils.hero
require DagorMath
require DagorShaders

let
  redout_blackout_colorVarId = get_shader_variable_id("redout_blackout_color", true)

[es(tag=(ui, render), on_appear)]
def aircraft_crew_init_prev_stamina(evt : Event;
                                    aircraft_crew__stamina : float;
                                    var aircraft_crew__staminaPrev : float&)
  aircraft_crew__staminaPrev = aircraft_crew__stamina

[es(tag=(ui, render), REQUIRE=watchedByPlr, after=(aircraft_crew_init_prev_stamina, aircraft_crew_stamina))]
def aircraft_crew_g_force_visual(info : UpdateStageInfoAct;
                                 eid : ecs::EntityId;
                                 isAlive : bool;
                                 aircraft_crew__stamina : float;
                                 entity_mods__aircraftCrewMaxStaminaMult : float = 1.0;
                                 g_force__isPositive : bool;
                                 var aircraft_crew__staminaPrev : float&;
                                 var g_force__visual : float&)
  if !has(eid, "hero") || !isAlive
    return

  let maxStamina = entity_mods__aircraftCrewMaxStaminaMult
  let stamina = aircraft_crew__stamina
  let staminaDelta = stamina - aircraft_crew__staminaPrev

  let visualDelta = staminaDelta * safediv((staminaDelta > 0.0 ? 0.0 : (g_force__isPositive ? 1.0 : -1.0)) - g_force__visual,
                                           (staminaDelta > 0.0 ? maxStamina : 0.0) - aircraft_crew__staminaPrev)
  g_force__visual += visualDelta
  aircraft_crew__staminaPrev = aircraft_crew__stamina

  if g_force__visual < 0.f
    DagorShaders::set_color4(redout_blackout_colorVarId, Color4(float4(0.4f, 0.f, 0.f, -g_force__visual)))
  else
    DagorShaders::set_color4(redout_blackout_colorVarId, Color4(float4(0.f, 0.f, 0.f, g_force__visual)))

[es(tag=(render), track=human_anim__vehicleSelected, REQUIRE=aircraftCrew)]
def aircraft_crew_g_force_visual_remove(evt : Event; eid : EntityId; human_anim__vehicleSelected : EntityId)
  if !has(eid, "hero") || has(human_anim__vehicleSelected, "airplane")
    return
  DagorShaders::set_color4(redout_blackout_colorVarId, Color4(float4(0.f, 0.f, 0.f, 0.f)))

[es(tag=(render), track=isAlive)]
def on_death_aircraft_crew_g_force_visual_remove(evt : Event; eid : EntityId; isAlive : bool)
  if !has(eid, "hero") || isAlive
    return
  DagorShaders::set_color4(redout_blackout_colorVarId, Color4(float4(0.f, 0.f, 0.f, 0.f)))

[es(on_event=(EventComponentsDisappear, EventEntityDestroyed), tag=render, no_order, REQUIRE=hero)]
def stop_redout_blackout_effect_critical_es(evt : Event)
  DagorShaders::set_color4(redout_blackout_colorVarId, Color4(float4(0.f, 0.f, 0.f, 0.f)))