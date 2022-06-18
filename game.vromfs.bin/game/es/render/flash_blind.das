require ecs
require app
require game.es.events
require game.es.flash_blind_common
require game.utils.hero

// intensity(power) = A * power ^ B; intensity(50) = 1; intensity(150) = 10000
// A * power ^ B = power ^ (B + log(A) / log(power))
let flash_blind_log_A : float const = -32.76988
let flash_blind_B : float const = 8.38361

[es(tag=render)]
def do_flash_blind(evt : EventFlashBlindEffect; eid : EntityId)
  let intensity = pow(evt.power, flash_blind_B + flash_blind_log_A / log(evt.power))
  fire_flash_blind_affect(eid, intensity)

[es(tag=render, track=isAlive)]
def on_death_disable_flash_blind(evt : Event; eid : EntityId; isAlive : bool)
  if !isAlive
    stop_flash_blind_affect(eid)
