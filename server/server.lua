-- server/server.lua

local db = {}  -- { [identifier] = { projects = {}, outfits = {} } }

local function Log(msg)
    if Config.Debug then print('^2[Olympo Server]^7 ' .. tostring(msg)) end
end

local function GetId(source)
    for i = 0, GetNumPlayerIdentifiers(source)-1 do
        local id = GetPlayerIdentifier(source, i)
        if id and (id:find('steam:') or id:find('license:')) then return id end
    end
    return 'player_'..source
end

local function GetOrCreate(id)
    if not db[id] then db[id] = { projects = {}, outfits = {}, lastReq = 0 } end
    return db[id]
end

-- Rate limit simples
local function CheckRate(source)
    local id   = GetId(source)
    local data = GetOrCreate(id)
    local now  = os.time()
    if now - data.lastReq < 1 then return false end
    data.lastReq = now
    return true
end

-- ============================================================
-- FUNÇÃO PARA APLICAR OUTFIT NO JOGADOR (RedM)
-- ============================================================
local function ApplyOutfitToPlayer(source, xmlStr)
    -- Em RedM, aplicar outfit é feito através de triggers e eventos
    -- O XML precisa ser validado e processado pelo client
    TriggerClientEvent('olympo:applyPending', source, {
        xml   = xmlStr,
        model = '',
        when  = os.time(),
    })
end

-- ============================================================
-- PROJETOS
-- ============================================================

RegisterServerEvent('olympo:saveProject')
AddEventHandler('olympo:saveProject', function(projectData)
    local src  = source
    if not CheckRate(src) then return end
    local id   = GetId(src)
    local data = GetOrCreate(id)

    local name = tostring(projectData.name or 'Projeto'):sub(1, 40)

    -- Encontrar ou criar projeto
    local found = false
    for _, p in ipairs(data.projects) do
        if p.name == name then
            p.slots = projectData.slots or p.slots
            p.model = projectData.model or p.model
            found = true
            break
        end
    end
    if not found then
        if #data.projects >= 20 then
            TriggerClientEvent('olympo:serverMsg', src, 'Limite de 20 projetos atingido', 'warn')
            return
        end
        table.insert(data.projects, {
            name  = name,
            slots = projectData.slots or {},
            model = projectData.model or 'player_zero',
        })
    end

    Log(('Projeto "%s" salvo para %s'):format(name, id))
    TriggerClientEvent('olympo:serverMsg', src, 'Projeto "'..name..'" salvo!', 'success')
    TriggerClientEvent('olympo:receiveProjects', src, data.projects)
end)

RegisterServerEvent('olympo:deleteProject')
AddEventHandler('olympo:deleteProject', function(name)
    local src  = source
    local id   = GetId(src)
    local data = GetOrCreate(id)

    for i, p in ipairs(data.projects) do
        if p.name == name then
            table.remove(data.projects, i)
            Log(('Projeto "%s" deletado para %s'):format(name, id))
            TriggerClientEvent('olympo:serverMsg', src, 'Projeto "'..name..'" deletado', 'info')
            TriggerClientEvent('olympo:receiveProjects', src, data.projects)
            return
        end
    end
end)

RegisterServerEvent('olympo:loadProject')
AddEventHandler('olympo:loadProject', function(name, slot)
    local src  = source
    local id   = GetId(src)
    local data = GetOrCreate(id)

    local slotNum = tonumber(slot) or 1
    for _, p in ipairs(data.projects) do
        if p.name == name then
            local xml = p.slots and p.slots[tostring(slotNum)]
            TriggerClientEvent('olympo:receiveOutfit', src, {
                xml   = xml or '',
                slot  = slotNum,
                model = p.model or 'player_zero',
                project = name,
            })
            return
        end
    end
    TriggerClientEvent('olympo:serverMsg', src, 'Projeto não encontrado', 'error')
end)

RegisterServerEvent('olympo:requestProjects')
AddEventHandler('olympo:requestProjects', function()
    local src  = source
    local id   = GetId(src)
    local data = GetOrCreate(id)
    TriggerClientEvent('olympo:receiveProjects', src, data.projects)
end)

-- Salvar outfit para aplicar no próximo spawn do jogador
RegisterServerEvent('olympo:setPendingApply')
AddEventHandler('olympo:setPendingApply', function(applyData)
    local src = source
    if not CheckRate(src) then return end
    local id   = GetId(src)
    local data = GetOrCreate(id)
    data.pendingApply = {
        xml   = tostring(applyData.xml or ''),
        model = tostring(applyData.model or 'player_zero'),
        when  = os.time(),
    }
    Log(('Pending apply saved for %s'):format(id))
    TriggerClientEvent('olympo:serverMsg', src, 'Outfit salvo e será aplicado no próximo spawn', 'success')
end)

-- Cliente pede se há pending apply após spawn
RegisterServerEvent('olympo:requestPending')
AddEventHandler('olympo:requestPending', function()
    local src = source
    local id  = GetId(src)
    local data = GetOrCreate(id)
    if data.pendingApply then
        TriggerClientEvent('olympo:applyPending', src, data.pendingApply)
        data.pendingApply = nil
        Log(('Delivering pending apply to %s'):format(id))
    end
end)

-- Aplicar agora e salvar pending (usado pela NUI quando solicitar aplicar ao jogador)
RegisterServerEvent('olympo:applyNow')
AddEventHandler('olympo:applyNow', function(applyData)
    local src = source
    if not CheckRate(src) then return end
    local id   = GetId(src)
    local data = GetOrCreate(id)
    data.pendingApply = {
        xml   = tostring(applyData.xml or ''),
        model = tostring(applyData.model or 'player_zero'),
        when  = os.time(),
    }
    -- Entregar imediatamente ao jogador
    TriggerClientEvent('olympo:applyPending', src, data.pendingApply)
    TriggerClientEvent('olympo:serverMsg', src, 'Outfit enviado — será aplicado agora (se possível) e no próximo spawn', 'info')
    Log(('ApplyNow: delivered and saved for %s'):format(id))
end)

-- ============================================================
-- OUTFITS POR SLOT
-- ============================================================

RegisterServerEvent('olympo:saveOutfit')
AddEventHandler('olympo:saveOutfit', function(outfitData)
    local src  = source
    if not CheckRate(src) then return end
    local id   = GetId(src)
    local data = GetOrCreate(id)

    -- Validação básica
    local xml  = tostring(outfitData.xml or '')
    local slot = tonumber(outfitData.slot) or 1

    if #xml == 0 then
        TriggerClientEvent('olympo:serverMsg', src, 'XML vazio', 'error')
        return
    end
    if #xml > (Config.MaxXml or 80000) then
        TriggerClientEvent('olympo:serverMsg', src, 'XML muito grande', 'error')
        return
    end
    if not xml:find('<drawable>') then
        TriggerClientEvent('olympo:serverMsg', src, 'XML inválido (sem <drawable>)', 'error')
        return
    end

    data.outfits[tostring(slot)] = {
        xml   = xml,
        model = tostring(outfitData.model or 'player_zero'),
        savedAt = os.time(),
    }
    Log(('Outfit %d salvo para %s'):format(slot, id))
    TriggerClientEvent('olympo:serverMsg', src, ('Outfit slot %d salvo'):format(slot), 'success')
end)

RegisterServerEvent('olympo:loadOutfit')
AddEventHandler('olympo:loadOutfit', function(slot)
    local src = source
    local id  = GetId(src)
    local data = GetOrCreate(id)
    local outfit = data.outfits[tostring(slot)]
    if outfit then
        TriggerClientEvent('olympo:receiveOutfit', src, {
            xml   = outfit.xml,
            slot  = slot,
            model = outfit.model,
        })
    else
        TriggerClientEvent('olympo:serverMsg', src, 'Outfit não encontrado no slot ' .. slot, 'warn')
    end

    

    Log(('Outfit slot %d salvo para %s'):format(slot, id))
    TriggerClientEvent('olympo:serverMsg', src, 'Outfit salvo no slot '..slot, 'success')
end)

-- ============================================================
-- COMANDOS ADMIN
-- ============================================================

RegisterCommand('olympo_info', function(source, args)
    if source ~= 0 then return end
    local targetId = tonumber(args[1])
    if not targetId then print('Uso: olympo_info <playerid>') return end
    local id   = GetId(targetId)
    local data = db[id]
    if data then
        print(('[Olympo] %s — projetos: %d | outfits salvos: %d'):format(
            id, #data.projects, (function() local n=0 for _ in pairs(data.outfits) do n=n+1 end return n end)()
        ))
    else
        print('[Olympo] Sem dados para '..id)
    end
end, false)

print('^2[Olympo Outfit Builder]^7 Server iniciado.')
