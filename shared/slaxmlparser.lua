-- shared/slaxmlparser.lua (VERSÃO CORRIGIDA FINAL)
-- Wrapper que usa SLAXML (já carregado) para parsear o XML do Olympo
-- e retorna uma lista de items como tabela Lua.
-- Expõe a global "OlympoXML" usada pelo ped.lua

OlympoXML = {}

-- ----------------------------------------------------------------
-- OlympoXML.parseItems(xmlStr) - CORRIGIDO
-- Recebe o bloco de <Item>...</Item> colado na NUI
-- Retorna: items (table[]), err (string|nil)
-- ----------------------------------------------------------------
function OlympoXML.parseItems(xmlStr)
    if not xmlStr or xmlStr == '' then
        return nil, 'XML vazio'
    end

    if Config and Config.Debug then
        print('^3[OlympoXML]^7 Iniciando parse de XML com ' .. #xmlStr .. ' bytes')
    end

    -- Envolver em raiz para garantir que SLAXML tenha um elemento pai
    local wrapped = '<Items>' .. xmlStr .. '</Items>'

    local items       = {}
    local currentItem = nil
    local currentTag  = nil
    local currentAttr = {}   -- acumula atributos da tag atual

    local parser = SLAXML:parser({
        startElement = function(name)
            currentTag  = name
            currentAttr = {}

            if name == 'Item' then
                currentItem = {
                    drawable    = '',
                    component   = '',
                    texture     = '',
                    albedo      = '',
                    normal      = '',
                    material    = '',
                    palette     = '',
                    tint0       = 0,
                    tint1       = 0,
                    tint2       = 0,
                    probability = 255,
                }
                if Config and Config.Debug then
                    print('^3[OlympoXML]^7 Iniciando novo <Item>')
                end
            end
        end,

        attribute = function(name, value)
            -- Captura atributos da tag atual (ex: tint0 value="21")
            currentAttr[name] = value
        end,

        text = function(txt)
            if not currentItem or not currentTag then return end
            -- Remove espaços
            txt = txt:match('^%s*(.-)%s*$')
            if txt == '' then return end

            if currentTag == 'drawable' then
                currentItem.drawable = txt
                if Config and Config.Debug then
                    print('^3[OlympoXML]^7   → drawable: ' .. txt)
                end
            elseif currentTag == 'component' then
                currentItem.component = txt
            elseif currentTag == 'texture' then
                currentItem.texture = txt
            elseif currentTag == 'albedo' then
                currentItem.albedo = txt
            elseif currentTag == 'normal' then
                currentItem.normal = txt
            elseif currentTag == 'material' then
                currentItem.material = txt
            elseif currentTag == 'palette' then
                currentItem.palette = txt
            end
        end,

        closeElement = function(name)
            if not currentItem then
                currentTag = nil
                return
            end

            -- Tags self-closing com atributo value: <tint0 value="21" />
            if (name == 'tint0' or name == 'tint1' or name == 'tint2' or name == 'probability') then
                local v = tonumber(currentAttr['value'])
                if v then
                    if     name == 'tint0'       then currentItem.tint0       = v
                    elseif name == 'tint1'       then currentItem.tint1       = v
                    elseif name == 'tint2'       then currentItem.tint2       = v
                    elseif name == 'probability' then currentItem.probability = v
                    end
                end
            end

            if name == 'Item' and currentItem then
                if currentItem.drawable ~= '' then
                    table.insert(items, currentItem)
                    if Config and Config.Debug then
                        print('^2[OlympoXML]^7 ✓ Item adicionado: ' .. currentItem.drawable)
                    end
                else
                    if Config and Config.Debug then
                        print('^1[OlympoXML]^7 ✗ Item sem drawable ignorado')
                    end
                end
                currentItem = nil
            end

            currentTag  = nil
            currentAttr = {}
        end,
    })

    -- ✅ CORREÇÃO: Melhor tratamento de erro no parse
    local ok, err = pcall(function()
        parser:parse(wrapped, { stripWhitespace = true })
    end)

    if not ok then
        local errMsg = 'Erro ao parsear XML: ' .. tostring(err)
        if Config and Config.Debug then
            print('^1[OlympoXML]^7 ' .. errMsg)
        end
        return nil, errMsg
    end

    -- Debug: imprimir resumo dos items parseados
    if Config and Config.Debug then
        if #items > 0 then
            print(('^2[OlympoXML]^7 ✓ Parse completo — %d item(s)'):format(#items))
            for i = 1, math.min(#items, 10) do
                local it = items[i]
                print(('^3[OlympoXML]^7   [%d] drawable=%s tint0=%s'):format(
                    i, tostring(it.drawable), tostring(it.tint0)
                ))
            end
            if #items > 10 then
                print(('^3[OlympoXML]^7   ... e mais %d items'):format(#items - 10))
            end
        else
            print('^1[OlympoXML]^7 ✗ Nenhum item parseado')
        end
    end

    if #items == 0 then
        return nil, 'Nenhum <Item> com <drawable> válido encontrado'
    end

    return items, nil
end

-- ----------------------------------------------------------------
-- OlympoXML.validate(xmlStr)
-- Validação rápida antes de parsear
-- ----------------------------------------------------------------
function OlympoXML.validate(xmlStr)
    if type(xmlStr) ~= 'string' or #xmlStr == 0 then
        return false, 'XML vazio'
    end
    if #xmlStr > (Config and Config.MaxXml or 80000) then
        return false, 'XML excede tamanho máximo (' .. (Config and Config.MaxXml or 80000) .. ' bytes)'
    end
    if not xmlStr:find('<Item>') and not xmlStr:find('<Item ') then
        return false, 'XML deve conter elementos <Item>'
    end
    if not xmlStr:find('<drawable>') then
        return false, 'Nenhum <drawable> encontrado no XML'
    end
    return true, nil
end

-- ----------------------------------------------------------------
-- OlympoXML.itemsToXml(items)
-- Serializa lista de items de volta para o formato Olympo
-- ----------------------------------------------------------------
function OlympoXML.itemsToXml(items)
    local lines = {}
    for _, item in ipairs(items) do
        table.insert(lines, '  <Item>')
        table.insert(lines, '    <drawable>'  .. (item.drawable  or '') .. '</drawable>')
        table.insert(lines, '    <component>' .. (item.component or '') .. '</component>')
        table.insert(lines, '    <texture>'   .. (item.texture   or '') .. '</texture>')
        table.insert(lines, '    <albedo>'    .. (item.albedo    or '') .. '</albedo>')
        table.insert(lines, '    <normal>'    .. (item.normal    or '') .. '</normal>')
        table.insert(lines, '    <material>'  .. (item.material  or '') .. '</material>')
        table.insert(lines, '    <palette>'   .. (item.palette   or '') .. '</palette>')
        table.insert(lines, '    <tint0 value="'       .. (item.tint0       or 0)   .. '" />')
        table.insert(lines, '    <tint1 value="'       .. (item.tint1       or 0)   .. '" />')
        table.insert(lines, '    <tint2 value="'       .. (item.tint2       or 0)   .. '" />')
        table.insert(lines, '    <probability value="' .. (item.probability or 255) .. '" />')
        table.insert(lines, '  </Item>')
    end
    return table.concat(lines, '\n')
end
