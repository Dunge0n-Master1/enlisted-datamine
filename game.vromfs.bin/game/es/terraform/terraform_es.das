require ecs
require terraform

[es(no_order)]
def terraform_update_es(info : UpdateStageInfoAct; var terraform : TerraformComponent)
  query() <| $ [es] (level__loaded : bool)
    if level__loaded
      terraform |> terraform_update()
