require ecs
require game.es.events
require math.base
require Dacoll
require player
require game.utils.team

def is_capzone_smoke_enabled()
  return (find_query() <| $ [es(REQUIRE=gamemodeCapzoneSmoke)] () => true)

def create_capzone_smoke(smoke_template : string; pos : float3; drop_height : float)
  return createEntity(smoke_template) <| $(init)
    var tm : float3x4 = IDENT_TM
    tm[3] = pos

    let traceStart = pos + float3(0.f, drop_height, 0.f)
    var height = drop_height * 2.0
    if tracedown_normalized(traceStart, height, ETF_DEFAULT)
      tm[3].y = traceStart.y - height
    init |> set("transform", tm)

def get_smoke_template(capzone__owningTeam, capzone__onlyTeamCanCapture : int;
                       friendly_template, neutral_template, enemy_template : string) : string
  var res = neutral_template
  query(get_local_player_eid()) <| $ [es] (team : int)
    let isDefendZone = capzone__onlyTeamCanCapture >= 0 && capzone__onlyTeamCanCapture != team
    let isAttackZone = capzone__onlyTeamCanCapture >= 0 && capzone__onlyTeamCanCapture == team
    if capzone__owningTeam == team || isDefendZone
      res = friendly_template
    elif capzone__owningTeam != TEAM_UNASSIGNED || isAttackZone
      res = enemy_template
  return res

[es(tag=render, on_appear, on_event=EventLevelLoaded, track=active, REQUIRE=capzone)]
def manage_capzone_smoke_signal(evt : Event;
                                active : bool;
                                transform : float3x4;
                                capzone__smokeTemplateFriendly : string;
                                capzone__smokeTemplateNeutral : string;
                                capzone__smokeTemplateEnemy : string;
                                capzone__owningTeam : int;
                                capzone__onlyTeamCanCapture : int = TEAM_UNASSIGNED;
                                capzone__smokeDropHeight : float;
                                var capzone__smokeEid : EntityId&)
  if !is_capzone_smoke_enabled()
    return
  if !active
    destroyEntity(capzone__smokeEid)
    capzone__smokeEid = INVALID_ENTITY_ID
  else
    if !!capzone__smokeEid
      destroyEntity(capzone__smokeEid)
    let smokeTemplate = get_smoke_template(capzone__owningTeam, capzone__onlyTeamCanCapture,
      capzone__smokeTemplateFriendly, capzone__smokeTemplateNeutral, capzone__smokeTemplateEnemy)
    capzone__smokeEid = create_capzone_smoke(smokeTemplate, transform[3], capzone__smokeDropHeight)

[es(tag=render, track=capzone__owningTeam)]
def capzone_change_smoke_color(evt : Event;
                               capzone__owningTeam : int;
                               capzone__onlyTeamCanCapture : int = TEAM_UNASSIGNED;
                               capzone__smokeTemplateFriendly : string;
                               capzone__smokeTemplateNeutral : string;
                               capzone__smokeTemplateEnemy : string;
                               capzone__smokeDropHeight : float;
                               transform : float3x4;
                               var capzone__smokeEid : EntityId&)
  if !capzone__smokeEid
    return
  let smokeTemplate = get_smoke_template(capzone__owningTeam, capzone__onlyTeamCanCapture,
    capzone__smokeTemplateFriendly, capzone__smokeTemplateNeutral, capzone__smokeTemplateEnemy)
  destroyEntity(capzone__smokeEid)
  capzone__smokeEid = create_capzone_smoke(smokeTemplate, transform[3], capzone__smokeDropHeight)

[es(tag=render, REQUIRE=capzone)]
def delete_smoke_on_capzone_destroy(evt : EventEntityDestroyed; capzone__smokeEid : EntityId)
  destroyEntity(capzone__smokeEid)
