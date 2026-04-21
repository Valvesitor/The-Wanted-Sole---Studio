-- shared/components.lua

Components = {}

-- Hashes dos componentes do ped (mp_male / mp_female)
-- Baseado em ClothesUtils.cs do VORP-ClothingStore
Components.DrawableCategories = {
    -- Índice => Nome do componente no XML
    [0]  = 'Head',
    [1]  = 'Mask',
    [2]  = 'HairStyle',
    [3]  = 'Shirt',
    [4]  = 'Vest',
    [5]  = 'Coat',
    [6]  = 'Gloves',
    [7]  = 'Pants',
    [8]  = 'Boots',
    [9]  = 'Spurs',
    [10] = 'Accessories',
    [11] = 'Hat',
    [12] = 'Glasses',
    [13] = 'EarsAccessory',
    [14] = 'MouthAccessory',
    [15] = 'NeckAccessory',
    [16] = 'Neckwear',
    [17] = 'NeckwearDecoder',
    [18] = 'Suspenders',
    [19] = 'Belt',
    [20] = 'LegAccessory',
    [21] = 'HolsterCrossdraw',
    [22] = 'HolsterLeft',
    [23] = 'HolsterRight',
    [24] = 'GunbeltAccessory',
    [25] = 'Satchel',
    [26] = 'Skirt',
    [27] = 'Chaps',
    [28] = 'Poncho',
    [29] = 'Cloak',
    [30] = 'Badge',
    [31] = 'Apron',
    [32] = 'CoatClosed',
    [33] = 'WristBand',
    [34] = 'RingLeft',
    [35] = 'RingRight',
}

-- Reverso: Nome => Índice
Components.DrawableIndex = {}
for idx, name in pairs(Components.DrawableCategories) do
    Components.DrawableIndex[name] = idx
end

-- Componentes que usam overlay (cor/textura separada)
Components.ColorComponents = {
    'HairColor',
    'HairSecondaryColor',
    'BeardColor',
    'BeardSecondaryColor',
    'EyebrowColor',
    'EyebrowSecondaryColor',
}

-- Componentes de overlay facial
Components.FacialOverlays = {
    'BeardType',
    'EyebrowType',
    'HairType',
}

-- Estrutura de XML de exemplo para o template
Components.ExampleXml = [[<?xml version="1.0" encoding="utf-8"?>
<CPedAppearanceDataList>
    <item>
        <Head>
            <Hash>-952561230</Hash>
            <Palette>0</Palette>
            <Texture>0</Texture>
        </Head>
        <HairStyle>
            <Hash>-1483393528</Hash>
            <Palette>0</Palette>
            <Texture>0</Texture>
        </HairStyle>
        <HairColor>
            <primary>2</primary>
            <secondary>2</secondary>
        </HairColor>
        <BeardType>
            <Hash>-1483393528</Hash>
            <Palette>0</Palette>
            <Texture>0</Texture>
        </BeardType>
        <BeardColor>
            <primary>2</primary>
            <secondary>2</secondary>
        </BeardColor>
        <EyebrowType>
            <Hash>-1483393528</Hash>
            <Palette>0</Palette>
            <Texture>0</Texture>
        </EyebrowType>
        <Shirt>
            <Hash>167765511</Hash>
            <Palette>0</Palette>
            <Texture>0</Texture>
        </Shirt>
        <Pants>
            <Hash>-1922823010</Hash>
            <Palette>0</Palette>
            <Texture>0</Texture>
        </Pants>
        <Boots>
            <Hash>-1826540252</Hash>
            <Palette>0</Palette>
            <Texture>0</Texture>
        </Boots>
        <Hat>
            <Hash>-1482374038</Hash>
            <Palette>0</Palette>
            <Texture>0</Texture>
        </Hat>
    </item>
</CPedAppearanceDataList>]]
