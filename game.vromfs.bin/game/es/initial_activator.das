require ecs
require game.es.capzones_common
require game.utils.team
require game.events_game


def two_chains_capzone_init(var nextGroupFound : bool&;
                            var nextGroup : string&;
                            var capzone__alwaysShow : bool&;
                            var capzone__lastZoneForTeam : int&;
                            var capzone__prevActivate : das_string&;
                            var capzone__nextActivate : das_string&;
                            var capzone__owningTeam : int&;
                            var capzone__capTeam : int&;
                            var capzone__progress : float&;
                            capzone__activateChoice : Object;
                            prevGroupName : string;
                            enemyTeam : int;
                            team : int)
  capzone__alwaysShow = true
  if !capzone__activateChoice.empty
    nextGroupFound = true
    nextGroup = select_random_choice(capzone__activateChoice)
  else
    capzone__lastZoneForTeam = team
  capzone__prevActivate := prevGroupName
  capzone__nextActivate := nextGroup
  capzone__owningTeam = enemyTeam
  capzone__progress = 1.
  capzone__capTeam = enemyTeam
  query() <| $ [es] (team__id : int;
                     var team__numZonesCaptured : int&)
    if team__id == team
      ++team__numZonesCaptured


def init_next_choice(currentGroupName : string;
                     current_ui_order : int)
  var nextGroupFound = false
  var nextGroup = ""
  query() <| $ [es(REQUIRE=capzone)] (groupName : string;
                                      capzone__activateChoice : Object;
                                      var capzone__activateAfterCap : das_string&;
                                      var capzone__alwaysShow : bool&;
                                      var ui_order : int&)
    if currentGroupName != groupName
      return
    capzone__alwaysShow = true
    if !capzone__activateChoice.empty
      nextGroupFound = true
      nextGroup = select_random_choice(capzone__activateChoice)
    capzone__activateAfterCap := nextGroup
    ui_order = current_ui_order
  if nextGroupFound && nextGroup != currentGroupName
    return 1 + init_next_choice(nextGroup, current_ui_order + 1)
  return 1


def init_next_choice_team2(prevGroupName : string;
                           currentGroupName : string)
  var capzoneEid = INVALID_ENTITY_ID
  var nextGroupFound = false
  var nextGroup = ""
  let enemyTeam = 1
  let team = 2
  query() <| $ [es(REQUIRE=capzone)] (eid : EntityId;
                                      groupName : string;
                                      capzone__activateChoiceTeam2 : Object;
                                      var capzone__activateAfterTeam1Cap : das_string&;
                                      var capzone__activateAfterTeam2Cap : das_string&;
                                      var capzone__alwaysShow : bool&;
                                      var capzone__owningTeam : int&;
                                      var capzone__progress : float&;
                                      var capzone__capTeam : int&;
                                      var capzone__lastZoneForTeam : int&)
    if currentGroupName != groupName
      return
    capzoneEid = eid
    two_chains_capzone_init(nextGroupFound,
                            nextGroup,
                            capzone__alwaysShow,
                            capzone__lastZoneForTeam,
                            capzone__activateAfterTeam1Cap,
                            capzone__activateAfterTeam2Cap,
                            capzone__owningTeam,
                            capzone__capTeam,
                            capzone__progress,
                            capzone__activateChoiceTeam2,
                            prevGroupName,
                            enemyTeam,
                            team)
  var numChoices = 0
  if nextGroupFound && nextGroup != currentGroupName
    numChoices = init_next_choice_team2(currentGroupName, nextGroup)
  query(capzoneEid) <| $ [es] (var ui_order : int&)
    ui_order = numChoices
  return 1 + numChoices


def init_next_choice_team1(prevGroupName : string;
                           currentGroupName : string;
                           current_ui_order : int)
  var nextGroupFound = false
  var nextGroup = ""
  let enemyTeam = 2
  let team = 1
  query() <| $ [es(REQUIRE=capzone)] (groupName : string;
                                      capzone__activateChoiceTeam1 : Object;
                                      var capzone__activateAfterTeam1Cap : das_string&;
                                      var capzone__activateAfterTeam2Cap : das_string&;
                                      var capzone__alwaysShow : bool&;
                                      var capzone__owningTeam : int&;
                                      var capzone__progress : float&;
                                      var capzone__capTeam : int&;
                                      var capzone__lastZoneForTeam : int&;
                                      var ui_order : int&)
    if currentGroupName != groupName
      return
    ui_order = current_ui_order + 1
    two_chains_capzone_init(nextGroupFound,
                            nextGroup,
                            capzone__alwaysShow,
                            capzone__lastZoneForTeam,
                            capzone__activateAfterTeam2Cap,
                            capzone__activateAfterTeam1Cap,
                            capzone__owningTeam,
                            capzone__capTeam,
                            capzone__progress,
                            capzone__activateChoiceTeam1,
                            prevGroupName,
                            enemyTeam,
                            team)
  if nextGroupFound && nextGroup != currentGroupName
    return 1 + init_next_choice_team1(currentGroupName, nextGroup, current_ui_order + 1)
  return 1


def init_next_choice_bidirectional_two_chaines(currentGroupName : string)
  var capzoneEid = INVALID_ENTITY_ID
  var nextGroupTeam2Found = false
  var nextGroupTeam1Found = false
  var nextGroupTeam2 = ""
  var nextGroupTeam1 = ""
  query() <| $ [es(REQUIRE=capzone)] (eid : EntityId;
                                      groupName : string;
                                      capzone__activateChoiceTeam1 : Object;
                                      capzone__activateChoiceTeam2 : Object;
                                      var capzone__activateAfterTeam1Cap : das_string&;
                                      var capzone__activateAfterTeam2Cap : das_string&;
                                      var capzone__alwaysShow : bool&)
    if currentGroupName != groupName
      return
    capzone__alwaysShow = true
    if !capzone__activateChoiceTeam2.empty
      nextGroupTeam2Found = true
      nextGroupTeam2 = select_random_choice(capzone__activateChoiceTeam2)
    capzone__activateAfterTeam2Cap := nextGroupTeam2
    if !capzone__activateChoiceTeam1.empty
      nextGroupTeam1Found = true
      nextGroupTeam1 = select_random_choice(capzone__activateChoiceTeam1)
    capzone__activateAfterTeam1Cap := nextGroupTeam1
    capzoneEid = eid
  var numChoices = 0
  if nextGroupTeam2Found && nextGroupTeam2 != currentGroupName
    numChoices = init_next_choice_team2(currentGroupName, nextGroupTeam2)
  query(capzoneEid) <| $ [es] (var ui_order : int&)
    ui_order = numChoices
  if nextGroupTeam1Found && nextGroupTeam1 != currentGroupName
    numChoices = max(numChoices, init_next_choice_team1(currentGroupName, nextGroupTeam1, numChoices + 1))
  return numChoices


def init_next_choice_bidirectional_one_chain(prevGroupName : string;
                                             currentGroupName : string;
                                             current_ui_order : int)
  var nextGroupFound = false
  var nextGroup = ""
  query() <| $ [es(REQUIRE=capzone)] (groupName : string;
                                      capzone__activateBidirectionalChoice : Object;
                                      var capzone__activateAfterTeam1Cap : das_string&;
                                      var capzone__activateAfterTeam2Cap : das_string&;
                                      var capzone__onlyTeamCanCapture : int&;
                                      var capzone__alwaysShow : bool&;
                                      var ui_order : int&)
    if currentGroupName != groupName
      return
    if prevGroupName == ""
      capzone__onlyTeamCanCapture = 1
    capzone__alwaysShow = true
    if !capzone__activateBidirectionalChoice.empty
      nextGroupFound = true
      nextGroup = select_random_choice(capzone__activateBidirectionalChoice)
    capzone__activateAfterTeam1Cap := nextGroup
    capzone__activateAfterTeam2Cap := prevGroupName
    ui_order = current_ui_order
    if !nextGroupFound
      capzone__onlyTeamCanCapture = capzone__onlyTeamCanCapture == 1 ? TEAM_UNASSIGNED : 2
  var numChoices = 1
  if nextGroupFound && nextGroup != currentGroupName
    numChoices += init_next_choice_bidirectional_one_chain(currentGroupName, nextGroup, current_ui_order + 1)
    return numChoices
  activate_group(currentGroupName)
  return numChoices


[es(tag=server, on_event=EventLevelLoaded, before=(init_choice_es, init_choice_bidirectional_two_chains_es))]
def reset_active_for_activatable_on_level_loaded_es(evt : Event)
  let hasEnabledActivators = find_query() <| $ [es] (activator__enabled : bool)
    return activator__enabled
  if !hasEnabledActivators
    return
  query() <| $ [es] (groupName : string;
                     var active : bool&)
    if groupName != "" && active
      active = false

[es(tag=server, on_event=EventLevelLoaded, before=session_stated_es)]
def init_choice_es(evt : Event;
                   activator__enabled : bool;
                   activator__initialLength : int;
                   activator__activateChoice : Object)
  if !activator__enabled
    return
  if !activator__activateChoice.empty
    let initialGroup = select_random_choice(activator__activateChoice)
    activate_group(initialGroup)
    let numChoices = (init_next_choice(initialGroup, 0) +
                      init_next_choice_bidirectional_two_chaines(initialGroup))
    let mult = activator__initialLength > 0 ? float(numChoices) / float(activator__initialLength) : 1.
    query() <| $ [es] (var team__score : float&;
                       var team__scoreCap : float&)
      team__score *= mult
      team__scoreCap *= mult


[es(tag=server, on_event=EventLevelLoaded)]
def init_choice_bidirectional_two_chains_es(evt : Event;
                                            activator__enabled : bool;
                                            activator__initialLength : int;
                                            activator__activateBidirectionalChoice : Object;
                                            activator__currentGroupNameForTeam1 : string;
                                            activator__currentGroupNameForTeam2 : string)
  if !activator__enabled
    return
  if !activator__activateBidirectionalChoice.empty
    let initialGroup = select_random_choice(activator__activateBidirectionalChoice)
    activate_group(initialGroup)
    let numChoices = init_next_choice_bidirectional_one_chain("", initialGroup, 0)
    let mult = activator__initialLength > 0 ? float(numChoices) / float(activator__initialLength) : 1.
    query() <| $ [es] (var team__score : float&;
                       var team__scoreCap : float&)
      team__score *= mult
      team__scoreCap *= mult
  activate_group(activator__currentGroupNameForTeam1)
  activate_group(activator__currentGroupNameForTeam2)