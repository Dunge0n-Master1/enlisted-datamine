let locIds = {
  nameLocId = @(id) $"wp/{id}/name"
  descLocId = @(id) $"wp/{id}/desc"
  hintLocId = @(id) $"wp/{id}/hint"
}

let function mkPresetnation(cfg, id) {
  let res = { id }.__update(cfg)
  foreach(key, ctor in locIds)
    if (key not in res)
      res[key] <- ctor(id)
  return res
}

let baseWpPresentation = {
  id = "baseWpPresentation"
  img = "agit_poster_enlisted_battlepass_tex_d*"
  nameLocId = $"wp/unknown/name"
  descLocId = $"wp/unknown/desc"
  hintLocId = $"wp/unknown/hint"
}

let wpPresentation = {
  wallposter_battlepass_season_2_preview = {
    img = "agit_poster_enlisted_battlepass_tex_d*"
  }
  wallposter_battlepass_season_4_preview = {
    img = "agit_poster_enlisted_battlepass_b_tex_d*"
  }
  wallposter_battlepass_season_5_preview = {
    img = "agit_poster_enlisted_battlepass_c_tex_d*"
  }
  agit_poster_ussr_a_preview = {
    img = "agit_poster_ussr_a_tex_d*"
  }
  agit_poster_veteran_ussr_a_preview = {
    img = "agit_poster_veteran_ussr_a_tex_d*"
  }
  agit_poster_german_a_preview = {
    img = "agit_poster_german_a_tex_d*"
  }
  agit_poster_veteran_axis_a_preview = {
    img = "agit_poster_veteran_axis_a_tex_d*"
  }
  agit_poster_normandy_axis_a_preview = {
    img = "agit_poster_normandy_axis_a_tex_d*"
  }
  agit_poster_veteran_usa_a_preview = {
    img = "agit_poster_veteran_usa_a_tex_d*"
  }
  agit_poster_normandy_usa_a_preview = {
    img = "agit_poster_normandy_usa_a_tex_d*"
  }
  agit_poster_ny_ussr_a_preview = {
    img = "agit_poster_ny_ussr_a_tex_d*"
  }
  agit_poster_ny_axis_a_preview = {
    img = "agit_poster_ny_axis_a_tex_d*"
  }
  agit_poster_ny_usa_a_preview = {
    img = "agit_poster_ny_usa_a_tex_d*"
  }
  agit_poster_china_a_preview = {
    img = "agit_poster_china_a_tex_d*"
  }
}.map(mkPresetnation)

return {
  wpPresentation
  baseWpPresentation
}
