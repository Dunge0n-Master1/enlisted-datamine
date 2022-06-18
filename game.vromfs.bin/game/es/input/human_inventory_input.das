require ecs
require app
require inventory
require DagorInput
require game.es.events
require game.es.input.input_events
require ForceFeedbackRumble
require game.es.input.input_common
require EnlistedHuman
require HumanPhys


def init(var human_inventory_input__forcedPickup : int&;
         var human_inventory_input__pickup : int&;
         var human_inventory_input__dropGun : int&)
  human_inventory_input__forcedPickup = int(get_action_handle("Inventory.ForcedPickup", TYPEGRP_DIGITAL))
  human_inventory_input__pickup       = int(get_action_handle("Inventory.Pickup", TYPEGRP_DIGITAL))
  human_inventory_input__dropGun      = int(get_action_handle("Inventory.DropGun", TYPEGRP_DIGITAL))


def reset(var human_inventory_input__forcedPickup : int&;
          var human_inventory_input__pickup : int&;
          var human_inventory_input__dropGun : int&)
  human_inventory_input__forcedPickup = int(BAD_ACTION_HANDLE)
  human_inventory_input__pickup = int(BAD_ACTION_HANDLE)
  human_inventory_input__dropGun = int(BAD_ACTION_HANDLE)

[es(tag=input, on_appear)]
def human_inventory_input_appear_es(evt : Event;
                                    var human_inventory_input__forcedPickup : int&;
                                    var human_inventory_input__pickup : int&;
                                    var human_inventory_input__dropGun : int&)
  init(human_inventory_input__forcedPickup, human_inventory_input__pickup, human_inventory_input__dropGun)

[es(tag=input)]
def human_inventory_input_init_es(evt : EventDaInputInit;
                                  var human_inventory_input__forcedPickup : int&;
                                  var human_inventory_input__pickup : int&;
                                  var human_inventory_input__dropGun : int&)
  if evt.init
    init(human_inventory_input__forcedPickup, human_inventory_input__pickup, human_inventory_input__dropGun)
  else
    reset(human_inventory_input__forcedPickup, human_inventory_input__pickup, human_inventory_input__dropGun)

