module upscale_sampling

require DagorDriver3D
require DagorResPtr

//same as in c++ code
let UPSCALE_WEIGHTS_COUNT = 64
let UPSCALE_DATA_SIZE = typeinfo(sizeof type<float4>)

[generic]
def upload_weights(var upscale_weights_buffer : UniqueBufHolder)
  let UPSCALE_WEIGHTS_DATA <- [{ float[UPSCALE_WEIGHTS_COUNT * 4]
    //Bottom Right
    0.75 * 0.25; 0.25 * 0.25; 0.75 * 0.25; 0.75 * 0.75;
    0f; 0f; 0f; 1f;
    0f; 0f; 1f; 0f;
    0f; 0f; 0.25; 0.75;
    0f; 1f; 0f; 0f;
    0f; 0f; 0f; 1f;
    0f; 0.25; 0.75; 0f;
    0f; 0f; 0.25; 0.75;
    1f; 0f; 0f; 0f;
    0.25; 0f; 0f; 0.75;
    1f; 0f; 0f; 0f;
    0.25; 0f; 0f; 0.75;
    0.75; 0.25; 0f; 0f;
    0.25; 0f; 0f; 0.75;
    0.75; 0.25; 0f; 0f;
    0.75 * 0.25; 0.25 * 0.25; 0.75 * 0.25; 0.75 * 0.75;
    // Bottom Left
    0.25 * 0.25; 0.75 * 0.25; 0.75 * 0.75; 0.75 * 0.25;
    0f; 0f; 0f; 1f;
    0f; 0f; 1f; 0f;
    0f; 0f; 0.75; 0.25;
    0f; 1f; 0f; 0f;
    0f; 1f; 0f; 0f;
    0f; 0.25; 0.75; 0f;
    0f; 0.25; 0.75; 0f;
    1f; 0f; 0f; 0f;
    0.25; 0f; 0f; 0.75;
    0f; 0f; 1f; 0f;
    0f; 0f; 0.75; 0.25;
    0.25; 0.75; 0f; 0f;
    0.25; 0.75; 0f; 0f;
    0f; 0.25; 0.75; 0f;
    0.25 * 0.25; 0.75 * 0.25; 0.75 * 0.75; 0.75 * 0.25;
    // Top Right
    0.75 * 0.75; 0.75 * 0.25; 0.25 * 0.25; 0.75 * 0.25;
    0f; 0f; 0f; 1f;
    0f; 0f; 1f; 0f;
    0f; 0f; 0.25; 0.75;
    0f; 1f; 0f; 0f;
    0f; 0f; 0f; 1f;
    0f; 0.75; 0.25; 0f;
    0f; 0f; 0.25; 0.75;
    1f; 0f; 0f; 0f;
    0.75; 0f; 0f; 0.25;
    1f; 0f; 0f; 0f;
    0.75; 0f; 0f; 0.25;
    0.75; 0.25; 0f; 0f;
    0.75; 0f; 0f; 0.25;
    0.75; 0.25; 0f; 0f;
    0.75 * 0.75; 0.75 * 0.25; 0.25 * 0.25; 0.75 * 0.25;
    // Top Left
    0.75 * 0.25; 0.75 * 0.75; 0.75 * 0.25; 0.25 * 0.25;
    0f; 0f; 0f; 1f;
    0f; 0f; 1f; 0f;
    0f; 0f; 0.75; 0.25;
    0f; 1f; 0f; 0f;
    0f; 1f; 0f; 0f;
    0f; 0.75; 0.25; 0f;
    0f; 0.75; 0.25; 0f;
    1f; 0f; 0f; 0f;
    0.75; 0f; 0f; 0.25;
    0f; 0f; 1f; 0f;
    0f; 0f; 0.75; 0.25;
    0.25; 0.75; 0f; 0f;
    0.25; 0.75; 0f; 0f;
    0f; 0.75; 0.25; 0f;
    0.75 * 0.25; 0.75 * 0.75; 0.75 * 0.25; 0.25 * 0.25
  }]
  *upscale_weights_buffer.getBuf |> updateData(UPSCALE_WEIGHTS_DATA, VBLOCK_WRITEONLY | VBLOCK_DISCARD)

[generic]
def init_upscale(var upscale_weights_buffer : UniqueBufHolder)
  create_sbuffer(upscale_weights_buffer, UPSCALE_DATA_SIZE, UPSCALE_WEIGHTS_COUNT, SBCF_CB_PERSISTENT, uint(0), "upscale_sampling_weights")

[generic]
def upscale_render(target : BaseTexture?; shader : PostFxRenderer)
  d3d_set_render_target(target, 0)
  shader |> render()
  d3d_resource_barrier(target, RB_RO_SRV | RB_STAGE_PIXEL | RB_STAGE_COMPUTE, uint(0), uint(0))
