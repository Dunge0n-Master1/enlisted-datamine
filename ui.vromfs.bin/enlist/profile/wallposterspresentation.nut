let texNameConvertor = require("%enlSqGlob/ui/texNameConvertor.nut")

let defImg = "agit_poster_enlisted_battlepass_tex_d*"

let locIds = {
  nameLocId = @(id) $"wp/{id}/name"
  descLocId = @(id) $"wp/{id}/desc"
  hintLocId = @(id) $"wp/{id}/hint"
}

let function mkPresentation(cfg, id) {
  let res = { id }.__update(cfg)
  res.img <- texNameConvertor(res?.img ?? defImg)
  foreach (key, ctor in locIds)
    if (key not in res)
      res[key] <- ctor(id)
  return res
}

let baseWpPresentation = {
  id = "baseWpPresentation"
  img = texNameConvertor(defImg)
  nameLocId = $"wp/unknown/name"
  descLocId = $"wp/unknown/desc"
  hintLocId = $"wp/unknown/hint"
}

let wpPresentation = freeze({
  wallposter_battlepass_season_2_preview = {
    img = "agit_poster_enlisted_battlepass_tex_d*"
  }
  wallposter_battlepass_season_4_preview = {
    img = "agit_poster_enlisted_battlepass_b_tex_d*"
  }
  wallposter_battlepass_season_5_preview = {
    img = "agit_poster_enlisted_battlepass_c_tex_d*"
  }
  wallposter_battlepass_season_6_preview = {
    img = "agit_poster_enlisted_battlepass_d_tex_d*"
  }
  wallposter_battlepass_season_7_preview = {
    img = "agit_poster_enlisted_battlepass_e_tex_d*"
  }
  wallposter_battlepass_season_8_preview = {
    img = "agit_poster_enlisted_battlepass_f_tex_d*"
    bpSeason = 9
    // OR icon = "ui/uiskin/battlepass/bp_seasons/myPicture.svg"
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
  agit_poster_china_b_preview = {
    img = "agit_poster_china_b_tex_d*"
  }
  agit_poster_china_c_preview = {
    img = "agit_poster_china_c_tex_d*"
  }
  agit_poster_china_d_preview = {
    img = "agit_poster_china_d_tex_d*"
  }
  agit_poster_china_e_preview = {
    img = "agit_poster_china_e_tex_d*"
  }
  agit_poster_china_f_preview = {
    img = "agit_poster_china_f_tex_d*"
  }
  agit_poster_china_g_preview = {
    img = "agit_poster_china_g_tex_d*"
  }
  agit_poster_china_h_preview = {
    img = "agit_poster_china_h_tex_d*"
  }
  agit_poster_china_i_preview = {
    img = "agit_poster_china_i_tex_d*"
  }
  agit_poster_china_j_preview = {
    img = "agit_poster_china_j_tex_d*"
  }
  agit_poster_china_k_preview = {
    img = "agit_poster_china_k_tex_d*"
  }
  agit_poster_china_l_preview = {
    img = "agit_poster_china_l_tex_d*"
  }
  agit_poster_china_m_preview = {
    img = "agit_poster_china_m_tex_d*"
  }
  agit_poster_combat_engineers_preview = {
    img = "agit_poster_combat_engineers_tex_d*"
  }
  agit_poster_raaf_pilot_preview = {
    img = "agit_poster_raaf_pilot_tex_d*"
  }
}.map(mkPresentation))

let getWPPresentation = @(wpTpl) wpPresentation?[wpTpl] ?? baseWpPresentation

return {
  getWPPresentation
}
