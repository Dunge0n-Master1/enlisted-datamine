require ecs
require game.es.aircraft.plane_cutting_common
require danetlibs.renderer.includes.render_events


let
  NO_CUT = float4(0, 0, 0, 1)
  NO_CUT_2 = -NO_CUT


[es(tag=gameClient, before=additional_data_for_plane_cutting_es)]
def plane_damage_part_cut_es(info : UpdateStageInfoBeforeRender;
                             plane_cutting__cuttingPlanes : Point4List;
                             plane_cutting__finsFrontCuttingPlane : float4;
                             plane_cutting__wingRearCuttingPlane : float4;
                             plane_cutting__wingBiplaneCuttingPlane : float4;
                             plane_cutting__wingLowerCuttingPlane : float4;
                             plane_cutting__wingUpperCuttingPlane : float4;
                             plane_cutting__leftWingCutState : int;
                             plane_cutting__rightWingCutState : int;
                             plane_cutting__largePartsCut : BoolList;
                             var plane_cutting__planes : Point4List&)
  let leftWingCut = plane_cutting__largePartsCut[int(WreckageType WRECKAGE_WING_L)]
  let rightWingCut = plane_cutting__largePartsCut[int(WreckageType WRECKAGE_WING_R)]
  let tailCut = plane_cutting__largePartsCut[int(WreckageType WRECKAGE_TAIL)]
  let leftStabCut = plane_cutting__largePartsCut[int(WreckageType WRECKAGE_STAB_L)]
  let rightStabCut = plane_cutting__largePartsCut[int(WreckageType WRECKAGE_STAB_R)]
  let vStabCut = plane_cutting__largePartsCut[int(WreckageType WRECKAGE_FIN)]

  let leftWingCutState = plane_cutting__leftWingCutState
  let rightWingCutState = plane_cutting__rightWingCutState

  plane_cutting__planes[0] = leftWingCut ? plane_cutting__cuttingPlanes[int(WreckageType WRECKAGE_WING_L)] : NO_CUT
  plane_cutting__planes[1] = rightWingCut ? plane_cutting__cuttingPlanes[int(WreckageType WRECKAGE_WING_R)] : NO_CUT
  plane_cutting__planes[2] = tailCut ? plane_cutting__cuttingPlanes[int(WreckageType WRECKAGE_TAIL)] : NO_CUT
  plane_cutting__planes[3] = leftStabCut && !tailCut ? plane_cutting__cuttingPlanes[int(WreckageType WRECKAGE_STAB_L)] : NO_CUT
  plane_cutting__planes[4] = rightStabCut && !tailCut ? plane_cutting__cuttingPlanes[int(WreckageType WRECKAGE_STAB_R)] : NO_CUT
  plane_cutting__planes[5] = vStabCut && !tailCut ? plane_cutting__cuttingPlanes[int(WreckageType WRECKAGE_FIN)] : NO_CUT
  plane_cutting__planes[6] = plane_cutting__wingRearCuttingPlane

  plane_cutting__planes[7] = NO_CUT_2
  if plane_cutting__wingBiplaneCuttingPlane.y != 0.0f && leftWingCutState < int(FlightModelCutState FMCS_ALL_CUT) && leftWingCut
    plane_cutting__planes[7] = plane_cutting__wingBiplaneCuttingPlane
  elif plane_cutting__wingLowerCuttingPlane.y != 0.0f && leftWingCut
    plane_cutting__planes[7] = plane_cutting__wingLowerCuttingPlane

  plane_cutting__planes[8] = NO_CUT_2
  if plane_cutting__wingBiplaneCuttingPlane.y != 0.0f && rightWingCutState < int(FlightModelCutState FMCS_ALL_CUT) && rightWingCut
    plane_cutting__planes[8] = plane_cutting__wingBiplaneCuttingPlane
  elif plane_cutting__wingLowerCuttingPlane.y != 0.0f && rightWingCut
    plane_cutting__planes[8] = plane_cutting__wingLowerCuttingPlane

  plane_cutting__planes[9] = plane_cutting__wingUpperCuttingPlane.y != 0.0f ? plane_cutting__wingUpperCuttingPlane : NO_CUT_2
  plane_cutting__planes[10] = !tailCut && (leftStabCut || rightStabCut || vStabCut) ? plane_cutting__finsFrontCuttingPlane : NO_CUT_2


[es(before=additional_data_for_plane_cutting_es)]
def plane_damage_part_wreckage_es(info : UpdateStageInfoBeforeRender;
                                  plane_wreckage__owner : EntityId;
                                  plane_wreckage__typeId : int;
                                  var plane_cutting__planes : Point4List&)
  var leftWingCut = false
  var rightWingCut = false
  var tailCut = false
  var leftStabCut = false
  var rightStabCut = false
  var vStabCut = false

  var leftWingCutState = int(FlightModelCutState FMCS_NONE)
  var rightWingCutState = int(FlightModelCutState FMCS_NONE)

  query(plane_wreckage__owner) <| $ [es] (plane_cutting__leftWingCutState : int;
                                          plane_cutting__rightWingCutState : int;
                                          plane_cutting__cuttingPlanes : Point4List;
                                          plane_cutting__wingRearCuttingPlane : float4;
                                          plane_cutting__wingLowerCuttingPlane : float4;
                                          plane_cutting__wingUpperCuttingPlane : float4;
                                          plane_cutting__wingBiplaneCuttingPlane : float4;
                                          plane_cutting__finsFrontCuttingPlane : float4;
                                          plane_cutting__largePartsCut : BoolList)
    leftWingCut = plane_cutting__largePartsCut[int(WreckageType WRECKAGE_WING_L)]
    rightWingCut = plane_cutting__largePartsCut[int(WreckageType WRECKAGE_WING_R)]
    tailCut = plane_cutting__largePartsCut[int(WreckageType WRECKAGE_TAIL)]
    leftStabCut = plane_cutting__largePartsCut[int(WreckageType WRECKAGE_STAB_L)]
    rightStabCut = plane_cutting__largePartsCut[int(WreckageType WRECKAGE_STAB_R)]
    vStabCut = plane_cutting__largePartsCut[int(WreckageType WRECKAGE_FIN)]

    leftWingCutState = plane_cutting__leftWingCutState
    rightWingCutState = plane_cutting__rightWingCutState

    let wreckageNo = plane_wreckage__typeId
    assume cuttingPlanes = plane_cutting__cuttingPlanes

    plane_cutting__planes[0] = leftWingCut && wreckageNo == int(WreckageType WRECKAGE_WING_L) ? -cuttingPlanes[int(WreckageType WRECKAGE_WING_L)] : NO_CUT
    plane_cutting__planes[1] = rightWingCut && wreckageNo == int(WreckageType WRECKAGE_WING_R) ? -cuttingPlanes[int(WreckageType WRECKAGE_WING_R)] : NO_CUT
    plane_cutting__planes[2] = tailCut && wreckageNo == int(WreckageType WRECKAGE_TAIL) ? -cuttingPlanes[int(WreckageType WRECKAGE_TAIL)] : NO_CUT

    let dir = wreckageNo != int(WreckageType WRECKAGE_TAIL) ? -1. : 1.
    plane_cutting__planes[3] = (leftStabCut && (wreckageNo == int(WreckageType WRECKAGE_TAIL) || wreckageNo == int(WreckageType WRECKAGE_STAB_L)) ?
      (dir * cuttingPlanes[int(WreckageType WRECKAGE_STAB_L)]) : NO_CUT)
    plane_cutting__planes[4] = (rightStabCut && (wreckageNo == int(WreckageType WRECKAGE_TAIL) || wreckageNo == int(WreckageType WRECKAGE_STAB_R)) ?
      (dir * cuttingPlanes[int(WreckageType WRECKAGE_STAB_R)]) : NO_CUT)
    plane_cutting__planes[5] = (vStabCut && (wreckageNo == int(WreckageType WRECKAGE_TAIL) || wreckageNo == int(WreckageType WRECKAGE_FIN)) ?
      (dir * cuttingPlanes[int(WreckageType WRECKAGE_FIN)]) : NO_CUT)
    plane_cutting__planes[6] = ((leftWingCut && wreckageNo == int(WreckageType WRECKAGE_WING_L)) || (rightWingCut && wreckageNo == int(WreckageType WRECKAGE_WING_R)) ?
      -plane_cutting__wingRearCuttingPlane : NO_CUT)

    plane_cutting__planes[7] = NO_CUT
    if (plane_cutting__wingBiplaneCuttingPlane.y != 0.0f && leftWingCutState < int(FlightModelCutState FMCS_ALL_CUT) &&
        leftWingCut && wreckageNo == int(WreckageType WRECKAGE_WING_L))
      plane_cutting__planes[7] = -plane_cutting__wingBiplaneCuttingPlane
    elif (plane_cutting__wingLowerCuttingPlane.y != 0.0f && leftWingCut && wreckageNo == int(WreckageType WRECKAGE_WING_L))
      plane_cutting__planes[7] = -plane_cutting__wingLowerCuttingPlane

    plane_cutting__planes[8] = NO_CUT
    if (plane_cutting__wingBiplaneCuttingPlane.y != 0.0f && rightWingCutState < int(FlightModelCutState FMCS_ALL_CUT) &&
        rightWingCut && wreckageNo == int(WreckageType WRECKAGE_WING_R))
      plane_cutting__planes[8] = -plane_cutting__wingBiplaneCuttingPlane
    elif (plane_cutting__wingLowerCuttingPlane.y != 0.0f && rightWingCut && wreckageNo == int(WreckageType WRECKAGE_WING_R))
      plane_cutting__planes[8] = -plane_cutting__wingLowerCuttingPlane

    plane_cutting__planes[9] = (plane_cutting__wingUpperCuttingPlane.y != 0.0f &&
      ((leftWingCut && wreckageNo == int(WreckageType WRECKAGE_WING_L)) ||
      (rightWingCut && wreckageNo == int(WreckageType WRECKAGE_WING_R)) ||
      (tailCut && wreckageNo == int(WreckageType WRECKAGE_TAIL))) ? -plane_cutting__wingUpperCuttingPlane : NO_CUT)

    plane_cutting__planes[10] = (!tailCut && (
      (wreckageNo == int(WreckageType WRECKAGE_STAB_L) && leftStabCut) ||
      (wreckageNo == int(WreckageType WRECKAGE_STAB_R) && rightStabCut) ||
      (wreckageNo == int(WreckageType WRECKAGE_FIN) && vStabCut)) ? -plane_cutting__finsFrontCuttingPlane : NO_CUT)
