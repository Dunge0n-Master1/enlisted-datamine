module motion_matching_common shared

require ecs
require DagorDataBlock
require DagorSystem
require MotionMatching
require daslib/strings_boost

def serialize_weights(path : string; weights : FeatureWeights; nodes_name : StringList; prediction_times : FloatList)

  if !empty(path)
    using <| $(var blk : DataBlock#)
      var nodes = blk |> datablock_add_new_block("nodes")
      for p, v, n in weights.position, weights.velocity, nodes_name
        var node = nodes |> datablock_add_new_block("{n}")
        node |> datablock_setReal("position_weight", p)
        node |> datablock_setReal("velocity_weight", v)


      var trajectory = blk |> datablock_add_new_block("trajectory")
      for p, v, a, t in weights.positionWeight, weights.linearVelocity, weights.angularVelocity, prediction_times
        var node = trajectory |> datablock_add_new_block("point")
        node |> datablock_setReal("time", t)
        node |> datablock_setReal("position_weight", p)
        node |> datablock_setReal("velocity_weight", v)
        node |> datablock_setReal("rotation_weight", a)

      datablock_save_to_text_file(blk, path)

  return true

def deserialize_weights(path : string; var weights : FeatureWeights; var nodes_name : StringList; var prediction_times : FloatList)

  var result = false
  using <| $(var blk : DataBlock#)
    if !datablock_load(blk, path)
      return
    let nodes = blk |> datablock_get_block_by_name_const("nodes")
    let nodeCount = int(nodes.blockCount)
    if nodes == null
      logerr("need nodes block in {path}");
      return ;
    assert(weights.position |> length() == nodeCount)


    nodes_name |> resize(nodeCount)

    for i in range(nodeCount)
      let node = datablock_get_block_const(nodes, i)
      weights.position[i] = datablock_getReal(node, "position_weight", 0.0)
      weights.velocity[i] = datablock_getReal(node, "velocity_weight", 0.0)
      nodes_name[i] := node.getBlockName


    let trajectory = blk |> datablock_get_block_by_name_const("trajectory")
    let pointCount = int(trajectory.blockCount)
    if trajectory == null
      logerr("need trajectory block in {path}");
      return ;
    assert(weights.positionWeight |> length() == pointCount)

    prediction_times |> resize(pointCount)

    for i in range(pointCount)
      let node = datablock_get_block_const(trajectory, i)
      weights.positionWeight[i] = datablock_getReal(node, "position_weight", 0.0)
      weights.linearVelocity[i] = datablock_getReal(node, "velocity_weight", 0.0)
      weights.angularVelocity[i] = datablock_getReal(node, "rotation_weight", 0.0)
      prediction_times[i] = datablock_getReal(node, "time", 0.0)

    result = true


  return result
