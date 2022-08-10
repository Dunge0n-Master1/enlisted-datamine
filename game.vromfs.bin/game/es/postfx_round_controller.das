require ecs
require ecs.safe
require game.events_game
require app


[es(tag=render, REQUIRE_NOT=(disableRoundEndPostfx))]
def start_round_end_postfx(evt : EventTeamRoundResult;
                           eid : EntityId;
                           postfx_round_ctrl__scaleOnWin : float;
                           postfx_round_ctrl__scaleOnLose : float;
                           var postfx_round_ctrl__expScale : float&;
                           var postfx_round_ctrl__maxExposure : float&;
                           var post_fx : Object&)
  query() <| $ [es(REQUIRE=hero)] (team : int)
    if team != evt.team
      return

    postfx_round_ctrl__maxExposure = post_fx |> get_float("adaptation__maxExposure") ?? postfx_round_ctrl__maxExposure
    postfx_round_ctrl__expScale = evt.isWon ? postfx_round_ctrl__scaleOnWin : postfx_round_ctrl__scaleOnLose

    post_fx |> set("adaptation__maxExposure", 1000.0)
    post_fx |> set("adaptation__minExposure", 0.001)
    post_fx |> set("adaptation__adaptUpSpeed", 1.0)
    post_fx |> set("adaptation__adaptDownSpeed", 1.0)

    let newTemplate = add_sub_template_name(eid, "postfx_roundctrl_update")
    reCreateEntityFrom(eid, newTemplate)


[es(tag=render, before=start_round_end_postfx, REQUIRE=postfx_round_ctrl_update)]
def update_round_end_postfx(info : UpdateStageInfoAct;
                            postfx_round_ctrl__expScale : float;
                            var post_fx : Object&)
  let curScale = post_fx |> get_float("adaptation__autoExposureScale") ?? 1.0
  post_fx |> set("adaptation__autoExposureScale", min(1000.0, curScale * pow(postfx_round_ctrl__expScale, info.dt * 5.0)))
