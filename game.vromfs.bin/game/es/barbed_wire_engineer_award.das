require ecs
require app
require game.utils.team
require common_shooter.events_common_shooter
require enlisted.events_enlisted
require EnlistedDm
require CollRes
require RendInst
require math.base

def find_nearby_barbwire(human_collres : CollisionResource; human_tm : float3x4; victim_team : int)
  var res = INVALID_ENTITY_ID
  let humanBoundingSphere = human_collres.boundingSphere

  find_query() <| $ [es(REQUIRE=barbwire)] (eid : EntityId;
                                            buildByPlayer : EntityId;
                                            transform : float3x4;
                                            ri_extra__name : string)
    var offenderTeam = TEAM_UNASSIGNED
    query(buildByPlayer) <| $ [es] (team : int)
      offenderTeam = team
    if is_teams_friendly(victim_team, offenderTeam)
      return false
    let barbwireCollres = get_rigen_extra_coll_res(get_rigen_extra_res_idx(ri_extra__name))
    if barbwireCollres != null
      let distSq = length_sq(human_tm * humanBoundingSphere.c - transform * barbwireCollres.boundingSphere.c)
      let contactDistSq = square(humanBoundingSphere.r + barbwireCollres.boundingSphere.r)
      if distSq < contactDistSq
        res = eid
        return true
    return false

  return res

[es(tag=server)]
def barbed_wire_award_for_engineer(evt : EventOnEntityHit) // broadcast
  query(evt.victim) <| $ [es(REQUIRE_NOT=deadEntity)] (collres : CollisionResource&;
                                                       transform : float3x4;
                                                       team : int;
                                                       engineer_barbwire_award__maxActivations : int;
                                                       engineer_barbwire_award__updateInterval : float;
                                                       var engineer_barbwire_award__activationCount : int&;
                                                       var engineer_barbwire_award__nextUpdateTime : float&)
    if evt.damageType == int(DamageType DM_BARBWIRE) && engineer_barbwire_award__activationCount < engineer_barbwire_award__maxActivations
      let time = get_sync_time()
      if time > engineer_barbwire_award__nextUpdateTime
        let barbwire = find_nearby_barbwire(collres, transform, team)
        if !!barbwire
          engineer_barbwire_award__nextUpdateTime = time + engineer_barbwire_award__updateInterval
          sendEvent(barbwire, [[EventOnBarbwireDamageAward]])
          engineer_barbwire_award__activationCount ++
