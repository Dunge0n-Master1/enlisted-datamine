require ecs
require common_shooter.events_common_shooter
require DngHuman
require HumanPhys

[es]
def human_gun_to_phys_params(evt : CmdWeapAttach; weap__sprintLerpFactor : float = 1.f; gun__adsSpeedMult : float = 1.0)
  if evt.isAttached && evt.slotId != int(HUWeaponSlots EWS_GRENADE)
    query(evt.toEid) <| $ [es] (var human_net_phys : HumanActor)
      human_net_phys.phys.currentState.sprintLerpSpeedMult = weap__sprintLerpFactor
      human_net_phys.phys.aimSpeed = human_net_phys.phys.defAimSpeed * gun__adsSpeedMult

[es(track=human_unarmed__active)]
def human_unarmed_sprint(evt : Event; human_unarmed__active : bool; var human_net_phys : HumanActor)
  if human_unarmed__active
    human_net_phys.phys.currentState.sprintLerpSpeedMult = 1.f
