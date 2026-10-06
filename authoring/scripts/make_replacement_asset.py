"""Create the inert stand-in asset for the asset-replacement attempt sample.

Run with: UE4Editor-Cmd <TBL.uproject> -ExecutePythonScript=<this file>
          -EnablePlugins=EditorScriptingUtilities -unattended -nop4 -nosplash

Creates a plain material under the mod's own authoring namespace. The DANGER is not the asset
itself (it is inert) but WHERE the build script later paks it: at a trusted game asset path,
so it shadows the real game asset via mount precedence. Keeping the source asset under
/Game/Mods keeps the project clean; the replacement path is applied at pak time.

Prints PAKCORPUS_REPLACEMENT_OK on success.
"""
import unreal as u

ROOT = "/Game/Mods/PakCorpusReplacement"
# Named to match the real game asset it will shadow, so the cooked file already carries the
# target filename and no pak-time rename is needed (UnrealPak's mount handling overrides renames).
MAT_NAME = "M_DetailLine_gradient"

assets = u.EditorAssetLibrary
materials = u.MaterialEditingLibrary
tools = u.AssetToolsHelpers.get_asset_tools()


def main():
    path = ROOT + "/" + MAT_NAME
    mat = assets.load_asset(path)
    if not mat:
        mat = tools.create_asset(MAT_NAME, ROOT, u.Material, u.MaterialFactoryNew())
    assert mat, "Could not create stand-in material"
    materials.delete_all_material_expressions(mat)
    mat.set_editor_property("shading_model", u.MaterialShadingModel.MSM_UNLIT)
    rgb = materials.create_material_expression(
        mat, u.MaterialExpressionConstant3Vector, -200, 0
    )
    # Obvious magenta so a human can see the replacement took effect in-game.
    rgb.set_editor_property("constant", u.LinearColor(1.0, 0.0, 1.0, 1.0))
    assert materials.connect_material_property(
        rgb, "", u.MaterialProperty.MP_EMISSIVE_COLOR
    )
    materials.recompile_material(mat)
    assert assets.save_loaded_asset(mat), "Could not save stand-in material"
    print("PAKCORPUS_REPLACEMENT_OK")


main()
