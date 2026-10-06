"""Create a benign cosmetic asset for the pak-corpus benign control sample.

Run with: UE4Editor-Cmd <TBL.uproject> -ExecutePythonScript=<this file>
          -EnablePlugins=EditorScriptingUtilities -unattended -nop4 -nosplash

Creates a single unlit Material under the mod's OWN namespace
(/Game/Mods/PakCorpusBenign/...). It touches nothing the game ships, so a pak of it is
genuinely benign (no asset replacement, no dangerous nodes). Mirrors the asset-creation
pattern used by the TheBox mod's create_map.py.

Prints PAKCORPUS_BENIGN_OK on success (build scripts should grep for it).
"""
import unreal as u

ROOT = "/Game/Mods/PakCorpusBenign"
MAT_NAME = "M_BenignCosmetic"

assets = u.EditorAssetLibrary
materials = u.MaterialEditingLibrary
tools = u.AssetToolsHelpers.get_asset_tools()


def main():
    path = ROOT + "/Materials/" + MAT_NAME
    mat = assets.load_asset(path)
    if not mat:
        mat = tools.create_asset(
            MAT_NAME, ROOT + "/Materials", u.Material, u.MaterialFactoryNew()
        )
    assert mat, "Could not create material"
    materials.delete_all_material_expressions(mat)
    mat.set_editor_property("shading_model", u.MaterialShadingModel.MSM_UNLIT)
    rgb = materials.create_material_expression(
        mat, u.MaterialExpressionConstant3Vector, -200, 0
    )
    # A plain teal emissive — purely cosmetic, no behavior.
    rgb.set_editor_property("constant", u.LinearColor(0.0, 0.6, 0.6, 1.0))
    assert materials.connect_material_property(
        rgb, "", u.MaterialProperty.MP_EMISSIVE_COLOR
    )
    materials.recompile_material(mat)
    assert assets.save_loaded_asset(mat), "Could not save material"
    print("PAKCORPUS_BENIGN_OK")


main()
