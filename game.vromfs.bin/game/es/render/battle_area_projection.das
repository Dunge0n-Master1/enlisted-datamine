require ecs
require enlisted.events_enlisted
require DagorMath
require math.base
require DagorStdGuiRender
require DagorDriver3D
require DngUI
require game.utils.team


def world_to_screen(worldPos : float3) : float2
  var uiViewTm : float3x4
  get_ui_view_tm(uiViewTm)
  let screenSize = StdGuiRender_screen_size()
  let halfScreen = screenSize * 0.5
  var wk : float
  var hk : float
  get_Driver3dPerspective() <| $(pers : Driver3dPerspective#)
    wk = pers.wk
    hk = pers.hk

  let sp = uiViewTm * worldPos
  let screenPos = float2(safediv(sp.x, sp.z) * wk * halfScreen.x, safediv(-sp.y, sp.z) * hk * halfScreen.y) + halfScreen
  return screenPos

[es(tag=gameClient, track=camera__accuratePos)]
def battle_area_screen_projection(evt : Event;
                                  camera__accuratePos : DPoint3;
                                  camera__target : EntityId)
  find_query() <| $ [es] (battle_area__activeBattleAreasPolygon : Point2List;
                          battle_area__projectionOnDist : float;
                          var battle_area__projectionOn : bool&;
                          var battle_area__activeBattleAreasScreenProjections : FloatList)
    battle_area__projectionOn = false
    query(camera__target) <| $ [es] (respawn_camera__lookAt : float3;
                                     respawn_camera__lookAtCurrent : float3;
                                     transform : float3x4;
                                     respawn_camera__lookSide : bool)
      if (!respawn_camera__lookSide &&
          distance_sq(respawn_camera__lookAt, respawn_camera__lookAtCurrent) < battle_area__projectionOnDist &&
          distance_sq(transform[3], float3(camera__accuratePos)) < battle_area__projectionOnDist)
        battle_area__projectionOn = true
        clear(battle_area__activeBattleAreasScreenProjections)
        let screenSize = StdGuiRender_screen_size()
        for point in battle_area__activeBattleAreasPolygon
          let worldPos = float3(point.x, 0., point.y)
          var screenPos = world_to_screen(worldPos)
          screenPos = float2(screenPos.x / screenSize.x * 100., screenPos.y / screenSize.y * 100.)
          push(battle_area__activeBattleAreasScreenProjections, screenPos.x)
          push(battle_area__activeBattleAreasScreenProjections, screenPos.y)
    return true