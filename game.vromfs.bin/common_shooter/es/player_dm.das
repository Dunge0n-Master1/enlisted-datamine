require common_shooter.events_common_shooter
require ecs
require EnlistedDm
require game.events_game

[es]
def process_entity_hit_by_player(evt : EventOnEntityHit)
  if evt.deltaHp != 0.f
    let victimPlrEid : EntityId = get_Eid(evt.victim, "possessedByPlr") ?? INVALID_ENTITY_ID
    let offenderPlrEid : EntityId = get_Eid(evt.offender, "possessedByPlr") ?? INVALID_ENTITY_ID
    if offenderPlrEid != INVALID_ENTITY_ID
      sendEvent(offenderPlrEid, [[EventPlayerInjuredEntity
                                  victim=evt.victim,
                                  offender=evt.offender,
                                  damageDesc_damageTypeId=uint16(uint(evt.damageType)),
                                  damageDesc_gunPropsId=int16(evt.gunPropsId),
                                  damageDesc_collNodeId=int16(evt.collNodeId),
                                  damageDesc_deltaHp=evt.deltaHp,
                                  damageDesc_armorMult=evt.armorMult,
                                  victimPlrEid=victimPlrEid,
                                  offenderPlrEid=offenderPlrEid]])
    if victimPlrEid != INVALID_ENTITY_ID
      sendEvent(offenderPlrEid, [[EventPlayerGotDamage
                                  victimEid=evt.victim,
                                  offenderEid=evt.offender,
                                  damageDesc_deltaHp=evt.deltaHp,
                                  victimPlayerEid=victimPlrEid,
                                  offenderPlayerEid=offenderPlrEid]])

[es]
def process_entity_died_by_player(evt : EventAnyEntityDied)
  var offenderPlayer : EntityId = evt.offenderPlayer
  if offenderPlayer == INVALID_ENTITY_ID
    offenderPlayer = get_Eid(evt.offender, "possessedByPlr") ?? INVALID_ENTITY_ID
  var victimPlayer : EntityId = evt.victimPlayer
  if victimPlayer == INVALID_ENTITY_ID
    victimPlayer = get_Eid(evt.victim, "possessedByPlr") ?? INVALID_ENTITY_ID
  if offenderPlayer != INVALID_ENTITY_ID
    sendEvent(offenderPlayer, [[EventPlayerKilledEntity
                                victimEid=evt.victim,
                                killerEid=evt.offender,
                                deathDesc_gunPropsId=int16(evt.gunPropsId),
                                deathDesc_collNodeId=int16(evt.collNodeId),
                                deathDesc_damageTypeId=uint16(uint(evt.damageType)),
                                victimPlayerEid=victimPlayer,
                                killerPlayerEid=offenderPlayer]]) // update kills before (potential) send of EventPlayerPlace

  if victimPlayer != INVALID_ENTITY_ID
    sendEvent(victimPlayer, [[EventPlayerPossessedEntityDied
                              victimEid=evt.victim,
                              killerEid=evt.offender,
                              deathDesc_damageTypeId=uint16(uint(evt.damageType)),
                              victimPlayerEid=victimPlayer,
                              killerPlayerEid=offenderPlayer]])
