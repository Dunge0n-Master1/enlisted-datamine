require ecs
require DagorTime
require DagorSystem

[es(no_order)]
def benchmark_update_es(
                        info : UpdateStageInfoAct;//wont correctly work with fixed timestamp, but it is strange to benchmark it
                        var averageDt : float&;
                        var prevMsec : int&;
                        var frames : int&;
                        var slowFrames : int&;
                        var verySlowFrames : int&;
                        var maxMemoryUsedKb : int&;
                        var allMemoryUsedKb : int64&;

                        var maxDeviceVRamUsedKb : int&;
                        var allDeviceVRamUsedKb : int64&;

                        var maxSharedVRamUsedKb : int&;
                        var allSharedVRamUsedKb : int64&;

                        benchmark_active : bool)

  if !benchmark_active
    return

  let msec = get_time_msec()
  let dt = float(msec - prevMsec) * 0.001
  frames = frames + 1
  if averageDt == 0.0
    averageDt = dt
  else
    averageDt = dt * 0.1 + averageDt * 0.9

  if dt > averageDt * 2.5 && frames > 50
    slowFrames = slowFrames + 1
  if dt > averageDt * 5.0
    verySlowFrames = verySlowFrames + 1
  prevMsec = msec

  // allocated system ram
  let memoryUsedKb = get_memory_allocated_kb(true)
  if maxMemoryUsedKb < memoryUsedKb
    maxMemoryUsedKb = memoryUsedKb

  allMemoryUsedKb = allMemoryUsedKb + int64(memoryUsedKb)

  // device local/dedicated vram
  let deviceVramUsedKb = get_device_vram_used_kb()
  if maxDeviceVRamUsedKb < deviceVramUsedKb
    maxDeviceVRamUsedKb = deviceVramUsedKb

  allDeviceVRamUsedKb = allDeviceVRamUsedKb + int64(deviceVramUsedKb)

  // shared vram
  let sharedVramUsedKb = get_shared_vram_used_kb()
  if maxSharedVRamUsedKb < sharedVramUsedKb
    maxSharedVRamUsedKb = sharedVramUsedKb

  allSharedVRamUsedKb = allSharedVRamUsedKb + int64(sharedVramUsedKb)

