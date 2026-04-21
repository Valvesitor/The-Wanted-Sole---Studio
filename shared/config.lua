-- shared/config.lua
Config = {}

Config.Debug   = true  -- Ativado para depuração: desative após testes
Config.OpenKey = 'F4'          -- tecla abrir/fechar
Config.MaxXml  = 80000         -- bytes máx do XML

-- ────────────────────────────────────────────────────────────
-- METAPED: nome do resource responsável por aplicar outfits
-- Exemplos comuns: 'metaped', 'metapeds', 'vorp_metaped',
--                  'ox_metaped', 'np-metaped', 'metaped_redm'
-- Se deixar vazio (''), tenta todos automaticamente.
-- ────────────────────────────────────────────────────────────
Config.MetapedResource = 'rsg-appearance'   -- ← nome do resource MetaPed criado

-- Slots de outfit por projeto
Config.OutfitSlots = 10

-- Paletas conhecidas do RDR3
Config.KnownPalettes = {
    'metaped_tint_makeup',
    'metaped_tint_hair',
    'metaped_tint_animal',
    'metaped_tint_eye',
    'metaped_tint_generic',
    'metaped_tint_skin',
    'metaped_tint_leather',
    'metaped_tint_cloth',
    'metaped_tint_metal',
    'metaped_tint_wood',
    'metaped_tint_fur',
}

-- Modelos de ped comuns para autocomplete
Config.CommonPeds = {
    'player_zero',
    'mp_male',
    'mp_female',
    'cs_mp_harriet_davenport_fs1',
    'cs_mrsadler_fs1',
    'a_m_m_ranchhand_01',
    'a_f_m_ranchhand_01',
    'u_m_m_playeractor',
}
