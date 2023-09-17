require ecs
require game.es.events
require DagorInput
require TouchInput
require DngHuman
require DagorMath
require DagorMathUtils
require math.base


[es(tag=input, after=(human_input_es, check_other_ladder))]
def restrict_on_ladder_movement(info : UpdateStageUpdateInput;
                                var human_net_phys : HumanActor&;
                                human_ladder__curLadderTm : float3x4;
                                human_ladder__ladderTm : float3x4;
                                human_anim__ladder__handToLegsOffset : float3;
                                human_input__move : int)
  assume state = human_net_phys.phys.currentState
  if !state.isAttachedToLadder
    return

  assume ct = human_net_phys.phys.producedCT
  let humanPos = float3(state.location.P)

  let checkedUp = normalize(human_ladder__curLadderTm[1])
  let checkedDir = human_ladder__curLadderTm[3] - humanPos
  let dir = basis_aware_x0z(checkedDir, checkedUp)
  let pos = humanPos + human_anim__ladder__handToLegsOffset + length(human_ladder__curLadderTm[0]) * normalize(dir)
  let up = (get_analog_stick_action_state(uint16(human_input__move)).y > 0f ||
            get_stick_value(uint16(human_input__move)).y > 0f)
  if ((inverse(human_ladder__curLadderTm) * pos).y > IDENT_BBOX.boxMax.y &&
      (inverse(human_ladder__ladderTm) * pos).y > IDENT_BBOX.boxMax.y && up)
    // out of ladder
    ct |> human_control_state_set_walk_dir(float2(0))
