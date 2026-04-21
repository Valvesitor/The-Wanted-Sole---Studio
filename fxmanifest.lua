fx_version 'cerulean'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

name        'TheWantedSole_Studio'
description 'Editor de Outfit com XML, Cores, Câmera e Projetos'
author      'Valvesitor'
version     '2.0.1'

-- ============================================================
-- SHARED SCRIPTS
-- ============================================================
-- Estes são carregados PRIMEIRO em ambos client e server
shared_scripts {
    'libs/slaxml.lua',          -- parser SAX (sem require() externo)
    'shared/slaxmlparser.lua',  -- wrapper: SLAXML → tabela Lua
    'shared/config.lua',
    'shared/components.lua',
}

-- ============================================================
-- CLIENT SCRIPTS (ORDEM IMPORTA!)
-- ============================================================
-- 1. Primeiro: Dados (componentes, categorias, drawables)
-- 2. Depois: Código que usa os dados (ped, camera, client)
client_scripts {
    -- DADOS (carregados primeiro, usados depois)
    -- ─────────────────────────────────────────
    'metaped_assets/*.lua',
     
    -- CÓDIGO PRINCIPAL (usa os dados acima)
    -- ────────────────────────────────────
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

-- ============================================================
-- EXPORTS
-- ============================================================
-- Se outro script precisar das funções daqui
exports {
    'getPlayerOutfit',
    'setPlayerOutfit',
}
