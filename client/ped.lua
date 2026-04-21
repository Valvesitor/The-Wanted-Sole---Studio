-- client/ped.lua (VERSÃO STANDALONE FINAL)
local currentPedModel   = 'player_zero'
local currentOutfitSlot = 1
local appliedItems      = {}

local previewPed    = nil
local previewActive = false

-- ---------------------------------------------------------------
-- PARSE DO XML
-- ---------------------------------------------------------------
function Ped_ParseOutfitXml(xmlStr)
    -- Tenta usar o parser do manifest (shared/slaxmlparser.lua)
    if OlympoXML then 
        return OlympoXML.parseItems(xmlStr) 
    elseif slaxmlparser then 
        return slaxmlparser.parseItems(xmlStr)
    end
    return nil, 'Parser XML não encontrado'
end

-- ---------------------------------------------------------------
-- APLICAÇÃO DE COMPONENTE (SISTEMA MELHORADO)
-- ---------------------------------------------------------------
local function ApplyComponent(ped, item)
    if not ped or not DoesEntityExist(ped) then return false end

    -- Garante que os valores sejam números
    local compId = tonumber(item.component)
    local drawable = tonumber(item.drawable)
    local tex = tonumber(item.texture) or 0
    local pal = tonumber(item.palette) or 0

    if compId == nil or drawable == nil then 
        print('^1[Erro]^7 Item inválido: Component ' .. tostring(compId) .. ' Drawable ' .. tostring(drawable))
        return false 
    end

    -- Log de Debug para saber o que está sendo aplicado
    if Config and Config.Debug then
        print(string.format('^5[Applying]^7 Ped: %s | Comp: %d | Draw: %d | Tex: %d', tostring(ped), compId, drawable, tex))
    end

    -- Tentativa 1: Nativa Padrão
    local ok = pcall(SetPedComponentVariation, ped, compId, drawable, tex, pal)
    
    if not ok then
        -- Tentativa 2: Se a nativa falhar, tenta via InvokeNative (algumas builds de RedM exigem)
        ok = pcall(function()
            Citizen.InvokeNative(0x22A1732A, ped, compId, drawable, tex, pal) -- Hash de SetPedComponentVariation
        end)
    end

    return ok
end

function Ped_ApplyOutfit(items, xmlStr)
    local ped = Ped_GetTargetPed()
    if not ped or not DoesEntityExist(ped) then return false, 'Ped não existe' end

    local applied = 0
    local errors = {}

    -- IMPORTANTE: Limpar o Ped antes de aplicar (opcional, mas evita conflitos)
    -- Para cada componente possível (0-12), resetar para 0 ou remover
    -- for i=0, 12 do SetPedComponentVariation(ped, i, 0, 0, 0) end

    for i, item in ipairs(items) do
        if ApplyComponent(ped, item) then
            applied = applied + 1
        else
            table.insert(errors, 'Item ' .. i .. ' (Draw: ' .. tostring(item.drawable) .. ')')
        end
    end

    appliedItems = items
    
    if applied > 0 then
        return true, { applied = applied, total = #items, errors = errors }
    else
        return false, 'Nenhuma peça de roupa pôde ser aplicada (Verifique se os IDs são Vanilla ou Custom)'
    end
end


-- ---------------------------------------------------------------
-- PREVIEW PED (MODELOS)
-- ---------------------------------------------------------------
function Ped_CreatePreview(modelName)
    Ped_DestroyPreview()
    local model = GetHashKey(modelName)

    RequestModel(model)
    local waited = 0
    while not HasModelLoaded(model) and waited < 80 do
        Wait(100)
        waited = waited + 1
    end

    if not HasModelLoaded(model) then
        return false, 'Timeout ao carregar modelo'
    end

    local camCoords = GetGameplayCamCoord()
    local camRot    = GetGameplayCamRot(2)
    local pitch     = math.rad(camRot.x)
    local yaw       = math.rad(camRot.z)
    local dist      = 3.0

    local spawnX = camCoords.x + -math.sin(yaw) * math.cos(pitch) * dist
    local spawnY = camCoords.y +  math.cos(yaw) * math.cos(pitch) * dist
    local spawnZ = camCoords.z +  math.sin(pitch) * dist
    local heading = (camRot.z + 180.0) % 360.0

    -- Nativa de criação de Ped do RedM
    previewPed = Citizen.InvokeNative(0xD49F9B0955C367DE, model, spawnX, spawnY, spawnZ, heading, false, false, false, false)

    if not previewPed or previewPed == 0 then
        return false, 'Falha ao criar ped de preview'
    end

    SetEntityInvincible(previewPed, true)
    SetBlockingOfNonTemporaryEvents(previewPed, true)
    SetPedCanRagdoll(previewPed, false)
    FreezeEntityPosition(previewPed, true)
    
    previewActive   = true
    currentPedModel = modelName
    appliedItems    = {}

    return true, nil
end

function Ped_DestroyPreview()
    if previewPed and DoesEntityExist(previewPed) then
        DeleteEntity(previewPed)
    end
    previewPed    = nil
    previewActive = false
end

function Ped_GetPreviewPed()
    if previewActive and previewPed and DoesEntityExist(previewPed) then
        return previewPed
    end
    return nil
end

function Ped_GetTargetPed()
    local preview = Ped_GetPreviewPed()
    if preview and DoesEntityExist(preview) then
        return preview
    end
    return PlayerPedId()
end

-- ---------------------------------------------------------------
-- APLICAÇÃO DE OUTFIT (SISTEMA STANDALONE)
-- ---------------------------------------------------------------
function Ped_ApplyOutfit(items, xmlStr)
    local ped = Ped_GetTargetPed()
    if not ped or not DoesEntityExist(ped) then return false, 'Ped não existe' end

    local applied = 0
    local errors = {}

    -- Aplica cada item da lista usando as nativas do RedM
    for _, item in ipairs(items) do
        if ApplyComponent(ped, item) then
            applied = applied + 1
        else
            table.insert(errors, item.drawable)
        end
    end

    appliedItems = items
    
    if applied > 0 then
        return true, { applied = applied, total = #items, errors = errors }
    else
        return false, 'Nenhuma peça de roupa pôde ser aplicada'
    end
end

function Ped_ApplyOutfitToPlayer(items)
    local ped = PlayerPedId()
    if not ped or not DoesEntityExist(ped) then return false, 'Player ped não existe' end
    
    local applied = 0
    local errors = {}

    for _, item in ipairs(items) do
        if ApplyComponent(ped, item) then
            applied = applied + 1
        else
            table.insert(errors, item.drawable)
        end
    end

    if applied == 0 and #items > 0 then
        return false, 'Nenhum drawable foi aplicado'
    end

    return true, { applied = applied, total = #items, errors = errors }
end

-- ---------------------------------------------------------------
-- OUTRAS FUNÇÕES
-- ---------------------------------------------------------------
function Ped_CaptureCurrentOutfit()
    if #appliedItems == 0 then return nil, 'Nenhum outfit aplicado' end
    -- Tenta usar o parser correto definido no manifest
    local xml = (OlympoXML and OlympoXML.itemsToXml(appliedItems)) or (slaxmlparser and slaxmlparser.itemsToXml(appliedItems))
    return xml, nil
end

function Ped_ApplyDrawableColor(drawableName, tint0, tint1, tint2, palette)
    local ped = Ped_GetTargetPed()
    if not DoesEntityExist(ped) then return false end

    for _, item in ipairs(appliedItems) do
        if item.drawable == drawableName then
            item.tint0, item.tint1, item.tint2, item.palette = tint0, tint1, tint2, palette
            break
        end
    end
    
    Ped_ApplyOutfit(appliedItems, nil)
    return true
end

function Ped_SetModel(modelName)
    if not modelName or modelName == '' then return false, 'Modelo vazio' end
    return Ped_CreatePreview(modelName)
end

CreateThread(function()
    while true do
        Wait(500) 
        if previewActive and previewPed and DoesEntityExist(previewPed) then
            FreezeEntityPosition(previewPed, true)
        end
    end
end)

function Ped_GetModel()   return currentPedModel   end
function Ped_GetApplied() return appliedItems       end
function Ped_GetSlot()    return currentOutfitSlot  end
function Ped_SetSlot(s)   currentOutfitSlot = tonumber(s) or 1 end
