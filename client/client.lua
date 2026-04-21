-- client/client.lua
local isOpen = false
local usePreviewMode = false

local function Log(msg)
    if Config.Debug then print('^3[TWS Client]^7 ' .. tostring(msg)) end
end

-- ============================================================
-- HELPERS PARA DADOS (data/*.lua)
-- ============================================================

-- Retorna lista de categorias disponíveis para um gênero
local function GetCategories(gender)
    local result = {}
    if type(ComponentsByCategory) ~= 'table' then return result end
    local gTbl = ComponentsByCategory[gender]
    if type(gTbl) ~= 'table' then return result end
    for cat, _ in pairs(gTbl) do
        table.insert(result, cat)
    end
    table.sort(result)
    return result
end

-- Retorna paletas simplificadas (só os nomes)
local function GetPaletteNames()
    local result = {}
    if type(Palettes) ~= 'table' then return result end
    for name, _ in pairs(Palettes) do
        table.insert(result, name)
    end
    table.sort(result)
    return result
end

local function OpenUI()
    if isOpen then return end
    isOpen = true

    SetNuiFocus(true, true)
    DisplayHud(false)
    DisplayRadar(false)

    -- 1. Se estiver em modo preview, cria o ped de preview; senão garante que não exista
    local currentModel = Ped_GetModel()
    if usePreviewMode then
        local ok, err = Ped_CreatePreview(currentModel)
        if not ok then
            Log('Preview ped falhou: ' .. tostring(err))
            SendNUIMessage({ type = 'serverMsg', message = 'Falha ao criar preview: ' .. tostring(err), msgType = 'error' })
            -- Desativa preview se falhar
            usePreviewMode = false
            Ped_DestroyPreview()
        else
            -- Aguardar até o ped aparecer (3s)
            local waited, maxWait = 0, 3000
            while waited < maxWait do
                local preview = Ped_GetPreviewPed()
                if preview and DoesEntityExist(preview) then break end
                Wait(50)
                waited = waited + 50
            end
            local preview = Ped_GetPreviewPed()
            if not preview or not DoesEntityExist(preview) then
                Log('Preview não apareceu após ' .. tostring(maxWait) .. 'ms')
                SendNUIMessage({ type = 'serverMsg', message = 'Preview não apareceu', msgType = 'error' })
                Ped_DestroyPreview()
                usePreviewMode = false
            end
        end
    else
        Ped_DestroyPreview()
    end

    -- 2. Criar a câmera apontando para o alvo atual (player)
    Camera_Create()

    TriggerServerEvent('olympo:requestProjects')

    SendNUIMessage({
        type          = 'open',
        pedModel      = Ped_GetModel(),
        slotIndex     = Ped_GetSlot(),
        camState      = Camera_GetState(),
        usePreview    = usePreviewMode,
        knownPalettes = Config.KnownPalettes,
        commonPeds    = Config.CommonPeds,
        -- Dados dos arquivos data/
        categories    = {
            male   = GetCategories('male'),
            female = GetCategories('female'),
        },
        paletteNames  = GetPaletteNames(),
    })

    Log('UI aberta | modelo: ' .. currentModel)
end

local function CloseUI(fromNui)
    if not isOpen then return end
    isOpen = false

    SetNuiFocus(false, false)
    Camera_Destroy()
    Ped_DestroyPreview()
    FreezeEntityPosition(PlayerPedId(), false)

    DisplayHud(true)
    DisplayRadar(true)

    if not fromNui then
        SendNUIMessage({ type = 'close' })
    end
    Log('UI fechada')
end

-- ============================================================
-- NUI CALLBACKS (CENTRALIZADOS AQUI)
-- ============================================================

RegisterNUICallback('close', function(_, cb)
    CloseUI(true)
    cb({ ok = true })
end)

-- Câmera - Único lugar onde este callback deve existir
RegisterNUICallback('cameraUpdate', function(data, cb)
    Camera_SetParams(data)
    cb({ ok = true })
end)

-- Aplicar outfit (no preview ped)
RegisterNUICallback('applyOutfit', function(data, cb)
    local xmlStr = data.xml
    local pedMdl = data.pedModel
    local slot   = data.slot

    -- 0. Validação inicial
    if not xmlStr or xmlStr == '' then
        cb({ ok = false, error = 'XML vazio' })
        return
    end

    -- 1. Validar XML
    local valid, valErr = OlympoXML.validate(xmlStr)
    if not valid then
        cb({ ok = false, error = valErr })
        return
    end

        -- 2. Em modo player, ignoramos tentativa de trocar modelo client-side
        if pedMdl and pedMdl ~= '' and pedMdl ~= Ped_GetModel() then
            Log('Ignorando troca de modelo (modo player ativo): ' .. pedMdl)
            SendNUIMessage({ type = 'serverMsg', message = 'Ignorando troca de modelo (modo player)', msgType = 'warn' })
        end

    -- 3. Parse
    local items, parseErr = Ped_ParseOutfitXml(xmlStr)
    if not items then
        cb({ ok = false, error = parseErr or 'Falha no parse XML' })
        return
    end
    if Config and Config.Debug then
        print(('^3[Client]^7 applyOutfit: parsed %d items'):format(#items))
    end

    -- 4. Aplicar drawables no preview ped
    local ok, result = Ped_ApplyOutfit(items, xmlStr)
    if not ok then
        local resStr = tostring(result or '')
        -- Se falhou → salva pending e avisa claramente
        if resStr:find('no_export_found') or resStr:find('unable_to_apply') or resStr:find('SetPedComponentVariation') then
            TriggerServerEvent('olympo:setPendingApply', { xml = xmlStr, model = Ped_GetModel() })
            -- Mensagem clara
            local msg = 'Nenhum resource metaped encontrado. Outfit será aplicado no próximo spawn. Configure Config.MetapedResource em shared/config.lua se tiver um instalado.'
            SendNUIMessage({ type = 'serverMsg', message = msg, msgType = 'warn' })
            cb({ ok = true, warning = 'pending_saved', result = { applied = 0, total = #items, errors = {} } })
            return
        end
        cb({ ok = false, error = resStr })
        return
    end

    if slot then Ped_SetSlot(slot) end

    -- 5. Salvar no servidor
    TriggerServerEvent('olympo:saveOutfit', {
        xml   = xmlStr,
        slot  = Ped_GetSlot(),
        model = Ped_GetModel(),
    })

    cb({ ok = true, result = result })
end)

-- Aplicar outfit no player real (confirmar)
RegisterNUICallback('confirmOutfit', function(_, cb)
    local items = Ped_GetApplied()
    if #items == 0 then
        cb({ ok = false, error = 'Nenhum outfit para confirmar' })
        return
    end
    local ok, result = Ped_ApplyOutfitToPlayer(items)
    cb({ ok = ok, result = result })
end)

-- Capturar outfit atual
RegisterNUICallback('captureOutfit', function(_, cb)
    local xml, err = Ped_CaptureCurrentOutfit()
    if xml then
        cb({ ok = true, xml = xml })
    else
        cb({ ok = false, error = err })
    end
end)

-- Cor (com validação)
RegisterNUICallback('applyColor', function(data, cb)
    if not data or not data.drawable then
        cb({ ok = false, error = 'Drawable inválido' })
        return
    end
    local ok = Ped_ApplyDrawableColor(
        data.drawable,
        tonumber(data.tint0) or 0,
        tonumber(data.tint1) or 0,
        tonumber(data.tint2) or 0,
        data.palette or ''
    )
    cb({ ok = ok })
end)

-- Aplicar outfit no jogador agora (via NUI) -> encaminha ao servidor
RegisterNUICallback('applyToPlayer', function(data, cb)
    local xml = data.xml or ''
    local model = data.pedModel or Ped_GetModel()
    local slot = data.slot or Ped_GetSlot()
    TriggerServerEvent('olympo:applyNow', { xml = xml, model = model, slot = slot })
    cb({ ok = true })
end)

-- Toggle preview mode (NUI)
local function SetPreviewMode(enable)
    if enable then
        local cur = Ped_GetModel() or 'player_zero'
        local ok, err = Ped_CreatePreview(cur)
        if not ok then return false, err end
        local waited, maxWait = 0, 3000
        while waited < maxWait do
            local preview = Ped_GetPreviewPed()
            if preview and DoesEntityExist(preview) then return true end
            Wait(50)
            waited = waited + 50
        end
        Ped_DestroyPreview()
        return false, 'Timeout ao criar preview'
    else
        Ped_DestroyPreview()
        return true
    end
end

RegisterNUICallback('togglePreview', function(data, cb)
    local use = data.usePreview == true
    local ok, err = SetPreviewMode(use)
    if ok then usePreviewMode = use end
    cb({ ok = ok, error = err })
end)

-- Setar modelo
RegisterNUICallback('setPedModel', function(data, cb)
    local model = data.model or ''
    if model == '' then
        cb({ ok = false, error = 'Modelo vazio' })
        return
    end

    if not usePreviewMode then
        cb({ ok = false, error = 'Ative "Usar preview" para trocar modelo localmente' })
        return
    end

    cb({ ok = true, pending = true })

    CreateThread(function()
        SendNUIMessage({ type = 'serverMsg', message = 'Carregando modelo: ' .. model, msgType = 'info' })

        local ok, err = Ped_SetModel(model)
        if ok then
            Wait(300)
            Camera_Destroy()
            Wait(400)
            Camera_Create()
            SendNUIMessage({ type = 'serverMsg', message = 'Modelo carregado: ' .. model, msgType = 'success' })
        else
            SendNUIMessage({ type = 'serverMsg', message = 'Erro ao carregar modelo: ' .. tostring(err), msgType = 'error' })
        end
    end)
end)

-- Projetos
RegisterNUICallback('saveProject', function(data, cb)
    TriggerServerEvent('olympo:saveProject', data)
    cb({ ok = true })
end)

RegisterNUICallback('deleteProject', function(data, cb)
    TriggerServerEvent('olympo:deleteProject', data.name)
    cb({ ok = true })
end)

RegisterNUICallback('loadProject', function(data, cb)
    TriggerServerEvent('olympo:loadProject', data.name, data.slot)
    cb({ ok = true })
end)

RegisterNUICallback('refreshProjects', function(_, cb)
    TriggerServerEvent('olympo:requestProjects')
    cb({ ok = true })
end)

-- ============================================================
-- DADOS DA PASTA data/ — CALLBACKS NUI
-- ============================================================

-- Retorna lista de drawables de uma categoria específica
RegisterNUICallback('browseCategory', function(data, cb)
    local gender   = tostring(data.gender or 'male')
    local category = tostring(data.category or '')

    if category == '' then
        cb({ ok = false, error = 'Categoria vazia' })
        return
    end

    if type(ComponentsByCategory) ~= 'table' then
        cb({ ok = false, error = 'ComponentsByCategory não carregado (verifique fxmanifest)' })
        return
    end

    local gTbl = ComponentsByCategory[gender]
    if type(gTbl) ~= 'table' then
        cb({ ok = false, error = 'Gênero inválido: ' .. gender })
        return
    end

    local list = gTbl[category]
    if type(list) ~= 'table' then
        cb({ ok = false, error = 'Categoria não encontrada: ' .. category })
        return
    end

    cb({ ok = true, drawables = list })
end)

-- Retorna info de um drawable específico (albedo, material, normal, palette)
RegisterNUICallback('getDrawableInfo', function(data, cb)
    local gender   = tostring(data.gender or 'male')
    local drawable = tostring(data.drawable or '')

    if drawable == '' then
        cb({ ok = false })
        return
    end

    if type(MetaPedAssets) ~= 'table' then
        -- MetaPedAssets não carregado; retornar vazio mas sem erro
        cb({ ok = true, albedo = '', material = '', normal = '', palette = '' })
        return
    end

    local gTbl = MetaPedAssets[gender]
    if type(gTbl) ~= 'table' then
        cb({ ok = true, albedo = '', material = '', normal = '', palette = '' })
        return
    end

    local info = gTbl[drawable]
    if type(info) ~= 'table' then
        cb({ ok = true, albedo = '', material = '', normal = '', palette = '' })
        return
    end

    -- Pega primeiro albedo, material, normal disponíveis
    local albedo   = (type(info.albedos)   == 'table' and info.albedos[1])   or ''
    local material = (type(info.materials) == 'table' and info.materials[1]) or ''
    local normal   = (type(info.normals)   == 'table' and info.normals[1])   or ''
    local palette  = info.category or ''

    cb({
        ok       = true,
        albedo   = albedo,
        material = material,
        normal   = normal,
        palette  = palette,
        category = info.category or '',
    })
end)

-- ============================================================
-- EVENTOS DO SERVIDOR
-- ============================================================

RegisterNetEvent('olympo:receiveProjects')
AddEventHandler('olympo:receiveProjects', function(projects)
    SendNUIMessage({ type = 'projects', data = projects })
end)

RegisterNetEvent('olympo:receiveOutfit')
AddEventHandler('olympo:receiveOutfit', function(outfitData)
    if outfitData and outfitData.xml then
        SendNUIMessage({
            type  = 'loadOutfit',
            xml   = outfitData.xml,
            slot  = outfitData.slot,
            model = outfitData.model,
        })
    end
end)

RegisterNetEvent('olympo:serverMsg')
AddEventHandler('olympo:serverMsg', function(msg, msgType)
    SendNUIMessage({ type = 'serverMsg', message = msg, msgType = msgType or 'info' })
end)

-- ============================================================
-- COMANDO /creator
-- ============================================================
RegisterCommand('creator', function()
    if isOpen then CloseUI(false) else OpenUI() end
end, false)

-- ============================================================
-- INICIALIZAÇÃO
-- ============================================================
AddEventHandler('onClientResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    Wait(3000)
    TriggerServerEvent('olympo:requestProjects')
    Log('Resource iniciado | use /creator para abrir')
end)

-- Pedir pending apply no spawn
AddEventHandler('playerSpawned', function()
    TriggerServerEvent('olympo:requestPending')
end)

RegisterNetEvent('olympo:applyPending')
AddEventHandler('olympo:applyPending', function(data)
    if not data or not data.xml then return end
    SendNUIMessage({ type = 'serverMsg', message = 'Aplicando outfit pendente no spawn...', msgType = 'info' })
    local items, err = Ped_ParseOutfitXml(data.xml)
    if not items then
        SendNUIMessage({ type = 'serverMsg', message = 'Erro ao parsear outfit pendente', msgType = 'error' })
        return
    end
    -- Se o model for diferente, pedir ao servidor para respawnar (simples: apenas notificar)
    -- Aplicar os drawables localmente (funciona se nativas disponíveis)
    local ok, res = Ped_ApplyOutfit(items, data.xml)
    if ok then
        SendNUIMessage({ type = 'serverMsg', message = 'Outfit aplicado no spawn (local)', msgType = 'success' })
    else
        SendNUIMessage({ type = 'serverMsg', message = 'Falha ao aplicar outfit pendente: ' .. tostring(res), msgType = 'error' })
    end
end)
