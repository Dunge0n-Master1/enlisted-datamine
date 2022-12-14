options no_aot = true

require ecs
require ecs.common
require ecs.ecs_template
require game.es.net_console_macro
require DagorConsole
require strings

[ecs_template(tag=dev)]
struct dev_ai_building_debug
  aiBuilding__debugMsgs : IPoint3List

[console_cmd(name="ai.debug_building")]
def ai_debug_building()
  query() <| $ [es(REQUIRE=botPlayerDebug)] (eid : EntityId)
    addSubTemplate(eid, "dev_ai_building_debug")

def out_ai_debug(var out : string&)
  if empty(out)
    return
  let text = "AI BUILDING:{out}"
  console_print("{text}\n")
  visual_log(text)
  out = ""

[es(tag=server, no_order)]
def log_ai_debug_building(info : UpdateStageInfoAct;
                          var aiBuilding__debugMsgs : IPoint3List&)
  if empty(aiBuilding__debugMsgs)
    return

  var out = ""
  for msg in aiBuilding__debugMsgs
    let pos = "({float(msg.y) * 0.001}, {float(msg.z) * 0.001})"
    if msg.x == 100
      out_ai_debug(out)
      out = "{out} Enough rally points ({msg.y} built, {msg.z} building)"
      out_ai_debug(out)
    elif msg.x == 200
      out = "{out} !NAVMESH {pos}"
    elif msg.x == 210
      out = "{out} !WALLS {pos}"
    elif msg.x == 220
      out = "{out} !UNDERWATER {pos}"
    elif msg.x == 230
      out = "{out} !RESPAWN {pos}"
    elif msg.x == 240
      out = "{out} !CAPZONE {pos}"
    elif msg.x == 250
      out = "{out} !ABOVE {pos}"
    elif msg.x == 260
      out = "{out} !RESTRICTED {pos}"
    elif msg.x == 270
      out = "{out} !!DEFENDZONE {pos}"
    elif msg.x == 280
      out = "{out} !!OUTSIDE {pos}"
    elif msg.x == 290
      out = "{out} !!TOOMANY {pos}"
    elif msg.x == 300
      out = "{out} !INOPTIMAL {pos}"
    elif msg.x == 310
      out = "{out} !NOPATH {pos}"
    elif msg.x == 400
      out = "{out} !WRONGSIDE {pos}"
    elif msg.x == 500
      out = "{out} !DESTROYED {pos}"
    elif msg.x == 600
      out = "{out} !EXPOSED {pos}"
    elif msg.x == 700
      out_ai_debug(out)
      out = " Rally point destroyed {pos}"
      out_ai_debug(out)
    elif msg.x == 710
      out_ai_debug(out)
      out = " Rally point added to list {pos}"
      out_ai_debug(out)
    elif msg.x == 1000
      out_ai_debug(out)
      out = " Preview found, building... {pos}"
      out_ai_debug(out)
    elif msg.x == 1100
      out_ai_debug(out)
      out = " Preview wait timeout!"
      out_ai_debug(out)
    elif msg.x == 1200
      out_ai_debug(out)
      out = " Can't create building, heights differ too much! {pos}"
      out_ai_debug(out)
    elif msg.x == 1300
      out_ai_debug(out)
      out = " Creating building preview {pos}"
      out_ai_debug(out)
  out_ai_debug(out)

  clear(aiBuilding__debugMsgs)
