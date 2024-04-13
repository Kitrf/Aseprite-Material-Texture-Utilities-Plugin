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
                for _, cel in ipairs(app.range.cels) do
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

    plugin:newCommand{
        id="GenerateTextures",
        title="Generate Textures",
        group="file_import",
        onclick=function()
            local imageFileTypes = {"jpg", "jpeg", "png"};
            local dlg = Dialog("Convert Textures")

            -- Always create new row
            dlg:newrow{ always=true }

            -- Create string field used for autofill identifier
            dlg:entry{ id="folder", label="Folder path"}
            dlg:entry{ id="identifier", label="File match name"}

            -- Create button to autofill fields if one is selected
            local function autofillTextures()
                -- If identifier is sete attempt autofill
                if app.fs.isDirectory(dlg.data.folder) and dlg.data.identifier ~= "" then

                    local function filterFilenames(filenames, searchString)
                        local filteredFilenames = {}
                        for _, filename in ipairs(filenames) do
                            if filename:find(searchString) then
                                table.insert(filteredFilenames, filename)
                            end
                        end
                        return filteredFilenames
                    end

                    local matchingFiles = filterFilenames(app.fs.listFiles(dlg.data.folder), dlg.data.identifier)

                    local function findFirstMatch(filenames, searchStrings, stringToRemove)
                        for _, filename in ipairs(filenames) do
                            local modifiedFilename = filename:gsub(stringToRemove, "") -- Remove the specified string
                            local lowercaseFilename = modifiedFilename:lower() -- Convert filename to lowercase
                            for _, searchString in ipairs(searchStrings) do
                                local lowercaseSearchString = searchString:lower() -- Convert search string to lowercase
                                if lowercaseFilename:find(lowercaseSearchString) then
                                    return app.fs.joinPath(dlg.data.folder, filename)
                                end
                            end
                        end
                        return nil -- If no match is found
                    end

                    if not app.fs.isFile(dlg.data.albedo) then
                        dlg:modify { id="albedo", filename=findFirstMatch(matchingFiles, {"albedo", "color", "base"}, dlg.data.identifier) }
                    end
                    if not app.fs.isFile(dlg.data.alpha) then
                        dlg:modify { id="alpha", filename=findFirstMatch(matchingFiles, {"alpha", "opacity"}, dlg.data.identifier) }
                    end
                    if not app.fs.isFile(dlg.data.ao) then
                        dlg:modify { id="ao", filename=findFirstMatch(matchingFiles, {"ambientocclusion", "occlusion", "occ"}, dlg.data.identifier) }
                    end
                    if not app.fs.isFile(dlg.data.metal) then
                        dlg:modify { id="metal", filename=findFirstMatch(matchingFiles, {"metal"}, dlg.data.identifier) }
                    end
                    if not app.fs.isFile(dlg.data.roughness) then
                        dlg:modify { id="roughness", filename=findFirstMatch(matchingFiles, {"rough"}, dlg.data.identifier) }
                    end
                    if not app.fs.isFile(dlg.data.normal) then
                        dlg:modify { id="normal", filename=findFirstMatch(matchingFiles, {"normal"}, dlg.data.identifier) }
                    end
                    if not app.fs.isFile(dlg.data.emission) then
                        dlg:modify { id="emission", filename=findFirstMatch(matchingFiles, {"emission"}, dlg.data.identifier) }
                    end
                end
            end

            local function updateIdentifier()
                if dlg.data.folder ~= "" then return end
                if dlg.data.identifier ~= "" then return end
                for _, path in pairs(dlg.data) do
                    if type(path) == "string" then
                        if path ~= "" then
                            local fileName = app.fs.fileName(path)
                            dlg:modify { id="folder", text=app.fs.filePath(path) }
                            dlg:modify { id="identifier", text=GetPrefixBeforeLastUnderscore(fileName) }
                            if dlg.data.newname == "" then dlg:modify { id="newname", text=dlg.data.identifier } end
                            break
                        end
                    end
                end

                autofillTextures()
            end

            dlg:separator()

            -- Create file fields for all possible textures
            dlg:file{ id="albedo", label="Albedo Texture", filetypes=imageFileTypes, onchange=updateIdentifier }
            dlg:file{ id="alpha", label="Alpha Texture", filetypes=imageFileTypes, onchange=updateIdentifier }
            dlg:file{ id="ao", label="Ambient Occlusion Texture", filetypes=imageFileTypes, onchange=updateIdentifier }
            dlg:file{ id="metal", label="Metal Texture", filetypes=imageFileTypes, onchange=updateIdentifier }
            dlg:file{ id="roughness", label="Roughness Texture", filetypes=imageFileTypes, onchange=updateIdentifier }
            dlg:file{ id="normal", label="Normal Texture", filetypes=imageFileTypes, onchange=updateIdentifier }
            dlg:file{ id="emission", label="Emission Texture", filetypes=imageFileTypes, onchange=updateIdentifier }

            dlg:separator()

            dlg:entry{ id="newname", label="Name" }
            dlg:number{ id="resolution", label="Resolution", text="128", decimals=0 }

            dlg:separator()

            -- Generate textures from files
            dlg:button{ id="generate", text="Generate Textures", onclick=function()
                local name = dlg.data.identifier
                if dlg.data.newname ~= "" then name = dlg.data.newname end
                local res = dlg.data.resolution

                local function cloneOpenAndResize(path)
                    if app.fs.isFile(path) then
                        local openedSprite = app.open(path) -- Open sprite
                        if openedSprite then
                            openedSprite:resize(res, res) -- Resize source file
                            local clone = openedSprite.cels[1].image:clone()
                            openedSprite:close()
                            return clone
                        end
                    end
                    return nil
                end

                local function openAndResize(path)
                    if app.fs.isFile(path) then
                        local openedSprite = app.open(path) -- Open sprite
                        if openedSprite then
                            openedSprite:resize(res, res) -- Resize source file
                            return openedSprite
                        end
                    end
                    return nil
                end

                -- Generate albedo alpha texture
                local albedoClone = cloneOpenAndResize(dlg.data.albedo)
                if albedoClone then
                    local newAlbedo = Sprite(res, res) -- Create new sprite to contain albedo
                    newAlbedo.filename = name .. "_Albedo"
                    newAlbedo.cels[1].image = albedoClone

                    -- Combine albedo and alpha
                    local alphaSprite = openAndResize(dlg.data.alpha)
                    if alphaSprite then
                        newAlbedo.filename = newAlbedo.filename .. "_Alpha"
                        alphaSprite.cels[1].image = RedToAlpha(alphaSprite.cels[1].image)
                        newAlbedo.cels[1].image = AlphaLockMerge(alphaSprite.cels[1], newAlbedo.cels[1])

                        alphaSprite:close()
                    end
                end

                -- Generate roughness metal texture
                local roguhnessClone = cloneOpenAndResize(dlg.data.roughness)
                if roguhnessClone then
                    local newRoughnes = Sprite(res, res) -- Create new sprite to contain albedo
                    newRoughnes.filename = name .. "_Roughness"
                    newRoughnes.cels[1].image = RedToAlpha(roguhnessClone)

                    -- Combine roughness and metal
                    local metalSprite = openAndResize(dlg.data.metal)
                    if metalSprite then
                        newRoughnes.filename = newRoughnes.filename .. "_Metal"
                        metalSprite.cels[1].image = IsolateRed(metalSprite.cels[1].image)
                        newRoughnes.cels[1].image = AlphaLockMerge(newRoughnes.cels[1], metalSprite.cels[1])

                        metalSprite:close()
                    end
                end

                -- Generate ambientocclusion texture
                local aoClone = cloneOpenAndResize(dlg.data.ao)
                if aoClone then
                    local newAo = Sprite(res, res) -- Create new sprite to contain albedo
                    newAo.filename = name .. "_AmbientOcclusion"
                    newAo.cels[1].image = aoClone
                end

                -- Generate normal texture
                local normalClone = cloneOpenAndResize(dlg.data.normal)
                if normalClone then
                    local newNormal = Sprite(res, res) -- Create new sprite to contain albedo
                    newNormal.filename = name .. "_Normal"
                    newNormal.cels[1].image = normalClone
                end

                -- Generate emission texture
                local emissionClone = cloneOpenAndResize(dlg.data.emission)
                if emissionClone then
                    local newEmission = Sprite(res, res) -- Create new sprite to contain albedo
                    newEmission.filename = name .. "_Emission"
                    newEmission.cels[1].image = emissionClone
                end

                Dialog:close() -- Close dialog when generated
            end }

            dlg:show()
        end
    }
end

function GetPrefixBeforeLastUnderscore(filename)
    local lastUnderscoreIndex = filename:find("[^_]*_[^_]*$") -- Finds the last occurrence of underscore
    if lastUnderscoreIndex then
        local prefix = filename:sub(1, lastUnderscoreIndex - 1) -- Extracts the substring before the last underscore
        return prefix:gsub("_$", "") -- Removes the last underscore from the result
    else
        return filename -- If there's no underscore, return the original filename
    end
end

function AlphaLockMerge(targetCel, otherCel)
    local focusedImage = targetCel.image:clone()
    -- Loop trough all pixels of focused cel
    for pixel in focusedImage:pixels() do
        -- Get pixel from other cel with offset
        local otherPixel = otherCel.image:getPixel(pixel.x + targetCel.position.x, pixel.y + targetCel.position.y)
        -- Get all colors separately
        local alphaLock = app.pixelColor.rgbaA(pixel())
        local red = app.pixelColor.rgbaR(otherPixel)
        local green = app.pixelColor.rgbaG(otherPixel)
        local blue = app.pixelColor.rgbaB(otherPixel)
        -- Overwrite pixel color
        pixel(app.pixelColor.rgba(red, green, blue, alphaLock))
    end
    -- Overwrite focused cel image
    return focusedImage
end

function RedToAlpha(targetImage)
    local image = targetImage:clone()
    for pixel in image:pixels() do
        pixel(app.pixelColor.rgba(0, 0, 0, app.pixelColor.rgbaR(pixel())))
    end
    return image
end

function IsolateRed(targetImage)
    local image = targetImage:clone()
    for pixel in image:pixels() do
        local red = app.pixelColor.rgbaR(pixel());
        pixel(app.pixelColor.rgba(red, 0, 0))
    end
    return image
end