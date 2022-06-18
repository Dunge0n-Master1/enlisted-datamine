options no_aot
require ecs
require DagorConsole

[console_cmd(name="perf_stat.draw")]
def perf_stat_draw()
  query() <| $ [es] (var perf_stat__draw : bool&)
    perf_stat__draw = !perf_stat__draw

[console_cmd(name="perf_stat.reset")]
def perf_stat_reset()
  query() <| $ [es] (var perf_stat__data : IntList)
    clear(perf_stat__data)