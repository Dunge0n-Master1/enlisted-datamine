require ecs
require game.es.player_events
require ecs.ecs_template

[ecs_template]
struct game_with_developer
  gameWithDeveloper : Tag

let developers = [[int[]
  1942786;
  83242353;
  415516;
  130554368;
  1488794;
  31525309;
  569137;
  10666297;
  103399819;
  100311646;
  105859752;
  127347718;
  91582970;
  88761617;
  30769899;
  120217917;
  94184962;
  3314713;
  111944497;
  86058421;
  130306219;
  1114500;
  63583289;
  129256330;
  15877073;
  50984663;
  78983890;
  115397823;
  106054965;
  78992476;
  123285099;
  102965778;
  124558300;
  26131170;
  92364932;
  113079031;
  139979429
]]

def is_developer(userid : int)
  return developers |> find_index(userid) >= 0

[es(tag=server)]
def mark_game_with_developers_on_player_connect(evt : EventOnPlayerConnected; userid : uint64)
  if is_developer(int(userid)) && !(find_query() <| $ [es(REQUIRE=gameWithDeveloper)] () => true)
    createEntity("game_with_developer")
