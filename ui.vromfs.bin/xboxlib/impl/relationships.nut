let rel = require("xbox.relationships")
let { subscribe, subscribe_onehit } = require("eventbus")


let function retrieve_related_people_list(callback) {
  let eventName = "xbox_get_related_people_list"
  subscribe_onehit(eventName, function(res) {
    let xuids = res?.xuids
    callback?(xuids)
  })
  rel.get_related_people_list(eventName)
}


let function retrieve_avoid_people_list(callback) {
  let eventName = "xbox_get_avoid_people_list"
  subscribe_onehit(eventName, function(res) {
    let xuids = res?.xuids
    callback?(xuids)
  })
  rel.get_avoid_people_list(eventName)
}


let function retrieve_muted_people_list(callback) {
  let eventName = "xbox_get_get_muted_people_list"
  subscribe_onehit(eventName, function(res) {
    let xuids = res?.xuids
    callback?(xuids)
  })
  rel.get_muted_people_list(eventName)
}


let function subscribe_to_relationships_change_events(callback) {
  let eventName = "relationships_changed"
  subscribe(eventName, function(res) {
    let list = res?.list
    let change_type = res?.type
    let xuids = res?.xuids
    callback?(list, change_type, xuids)
  })
}


return {
  ListType = rel.ListType
  ChangeType = rel.ChangeType

  retrieve_related_people_list
  retrieve_avoid_people_list
  retrieve_muted_people_list

  subscribe_to_relationships_change_events
}