require ecs
require DagorInput
require game.es.input.input_events
require game.es.input.input_common

def init(var vehicle_input__aim : int&;
         var vehicle_input__shoot : int&;
         var vehicle_input__shootSecondary : int&;
         var vehicle_input__shootMachinegun : int&;
         var vehicle_input__shootGrenadeLauncher : int&;
         var vehicle_input__shootTurret03 : int&;
         var vehicle_input__mainNextBulletType : int&;
         var vehicle_input__secondaryNextBulletType : int&;
         var vehicle_input__toggleStabilizer : int&;
         turret_input__actionSet : string)
  vehicle_input__aim             = int(get_action_handle("Vehicle.Aim", TYPEGRP_STICK))
  vehicle_input__shoot           = int(get_action_handle("Vehicle.Shoot", TYPEGRP_DIGITAL))
  vehicle_input__shootSecondary  = int(get_action_handle("Vehicle.ShootSecondary", TYPEGRP_DIGITAL))
  vehicle_input__shootMachinegun = int(get_action_handle("Vehicle.ShootMachinegun", TYPEGRP_DIGITAL))
  vehicle_input__shootGrenadeLauncher = int(get_action_handle("Vehicle.ShootGrenadeLauncher", TYPEGRP_DIGITAL))
  vehicle_input__shootTurret03   = int(get_action_handle("Vehicle.ShootTurret03", TYPEGRP_DIGITAL))
  vehicle_input__mainNextBulletType = int(get_action_handle("Vehicle.NextBulletType", TYPEGRP_DIGITAL))
  vehicle_input__secondaryNextBulletType = int(get_action_handle("Vehicle.SecondaryNextBulletType", TYPEGRP_DIGITAL))
  vehicle_input__toggleStabilizer = int(get_action_handle("Vehicle.StabilizerToggle", TYPEGRP_DIGITAL))

  activate_action_set(get_action_set_handle(turret_input__actionSet), /*active*/true)


def reset(var vehicle_input__aim : int&;
          var vehicle_input__shoot : int&;
          var vehicle_input__shootSecondary : int&;
          var vehicle_input__shootMachinegun : int&;
          var vehicle_input__shootGrenadeLauncher : int&;
          var vehicle_input__shootTurret03 : int&;
          var vehicle_input__mainNextBulletType : int&;
          var vehicle_input__secondaryNextBulletType : int&;
          var vehicle_input__toggleStabilizer : int&;
          turret_input__actionSet : string)
  vehicle_input__aim             = int(BAD_ACTION_HANDLE)
  vehicle_input__shoot           = int(BAD_ACTION_HANDLE)
  vehicle_input__shootSecondary  = int(BAD_ACTION_HANDLE)
  vehicle_input__shootMachinegun = int(BAD_ACTION_HANDLE)
  vehicle_input__shootGrenadeLauncher = int(BAD_ACTION_HANDLE)
  vehicle_input__shootTurret03   = int(BAD_ACTION_HANDLE)
  vehicle_input__mainNextBulletType = int(BAD_ACTION_HANDLE)
  vehicle_input__secondaryNextBulletType = int(BAD_ACTION_HANDLE)
  vehicle_input__toggleStabilizer = int(BAD_ACTION_HANDLE)

  activate_action_set(get_action_set_handle(turret_input__actionSet), /*active*/false)

[es(tag=input, on_appear)]
def vehicle_turret_input_appear(evt : Event;
                                var vehicle_input__aim : int&;
                                var vehicle_input__shoot : int&;
                                var vehicle_input__shootSecondary : int&;
                                var vehicle_input__shootMachinegun : int&;
                                var vehicle_input__shootGrenadeLauncher : int&;
                                var vehicle_input__shootTurret03 : int&;
                                var vehicle_input__mainNextBulletType : int&;
                                var vehicle_input__secondaryNextBulletType : int&;
                                var vehicle_input__toggleStabilizer : int&;
                                turret_input__actionSet : string)
  init(vehicle_input__aim, vehicle_input__shoot,
       vehicle_input__shootSecondary, vehicle_input__shootMachinegun, vehicle_input__shootGrenadeLauncher,
       vehicle_input__shootTurret03, vehicle_input__mainNextBulletType,
       vehicle_input__secondaryNextBulletType, vehicle_input__toggleStabilizer, turret_input__actionSet)

[es(tag=input, on_disappear)]
def vehicle_turret_input_disappear(evt : Event;
                                   var vehicle_input__aim : int&;
                                   var vehicle_input__shoot : int&;
                                   var vehicle_input__shootSecondary : int&;
                                   var vehicle_input__shootMachinegun : int&;
                                   var vehicle_input__shootGrenadeLauncher : int&;
                                   var vehicle_input__shootTurret03 : int&;
                                   var vehicle_input__mainNextBulletType : int&;
                                   var vehicle_input__secondaryNextBulletType : int&;
                                   var vehicle_input__toggleStabilizer : int&;
                                   turret_input__actionSet : string)
  reset(vehicle_input__aim, vehicle_input__shoot,
        vehicle_input__shootSecondary, vehicle_input__shootMachinegun, vehicle_input__shootGrenadeLauncher,
        vehicle_input__shootTurret03, vehicle_input__mainNextBulletType,
        vehicle_input__secondaryNextBulletType, vehicle_input__toggleStabilizer, turret_input__actionSet)

[es(tag=input)]
def vehicle_turret_input_init_reset(evt : EventDaInputInit;
                                    var vehicle_input__aim : int&;
                                    var vehicle_input__shoot : int&;
                                    var vehicle_input__shootSecondary : int&;
                                    var vehicle_input__shootMachinegun : int&;
                                    var vehicle_input__shootGrenadeLauncher : int&;
                                    var vehicle_input__shootTurret03 : int&;
                                    var vehicle_input__mainNextBulletType : int&;
                                    var vehicle_input__secondaryNextBulletType : int&;
                                    var vehicle_input__toggleStabilizer : int&;
                                    turret_input__actionSet : string)
  if evt.init
    init(vehicle_input__aim, vehicle_input__shoot,
         vehicle_input__shootSecondary, vehicle_input__shootMachinegun, vehicle_input__shootGrenadeLauncher,
         vehicle_input__shootTurret03, vehicle_input__mainNextBulletType,
         vehicle_input__secondaryNextBulletType, vehicle_input__toggleStabilizer, turret_input__actionSet)
  else
    reset(vehicle_input__aim, vehicle_input__shoot,
          vehicle_input__shootSecondary, vehicle_input__shootMachinegun, vehicle_input__shootGrenadeLauncher,
          vehicle_input__shootTurret03, vehicle_input__mainNextBulletType,
          vehicle_input__secondaryNextBulletType, vehicle_input__toggleStabilizer, turret_input__actionSet)
