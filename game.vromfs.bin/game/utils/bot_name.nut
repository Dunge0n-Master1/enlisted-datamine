
let {generatedNames, botSuffix} = require("%scripts/game/utils/generated_names.nut")
let pickword = require("%sqstd/random_pick.nut")

local usedNames = {}

local function get_gen_bot_name(seed) {
  let allow_cache = true
  local name
  do {
    name = $"{pickword(generatedNames, seed++, allow_cache)}{botSuffix}"
  } while (name in usedNames)
  usedNames[name] <- true
  return name
}

let function clear_used_bot_names() {
  usedNames = {}
}

return {
  get_gen_bot_name,
  clear_used_bot_names
}