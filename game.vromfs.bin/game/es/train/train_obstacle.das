require ecs
require DagorMath
require pathfinder
require enlisted.game.es.train.train_common

def private try_init_train_obstacle(train_obstacle__offsetFromTrain : float3;
                                    train_obstacle__size : float3;
                                    var train_obstacle__handles : IntList&;
                                    var transform : float3x4&) : bool
  if !tilecache_is_loaded()
    return false

  transform[3] = project_on_railroad(transform[3] + train_obstacle__offsetFromTrain)

  for i in range(int(train_obstacle__size.x))
    let startX = -train_obstacle__size.x * 0.5 + float(i)

    let min = float3(startX - 0.5, -train_obstacle__size.y * 0.5, -train_obstacle__size.z * 0.5)
    let max = float3(startX + 0.5, +train_obstacle__size.y * 0.5, +train_obstacle__size.z * 0.5)

    let handle = tilecache_obstacle_add(transform, BBox3(min, max))

    push(train_obstacle__handles, handle)

  return true

[es(tag=server, no_order)]
def move_train_obstacle_es(evt : UpdateStageInfoAct;
                           var train_obstacle__is_inited : bool&;
                           train_obstacle__size : float3;
                           train_obstacle__offsetFromTrain : float3;
                           train_obstacle__trainEid : EntityId;
                           var train_obstacle__handles : IntList&;
                           var transform aka train_obstacle_transform : float3x4&)
  if !train_obstacle__is_inited
    train_obstacle__is_inited = try_init_train_obstacle(train_obstacle__offsetFromTrain,
      train_obstacle__size, train_obstacle__handles, transform)
    return

  query(train_obstacle__trainEid) <| $ [es] (transform aka train_transform : float3x4)
    let pos = train_transform[3] + train_obstacle__offsetFromTrain
    let len = length((pos - train_obstacle_transform[3]).xz)
    let lenInteger = int(len)

    for _i in range(lenInteger)
      if length(train_obstacle__handles) != 0
        tilecache_obstacle_remove(train_obstacle__handles[0])
        erase(train_obstacle__handles, 0)

    if lenInteger != 0
      train_obstacle_transform = train_transform
      train_obstacle_transform[3] = pos - train_transform[0] * (len - float(lenInteger))

    for i in range(int(train_obstacle__size.x) - lenInteger, int(train_obstacle__size.x))
      let startX = -train_obstacle__size.x * 0.5 + float(i)

      let min = float3(startX - 0.5, -train_obstacle__size.y * 0.5, -train_obstacle__size.z * 0.5)
      let max = float3(startX + 0.5, +train_obstacle__size.y * 0.5, +train_obstacle__size.z * 0.5)

      let handle = tilecache_obstacle_add(train_obstacle_transform, BBox3(min, max))

      push(train_obstacle__handles, handle)
