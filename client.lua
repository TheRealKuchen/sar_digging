local digging = false
local allowedMaterials = Config.AllowedMaterials

local function isGroundAllowed()
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local endCoords = coords - vector3(0.0, 0.0, 2.0)

    local rayHandle = StartShapeTestRay(coords.x, coords.y, coords.z, endCoords.x, endCoords.y, endCoords.z, 1, playerPed,
        0)
    local _, hit, _, _, materialHash = GetShapeTestResultEx(rayHandle)

    if Config.Debug then
        print("[DEBUG] MaterialHash: " ..
        tostring(materialHash) .. " | Allowed: " .. tostring(Config.AllowedMaterials[materialHash] == true))
    end

    return allowedMaterials[materialHash] == true
end

local function playDigAnimation(callback)
    local ped = PlayerPedId()
    local cancelled = false

    FreezeEntityPosition(ped, true)

    local model = `prop_tool_shovel`
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(0) end

    local shovel = CreateObject(model, GetEntityCoords(ped), true, true, true)
    AttachEntityToEntity(shovel, ped, GetPedBoneIndex(ped, 28422), 0.0, 0.0, 0.24, 0.0, 0.0, 0.0, true, true, false, true,
        1, true)

    local dict = "random@burial"
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do Wait(0) end

    TaskPlayAnim(ped, dict, "a_burial", 8.0, -8.0, -1, 1, 0, false, false, false)

    -- Progressbar starten
    local progressData = {
        label = Config.Transl.digging_label,
        duration = 10000,
        canCancel = true,
        disable = {
            move = true,
            car = true,
            combat = true,
            mouse = false,
            sprint = true,
        },
        anim = {
            dict = dict,
            clip = "a_burial",
            flag = 1,
        },
        prop = {
            model = model,
            bone = 28422,
            pos = { x = 0.0, y = 0.0, z = 0.24 },
            rot = { x = 0.0, y = 0.0, z = 0.0 }
        }
    }

    local retVal = exports.ls_progressbar:progressBar(progressData)

    if not retVal then
        -- Falls abgebrochen oder fehlgeschlagen
        cancelled = true
    end

    -- Nach Ende Progressbar / Abbruch:
    ClearPedTasks(ped)
    DeleteEntity(shovel)
    FreezeEntityPosition(ped, false)

    if cancelled then
        digging = false
        TriggerEvent('okokNotify:Alert', Config.Transl.cancelled_title, Config.Transl.cancelled_text, 5000, 'error')
        return
    end

    callback()
end

exports('useShovel', function(item)
    if digging then return end

    if not isGroundAllowed() then
        TriggerEvent('okokNotify:Alert', Config.Transl.not_allowed_title, Config.Transl.not_allowed_text, 7000, 'error')
        return
    end

    digging = true
    TriggerEvent('okokNotify:Alert', Config.Transl.digging_title, Config.Transl.digging_text, 5000, 'info')

    playDigAnimation(function()
        TriggerServerEvent('dig:rewardItem')
        digging = false
    end)
end)

RegisterNetEvent('dig:notifyItemFound', function(itemName, itemLabel)
    if itemName == "nothing" then
        TriggerEvent('okokNotify:Alert', Config.Transl.nothing_title, Config.Transl.nothing_text, 7000, 'error')
        return
    end

    local label = itemLabel or itemName
    local message = string.format(Config.Transl.found_text, label)
    TriggerEvent('okokNotify:Alert', Config.Transl.found_title, message, 7000, 'success')
end)
