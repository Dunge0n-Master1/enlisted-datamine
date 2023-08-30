require ecs
require soundEvent


[es(tag=sound, track=placeable_item__inProgress)]
def placeable_item_sound(evt : Event;
                         placeable_item__inProgress : bool;
                         placeable_item__lastPosition : float3;
                         placeable_item_sound__beginPath : string;
                         placeable_item_sound__endPath : string)
  oneshot(placeable_item__inProgress ? placeable_item_sound__beginPath : placeable_item_sound__endPath, placeable_item__lastPosition)


[es(tag=sound, track=mine__blockedToTime)]
def mine_unblock_sound(evt : Event;
                       mine__blockedToTime : float;
                       mine_blocked_sound__unblockedPath : string;
                       transform : float3x4)
  if mine__blockedToTime < 0.
    oneshot(mine_blocked_sound__unblockedPath, transform[3])
