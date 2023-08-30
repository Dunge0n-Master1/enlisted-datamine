module paratroopers_common shared

require ecs
require app
require enlisted.events_enlisted
require game.es.vehicle.vehicle_events
require game.es.artillery_aircraft_common
require game.es.stat_bq_common
require math.random
require math.base
require math.ang
require ecs.safe

def create_paratroopers_aircraft(respawnerEid : EntityId; squadId : int; memberId : int)
  query(respawnerEid) <| $ [es] (respawner__paratroopersAircraftStartPointOffset : float;
                                 respawner__paratroopersAircraftEndPointOffset : float;
                                 respawner__paratroopersAircraftHeight : float;
                                 respawner__paratroopersAircraftSpawnDist : float;
                                 respawner__paratroopersAircraftHeightOffset : float;
                                 respawner__paratroopersAircraftHeightToDistanceOffsetMult : float;
                                 [[shared_comp]] respawner__paratroopersAircraftAngels : FloatList;
                                 respawner__paratroopersAircraftTemplate : string;
                                 team aka player_team : int;
                                 var respawner__paratroopersPointCoords : float3&)
    let teamEid = get_team_eid(player_team)
    query(teamEid) <| $ [es] (paratroopersAircraftCrewAndPlaneTemplate : string;
                              var paratroopersAircraftSpawnPoints : Object&)
      var startpoint : float3
      let aircraftEid = createEntity(add_sub_template_name(paratroopersAircraftCrewAndPlaneTemplate, respawner__paratroopersAircraftTemplate)) <| $(init)
        var point = respawner__paratroopersPointCoords
        point[1] += respawner__paratroopersAircraftHeight
        var dir = calc_aircraft_request_dir(player_team)
        let dirAngelNo = rnd_int(0, length(respawner__paratroopersAircraftAngels) - 1)
        dir = rotate(dir, respawner__paratroopersAircraftAngels[dirAngelNo])

        let xAxis = float3(dir.x, 0., dir.y)
        let yAxis = float3(0., 1., 0.)
        let zAxis = cross(xAxis, yAxis)

        init |> set("team", player_team)
        init |> set("ownedByPlayer", respawnerEid)

        init |> set("paratroopers_aircraft__squadId", squadId)
        init |> set("paratroopers_aircraft__memberId", memberId)

        init |> set("startVelDir", xAxis)
        init |> set("startRelativeSpeed", 1.)

        let offset = float(team + dirAngelNo * 2) * respawner__paratroopersAircraftHeightOffset
        point[1] += offset
        startpoint = point - xAxis * (respawner__paratroopersAircraftStartPointOffset - offset * respawner__paratroopersAircraftHeightToDistanceOffsetMult)
        var isFriendAircraftObstacle = true
        let distSquare = square(respawner__paratroopersAircraftSpawnDist)

        while isFriendAircraftObstacle
          isFriendAircraftObstacle = false
          for spawnPoint in paratroopersAircraftSpawnPoints
            let pos = spawnPoint.value ?? float3()
            if distance_sq(startpoint, pos) < distSquare
              isFriendAircraftObstacle = true
              break
          isFriendAircraftObstacle ||= find_query() <| $ [es(REQUIRE=paratroopersAircraft)] (transform : float3x4; team aka friend_team : int)
            return player_team == friend_team && distance_sq(startpoint, transform[3]) < distSquare
          if isFriendAircraftObstacle
            startpoint -= xAxis * respawner__paratroopersAircraftSpawnDist

        let endpoint = point + xAxis * respawner__paratroopersAircraftEndPointOffset
        init |> set("ai_aircraft__flyPos", endpoint)
        init |> set("ai_aircraft__endPos", endpoint)
        init |> set("ai_aircraft__targetPos", point)
        init |> set("ai_aircraft__state", int(AIAircraftState FLY_TO_END))
        init |> set("paratroopers_aircraft__respawnerEid", respawnerEid)
        init |> set("paratroopers_aircraft__flyToKickTimer", get_sync_time() + 30.)
        var tm = IDENT_TM

        tm[0] = xAxis
        tm[1] = yAxis
        tm[2] = zAxis
        tm[3] = startpoint

        init |> set("transform", tm)

        point[1] -= offset + respawner__paratroopersAircraftHeight
        respawner__paratroopersPointCoords = point

        query() <| $ [es] (counter_team : int;
                           paratroopers_target_points__lifeTime : float;
                           var paratroopers_target_points : Point3List;
                           var paratroopers_target_points__eids : EidList;
                           var paratroopers_target_points__disappearanceTime : FloatList)
          if team == counter_team
            push(paratroopers_target_points, point)
            push(paratroopers_target_points__eids, respawnerEid)
            push(paratroopers_target_points__disappearanceTime, get_sync_time() + paratroopers_target_points__lifeTime)

      set(paratroopersAircraftSpawnPoints, string(uint(aircraftEid)), startpoint)
