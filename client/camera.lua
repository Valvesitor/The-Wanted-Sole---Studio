-- client/camera.lua
-- Câmera orbital para preview — RedM

local cam       = nil
local camActive = false

local camState = {
    zoom   = 1.35,
    rotH   = 0.0,
    rotV   = -6.0,
    height = 0.0,
    focus  = 'body',
    pedRot = 0.0,
}

local focusConfigs = {
    body = { distMult = 1.0, zOff =  0.00 },
    head = { distMult = 0.3, zOff =  0.65 },
    feet = { distMult = 0.5, zOff = -0.70 },
}

local BASE_DIST = 2.2

-- Obtém o ped alvo
local function GetTargetPed()
    if Ped_GetPreviewPed then
        local preview = Ped_GetPreviewPed()
        if preview and DoesEntityExist(preview) then
            return preview
        end
    end
    return PlayerPedId()
end

-- Aplica a transformação da câmera
local function ApplyCamTransform()
    if not camActive or not cam then return end

    local ped = GetTargetPed()
    if not ped or not DoesEntityExist(ped) then return end

    if ped ~= PlayerPedId() then
        SetEntityHeading(ped, camState.pedRot)
    end

    local center = GetEntityCoords(ped)
    local cfg = focusConfigs[camState.focus] or focusConfigs.body

    local dist = BASE_DIST * camState.zoom * cfg.distMult
    if dist < 0.3 then dist = 0.3 end

    local rH = math.rad(camState.rotH)
    local rV = math.rad(camState.rotV)
    local cosV = math.cos(rV)
    local sinV = math.sin(rV)

    local cx = center.x + dist * math.sin(rH) * cosV
    local cy = center.y - dist * math.cos(rH) * cosV
    local cz = center.z + cfg.zOff + camState.height + dist * sinV

    local tz = center.z + cfg.zOff + camState.height

    SetCamCoord(cam, cx, cy, cz)
    PointCamAtCoord(cam, center.x, center.y, tz)
end

function Camera_Create()
    if camActive then return end

    -- Destrói se existir algo residual
    if cam then DestroyCam(cam, false) end

    cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    if not cam then
        print('[Camera] Erro ao criar câmera')
        return
    end

    SetCamActive(cam, true)
    RenderScriptCams(true, false, 0, true, false)

    camActive = true
    ApplyCamTransform()
end

function Camera_Destroy()
    if not camActive then return end

    RenderScriptCams(false, false, 0, true, false)
    if cam and DoesCamExist(cam) then
        DestroyCam(cam, false)
    end

    cam = nil
    camActive = false
end

function Camera_SetParams(params)
    if params.zoom   ~= nil then camState.zoom   = math.max(0.1, tonumber(params.zoom)   or 1.0) end
    if params.rotH   ~= nil then camState.rotH   = tonumber(params.rotH)   or 0.0  end
    if params.rotV   ~= nil then camState.rotV   = tonumber(params.rotV)   or -6.0 end
    if params.height ~= nil then camState.height = tonumber(params.height) or 0.0  end
    if params.focus  ~= nil then camState.focus  = params.focus end
    if params.pedRot ~= nil then camState.pedRot = tonumber(params.pedRot) or 0.0 end
    -- A atualização visual agora é feita na thread de 0ms
end

function Camera_GetState() return camState end
function Camera_IsActive() return camActive end

-- Thread de manutenção (Sincronizada a 60fps/0ms)
CreateThread(function()
    while true do
        if camActive then
            local playerPed = PlayerPedId()
            FreezeEntityPosition(playerPed, true)
            ApplyCamTransform()
            Wait(0) -- CRUCIAL: Câmeras precisam de 0ms para serem fluidas
        else
            Wait(500) -- Quando inativa, não gasta CPU
        end
    end
end)

-- Removido o RegisterNUICallback daqui para evitar duplicata com o client.lua
