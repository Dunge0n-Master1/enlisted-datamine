options no_aot
require ecs
require ecs.safe
require EcsUtils
require strings
require DagorConsole
require RegExp
require DagorFiles
require DagorSystem

[console_cmd(name="vehicle.skins_to_profile", hint="0 = filter '_skins' by default 1 = custom path 2 = customFileName")]
def vehicle_save_skins_to_profile(filter = "_skins";
                                  file_path = "../prog/enlisted/scripts/enlisted/profileServer/config/";
                                  file_name = "vehCamouflageConfig.das")
  let fileRegExp = ".*{filter}"
  let fullPathFile = "{file_path}{file_name}"

  df_open(fullPathFile, DF_WRITE) <| $(fw)
    if fw == null
      logerr("can't open {fullPathFile} for writing")
      return

    fw |> df_puts("let shared\n")
    fw |> df_puts("  vehCamouflageCfg <- \{\{\n")

    using() <| $(var regexTester : RegExp)
      regexTester |> compile(fileRegExp, "", 0)
      getTemplateDB() |> find_templateDB() <| $(name; tmpl)
        if (regexTester |> test(name, 0)) != 0
          let skins = getTemplateComponent(tmpl, "skin__objTexReplace") ?as Array
          if skins != null
            for skin in *skins
              let data = skin |> get_ecs_object()
              if data != null
                let id = get_string(data, "id", "")
                if id != ""
                  let nameWithoutPrefix = replace(name, filter, "")
                  let skinString = "    \"{id}\" => \"{nameWithoutPrefix}\";\n"
                  fw |> df_puts(skinString)
        return false
    fw |> df_puts("\}\}\n")