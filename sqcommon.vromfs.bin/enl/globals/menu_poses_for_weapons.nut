from "%enlSqGlob/ui_library.nut" import *

local i = @(pos, sufx = "_weapon")
  "enlisted_idle_{0}{1}".subst(pos >= 10 ? pos : $"0{pos}", sufx)

local standardRifle = [i(9), i(12), i(13), i(14), i(15), i(16), i(18)]
local specificRifle = [i(9), i(12), i(14), i(16), i(18)]
local specificGun = [i(9), i(11), i(12), i(13), i(14), i(15), i(16), i(18)]
local standardPistol = [i(3, ""), i(2, ""), i(19)]

local weaponToAnimState = freeze({
  defaultPoses = [i(11)]
  unarmedPoses = [i(1, ""), i(2, ""), i(3, ""), i(4, "")]
  sittingPoses = [i(20)]
  standardRifle
  specificRifle
  specificGun
  standardPistol

  tt_33_gun =                  [i(10)]
  stl_tt_33_gun =              standardPistol
  nagant_m1895_gun =           standardPistol
  stl_nagant_m1895_gun =       standardPistol
  tk_26_gun =                  standardPistol
  stl_tk_26_gun =              standardPistol
  mauser_c96_gun =             standardPistol
  stl_mauser_c96_gun =         standardPistol
  p38_walther_gun =            standardPistol
  stl_p38_walther_gun =        standardPistol
  p08_luger_gun =              standardPistol
  stl_p08_luger_gun =          standardPistol
  mauser_c96_m712_gun =        standardPistol
  m1911_colt_gun =             standardPistol
  colt_walker_gun =            standardPistol
  leuchtpistole_42_gun =       standardPistol
  walther_pp_gun =             standardPistol
  walther_ppk_gun =            standardPistol
  stl_walther_ppk_gun =        standardPistol
  sturmpistole_gun =           standardPistol
  enfield_no2_mk1_gun =        standardPistol
  colt_new_service_m1909_gun = standardPistol
  webley_mk6_gun =             [i(10)]
  beretta_m1923_gun =          standardPistol
  browning_hp =                standardPistol
  welrod_mk2_gun =             standardPistol
  cz_vz_27_gun =               standardPistol
  p08_luger_artillery_gun =    [i(10)]
  nambu_type_14_gun =          standardPistol
  nambu_type_94_gun =          standardPistol
  hamada_type_1_gun =          standardPistol
  hamada_type_2_gun =          standardPistol
  enfield_p14_gun =    [i(9), i(11), i(13), i(14), i(15), i(16), i(18)]

  mosin_m38_gun =              standardRifle
  stl_mosin_m38_gun =          standardRifle
  mosin_m44_gun =              [i(9), i(12), i(13), i(14), i(15), i(18)]
  mosin_m91_gun =              standardRifle
  mosin_m91_camouflaged_s_gun = standardRifle
  mosin_m91_camouflaged_w_gun = standardRifle
  stl_mosin_m91_gun =          [i(9), i(12), i(13), i(16), i(17), i(18)]
  mosin_m91_30_gun =           standardRifle
  stl_mosin_m91_30_gun =       [i(9), i(12), i(13), i(16), i(17)]
  mosin_m1907_gun =            standardRifle
  mosin_dragoon_gun =          standardRifle
  mosin_infantry_gun =         standardRifle

  gewehr_41_gun =              specificRifle
  sniper_gewehr_41_gun =              specificRifle
  stl_gewehr_41_gun =          specificRifle
  gewehr_43_gun =              specificRifle
  gewehr_41_mauser_gun =       [i(9), i(12), i(13), i(15), i(16), i(18)]
  sniper_gewehr_43_gun =       [i(9), i(16), i(18)]
  svt_38_gun =                 [i(9), i(12), i(14), i(16), i(18)]
  stl_svt_38_gun =             [i(9), i(12), i(14), i(16), i(18)]
  stl_sniper_svt_38_gun =      [i(9), i(12), i(14), i(16), i(18)]
  svt_40_gun =                 [i(9), i(14), i(16), i(18)]
  stl_svt_40_gun =             [i(9), i(14), i(16), i(18)]
  avt_40_gun =                 specificRifle
  stl_avt_40_gun =             specificRifle
  akt_40_gun =                 [i(9), i(12), i(14), i(18)]
  vg_2_gun =                   [i(9), i(12), i(14), i(16)]
  erma_emp_44_gun =            [i(10), i(18)]
  ovp_1918_gun =               [i(9), i(11), i(12), i(13), i(14), i(15), i(16), i(17), i(18)]
  bren_mk1_gun =               [i(9), i(12), i(14), i(16)]
  vickers_berthier_gun =       [i(8)]
  browning_m1918a2_gun =       [i(16), i(18)]
  pdm_42_gun =                 [i(13), i(15)]
  avs_36_gun =                 [i(11), i(12), i(13), i(14), i(15), i(16), i(18)]
  stl_sniper_avs_36_gun =      [i(11), i(12), i(13), i(14), i(15), i(16), i(18)]
  danuvia_39_gun =         [i(9), i(12), i(13), i(15), i(16)]
  stl_danuvia_39_gun =         [i(9), i(12), i(13), i(15), i(16)]
  danuvia_43m_gun =            [i(9), i(11), i(12), i(15), i(16)]
  browning_m1919a6_gun =       [i(8), i(13), i(15), i(16)]
  turner_automatic_rifle_gun = [i(12), i(13), i(14), i(15), i(18)]
  beretta_m31_gun =            [i(11), i(13), i(14), i(15), i(18)]
  type_hei_rifle_gun =         [i(9), i(13), i(14), i(15), i(16), i(18)]
  type_hei_rifle_extended_gun =         [i(9), i(13), i(14), i(15), i(16), i(18)]
  scotti_model_x_gun =         [i(9), i(12), i(14), i(16), i(18)]
  arisaka_type_99_early_short_gun =  [i(9), i(11), i(12),i(13), i(14), i(15), i(16), i(17)]
  nambu_type_96_lmg_gun =  [i(9), i(13), i(15), i(18)]
  nambu_type_97_lmg_gun =  [i(9), i(13), i(15), i(18)]
  nambu_type_99_lmg_gun =  [i(9), i(13), i(15), i(18)]
  m1903a4_springfield_gun =  [i(9), i(12), i(15), i(18)]
  mp_34_jp_gun =  [i(13), i(14), i(15), i(18)]
  type_97_antitank_canon_gun = [i(7), i(6), i(18), i(16), i(17)]



  browning_auto_5_gun =        specificGun
  m30_luftwaffe_drilling_gun = specificGun
  winchester_model_1912_gun =  [i(9), i(11), i(12), i(14), i(15), i(16)]

  mauser_98k_gun =             specificGun
  kar98k_with_scope_mount_gun = specificGun
  kar98k_kriegsmodell_gun =    specificGun
  pre_war_kar98k_camouflaged_s_gun =    specificGun
  pre_war_kar98k_camouflaged_w_gun =    specificGun
  stl_pre_war_kar98k_with_scope_mount_gun =    specificGun
  stl_kar98k_wartime_production_gun =    specificGun
  gewehr_33_40_gun =           specificGun
  m1903_springfield_gun =      specificGun
  m1_garand_gun =              [i(9), i(12), i(13), i(14), i(15), i(16), i(17), i(18)]
  m1_carbine_gun =             [i(9), i(11), i(12), i(14), i(16), i(18)]
  m1a2_carbine_gun =           [i(9), i(14), i(16), i(18)]
  m1941_johnson_gun =          [i(12), i(14), i(16), i(18)]
  vz_24_gun =                  specificGun
  winchester_1895_gun =        specificGun
  stl_winchester_1895_gun =    specificGun
  mannlicher_m93_roman_gun =   [i(9), i(12), i(13), i(16)]
  stl_mannlicher_m93_roman_gun = [i(9), i(12), i(13), i(16)]
  mannlicher_m1895_gun =       [i(13), i(14), i(18)]
  stl_mannlicher_m1895_gun =   [i(13), i(14), i(18)]
  mauser_gewehr_98_with_scope_mount_gun = [i(9), i(13), i(16), i(18)]
  mauser_gewehr_98_warmod_gun = [i(9), i(13), i(16), i(18)]
  mas_36_with_bayonet_gun =    [i(9), i(11), i(12), i(13), i(14), i(15), i(16), i(18)]
  smle_mk3_gun =               [i(9), i(11), i(14), i(15)]
  lee_enfield_no4_mk1_with_scope_gun = [i(9), i(14), i(16), i(18)]
  carcano_m41_gun =            [i(9), i(12), i(13), i(14), i(16)]
  armaguerra_mod_39_gun =      [i(9), i(12), i(16)]
  pavesi_m42_gun =             [i(12), i(9)]
  vollmer_m35_gun =            [i(9), i(12), i(14), i(18)]
  neiman_minethrower_gun =     [i(9), i(12), i(13), i(14), i(16), i(18)]
  pedersen_rifle_gun  =        [i(9), i(12), i(13), i(15), i(16)]
  carcano_m91_gun =            [i(9), i(12), i(13), i(14), i(16)]
  gerat_03_gun =               [i(12), i(9), i(16)]
  mg_13_gun =                  [i(16), i(12)]
  stl_mg_13_gun =              [i(16), i(12)]
  mg_13_saddle_drum_gun =      [i(16), i(12)]
  berthier_1892_m16_gun =      [i(9), i(12), i(13), i(14), i(18)]
  lewis_lmg_gun =              [i(6)]
  kar98k_wartime_production_gun = [i(9), i(12), i(13), i(16)]
  akm_47_gun =                 [i(9), i(12), i(16), i(18)]
  fedorov_avtomat_gun =        [i(9), i(12), i(16)]
  stg_44_gun =                 [i(9), i(12), i(16), i(18)]
  stg_44_rail_gun =            [i(9), i(12), i(16)]
  mp43_1_gun =                 [i(9), i(12), i(16), i(18)]
  vstg_1_5_gun =               [i(9), i(12), i(16), i(18)]
  mosin_m91_30_vpgs_gun =      [i(9), i(12), i(13), i(15), i(16), i(17)]
  skt_40_gun =                 [i(9), i(16), i(18)]
  suomi_kp_31_gun =            [i(13), i(15)]
  stg_45_m_gun =               [i(12), i(9)]
  kb_p_135_gun =               [i(9), i(12), i(16)]
  sw_light_rifle_mk_2_gun =    [i(9), i(13), i(15)]
  beretta_m1918_30_gun =       [i(9), i(12), i(13), i(15)]
  arisaka_type_38_gun =        [i(9), i(11), i(12), i(13), i(14), i(15), i(16) ]
  arisaka_type_97_gun =        [i(9), i(11), i(12), i(13), i(14), i(15), i(16) ]
  japanese_type_i_carcano_gun = [i(9), i(12), i(13), i(14), i(15), i(16) ]
  wzh_29_jp_gun =              [i(9), i(11), i(12), i(13), i(14), i(15), i(16), i(18)]
  nambu_type_2a_smg_gun =      [i(13), i(18)]
  nambu_type_1_smg_gun =       [i(18)]
  m1903a1_springfield_usmc_gun = [i(9), i(11), i(12), i(13), i(14), i(15), i(16), i(18)]
  mkb_42_w_gun =               [i(9), i(12), i(16), i(18)]
  type_100_smg_late_gun =      [i(9), i(14), i(15)]
  type_100_smg_early_gun =     [i(9), i(14), i(15)]
  owen_mk1_42_gun =            [i(13), i(14), i(15), i(18)]
  thompson_m1921_28_usmc_gun = [i(10), i(24), i(23), i(21)]
  m55_reising_gun =            [i(18)]
  type_100_paratrooper_smg_gun = [i(9), i(14), i(15)]
  arisaka_type_99_late_gun =   [i(9), i(11), i(12), i(13), i(14), i(15), i(17), i(18)]


  beretta_m38_gun =            [i(9), i(11), i(12), i(15), i(16)]
  beretta_m38_42_gun =         [i(11), i(13), i(15)]
  beretta_m1934_gun =          [i(10)]
  m3_submachine_gun_gun =      [i(18)]
  mp_18_gun =                  [i(9), i(12), i(13), i(14), i(15), i(16)]
  mp_28_jp_gun =               [i(13), i(14), i(15)]
  mp_28_32_round_gun =         [i(13), i(14), i(15)]
  mp_28_gun =                  [i(13), i(14), i(15), i(18)]
  stl_mp_28_gun =              [i(13), i(14), i(15), i(18)]
  mp34o_gun =                  [i(12), i(13), i(15)]
  mp_35_gun =                  [i(9), i(11), i(13), i(15), i(18)]
  mp_38_gun =                  [i(11), i(15)]
  mp40_gun =                   [i(13), i(15), i(16), i(18)]
  mp_40_silenced_gun =         [i(13), i(15), i(11)]
  stl_mp_40_gun =              [i(13), i(15), i(16), i(18)]
  mp_40_1_gun =                [i(13), i(15)]
  mp41_gun =                   [i(11), i(13), i(15), i(17)]
  m50_reising_gun =            [i(9), i(12), i(16), i(18)]
  sten_mk2_gun =               [i(13), i(14), i(15), i(16)]
  sten_mk2s_gun =              [i(13), i(14), i(15), i(16)]
  ppsh_41_gun =                [i(9), i(13), i(15), i(16)]
  stl_ppsh_41_gun =            [i(9), i(13), i(15), i(16)]
  ppd_3438_gun =               [i(9), i(11), i(13), i(15), i(16)]
  ppd_3438_box_gun =           [i(9), i(11), i(13), i(15), i(16)]
  stl_ppd_3438_box_gun =       [i(9), i(11), i(13), i(15), i(16)]
  ppd_40_gun =                 [i(9), i(11), i(13), i(15), i(16)]
  ppd_40_dv_gun =              [i(13), i(15)]
  ppsh_2_gun =                 [i(22)]
  ppk_41_gun =                 [i(11), i(15), i(16)]
  ppk_42_gun =                 [i(10), i(18)]
  pps_43_gun =                 [i(9), i(12), i(15)]
  pps_42_gun =                 [i(11), i(12), i(15), i(16)]
  stl_pps_42_gun =             [i(11), i(12), i(15), i(16)]
  m1a1_thompson_gun =          [i(12), i(16)]
  m1921ac_thompson_gun =       [i(10)]
  thompson_m1928a1_box_mag_gun = [i(12), i(16), i(18)]
  thompson_m1921_28_box_gun =  [i(10)]
  stl_thompson_m1921_28_box_gun = [i(13), i(15)]
  m2_hyde_gun =                [i(12), i(16), i(18)]
  zk_383_gun =                 [i(13), i(14), i(15)]
  pp_dolganov_gun =            [i(13), i(15)]
  orita_m1941_gun =            [i(11), i(13), i(15)]
  stl_orita_m1941_gun =        [i(11), i(13), i(15)]
  stl_ppd_bramit_gun =         [i(11), i(13), i(15)]
  stl_silenced_erma_emp_gun =  [i(13), i(15)]
  stl_mp_717r_gun =            [i(9), i(13), i(15), i(16)]
  erma_emp_36_gun =            [i(13), i(14), i(15)]
  as_44_gun =                  [i(9), i(12), i(13), i(16)]
  stl_ppsh_41_phosphated_gun = [i(9), i(13), i(15)]
  thompson_m1928a1_50_drum_gun = [i(9), i(16)]

  browning_m1918_gun =         [i(12), i(13), i(15), i(16), i(18)]
  charlton_automatic_rifle_gun = [i(13), i(15)]
  bren_mk2_gun =               [i(13), i(15), i(18)]
  bren_mk3_gun =               [i(13), i(14), i(15), i(18)]
  mg_42_handheld_gun =         [i(12), i(14), i(16)]
  mg_34_gun =                  [i(8), i(16)]
  stl_mg_34_gun =              [i(8), i(16)]
  mg_34_with_patronentrommel_gun = [i(8)]
  mg_30_gun =                  [i(14),i(16)]
  dp_27_gun =                  [i(8), i(15)]
  stl_dp_27_gun =              [i(8), i(15)]
  dt_29_gun =                  [i(13), i(15)]
  stl_dt_29_gun =              [i(13), i(15)]
  fg_42_gun =                  [i(12), i(14), i(16)]
  rd_44_gun =                  [i(15)]
  madsen_gun =                 [i(8), i(15)]
  zb_26_gun =                  [i(8), i(15)]
  breda_mod_30_gun =           [i(13), i(15)]
  stl_breda_mod_30_gun =       [i(13), i(15)]
  chauchat_gun =               [i(12), i(13)]
  stl_mg_42_handheld_gun =     [i(8), i(12), i(16)]
  type_11_lmg_gun =            [i(8), i(13), i(16)]
  mg_45_gun =                  [i(8), i(12), i(16)]

  ptrs_41_gun =                [i(7), i(6), i(18), i(16), i(17)]
  stl_ptrs_41_gun =            [i(7), i(6), i(18), i(16), i(17)]
  ptrd_41_gun =                [i(7), i(6), i(18), i(16), i(17)]
  pzb_38_gun =                 [i(13), i(8) , i(13), i(17)]
  pzb_39_gun =                 [i(13), i(8) , i(13), i(17)]
  pzb_39_with_two_magazines_gun = [i(13), i(8) , i(13), i(17)]

  panzerschreck_gun =           [i(5)]
  captured_panzerschreck_gun =  [i(5)]
  rpzb_43_ofenrohr_gun =        [i(5)]
  rpzb_54_1_panzerschreck_gun = [i(5)]
  m9_bazooka_gun =              [i(8)]
  m1_bazooka_gun =              [i(8)]


  roks_3_gun =                 [i(12), i(14), i(16), i(18)]
  roks_2_gun =                 [i(12), i(14), i(16), i(18)]
//flammenwerfer_35_gun         //wip asset
  flammenwerfer_41_gun =       [i(18), i(15)]
  m1_flamethrower_gun =        [i(11), i(13), i(15)]
  m2_flamethrower_gun =        [i(11), i(15), i(18)]
  lanciafiamme_m35_gun =       [i(11), i(15)]

//  ithaca_37_gun =              specificRifle  //wip asset
//  winchester_model_1912_gun =  specificRifle  //wip asset
//  lee_enfield_no4_mk1_gun =    specificRifle  //wip asset
//  m1917_enfield_gun =          specificRifle  //wip asset
})

return weaponToAnimState