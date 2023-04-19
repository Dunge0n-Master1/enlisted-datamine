require ecs
require app
require math.base
require game.events_game
require strings
require DngHumanAnim
require DngHuman
require DngActor
require PhysVars
require PhysDecl
require HumanPhys
require HumanAnim
require DagorMath
require DagorSystem


[es(tag=(server, net), REQUIRE=human_net_phys, REQUIRE_NOT=ragdoll, track=isAlive)]
def human_anim_disable_anim_updates_for_deadmen_server_es(evt : Event;
                                                          isAlive : bool;
                                                          var animchar__updatable : bool&)
  animchar__updatable = isAlive


[es(on_appear, before=anim_phys_init_es)]
def human_anim_set_animchar_params_es(event : Event;
                                      animcharParams : Object;
                                      var phys_vars : PhysVars)
  var params : array<int>
  var values : array<float>
  for item in animcharParams
    let k = phys_vars |> registerVar(item.key, 0.0)
    params |> push(k)
    let v = get_float(item.value) ?? 0.0
    values |> push(v)
  for i in iter_range(animcharParams)
    phys_vars |> setVar(params[i], values[i])
