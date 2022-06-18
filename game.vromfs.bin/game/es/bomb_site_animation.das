require ecs

enum BombSiteAnim
  PLANT = 0
  RESET = 1
  DEFUSE = 2

[es(tag=server, on_appear, track=(bomb_site__operator, bomb_site__isDefusing, bomb_site__isPlantingOrReseting))]
def bomb_site_operator_animation(evt : Event;
                                 bomb_site__operator : EntityId;
                                 bomb_site__isDefusing : bool;
                                 bomb_site__isPlantingOrReseting : bool;
                                 bomb_site__plantProgressDeltaPerSec : float;
                                 bomb_site__plantAnimationTemplate : string;
                                 bomb_site__resetAnimationTemplate : string;
                                 bomb_site__defuseAnimationTemplate : string;
                                 var bomb_site__animationAction : int&;
                                 var bomb_site__animationOperator : EntityId&;
                                 var bomb_site__animationEntity : EntityId&)
  if !bomb_site__operator || (!bomb_site__isDefusing && !bomb_site__isPlantingOrReseting)
    destroyEntity(bomb_site__animationEntity)
    bomb_site__animationEntity = INVALID_ENTITY_ID
    return

  let currentAction = (bomb_site__isDefusing ? BombSiteAnim DEFUSE
    : bomb_site__plantProgressDeltaPerSec > 0.0 ? BombSiteAnim PLANT
    : BombSiteAnim RESET)

  if !!bomb_site__animationEntity && int(currentAction) == bomb_site__animationAction && bomb_site__animationOperator == bomb_site__operator
    return

  let animationTemplate = (currentAction == BombSiteAnim DEFUSE ? bomb_site__defuseAnimationTemplate
    : currentAction == BombSiteAnim RESET ? bomb_site__resetAnimationTemplate
    : bomb_site__plantAnimationTemplate)

  if !!bomb_site__animationEntity
    destroyEntity(bomb_site__animationEntity)
  bomb_site__animationAction = int(currentAction)
  bomb_site__animationOperator = bomb_site__operator
  bomb_site__animationEntity = createEntity(animationTemplate) <| $(var init : ComponentsInitializer)
    set(init, "game_effect__attachedTo", bomb_site__operator)

[es(tag=server, on_event=(EventEntityDestroyed, EventComponentsDisappear))]
def bomb_site_stop_operator_animation_on_destroy(evt : Event; var bomb_site__animationEntity : EntityId&)
  destroyEntity(bomb_site__animationEntity)
  bomb_site__animationEntity = INVALID_ENTITY_ID