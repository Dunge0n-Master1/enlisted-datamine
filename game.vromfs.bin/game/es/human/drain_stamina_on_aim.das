require ecs
require app
require EnlistedHuman
require game.es.events

[es(tag=server, on_appear, track=human_weap__currentGunEid)]
def set_aim_stamina_values_from_weapon(evt : Event;
                                       human_weap__currentGunEid : EntityId;
                                       var human_weap__drainStaminaOnAim : float&;
                                       var human_weap__staminaToStartAim : float&;
                                       var human_weap__drainStaminaDelay : float&)
  human_weap__drainStaminaOnAim = 0.
  human_weap__staminaToStartAim = 0.
  human_weap__drainStaminaDelay = 0.
  query(human_weap__currentGunEid) <| $ [es] (gun__drainStaminaOnAim : float;
                                              gun__staminaToStartAim : float;
                                              gun__drainStaminaDelay : float = 0.)
    human_weap__drainStaminaOnAim = gun__drainStaminaOnAim
    human_weap__staminaToStartAim = gun__staminaToStartAim
    human_weap__drainStaminaDelay = gun__drainStaminaDelay

[es(tag=server, on_appear)]
def human_set_aim_stamina_values_from_weapon(evt : Event;
                                             eid : EntityId;
                                             gun__owner : EntityId;
                                             gun__drainStaminaOnAim : float;
                                             gun__staminaToStartAim : float;
                                             gun__drainStaminaDelay : float = 0.)
  query(gun__owner) <| $ [es] (human_weap__currentGunEid : EntityId;
                               var human_weap__drainStaminaOnAim : float&;
                               var human_weap__staminaToStartAim : float&;
                               var human_weap__drainStaminaDelay : float&)
    if eid == human_weap__currentGunEid
      human_weap__drainStaminaOnAim = gun__drainStaminaOnAim
      human_weap__staminaToStartAim = gun__staminaToStartAim
      human_weap__drainStaminaDelay = gun__drainStaminaDelay

[es(tag=server, after=human_input_es, before=before_net_phys_sync)]
def check_aim_stamina_threshold(evt : UpdateStageUpdateInput;
                                human_weap__minStaminaLevelToAim : float;
                                human_weap__drainStaminaOnAim : float;
                                human_weap__staminaToStartAim : float;
                                bipod__enabled : bool = false;
                                human_net_phys__isCrawl : bool;
                                var human_weap__staminaCanAim : bool&;
                                human_net_phys : HumanActor)
  let stamina = human_net_phys.phys.currentState.stamina
  assume isAiming = human_net_phys.phys.currentState.isAiming
  let threshold = (human_weap__drainStaminaOnAim > 0.
    ? (isAiming ? 0. : human_weap__minStaminaLevelToAim + human_weap__staminaToStartAim)
    : -1.0)
  human_weap__staminaCanAim = bipod__enabled || human_net_phys__isCrawl || stamina > threshold

def drain_stamina(var human_net_phys : HumanActor&; value : float)
  assume stamina = human_net_phys.phys.currentState.stamina
  stamina = max(stamina - value, 0.)

[es(tag=server, track=human_net_phys__isAiming)]
def drain_stamina_on_start_aim(evt : Event;
                               human_net_phys__isAiming : bool;
                               human_weap__staminaToStartAim : float;
                               bipod__enabled : bool = false;
                               human_net_phys__isCrawl : bool;
                               var human_net_phys : HumanActor&)
  if human_net_phys__isAiming && !bipod__enabled && !human_net_phys__isCrawl
    human_net_phys |> drain_stamina(human_weap__staminaToStartAim)

[es(tag=netClient, REQUIRE=hero, track=human_net_phys__isAiming)]
def drain_stamina_on_start_aim_client(evt : Event;
                                      human_net_phys__isAiming : bool;
                                      human_weap__staminaToStartAim : float;
                                      bipod__enabled : bool = false;
                                      human_net_phys__isCrawl : bool;
                                      var human_net_phys : HumanActor&)
  if human_net_phys__isAiming && !bipod__enabled && !human_net_phys__isCrawl
    human_net_phys |> drain_stamina(human_weap__staminaToStartAim)

[es(tag=server, track=human_net_phys__isAiming)]
def aim_stamina_save_start_time(evt : Event;
                                human_net_phys__isAiming : bool;
                                var human_weap__aimStartTime : float&)
  if human_net_phys__isAiming
    human_weap__aimStartTime = get_sync_time()

[es(tag=netClient, REQUIRE=hero, track=human_net_phys__isAiming)]
def aim_stamina_save_start_time_client(evt : Event;
                                       human_net_phys__isAiming : bool;
                                       var human_weap__aimStartTime : float&)
  if human_net_phys__isAiming
    human_weap__aimStartTime = get_sync_time()

[es(tag=server, after=(before_net_phys_sync, entity_restore_stamina_mult_applier_es), before=human_phys_es)]
def drain_stamina_on_aim(evt : UpdateStageInfoAct;
                         human_weap__drainStaminaOnAim : float;
                         human_weap__drainStaminaDelay : float = 0.f;
                         bipod__enabled : bool = false;
                         human_net_phys__isCrawl : bool;
                         human_weap__aimStartTime : float;
                         var human_net_phys : HumanActor)
  let isDelayOver = get_sync_time() - human_weap__aimStartTime > human_weap__drainStaminaDelay
  if isDelayOver && human_weap__drainStaminaOnAim > 0. && !bipod__enabled && human_net_phys.phys.currentState.isAiming && !human_net_phys__isCrawl
    human_net_phys |> drain_stamina(human_weap__drainStaminaOnAim * evt.dt)
    human_net_phys.phys.currentState.restoreStaminaMult = 0.0

[es(tag=netClient, REQUIRE=hero, after=(before_net_phys_sync, entity_restore_stamina_mult_applier_es), before=human_phys_es)]
def drain_stamina_on_aim_client(evt : UpdateStageInfoAct;
                                human_weap__drainStaminaOnAim : float;
                                human_weap__drainStaminaDelay : float = 0.f;
                                bipod__enabled : bool = false;
                                human_net_phys__isCrawl : bool;
                                human_weap__aimStartTime : float;
                                var human_net_phys : HumanActor)
  let isDelayOver = get_sync_time() - human_weap__aimStartTime > human_weap__drainStaminaDelay
  if isDelayOver && human_weap__drainStaminaOnAim > 0. && !bipod__enabled && human_net_phys.phys.currentState.isAiming && !human_net_phys__isCrawl
    human_net_phys |> drain_stamina(human_weap__drainStaminaOnAim * evt.dt)
    human_net_phys.phys.currentState.restoreStaminaMult = 0.0
