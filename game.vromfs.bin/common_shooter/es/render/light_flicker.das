require ecs
require math.random
require DagorMath

def smoothstep(edge0 : float; edge1 : float; x : float)
   // Scale, and clamp x to 0..1 range
  let c = clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0);
  // Evaluate polynomial
  return c * c * c * (c * (c * 6.0 - 15.0) + 10.0);

[es(tag=render, after=after_camera_sync)]
def flicker_light_update_es(info : UpdateStageInfoAct;
                            eid : EntityId;
                            light_flicker__on_time : float2;
                            light_flicker__off_time : float2;
                            light_flicker__on_brightness : float2;
                            light_flicker__off_brightness : float2;
                            light_flicker__attack_time : float2;
                            light_flicker__release_time : float2;
                            light_flicker__noise_brightness : float2;
                            light_flicker__noise_time : float;
                            light_flicker__brightness_multiplier : float;
                            var light_flicker__time : float&;
                            var light_flicker__seed : int&;
                            var light__brightness : float&)
  light_flicker__seed = (light_flicker__seed == 0) ? int(uint(eid)) ^ get_rnd_seed() : light_flicker__seed;

  var last_seed = light_flicker__seed;
  let local_time = info.curTime - light_flicker__time;

  let off_time = _rnd_float(last_seed, light_flicker__off_time.x, light_flicker__off_time.y);
  let on_time = _rnd_float(last_seed, light_flicker__on_time.x, light_flicker__on_time.y);
  let on_brightness = _rnd_float(last_seed, light_flicker__on_brightness.x, light_flicker__on_brightness.y);
  let off_brightness = _rnd_float(last_seed, light_flicker__off_brightness.x, light_flicker__off_brightness.y);
  let attack_time = _rnd_float(last_seed, light_flicker__attack_time.x, light_flicker__attack_time.y);
  let release_time = _rnd_float(last_seed, light_flicker__release_time.x, light_flicker__release_time.y);

  let total_cycle_time = off_time + attack_time + on_time + release_time;

  let flicker_on = smoothstep(off_time, off_time + attack_time, local_time);
  let flicker_off = (1.0 - smoothstep(off_time + attack_time + on_time, total_cycle_time, local_time));

  let brightness = lerp(off_brightness, on_brightness, flicker_on * flicker_off);

  if (local_time > total_cycle_time)
    light_flicker__time += total_cycle_time;
    light_flicker__seed = last_seed;

  let noise_time = info.curTime * light_flicker__noise_time;
  let noise = (perlin_noise1(noise_time) + 1.0) * 0.5f;
  let noise_brightness = lerp(light_flicker__noise_brightness.x, light_flicker__noise_brightness.y, noise);

  light__brightness = brightness * noise_brightness * light_flicker__brightness_multiplier;