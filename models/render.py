import subprocess
import os

import bpy

output_dir = os.getcwd() + "\\output\\"


def render(models, camera):
    for collection in models.children:
        collection.hide_render = True

    for collection in models.children:
        collection.hide_render = False

        model = collection.objects[collection.name]

        frames_count = model.get("frames_count", 0)

        if frames_count <= 0:
            print("frames_count invalid for", model.name)
            model["frames_count"] = 0
            collection.hide_render = True
            continue

        model_dir = output_dir + model.name

        if not os.path.exists(output_dir):
            os.makedirs(output_dir)

        for window in bpy.context.window_manager.windows:
            screen = window.screen

            for area in screen.areas:
                if area.type == 'VIEW_3D':
                    override = bpy.context.copy()

                    override["active_object"] = camera

                    override["window"] = window
                    override["area"] = area
                    override["region"] = area.regions[0]

                    with bpy.context.temp_override(**override):
                        bpy.ops.view3d.object_as_camera()

                        for i in range(frames_count):
                            bpy.context.scene.frame_set(i)
                            bpy.context.scene.render.filepath = model_dir + \
                                "\\" + str(i) + ".png"
                            bpy.ops.render.render(write_still=True)

                    break

        collection.hide_render = True


def quantize():
    script = os.path.abspath(os.path.join(
        os.getcwd(), os.pardir, "QuantizeRenders.ps1"))
    subprocess.run(["powershell.exe", script, output_dir], check=True)


def main():
    render(bpy.data.collections["Models"], bpy.data.objects["ModelCamera"])
    render(bpy.data.collections["FpsModels"], bpy.data.objects["FpsCamera"])
    quantize()


if __name__ == "__main__":
    main()
