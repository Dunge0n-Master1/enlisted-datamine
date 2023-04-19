options no_global_variables = false
require DagorConsole
require DagorMath
require DagorSystem
require ecs
require game.es.events
require GridCollision
require Grid
require matching
require math
require math.base
require DngNet
require net
require player

var error_logged_initial = false
var error_logged_default = false
var error_logged_grid = false
var error_logged_runtime = false

let NET_SCOPE_LOOT_FIXED_RADIUS = 50f
let NET_SCOPE_DOORS_FIXED_RADIUS = 330f
let ENTITY_BEHIND_DIST_MULT = 8u
// All entities that doesn't have transform component (and doesn't have parent/owner) assume to be this meters away from POI
let NON_POS_ENTITIES_DIST_SQ = 10000u

struct EntDistRec
  obj : NetObject?
  cmp : uint64

def do_add_entity_in_net_scope(var conn : IConnection?;
                               var no : NetObject&;
                               var errlogged : bool&)
  if setObjectInScopeAlways(*conn, no) || errlogged
    return
  let noEid = no.eid
  let noId = int(uint(noEid))
  let templateName = getEntityTemplateName(noEid)
  let connId = connection_getId(*conn)
  let plrEid = find_player_eid_for_connection(conn)
  let plrUserId = get_uint64(plrEid, "userid") ?? INVALID_USER_ID
  let plrName = get_string(plrEid, "name", "")
  logerr("Failed to add entity {noId}<{templateName}> into net scope for conn=#{connId},user\{name,id\}=<{plrName}>/{int(plrUserId)}. MaxReplicas limit reached?\nEntity histogram dumped in log.")
  console_command("ecs.entity_histogram 0") // 0 means whole histogram
  errlogged = true

def ordered_add_entities_in_net_scope(callsite : string;
                                      var conn : IConnection?;
                                      var entdist : array<EntDistRec>;
                                      var errlogged : bool&;
                                      reft : uint64;
                                      view_pos : float3 = float3())
  entdist |> sort() <| $(left : EntDistRec; right : EntDistRec)
    return left.cmp < right.cmp
  for ed in entdist
    do_add_entity_in_net_scope(conn, *ed.obj, errlogged)
  let len = length(entdist)
  let first = ((len != 0) ? int(uint(entdist[0].obj.eid)) : 0)
  let last = ((len != 0) ? int(uint(entdist[len - 1].obj.eid)) : 0)
  let at = "{view_pos.x}, {view_pos.y}, {view_pos.z}"
  let connId = connection_getId(*conn)
  let usec = int64(profile_usec_from_ticks_delta(profile_ref_ticks() - reft))
  print("{callsite}: added (approx) {len} entities (first={first}, last={last}) in net scope (viewer_at={at}) for conn #{connId} for {usec} us")

def push(var entdist : array<EntDistRec>&; var replication : NetObject?; distSq : uint = NON_POS_ENTITIES_DIST_SQ)
  // First comparing by distance, then by creation order
  let cmp : uint64 = (uint64(distSq) << uint64(32)) | uint64(replication.creationOrder)
  entdist |> push() <| [[EntDistRec obj=replication, cmp=cmp]]

def push(var entdist : array<EntDistRec>&; var replication : NetObject?; ent_pos : float3;
         view_pos : float3; view_fwd : float3; scope_dist_sq : float = FLT_MAX)
  let dirToEnt = ent_pos - view_pos
  let distToEntSq = length_sq(dirToEnt)
  if distToEntSq > scope_dist_sq
    return
  var distSq = uint(distToEntSq)
  if dot(view_fwd, dirToEnt) < 0f // entities behind viewer has lower priority
    distSq *= ENTITY_BEHIND_DIST_MULT
  entdist |> push(replication, distSq)

[es(tag=(server, net))]
def add_initial_entities_in_net_scope(evt : CmdAddInitialEntitiesInNetScope)
  let reft = profile_ref_ticks()
  var conn : IConnection? = evt.connid |> get_client_connection()
  assert(conn != null)
  var entdist : array<EntDistRec>
  query() <| $ [es(REQUIRE=(net__inInitialScope, replication))] (var replication : NetObject?)
    entdist |> push(replication)
  query() <| $ [es(REQUIRE=replication, REQUIRE_NOT=(transform, net__notInInitialScope))] (var replication : NetObject?)
    entdist |> push(replication)
  ordered_add_entities_in_net_scope("add_initial_entities_in_net_scope", conn, entdist, error_logged_initial, reft)

[es(tag=(server, net))]
def add_default_entities_in_net_scope(evt : CmdAddDefaultEntitiesInNetScope)
  let reft = profile_ref_ticks()
  var conn : IConnection? = evt.connid |> get_client_connection()
  assert(conn != null)
  let view_pos = evt.viewPos
  let view_fwd = evt.viewFwd
  var entdist : array<EntDistRec>

  query() <| $ [es(REQUIRE=(net__alwaysInScope, replication))] (var replication : NetObject?; transform : float3x4 const?)
    if transform != null
      entdist |> push(replication, (*transform)[3], view_pos, view_fwd)
    else
      entdist |> push(replication)

  query() <| $ [es(REQUIRE_NOT=net__scopeDistanceSq, REQUIRE=replication)] (var replication : NetObject?; transform : float3x4)
    entdist |> push(replication, transform[3], view_pos, view_fwd)

  query() <| $ [es(REQUIRE_NOT=(net__scopeDistanceSq, transform),
                   REQUIRE=replication)] (var replication : NetObject?; slot_attach__attachedTo : EntityId)
    var attachTransform = get_TMatrix(slot_attach__attachedTo, "transform")
    if attachTransform == null
      // Assume that two levels of nesting is enough (e.g. scope -> gun -> human)
      let attachedTo = get_Eid(slot_attach__attachedTo, "slot_attach__attachedTo") ?? INVALID_ENTITY_ID
      attachTransform = get_TMatrix(attachedTo, "transform")

    if attachTransform != null
      entdist |> push(replication, (*attachTransform)[3], view_pos, view_fwd)
    elif !connection_isEntityInScope(*conn, replication.eid) // Assume that most of non pos entities should be already added in initial step
      entdist |> push(replication)

  query() <| $ [es(REQUIRE_NOT=(net__scopeDistanceSq, transform, slot_attach__attachedTo),
                   REQUIRE=replication)] (var replication : NetObject?;
                                          item__ownerEid : EntityId = INVALID_ENTITY_ID;
                                          gun__owner : EntityId = INVALID_ENTITY_ID;
                                          turret__owner : EntityId = INVALID_ENTITY_ID)
    var ownerTransform = get_TMatrix(item__ownerEid, "transform")
    if ownerTransform == null
      ownerTransform = get_TMatrix(gun__owner, "transform")
    if ownerTransform == null
      ownerTransform = get_TMatrix(turret__owner, "transform")
    if ownerTransform != null
      entdist |> push(replication, (*ownerTransform)[3], view_pos, view_fwd)
    elif !connection_isEntityInScope(*conn, replication.eid) // Assume that most of non pos entities should be already added in initial step
      entdist |> push(replication)

  for_each_entity_in_grid(ecs_hash("doors"), BSphere3(view_pos, NET_SCOPE_DOORS_FIXED_RADIUS / 3f), GridEntCheck POS) <| $(eid : EntityId; pos : float3)
    query(eid) <| $ [es(REQUIRE=(replication, net__scopeDistanceSq))] (var replication : NetObject?)
      // doors are added with max distance anyway, so don't waste cpu cycles onto check net__scopeDistanceSq
      entdist |> push(replication, pos, view_pos, view_fwd)

  for_each_entity_in_grid(ecs_hash("loot"), BSphere3(view_pos, NET_SCOPE_LOOT_FIXED_RADIUS / 2f), GridEntCheck POS) <| $(eid : EntityId; pos : float3)
    query(eid) <| $ [es(REQUIRE=(replication))] (var replication : NetObject?; net__scopeDistanceSq : float)
      entdist |> push(replication, pos, view_pos, view_fwd, net__scopeDistanceSq)

  // Note: this query is only needed because entities *bag_item's (like large_cuisine_bag_item) always have
  // overridden net__scopeDistanceSq, but transform exist only when it's added in world (i.e not attached to human).
  // Todo: fix it in templates (something like bag_item_in_world {_extend:"item_in_world";} and remove this query
  query() <| $ [es(REQUIRE=(replication, net__scopeDistanceSq),
                   REQUIRE_NOT=transform)] (var replication : NetObject?;
                                            slot_attach__attachedTo : EntityId = INVALID_ENTITY_ID)
    var attachTransform = get_TMatrix(slot_attach__attachedTo, "transform")
    if attachTransform != null
      entdist |> push(replication, (*attachTransform)[3], view_pos, view_fwd)
    else
      entdist |> push(replication)

  ordered_add_entities_in_net_scope("add_default_entities_in_net_scope", conn, entdist, error_logged_default, reft, view_pos)

// Monotonically increasing counter used to infer a connections, being processed in current frame
var netScopeGridAdderCounter = 0u

def add_grid_entity_if_close_enough(lat : float3; var conn : IConnection?; eid : EntityId; var replication : NetObject&; transform : float3x4; net__scopeDistanceSq : float)
  if !connection_isEntityInScope(*conn, eid)
    let distToPosSqX = length_sq(lat - transform[3])
    if distToPosSqX < net__scopeDistanceSq
      do_add_entity_in_net_scope(conn, replication, error_logged_grid)

def add_grid_entity_if_close_enough(lat : float3; var conn : IConnection?; eid : EntityId)
  if !connection_isEntityInScope(*conn, eid)
    query(eid) <| $ [es] (var replication : NetObject&; transform : float3x4; net__scopeDistanceSq : float)
      let distToPosSqX = length_sq(lat - transform[3])
      if distToPosSqX < net__scopeDistanceSq
        do_add_entity_in_net_scope(conn, replication, error_logged_grid)

[es(tag=(server, net), no_order)]
def net_scope_grid_adder_es(info : UpdateStageInfoAct)
  // processing approx NET_MAX_PLAYERS * 2 connections per second
  get_client_connections() <| $(connections)
    var procNConns = uint(float(NET_MAX_PLAYERS) * float(2) * info.dt)
    while procNConns > 0u
      // connIdX2 goes through [0..(NET_MAX_PLAYERS * 2)] each second
      let connIdX2 : uint = netScopeGridAdderCounter % uint(NET_MAX_PLAYERS * 2)
      // connId goes through [0..NET_MAX_PLAYERS, 0..NET_MAX_PLAYERS] each second
      // in other words it goes through [0..NET_MAX_PLAYERS] each half second
      let connId : uint = netScopeGridAdderCounter % uint(NET_MAX_PLAYERS)
      if int(connId) >= length(connections)
        // skipping non-active connections, but not skipping over NET_MAX_PLAYERS
        let skip = min(procNConns, uint(NET_MAX_PLAYERS) - connId)
        procNConns -= skip
        netScopeGridAdderCounter += skip
        continue
      procNConns--
      netScopeGridAdderCounter++

      var conn : IConnection? = connections[connId]
      if conn == null
        continue
      let player_eid : EntityId = conn |> find_player_eid_for_connection()
      query(player_eid) <| $ [es] (clientNetFlags : int)
        let lookingAt : LookingAt = player_eid |> player_get_looking_at()
        let lat : float3 const? = lookingAt.pos
        if lat == null
          return
        let doReplicate : bool = (clientNetFlags & int(ClientNetFlags CNF_REPLICATE_PHYS_ACTORS)) != 0
        if doReplicate == false
          return
        if connIdX2 < uint(NET_MAX_PLAYERS)
          ecs::query() <| $ [es(REQUIRE=isDoor)] (eid : EntityId; var replication : NetObject&; transform : float3x4; net__scopeDistanceSq : float)
            add_grid_entity_if_close_enough(*lat, conn, eid, replication, transform, net__scopeDistanceSq)
        for_each_entity_in_grid(ecs_hash("loot"), BSphere3(*lat, NET_SCOPE_LOOT_FIXED_RADIUS), GridEntCheck POS) <| $(eid : EntityId)
          add_grid_entity_if_close_enough(*lat, conn, eid)

def server_scope_adder_impl(var replication : NetObject&; always_in_scope : bool)
  get_client_connections() <| $(connections)
    for connId in range(0, length(connections))
      var conn : IConnection? = connections[connId]
      if conn == null
        continue
      let player_eid : EntityId = conn |> find_player_eid_for_connection()
      query(player_eid) <| $ [es] (clientNetFlags : int)
        let doReplicate : bool = (clientNetFlags & int(ClientNetFlags CNF_REPLICATE_PHYS_ACTORS)) != 0
        if doReplicate || always_in_scope
          do_add_entity_in_net_scope(conn, replication, error_logged_runtime)

[es(tag=(server, net), on_appear, REQUIRE_NOT=net__scopeDistanceSq)]
def server_scope_adder_es(evt : Event; var replication : NetObject&)
  replication |> server_scope_adder_impl(false)

[es(tag=(server, net), on_appear, REQUIRE=net__alwaysInScope)]
def server_always_scope_adder_es(evt : Event; var replication : NetObject&)
  replication |> server_scope_adder_impl(true)

[es(tag=(server, net), on_event=EventEntityRecreated, REQUIRE_NOT=transform)]
def net_scope_on_recreate_adder_es(evt : Event; var replication : NetObject&)
  replication |> server_scope_adder_impl(false)

[es(tag=(server, net, recordingReplay), on_appear)]
def net_scope_add_replay_es(evt : Event; var replication : NetObject&)
  var conn : IConnection? = get_replay_connection()
  if conn != null
    *conn |> setObjectInScopeAlways(replication)
