require ecs
require ecs.safe
require AnimV20
require GeomNodeTree
require game.es.aircraft.plane_cutting_common

[es(tag=server, track=(plane_cutting__largePartsCut, plane_cutting__cuttingPlanes))]
def cut_wing_weapon(evt : Event;
                    animchar : AnimcharBaseComponent;
                    turret_control__gunEids : EidList;
                    plane_cutting__largePartsCut : BoolList;
                    plane_cutting__cuttingPlanes : Point4List)
  var cutPlanes : array<float4>
  for part in [[int[] int(WreckageType WRECKAGE_WING_L); int(WreckageType WRECKAGE_WING_R)]]
    if (plane_cutting__largePartsCut?[part] ?? false) && part < length(plane_cutting__cuttingPlanes)
      cutPlanes |> push(plane_cutting__cuttingPlanes[part])

  assume tree = *animchar.nodeTree
  var rootTm : float3x4
  tree |> geomtree_getNodeWtmRelScalar(0, rootTm)
  let invRootTm = inverse(rootTm)

  for gunEid in turret_control__gunEids
    query(gunEid) <| $ [es] (gun__shootNodeName : string; var turret__isCut : bool&)
      let nodeId = geomtree_findNodeIndex(tree, gun__shootNodeName)
      if nodeId < 0
        return
      let nodePos = geomtree_getNodeWposRel(tree, nodeId)
      let nodePosLocal = -(invRootTm * nodePos)
      turret__isCut = false
      for plane in cutPlanes
        if dot(plane.xyz, nodePosLocal) > plane.w
          turret__isCut = true
          return

[es(on_appear, track=turret__isCut)]
def remove_ammo_from_cut_gun(evt : Event; turret__isCut : bool; var gun__ammo : int&; var gun__totalAmmo : int&)
  if turret__isCut
    gun__ammo = 0
    gun__totalAmmo = 0
