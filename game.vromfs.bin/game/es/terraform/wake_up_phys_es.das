require ecs
require vehicle
require PhysObj
require Ship
require DngShip
require DngPhysObj
require DagorMath
require Grid
require GridCollision
require enlisted.events_enlisted

def private wake_up_phys_on_terraform_impl(pos : float3; radius : float)
  for_each_entity_in_grid(ecs_hash("vehicles"), BSphere3(pos, radius), GridEntCheck BOUNDING) <| $(eid : EntityId)
    query(eid) <| $ [es] (var vehicle_net_phys : VehiclePhysActor)
      vehicle_net_phys.phys |> wakeUp()

    query(eid) <| $ [es] (var phys_obj_net_phys : PhysObjActor)
      phys_obj_net_phys.phys |> wakeUp()

    query(eid) <| $ [es] (var ship_net_phys : ShipActor)
      ship_net_phys.phys |> ship_phys_wake_up()

[es(tag=server)]
def wake_up_phys_on_terraform(evt : CmdDig)
  wake_up_phys_on_terraform_impl(evt.pos, 2. * evt.radius)

[es(tag=server)]
def wake_up_phys_on_terraform_bomb_crater(evt : EventBombCraterPartTerraformed)
  wake_up_phys_on_terraform_impl(evt.partPos, 2. * evt.partRadius)