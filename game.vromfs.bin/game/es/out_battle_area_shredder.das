require ecs
require game.utils.team
require game.es.battle_area_common
require zones

def check_shreddable_in_deactivating_zones()
  query() <| $ [es(REQUIRE=(shredOutsideBattleArea, shredInDeactivatingBattleArea), REQUIRE_NOT=builder_info__team)] (eid : EntityId; transform : float3x4; team = int(TEAM_UNASSIGNED))
    if !has_active_non_deactivating_human_battle_area_at(transform[3], team)
      destroyEntity(eid)
  query() <| $ [es(REQUIRE=(shredOutsideBattleArea, shredInDeactivatingBattleArea))] (eid : EntityId; transform : float3x4; builder_info__team : int)
    if !has_active_non_deactivating_human_battle_area_at(transform[3], builder_info__team)
      destroyEntity(eid)

def check_shreddable()
  query() <| $ [es(REQUIRE=shredOutsideBattleArea, REQUIRE_NOT=(shredInDeactivatingBattleArea, builder_info__team))] (eid : EntityId; transform : float3x4; team = int(TEAM_UNASSIGNED))
    if is_tm_outside_battle_area(transform, team)
      destroyEntity(eid)
  query() <| $ [es(REQUIRE=shredOutsideBattleArea, REQUIRE_NOT=shredInDeactivatingBattleArea)] (eid : EntityId; transform : float3x4; builder_info__team : int)
    if is_tm_outside_battle_area(transform, builder_info__team)
      destroyEntity(eid)

[es(tag=server, REQUIRE=shredOutsideBattleArea, REQUIRE_NOT=shredInDeactivatingBattleArea, on_appear)]
def out_battle_area_shredder_create_check(evt : Event; eid : EntityId; transform : float3x4; team = int(TEAM_UNASSIGNED))
  if is_tm_outside_battle_area(transform, team)
    destroyEntity(eid)

[es(tag=server, REQUIRE=(shredOutsideBattleArea, shredInDeactivatingBattleArea), on_appear)]
def out_non_deactivating_battle_area_shredder_create_check(evt : Event; eid : EntityId; transform : float3x4; team = int(TEAM_UNASSIGNED))
  if !has_active_non_deactivating_human_battle_area_at(transform[3], team)
    destroyEntity(eid)

[es(tag=server, REQUIRE=(battle_area, humanTriggerable), on_event=EventEntityDestroyed)]
def out_battle_area_shredder_destroyed_check(evt : Event)
  check_shreddable()
  check_shreddable_in_deactivating_zones()

[es(tag=server, track=active, REQUIRE=(battle_area, humanTriggerable))]
def out_battle_area_shredder_deactivate_check(evt : Event; active : bool)
  if !active
    check_shreddable()

[es(tag=server, track=battle_area__deactivatedAtTime, REQUIRE=(battle_area, humanTriggerable))]
def out_battle_area_shredder_deactivation_timer_check(evt : Event; battle_area__deactivatedAtTime : float)
  if battle_area__deactivatedAtTime > 0.f
    check_shreddable_in_deactivating_zones()
