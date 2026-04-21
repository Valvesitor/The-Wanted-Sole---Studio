fx_version 'cerulean'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

name        'TheWantedSole_Studio'
description 'Editor de Outfit com XML, Cores, Câmera e Projetos'
author      'Valvesitor'
version     '2.0.2'

-- ============================================================
-- SHARED SCRIPTS
-- ============================================================
shared_scripts {
    'libs/slaxml.lua',
    'shared/slaxmlparser.lua',
    'shared/config.lua',
    'shared/components.lua',
    -- FIX: 'shared/components.lua' removido — arquivo não existe no projeto
}

-- ============================================================
-- CLIENT SCRIPTS (ORDEM IMPORTA!)
-- ============================================================
client_scripts {
    -- FIX: removido o '@' que fazia o RedM procurar num resource EXTERNO chamado
    -- 'metaped_assets'. Os arquivos estão DENTRO deste próprio resource,
    -- por isso o caminho correto é sem '@'.
    'metaped_assets/categorizedComponents.lua',
    'metaped_assets/componentCategories.lua',
    'metaped_assets/drawables.lua',
    'metaped_assets/matchTagsDrawables.lua',
    'metaped_assets/palettes.lua',
    'metaped_assets/tints.lua',
    

    'client/ped.lua',
    'client/camera.lua',
    'client/client.lua',
}

-- ============================================================
-- SERVER SCRIPTS
-- ============================================================
server_scripts {
    'server/server.lua',
}

-- ============================================================
-- UI PAGE
-- ============================================================
ui_page 'html/index.html'

-- ============================================================
-- FILES
-- ============================================================
files {
    'html/index.html',
    'html/app.js',
    'html/style.css',
}

-- FIX: exports removidos — getPlayerOutfit e setPlayerOutfit nunca foram
-- implementados em nenhum arquivo. Declarar exports que não existem
-- causa erro ao iniciar o resource.
