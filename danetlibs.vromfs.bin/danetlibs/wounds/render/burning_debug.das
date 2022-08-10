options no_aot
require danetlibs.wounds.render.burning_common
require ecs
require DagorConsole

[console_cmd(name="wounds.apply_burning")]
def apply_burning_cmd(burning_state : int)
  query() <| $ [es(REQUIRE=burning__isBurning)] (attaches_list : EidList)
    set_burning_params(attaches_list, burning_state)
