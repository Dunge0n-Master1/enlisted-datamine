require ecs
require terraform

[es(after=after_net_phys_sync)] //after after_net_phys_sync for more time for bullet phys update
def terraform_update_es(info : UpdateStageInfoAct; var terraform : TerraformComponent)
  query() <| $ [es] (level__loaded : bool)
    if level__loaded
      terraform |> terraform_update()
