require ecs
require DagorConsole

let
  FLT_INACCURACY = 1e-9

[console_cmd(name="app.debug_canopy_collision")]
def app_debug_canopy_collision()
  var found = false
  query() <| $ [es(REQUIRE=collision_canopy_debug)] (eid : EntityId)
    found = true
    destroyEntity(eid)
  if !found
    createEntity("collision_canopy_debug")


[console_cmd(name="app.debug_collision")]
def app_debug_collision(coll_dist = 1000.;
                        label_dist = 20.)
  var found = false
  let collDistSq = coll_dist * coll_dist
  let labelDistSq = label_dist * label_dist
  let collDistSqTmp = (collDistSq > 0. + FLT_INACCURACY) ? collDistSq : 0.
  let labelDistSqTmp = (collDistSqTmp - labelDistSq > 0. + FLT_INACCURACY) ? labelDistSq : collDistSqTmp
  query() <| $ [es(REQUIRE=collision_debug)] (var collision_debug__collMaxDistSq : float&;
                                              var collision_debug__labelMaxDistSq : float&)
    collision_debug__collMaxDistSq = collDistSqTmp
    collision_debug__labelMaxDistSq = labelDistSqTmp
    found = true
  if !found
    createEntity("collision_debug") <| $(init)
      init |> set("collision_debug__collMaxDistSq", collDistSqTmp)
      init |> set("collision_debug__labelMaxDistSq", labelDistSqTmp)

[console_cmd(name="app.debug_collision_disable")]
def app_debug_collision_disable()
  query() <| $ [es(REQUIRE=collision_debug)] (eid : EntityId)
    destroyEntity(eid)


[console_cmd(name="app.debug_phys_collision")]
def app_debug_phys_collision(coll_dist = 1000.;
                             label_dist = 20.)
  var found = false
  let collDistSq = coll_dist * coll_dist
  let labelDistSq = label_dist * label_dist
  let collDistSqTmp = (collDistSq > 0. + FLT_INACCURACY) ? collDistSq : 0.
  let labelDistSqTmp = (collDistSqTmp - labelDistSq > 0. + FLT_INACCURACY) ? labelDistSq : collDistSqTmp
  query() <| $ [es(REQUIRE=collision_phys_debug)] (var collision_debug__collMaxDistSq : float&;
                                                   var collision_debug__labelMaxDistSq : float&)
    collision_debug__collMaxDistSq = collDistSqTmp
    collision_debug__labelMaxDistSq = labelDistSqTmp
    found = true
  if !found
    createEntity("collision_phys_debug") <| $(init)
      init |> set("collision_debug__collMaxDistSq", collDistSqTmp)
      init |> set("collision_debug__labelMaxDistSq", labelDistSqTmp)

[console_cmd(name="app.debug_phys_collision_disable")]
def app_debug_phys_collision_disable()
  query() <| $ [es(REQUIRE=collision_phys_debug)] (eid : EntityId)
    destroyEntity(eid)
