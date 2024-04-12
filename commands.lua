function init(plugin)
    plugin:newMenuGroup{
        id="material_texture_utils",
        title="Material Texture Utils",
        group="edit_insert"
    }

    plugin:newCommand{
        id="RedToAlpha",
        title="Red to Alpha Channel",
        group="material_texture_utils",
        onclick=function()
            if not app.cel then return app.alert "There is no active cel" end

            local image = app.cel.image:clone()
            for pixel in image:pixels() do
                pixel(app.pixelColor.rgba(0, 0, 0, app.pixelColor.rgbaR(pixel())))
            end

            app.transaction(
            "Converted red to alpha",
            function()
                app.cel.image = image
            end)
            app.refresh()
        end
    }

    plugin:newCommand{
        id="IsolateRed",
        title="Isolate Red Channel",
        group="material_texture_utils",
        onclick=function()
            if not app.cel then return app.alert "There is no active cel" end

            local image = app.cel.image:clone()
            for pixel in image:pixels() do
                local red = app.pixelColor.rgbaR(pixel());
                pixel(app.pixelColor.rgba(red, 0, 0))
            end
            app.transaction(
            "Isolated red channel",
            function()
                app.cel.image = image
            end)
            app.refresh()
        end
    }

    plugin:newCommand{
        id="AlphaLockActiveMerge",
        title="Merge to Active Alpha Lock",
        group="material_texture_utils",
        onclick=function()
            -- Check if selection requirements are met
            if not app.cel then return app.alert "There is no active cel" end
            if not app.range.type == RangeType.CELS then return app.alert "There is no active cel selection" end
            if #app.range.cels < 2 then return app.alert "Not enough cels selected" end

            local focusedImage = app.cel.image:clone()

            app.transaction(
            "Merged to active alpha lock cel",
            function()
                -- Loop trough all selected cels
                for i, cel in ipairs(app.range.cels) do
                    -- Ignore focused cel
                    if cel ~= app.cel then
                        -- Loop trough all pixels of focused cel
                        for pixel in focusedImage:pixels() do
                            -- Get pixel from other cel with offset
                            local otherPixel = cel.image:getPixel(pixel.x + app.cel.position.x, pixel.y + app.cel.position.y)
                            -- Get all colors separately
                            local alphaLock = app.pixelColor.rgbaA(pixel())
                            local red = app.pixelColor.rgbaR(otherPixel)
                            local green = app.pixelColor.rgbaG(otherPixel)
                            local blue = app.pixelColor.rgbaB(otherPixel)
                            -- Overwrite pixel color
                            pixel(app.pixelColor.rgba(red, green, blue, alphaLock))
                        end
                        -- Hide non focused cels
                        cel.layer.isVisible = false
                    end
                end
                -- Overwrite focused cel image
                app.cel.image = focusedImage
            end)
        end
    }
end