require ecs
require ecs.common

[es(on_appear, tag=gameClient)]
def hitmarks_victim_group_id_initalizer_es(evt : Event;
                                           hitmarks_victim__group : string;
                                           var hitmarks_victim__groupId : int&)
  query() <| $ [es] (var hitmarksGroupsNamesList : StringList&)
    let index = find_index(hitmarksGroupsNamesList, hitmarks_victim__group)
    if index != -1
      hitmarks_victim__groupId = index
    else
      hitmarks_victim__groupId = length(hitmarksGroupsNamesList)
      push(hitmarksGroupsNamesList, hitmarks_victim__group)

[es(on_appear, tag=gameClient)]
def hitmarks_groups_id_initalizer_es(evt : Event;
                                     hitmarks__groups : StringList;
                                     var hitmarks__groupsIds : IntList&)
  query() <| $ [es] (var hitmarksGroupsNamesList : StringList&)
    for groupName in hitmarks__groups
      let index = find_index(hitmarksGroupsNamesList, groupName)
      if index != -1
        push(hitmarks__groupsIds, index)
      else
        push(hitmarks__groupsIds, length(hitmarksGroupsNamesList))
        push(hitmarksGroupsNamesList, groupName)
