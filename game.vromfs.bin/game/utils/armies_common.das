module armies_common shared
require ecs
require ecs.common
require game.es.stat_bq_common


def get_army_squads(armies; armyId) : Array const?
  let armyData = get_ecs_object(armies, armyId)
  return armyData != null ? get_ecs_array(armyData, "squads") : null


def get_squad_vehicle(squad : Object const?) : string
  let curVehicle = get_ecs_object(squad, "curVehicle")
  return curVehicle != null ? get_string(curVehicle, "gametemplate", "") : ""
