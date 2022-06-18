options no_aot
require ecs
require ecs.common
require player
require DagorConsole
require DagorSystem
require game.utils.hero
require game.events_game


[console_cmd(name="player.enable_tps_camera")]
def player_enable_tps_camera()
  find_query() <| $ [es(REQUIRE=hero)] (var camNames : Array; human_anim__vehicleSelected : EntityId)
    if find_index(camNames, "dev_tps_cam") < 0
      push(camNames, "dev_tps_cam")
    query(human_anim__vehicleSelected) <| $ [es] (var camNames : Array)
      if find_index(camNames, "dev_tps_tankcam") < 0
        push(camNames, "dev_tps_tankcam")
    return true

  sendEvent(get_local_player_eid(), [[CmdSwitchCamera]])


[console_cmd(name="camera.blk_tm")]
def copy_camera_itm_cmd()
  find_query() <| $ [es] (eid : EntityId; camera__active : bool; transform : float3x4)
    if camera__active
      let s = "[[{transform[0]}] [{transform[1]}] [{transform[2]}] [{transform[3]}]]"
      console_print("{getEntityTemplateName(eid)} tm: {s}")
      set_clipboard_ansi_text(s)
      return true
    return false
