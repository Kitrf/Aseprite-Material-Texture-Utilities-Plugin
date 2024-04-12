function init(plugin)
    plugin:newMenuGroup{
        id="material_texture_utils",
        title="Material Texture Utils",
        group="edit_insert"
    }

    plugin:newCommand{
        id="RedToAlpha",
        title="Red to Alpha",
        group="material_texture_utils",
        onclick=function()
            local image = app.cel.image:clone()
            for it in image:pixels() do
                it(app.pixelColor.rgba(0, 0, 0, app.pixelColor.rgbaR(it())))
            end
            app.cel.image = image
            app.refresh()
        end
    }

    plugin:newCommand{
        id="Isolate Red",
        title="Isolate Red",
        group="material_texture_utils",
        onclick=function()
            local image = app.cel.image:clone()
            for it in image:pixels() do
                it(app.pixelColor.rgb(app.pixelColor.rgbaR(it())), 0, 0)
            end
            app.cel.image = image
            app.refresh()
        end
    }
end