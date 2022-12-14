options no_aot

require ecs
require DagorConsole
require DagorDebug3D
require ecs.ecs_template

[ecs_template]
struct turret_ai_debug
  turret_ai__debug : Tag
  turret_ai__debugDrawFrames : int

[console_cmd(name="turret_ai.draw_shoot_pos")]
def turret_ai_draw_shoot_pos_console_cmd(activate : bool = true; frames : int = 1000)
  if activate
    query() <| $ [es(REQUIRE=controlledByAiGunner, REQUIRE_NOT=turret_ai__debug)] (eid : EntityId)
      addSubTemplate(eid, "turret_ai_debug") <| $(var init)
        init |> set("turret_ai__debugDrawFrames", frames)
  else
    query() <| $ [es(REQUIRE=turret_ai__debug)] (eid : EntityId)
      removeSubTemplate(eid, "turret_ai_debug")

[es(REQUIRE=turret_ai__debug, after=turret_ai_gunner_aim)]
def turret_ai_debug(evt : UpdateStageInfoAct; turret_aim__shootToPos : float3; turret_ai__debugDrawFrames : int)
  draw_debug_sphere_buffered(turret_aim__shootToPos, 0.1, E3DCOLOR(0xFFFF0000), turret_ai__debugDrawFrames)
