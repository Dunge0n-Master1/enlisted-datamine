require ecs
require DagorInput

def private set_input_disable(eid : EntityId; tutorial_input__disable : StringList; var tutorial__savedInput : Object&)
  for key in tutorial_input__disable
    let input = string(key)
    let inputHash = ecs_hash(input)
    let value = get_int(eid, input, inputHash) ?? int(BAD_ACTION_HANDLE)
    if tutorial__savedInput[input] == null
      tutorial__savedInput |> set(input, value)
    if value != int(BAD_ACTION_HANDLE)
      setOptional(eid, input, inputHash, int(BAD_ACTION_HANDLE))

def private set_input_enable(eid : EntityId; tutorial_input__enable : StringList; tutorial__savedInput : Object)
  for input in tutorial_input__enable
    let key = string(input)
    let value = tutorial__savedInput |> get_int(key) ?? int(BAD_ACTION_HANDLE)
    if value != int(BAD_ACTION_HANDLE)
      setOptional(eid, key, ecs_hash(key), value)

[es(on_appear, REQUIRE=human_input)]
def tutorial_input_human_init_es(evt : Event; eid : EntityId)
  query() <| $ [es] (tutorial__savedInput : Object)
    for input in tutorial__savedInput
      setOptional(eid, input.key, ecs_hash(input.key), int(BAD_ACTION_HANDLE))

[es(on_appear)]
def tutorial_input_disable_es(evt : Event; tutorial_input__disable : StringList)
  query() <| $ [es] (var tutorial__savedInput : Object&)
    query() <| $ [es(REQUIRE=human_input)] (eid : EntityId)
      set_input_disable(eid, tutorial_input__disable, tutorial__savedInput)

[es(on_appear)]
def tutorial_input_enable_es(evt : Event; tutorial_input__enable : StringList)
  query() <| $ [es] (var tutorial__savedInput : Object&)
    query() <| $ [es(REQUIRE=human_input)] (eid : EntityId)
      set_input_enable(eid, tutorial_input__enable, tutorial__savedInput)
    for input in tutorial_input__enable
      tutorial__savedInput |> erase(string(input))
