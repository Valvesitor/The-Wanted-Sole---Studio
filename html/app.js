'use strict';
/* ============================================================
   Olympo Store Outfit Builder — app.js
   Gerencia toda a lógica NUI: câmera, XML, cores, projetos
   ============================================================ */

// ─── ESTADO ─────────────────────────────────────────────────
const S = {
  open:      false,
  pedModel:  'player_zero',
  slot:      9,
  projects:  [],
  curProject: null,
  items:     [],          // items parseados do XML atual
  camState: { zoom: 1.35, rotH: 0, rotV: -6, height: 0.0, focus: 'body' },
  focusModes: ['body', 'head', 'feet'],
  focusIdx:  0,
  usePreview: false,
  colorDrawable: null,    // drawable selecionado no editor de cores
  knownPalettes: [],
  // Dados dos arquivos data/
  categories:   { male: [], female: [] },
  paletteNames: [],
  browseDrawables: [],    // lista atual no browser
  dragPanel: null,
  dragOffset: { x:0, y:0 },
};
// ─── TRADUÇÃO DAS CATEGORIAS (fallback) ─────────────────────
const CATEGORY_TRANSLATIONS = {
    accessories: "Acessórios",
    ammo_pistols: "Munição de Pistola",
    ammo_rifles: "Munição de Rifle",
    ammo_shotguns: "Munição de Espingarda",
    ankle_bindings: "Amarrações de Tornozelo",
    aprons: "Aventais",
    armor: "Armaduras",
    badges: "Insígnias",
    beards: "Barbas",
    beards_chin: "Barbas no Queixo",
    beards_chops: "Costeletas",
    beards_complete: "Barbas Completas",
    beards_mustache: "Bigodes",
    belt_buckles: "Fivelas",
    belts: "Cintos",
    bodies_lower: "Corpo Inferior",
    bodies_upper: "Corpo Superior",
    boot_accessories: "Acessórios de Botas",
    boots: "Botas",
    capes: "Capas",
    chaps: "Perneiras",
    chemises: "Camisolas",
    cloaks: "Mantos",
    coat_accessories: "Acessórios de Casaco",
    coats: "Casacos",
    coats_closed: "Casacos Fechados",
    coats_heavy: "Casacos Pesados",
    corsets: "Espartilhos",
    dresses: "Vestidos",
    eyebrows: "Sobrancelhas",
    eyecaps: "Tampas de Olhos",
    eyelashes: "Cílios",
    eyes: "Olhos",
    eyewear: "Óculos",
    face_props: "Acessórios de Rosto",
    gauntlets: "Cotoveleiras",
    gloves: "Luvas",
    gore_corpse: "Sangue de Corpo",
    gore_head: "Sangue de Cabeça",
    gore_skull: "Caveira Sangrada",
    gunbelt_accs: "Acessórios de Cinto de Arma",
    gunbelts: "Cintos de Arma",
    hair: "Cabelo",
    hair_accessories: "Acessórios de Cabelo",
    hair_bonnet: "Touca de Cabelo",
    hat_accessories: "Acessórios de Chapéus",
    hatband: "Fita de Chapéu",
    hats: "Chapéus",
    heads: "Cabeças",
    headwear: "Acessórios de Cabeça",
    holsters_center: "Coldres Centrais",
    holsters_crossdraw: "Coldres Cruzados",
    holsters_knife: "Bainhas de Faca",
    holsters_left: "Coldres Esquerda",
    holsters_quivers: "Aljavas",
    holsters_right: "Coldres Direita",
    jewelry_bracelets: "Pulseiras",
    jewelry_earrings: "Brincos",
    jewelry_necklaces: "Colares",
    jewelry_rings_left: "Anéis Esquerda",
    jewelry_rings_right: "Anéis Direita",
    knickers: "Calcinhas",
    loadouts: "Equipamentos",
    masks: "Máscaras",
    masks_large: "Máscaras Grandes",
    neckerchiefs: "Lenços de Pescoço",
    neckties: "Gravatas",
    neckwear: "Acessórios de Pescoço",
    outfits: "Roupas Completas",
    overalls_full: "Macacões Completos",
    overalls_modular_lowers: "Calças Modulares",
    overalls_modular_uppers: "Parte Superior Modular",
    pants: "Calças",
    pants_accessories: "Acessórios de Calça",
    petticoats: "Anáguas",
    ponchos: "Ponchos",
    satchel_straps: "Correias de Mochila",
    satchels: "Mochilas",
    shawls: "Xales",
    shirts_full: "Camisetas Completas",
    shirts_full_overpants: "Camisetas Sobre Calças",
    skirts: "Saias",
    slods: "Modelos LOD",
    spats: "Polainas",
    stockings: "Meias",
    suspenders: "Suspensórios",
    teeth: "Dentes",
    unionsuit_legs: "Pernas de Macacão",
    unionsuits_full: "Macacões Completos",
    vest_accessories: "Acessórios de Colete",
    vests: "Coletes",
    wrist_bindings: "Amarrações de Pulso",
    // IDs hex (se precisar)
    arbhwiba_0x2f725b6c: "Braço Direito",
    bctrhzba_0xcb350942: "Perna Esquerda",
    cgvqvdaa_0xd4968e65: "Mão Direita",
    clwjgoxa_0xb53677b7: "Cobertura",
    cnvfyaba_0xd7ae0d03: "Mangas",
    dlzdyqba_0xd82c8dd3: "Gore Cabeça",
    dytuhxia_0x4e0f1b95: "Vazio",
    gjrbmoma_0xcb39a6f4: "Acessórios Especiais",
    gnuusvra_0x7024af8b: "Detalhes Camisa",
    hyohcica_0xa1071d52: "Gore Braço Direito",
    idntoqja_0xe85a1a4d: "Mão Esquerda",
    jmwhzgaa_0x106fe11f: "Pé Esquerdo",
    kkawrfba_0x202a8054: "Gore Perna Esquerda",
    kqmlmpca_0x294e561e: "Pé Direito",
    lduvmjua_0x2b388a05: "Camisa",
    lvpmxtsa_0xb57244a4: "Manga Esquerda",
    mbbwboia_0x42e8f927: "Anexos Vestido",
    najrjqia_0x37b57629: "Perna Direita",
    nbtudvja_0x53b67599: "Torso Vestido",
    nhtwicmb_0xbb9ef54c: "Ferimentos",
    nqdexqca_0x63513de0: "Gore Perna Direita",
    nrpnskza_0x3cadebb7: "Manga Direita",
    oacpqvda_0x41292b6f: "Manto",
    ogdexlma_0xe8b5e43d: "Gore Braço Esquerdo",
    ogoolgaa_0xecd61654: "Anágua",
    pnyvpusa_0x44f4c713: "Renda",
    tyyeqpea_0x5ad6c8a1: "Gola",
    upigupqa_0x5a536e23: "Vazio",
    xvnliuia_0x625d7b14: "Braço Esquerdo",
    ywkywwvb_0xe93b9f1b: "Babado"
};

// Função auxiliar para obter nome traduzido
function getCategoryLabel(catKey) {
    return CATEGORY_TRANSLATIONS[catKey] || catKey;
}

const FOCUS_LABELS = { body: 'Corpo Inteiro', head: 'Cabeça', feet: 'Pés' };

// ─── DOM ─────────────────────────────────────────────────────
const $ = id => document.getElementById(id);
const app          = $('app');
const xmlEditor    = $('xmlEditor');
const statusBar    = $('statusBar');
const statusText   = $('statusText');
const panelColors  = $('panelColors');
const panelDrawables = $('panelDrawables');
const drawableList = $('drawableList');
const toastStack   = $('toastStack');
const selProject   = $('selProject');
const slotsList    = $('slotsList');
const selDrawable  = $('selDrawable');
const pedList      = $('pedList');
const chkUsePreview = $('chkUsePreview');

// ─── NUI COMMUNICATION ───────────────────────────────────────
function nui(action, data = {}) {
  // Validar GetParentResourceName() com fallback seguro
  let resource = 'TheWantedSole_Studio';
  try {
    if (typeof GetParentResourceName === 'function') {
      const name = GetParentResourceName();
      if (name && typeof name === 'string' && name.length > 0) {
        resource = name;
      }
    }
  } catch (e) {
    console.warn('GetParentResourceName falhou, usando fallback:', e);
  }
  
  return fetch(`https://${resource}/${action}`, {
    method:  'POST',
    headers: { 'Content-Type': 'application/json' },
    body:    JSON.stringify(data),
  })
    .then(r => r.json())
    .catch(err => {
      console.error('NUI fetch error', err);
      return ({ ok: false, error: 'NUI timeout' });
    });
}

// ─── TOAST ────────────────────────────────────────────────────
function toast(msg, type = 'info', ms = 3000) {
  const el = document.createElement('div');
  el.className = `toast ${type}`;
  el.textContent = msg;
  toastStack.appendChild(el);
  setTimeout(() => {
    el.classList.add('out');
    setTimeout(() => el.remove(), 220);
  }, ms);
}

// ─── STATUS BAR ───────────────────────────────────────────────
function setStatus(msg, type = '') {
  statusText.textContent = msg;
  statusBar.className = 'status-bar ' + type;
}

// ─── OPEN / CLOSE ─────────────────────────────────────────────
function openUI(data) {
  S.open = true;
  app.classList.remove('hidden');
  app.classList.add('visible');

  if (data.pedModel)  { S.pedModel = data.pedModel; $('inpPedModel').value = data.pedModel; }
  if (data.slotIndex) { S.slot = data.slotIndex; $('inpOutfitSlot').value = data.slotIndex; }
  if (data.camState)  { Object.assign(S.camState, data.camState); syncCamSliders(); }
  if (data.knownPalettes) {
    S.knownPalettes = data.knownPalettes;
    populatePaletteSelects();
  }
  if (data.categories) {
    S.categories = data.categories;
    populateCategorySelect($('selGender').value);
  }
  if (data.paletteNames && data.paletteNames.length > 0) {
    // Mescla paletteNames com knownPalettes para o editor de cores
    const merged = [...new Set([...S.knownPalettes, ...data.paletteNames])].sort();
    S.knownPalettes = merged;
    populatePaletteSelects();
  }
  if (data.commonPeds) populatePedList(data.commonPeds);
  if (data.usePreview !== undefined) { S.usePreview = !!data.usePreview; if (chkUsePreview) chkUsePreview.checked = S.usePreview; }

  startFpsTicker();
}

function closeUI() {
  S.open = false;
  app.classList.remove('visible');
  app.classList.add('hidden');
  panelColors.style.display   = 'none';
  panelDrawables.style.display = 'none';
  stopFpsTicker();
}

// ─── FPS TICKER ───────────────────────────────────────────────
let fpsTimer = null;
let fpsCount = 0;
function startFpsTicker() {
  // Simular fps; RedM envia via evento se quiser integrar nativo
  fpsCount = 30 + Math.floor(Math.random() * 6);
  fpsTimer = setInterval(() => {
    fpsCount = Math.max(28, Math.min(60, fpsCount + (Math.random() > 0.5 ? 1 : -1)));
    $('fpsBadge').textContent = fpsCount + 'fps';
  }, 1000);
}
function stopFpsTicker() {
  clearInterval(fpsTimer);
  $('fpsBadge').textContent = '--fps';
}

// ─── CÂMERA ───────────────────────────────────────────────────
// NOTA: camState já está definido no estado global S.camState
// Evitar duplicação mantendo sincronização

const focusModes = ['body', 'head', 'feet'];
let currentFocusIdx = 0;

// Função para enviar os dados para o Lua
function sendCameraUpdate() {
    const resourceName = (typeof GetParentResourceName === 'function' && GetParentResourceName()) || 'TheWantedSole_Studio';
    fetch(`https://${resourceName}/cameraUpdate`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(S.camState)
    });
}

// Atualiza os textos e a posição dos sliders na tela
function updateCameraUI(state) {
    S.camState.zoom = state.zoom;
    S.camState.rotH = state.rotH;
    S.camState.rotV = state.rotV;
    S.camState.height = state.height;
    S.camState.focus = state.focus;
    S.camState.pedRot = state.pedRot || 0;

    document.getElementById('slZoom').value = state.zoom;
    document.getElementById('valZoom').innerText = state.zoom;
    
    document.getElementById('slRotH').value = state.rotH;
    document.getElementById('valRotH').innerText = state.rotH;
    
    document.getElementById('slRotV').value = state.rotV;
    document.getElementById('valRotV').innerText = state.rotV;
    
    document.getElementById('slHeight').value = state.height;
    document.getElementById('valHeight').innerText = state.height;

    document.getElementById('slPedRot').value = S.camState.pedRot;
    document.getElementById('valPedRot').innerText = S.camState.pedRot;

    document.getElementById('btnFocus').innerText = `Foco: ${state.focus === 'body' ? 'Corpo Inteiro' : state.focus === 'head' ? 'Cabeça' : 'Pés'}`;
}

// Listeners dos Sliders
    document.getElementById('slZoom').addEventListener('input', (e) => {
      S.camState.zoom = parseFloat(e.target.value);
      document.getElementById('valZoom').innerText = S.camState.zoom;
      sendCameraUpdate();
  });

    document.getElementById('slRotH').addEventListener('input', (e) => {
      S.camState.rotH = parseInt(e.target.value);
      document.getElementById('valRotH').innerText = S.camState.rotH;
      sendCameraUpdate();
  });

    document.getElementById('slRotV').addEventListener('input', (e) => {
      S.camState.rotV = parseInt(e.target.value);
      document.getElementById('valRotV').innerText = S.camState.rotV;
      sendCameraUpdate();
  });

    document.getElementById('slHeight').addEventListener('input', (e) => {
      S.camState.height = parseFloat(e.target.value);
      document.getElementById('valHeight').innerText = S.camState.height;
      sendCameraUpdate();
  });

    document.getElementById('slPedRot').addEventListener('input', (e) => {
      S.camState.pedRot = parseInt(e.target.value);
      document.getElementById('valPedRot').innerText = S.camState.pedRot;
      sendCameraUpdate();
  });

// Botão de Alternar Foco
    document.getElementById('btnFocus').addEventListener('click', () => {
      currentFocusIdx = (currentFocusIdx + 1) % focusModes.length;
      S.camState.focus = focusModes[currentFocusIdx];
    
     const labels = { 'body': 'Corpo Inteiro', 'head': 'Cabeça', 'feet': 'Pés' };
      document.getElementById('btnFocus').innerText = `Foco: ${labels[S.camState.focus]}`;
    
      sendCameraUpdate();
  });

function syncCamSliders() {
  document.getElementById('slZoom').value = S.camState.zoom;
  document.getElementById('valZoom').innerText = S.camState.zoom;
  document.getElementById('slRotH').value = S.camState.rotH;
  document.getElementById('valRotH').innerText = S.camState.rotH;
  document.getElementById('slRotV').value = S.camState.rotV;
  document.getElementById('valRotV').innerText = S.camState.rotV;
  document.getElementById('slHeight').value = S.camState.height;
  document.getElementById('valHeight').innerText = S.camState.height;
  document.getElementById('slPedRot').value = S.camState.pedRot;
  document.getElementById('valPedRot').innerText = S.camState.pedRot;
}

function setupCamSliders() {
  syncCamSliders();
}

// ─── XML EDITOR ───────────────────────────────────────────────
let xmlTimer = null;
xmlEditor.addEventListener('input', () => {
  clearTimeout(xmlTimer);
  xmlTimer = setTimeout(validateXml, 500);
});

function validateXml() {
  const xml = xmlEditor.value.trim();
  if (!xml) { setStatus('Cole o XML e clique em Aplicar Outfit', ''); S.items = []; return; }

  const parser = new DOMParser();
  const doc    = parser.parseFromString('<Items>' + xml + '</Items>', 'text/xml');
  const err    = doc.querySelector('parsererror');

  if (err) {
    setStatus('❌ Erro no XML: ' + err.textContent.split('\n')[0].slice(0,60), 'error');
    S.items = [];
    return;
  }

  const items = doc.querySelectorAll('Item');
  if (items.length === 0) {
    setStatus('⚠ Nenhum <Item> encontrado', 'warn');
    S.items = [];
    return;
  }

  S.items = parseItemsFromDoc(doc);
  setStatus(`✔ ${items.length} item(s) válido(s) — pronto para aplicar`, 'ok');
  updateDrawableSelects();
}

function parseItemsFromDoc(doc) {
  const out = [];
  doc.querySelectorAll('Item').forEach(el => {
    const g = tag => el.querySelector(tag)?.textContent?.trim() || '';
    const ga = (tag, attr) => el.querySelector(tag)?.getAttribute(attr) || '0';
    out.push({
      drawable:    g('drawable'),
      albedo:      g('albedo'),
      normal:      g('normal'),
      material:    g('material'),
      palette:     g('palette'),
      tint0:       parseInt(ga('tint0', 'value')),
      tint1:       parseInt(ga('tint1', 'value')),
      tint2:       parseInt(ga('tint2', 'value')),
      probability: parseInt(ga('probability', 'value') || '255'),
    });
  });
  return out;
}

// ─── APLICAR OUTFIT ───────────────────────────────────────────
$('btnApply').addEventListener('click', async () => {
  const xml = xmlEditor.value.trim();
  if (!xml) { toast('Cole um XML primeiro', 'warn'); return; }
  if (S.items.length === 0) { toast('XML inválido', 'error'); return; }

  setStatus('Aplicando outfit...', 'info');
  const res = await nui('applyOutfit', {
    xml:      xml,
    pedModel: S.pedModel,
    slot:     S.slot,
  });

  if (res.ok) {
    const r = res.result || {};
    const applied = (r.applied != null) ? r.applied : S.items.length;
    const total   = (r.total   != null) ? r.total   : S.items.length;

    if (res.warning === 'pending_saved') {
      setStatus(`⏳ Outfit salvo — será aplicado no próximo spawn`, 'warn');
      toast('Sem export ativo — outfit salvo para o próximo spawn', 'warn', 4000);
    } else {
      setStatus(`✔ Outfit trocado — ${applied}/${total} drawables`, 'ok');
      toast(`Outfit aplicado! (${applied} drawables)`, 'success');
    }

    // Abrir painel de drawables na aba "Aplicados" para mostrar os itens
    panelDrawables.style.display = 'block';
    switchDrawTab('applied');
    updateDrawableList();
  } else {
    setStatus('❌ ' + (res.error || 'Erro ao aplicar'), 'error');
    toast(res.error || 'Erro ao aplicar', 'error');
  }
});

// Aplicar no jogador agora (e salvar para o próximo spawn)
const btnApplyPlayer = $('btnApplyPlayer');
if (btnApplyPlayer) {
  btnApplyPlayer.addEventListener('click', async () => {
    const xml = xmlEditor.value.trim();
    if (!xml) { toast('Cole um XML primeiro', 'warn'); return; }
    setStatus('Aplicando outfit no jogador...', 'info');
    const res = await nui('applyToPlayer', { xml: xml, pedModel: S.pedModel, slot: S.slot });
    if (res.ok) {
      toast('Solicitação enviada: outfit será aplicado no jogador (e salvo para próximo spawn)', 'success');
      setStatus('Outfit enviado ao servidor', 'ok');
    } else {
      toast(res.error || 'Erro ao aplicar no jogador', 'error');
      setStatus('Erro ao enviar outfit', 'error');
    }
  });
}

// ─── CAPTURAR OUTFIT ─────────────────────────────────────────
$('btnCapture').addEventListener('click', async () => {
  const res = await nui('captureOutfit', {});
  if (res.ok && res.xml) {
    xmlEditor.value = res.xml;
    validateXml();
    toast('Outfit atual capturado!', 'success');
  } else {
    toast(res.error || 'Nada para capturar', 'warn');
  }
});

// ─── SETAR PED ────────────────────────────────────────────────
$('btnSetPed').addEventListener('click', async () => {
  const model = $('inpPedModel').value.trim();
  if (!model) return;
  S.pedModel = model;
  const res = await nui('setPedModel', { model });
  if (res.ok) {
    setStatus('Carregando modelo...', 'info');
    toast('Solicitando modelo: ' + model, 'info');
  } else {
    toast(res.error || 'Modelo inválido', 'error');
  }
});

// Alternar uso de preview ped
if (chkUsePreview) {
  chkUsePreview.addEventListener('change', async (e) => {
    const use = !!e.target.checked;
    const res = await nui('togglePreview', { usePreview: use });
    if (res.ok) {
      S.usePreview = use;
      toast('Modo preview ' + (use ? 'ativado' : 'desativado'), 'info');
    } else {
      toast(res.error || 'Falha ao alternar preview', 'error');
      chkUsePreview.checked = !use;
    }
  });
}

// ─── SALVAR OUTFIT ────────────────────────────────────────────
$('btnSaveOutfit').addEventListener('click', async () => {
  const xml = xmlEditor.value.trim();
  if (!xml) { toast('Nada para salvar', 'warn'); return; }
  S.slot = parseInt($('inpOutfitSlot').value) || 1;
  await nui('applyOutfit', { xml, pedModel: S.pedModel, slot: S.slot });
  toast('Outfit salvo no slot ' + S.slot, 'success');
  markSlotSaved(S.slot);
});

$('btnSaveSlot').addEventListener('click', () => $('btnSaveOutfit').click());

// ─── FECHAR ───────────────────────────────────────────────────
$('btnClose').addEventListener('click', async () => {
  await nui('close', {});
  closeUI();
});

// ─── EDITOR DE CORES ─────────────────────────────────────────
$('btnEditColors').addEventListener('click', () => {
  if (S.items.length === 0) { toast('Aplique um outfit primeiro', 'warn'); return; }
  panelColors.style.display = panelColors.style.display === 'none' ? 'block' : 'none';
  updateDrawableSelects();
});
$('btnColorClose').addEventListener('click', () => { panelColors.style.display = 'none'; });
$('btnColorMin').addEventListener('click', () => {
  const b = panelColors.querySelector('.float-body');
  b.style.display = b.style.display === 'none' ? '' : 'none';
});

// Selecionar drawable → preencher campos de cor
selDrawable.addEventListener('change', () => {
  const name = selDrawable.value;
  const item  = S.items.find(i => i.drawable === name);
  if (!item) return;
  S.colorDrawable = name;
  $('inpPaletteActual').value = item.palette || '—';
  $('inpMaterial').value       = item.material || '—';
  $('slT0').value = item.tint0; $('valT0').textContent = item.tint0;
  $('slT1').value = item.tint1; $('valT1').textContent = item.tint1;
  $('slT2').value = item.tint2; $('valT2').textContent = item.tint2;
});

// Sliders de tint
['slT0','slT1','slT2'].forEach(id => {
  $(id).addEventListener('input', () => {
    const n = id.slice(-1);
    $('valT'+n).textContent = $(id).value;
    // Auto-aplicar em tempo real
    applyColorNow();
  });
});

$('selPaletteSug').addEventListener('change', () => {
  const p = $('selPaletteSug').value;
  if (p) $('inpPaletteActual').value = p;
});

$('btnApplyColor').addEventListener('click', applyColorNow);

async function applyColorNow() {
  if (!S.colorDrawable) return;
  const item = S.items.find(i => i.drawable === S.colorDrawable);
  if (!item) return;

  item.tint0   = parseInt($('slT0').value);
  item.tint1   = parseInt($('slT1').value);
  item.tint2   = parseInt($('slT2').value);
  item.palette = $('inpPaletteActual').value;

  await nui('applyColor', {
    drawable: S.colorDrawable,
    tint0:    item.tint0,
    tint1:    item.tint1,
    tint2:    item.tint2,
    palette:  item.palette,
  });

  // Atualizar XML no editor e sincronizar
  rebuildXmlFromItems();
  setStatus('Cores atualizadas', 'ok');
}

function updateDrawableSelects() {
  selDrawable.innerHTML = '';
  S.items.forEach(item => {
    const opt = document.createElement('option');
    opt.value = item.drawable;
    opt.textContent = item.drawable;
    selDrawable.appendChild(opt);
  });
  // Trigger change para preencher campos
  if (S.items.length > 0) selDrawable.dispatchEvent(new Event('change'));
}

function populatePaletteSelects() {
  [$('selPaletteSug'), $('selMatFem'), $('selMatMasc')].forEach(sel => {
    // Manter opção padrão
    const def = sel.options[0];
    sel.innerHTML = '';
    sel.appendChild(def);
    S.knownPalettes.forEach(p => {
      const o = document.createElement('option');
      o.value = p; o.textContent = p;
      sel.appendChild(o);
    });
  });
}

// ─── DRAWABLES PANEL ─────────────────────────────────────────
$('btnDrawables').addEventListener('click', () => {
  const willOpen = panelDrawables.style.display === 'none';
  panelDrawables.style.display = willOpen ? 'block' : 'none';
  if (willOpen) {
    switchDrawTab('applied');  // Sempre abre na aba dos itens aplicados
    updateDrawableList();
  }
});
$('btnDrawClose').addEventListener('click', () => { panelDrawables.style.display = 'none'; });

// Tabs
$('tabApplied').addEventListener('click', () => switchDrawTab('applied'));
$('tabBrowse').addEventListener('click',  () => switchDrawTab('browse'));

function switchDrawTab(tab) {
  if (tab === 'applied') {
    $('bodyApplied').style.display = '';
    $('bodyBrowse').style.display  = 'none';
    $('tabApplied').classList.add('active');
    $('tabBrowse').classList.remove('active');
    updateDrawableList();
  } else {
    $('bodyApplied').style.display = 'none';
    $('bodyBrowse').style.display  = '';
    $('tabApplied').classList.remove('active');
    $('tabBrowse').classList.add('active');
  }
}

function updateDrawableList() {
  drawableList.innerHTML = '';
  if (S.items.length === 0) {
    drawableList.innerHTML = '<div class="empty-draw">Nenhum drawable no XML</div>';
    return;
  }
  S.items.forEach(item => {
    const div = document.createElement('div');
    div.className = 'draw-item';
    div.textContent = item.drawable;
    div.title = `albedo: ${item.albedo}\npalette: ${item.palette}\ntint: ${item.tint0}/${item.tint1}/${item.tint2}`;
    div.addEventListener('click', () => {
      selDrawable.value = item.drawable;
      selDrawable.dispatchEvent(new Event('change'));
      panelColors.style.display = 'block';
      panelDrawables.style.display = 'none';
    });
    drawableList.appendChild(div);
  });
}

// ─── BROWSE POR CATEGORIA ─────────────────────────────────────
function populateCategorySelect(gender) {
  const sel = $('selCategory');
  sel.innerHTML = '<option value="">— categoria —</option>';
  const cats = (S.categories[gender] || []);
  cats.forEach(cat => {
    const opt = document.createElement('option');
    // Se cat for string (formato antigo) ou objeto (novo formato)
    const key = typeof cat === 'string' ? cat : cat.key;
    const label = (typeof cat === 'string') ? getCategoryLabel(cat) : cat.label;
    opt.value = key;
    opt.textContent = label;
    sel.appendChild(opt);
  });
}

$('selGender').addEventListener('change', () => {
  populateCategorySelect($('selGender').value);
  $('browseList').innerHTML = '';
  $('browseStatus').textContent = 'Selecione uma categoria';
  S.browseDrawables = [];
});

$('selCategory').addEventListener('change', async () => {
  const gender   = $('selGender').value;
  const category = $('selCategory').value;
  if (!category) return;

  $('browseStatus').textContent = 'Carregando...';
  $('browseList').innerHTML = '';

  const res = await nui('browseCategory', { gender, category });
  if (res.ok && res.drawables) {
    S.browseDrawables = res.drawables;
    $('browseStatus').textContent = `${res.drawables.length} drawable(s)`;
    renderBrowseList(res.drawables);
  } else {
    $('browseStatus').textContent = res.error || 'Sem dados';
    S.browseDrawables = [];
  }
});

// Filtro de busca
let browseSearchTimer = null;
$('inpBrowseSearch').addEventListener('input', () => {
  clearTimeout(browseSearchTimer);
  browseSearchTimer = setTimeout(() => {
    const q = $('inpBrowseSearch').value.trim().toLowerCase();
    const filtered = q
      ? S.browseDrawables.filter(d => d.toLowerCase().includes(q))
      : S.browseDrawables;
    $('browseStatus').textContent = `${filtered.length} / ${S.browseDrawables.length}`;
    renderBrowseList(filtered);
  }, 200);
});

function renderBrowseList(drawables) {
  const list = $('browseList');
  list.innerHTML = '';

  if (!drawables || drawables.length === 0) {
    list.innerHTML = '<div class="browse-empty">Nenhum drawable encontrado</div>';
    return;
  }

  // Limitar exibição a 200 itens por vez para performance
  const MAX = 200;
  const shown = drawables.slice(0, MAX);

  shown.forEach(name => {
    const div = document.createElement('div');
    div.className = 'browse-item';
    div.innerHTML = `<span class="bname">${name}</span><span class="badd">+ ADD</span>`;
    div.addEventListener('click', async () => {
      await addDrawableToXml(name);
    });
    list.appendChild(div);
  });

  if (drawables.length > MAX) {
    const more = document.createElement('div');
    more.className = 'browse-empty';
    more.textContent = `+ ${drawables.length - MAX} itens — use o filtro para refinar`;
    list.appendChild(more);
  }
}

async function addDrawableToXml(drawableName) {
  // Buscar info do drawable (albedo, material, normal, palette)
  const gender = $('selGender').value;
  const info   = await nui('getDrawableInfo', { gender, drawable: drawableName });

  const albedo   = (info.ok && info.albedo)   ? info.albedo   : '';
  const material = (info.ok && info.material) ? info.material : '';
  const normal   = (info.ok && info.normal)   ? info.normal   : '';
  const palette  = (info.ok && info.palette)  ? info.palette  : '';

  const newItem = `  <Item>\n    <drawable>${drawableName}</drawable>\n    <albedo>${albedo}</albedo>\n    <normal>${normal}</normal>\n    <material>${material}</material>\n    <palette>${palette}</palette>\n    <tint0 value="0" />\n    <tint1 value="0" />\n    <tint2 value="0" />\n    <probability value="255" />\n  </Item>`;

  const cur = xmlEditor.value.trim();
  xmlEditor.value = cur ? cur + '\n' + newItem : newItem;
  validateXml();
  toast(`+ ${drawableName}`, 'success', 1500);
}

// ─── PROJETOS ─────────────────────────────────────────────────
function renderProjects(projects) {
  S.projects = projects || [];
  selProject.innerHTML = '<option value="">— sem projeto —</option>';
  S.projects.forEach(p => {
    const opt = document.createElement('option');
    opt.value = p.name;
    opt.textContent = p.name;
    selProject.appendChild(opt);
  });
  if (S.curProject) selProject.value = S.curProject;
}

selProject.addEventListener('change', () => {
  S.curProject = selProject.value || null;
  if (!S.curProject) { clearSlots(); return; }
  const proj = S.projects.find(p => p.name === S.curProject);
  if (proj) renderSlots(proj);
});

function renderSlots(proj) {
  document.querySelectorAll('.slot-row').forEach(row => {
    const s = row.dataset.slot;
    const input = row.querySelector('.slot-input');
    const hasXml = proj.slots && proj.slots[s];
    input.value = hasXml ? ('Slot ' + s + ' ✔') : '';
    input.placeholder = s;
    row.classList.toggle('active', !!hasXml);

    // Click no slot → carregar
    input.onclick = () => {
      if (hasXml) nui('loadProject', { name: proj.name, slot: parseInt(s) });
    };
  });
}

function clearSlots() {
  document.querySelectorAll('.slot-row').forEach(row => {
    row.querySelector('.slot-input').value = '';
    row.classList.remove('active');
  });
}

function markSlotSaved(slot) {
  document.querySelectorAll('.slot-row').forEach(row => {
    if (parseInt(row.dataset.slot) === slot) {
      const input = row.querySelector('.slot-input');
      input.value = 'Slot ' + slot + ' ✔';
      row.classList.add('active');
    }
  });
}

// X por slot → limpar
document.querySelectorAll('.btn-x').forEach(btn => {
  btn.addEventListener('click', () => {
    const row = btn.closest('.slot-row');
    row.querySelector('.slot-input').value = '';
    row.classList.remove('active');
    // Aqui poderia notificar servidor para limpar slot do projeto
  });
});

// Deletar projeto
$('btnDeleteProject').addEventListener('click', async () => {
  if (!S.curProject) { toast('Selecione um projeto', 'warn'); return; }
  if (!confirm('Deletar projeto "' + S.curProject + '"?')) return;
  await nui('deleteProject', { name: S.curProject });
  S.curProject = null;
  clearSlots();
});

// Colapsar projetos
$('btnCollapseProj').addEventListener('click', () => {
  const sec = $('btnCollapseProj').closest('.section');
  const body = sec.querySelectorAll(':scope > *:not(.section-title-row)');
  const hidden = [...body].some(el => el.style.display === 'none');
  body.forEach(el => el.style.display = hidden ? '' : 'none');
  $('btnCollapseProj').textContent = hidden ? '‹' : '›';
});

// ─── RECONSTRUIR XML DOS ITEMS EDITADOS ───────────────────────
function rebuildXmlFromItems() {
  const lines = [];
  S.items.forEach(item => {
    lines.push('  <Item>');
    lines.push(`    <drawable>${item.drawable}</drawable>`);
    lines.push(`    <albedo>${item.albedo}</albedo>`);
    lines.push(`    <normal>${item.normal}</normal>`);
    lines.push(`    <material>${item.material}</material>`);
    lines.push(`    <palette>${item.palette}</palette>`);
    lines.push(`    <tint0 value="${item.tint0}" />`);
    lines.push(`    <tint1 value="${item.tint1}" />`);
    lines.push(`    <tint2 value="${item.tint2}" />`);
    lines.push(`    <probability value="${item.probability}" />`);
    lines.push('  </Item>');
  });
  xmlEditor.value = lines.join('\n');
}

// ─── PED AUTOCOMPLETE ─────────────────────────────────────────
function populatePedList(peds) {
  pedList.innerHTML = '';
  peds.forEach(p => {
    const opt = document.createElement('option');
    opt.value = p;
    pedList.appendChild(opt);
  });
}

// ─── DRAG PARA PAINÉIS FLUTUANTES ─────────────────────────────
function makeDraggable(panel) {
  const header = panel.querySelector('.float-header');
  header.addEventListener('mousedown', e => {
    S.dragPanel  = panel;
    const rect   = panel.getBoundingClientRect();
    S.dragOffset = { x: e.clientX - rect.left, y: e.clientY - rect.top };
    panel.style.userSelect = 'none';
  });
}

document.addEventListener('mousemove', e => {
  if (!S.dragPanel) return;
  S.dragPanel.style.left = (e.clientX - S.dragOffset.x) + 'px';
  S.dragPanel.style.top  = (e.clientY - S.dragOffset.y) + 'px';
});
document.addEventListener('mouseup', () => {
  if (S.dragPanel) { S.dragPanel.style.userSelect = ''; S.dragPanel = null; }
});

makeDraggable(panelColors);
makeDraggable(panelDrawables);


// ─── NOTAS (MOVÍVEL) ──────────────────────────────────────────
const panelNotes = $('panelNotes');
makeDraggable(panelNotes);

$('btnMiniNotes').addEventListener('click', () => {
  const body = panelNotes.querySelector('.float-body');
  const isHidden = body.style.display === 'none';
  body.style.display = isHidden ? '' : 'none';
  $('btnMiniNotes').textContent = isHidden ? '—' : '+';
});

// ─── ESC ──────────────────────────────────────────────────────
document.addEventListener('keydown', e => {
  if (e.key === 'Escape' && S.open) {
    nui('close', {}).catch(() => {});
    closeUI();
  }
});

// ─── MENSAGENS DO LUA ─────────────────────────────────────────
window.addEventListener('message', e => {
  const d = e.data;
  if (!d || !d.type) return;

  switch (d.type) {
    case 'open':
      openUI(d);
      break;
    case 'close':
      closeUI();
      break;
    case 'projects':
      renderProjects(d.data);
      break;
    case 'loadOutfit':
      xmlEditor.value = d.xml || '';
      if (d.model) { S.pedModel = d.model; $('inpPedModel').value = d.model; }
      if (d.slot)  { S.slot = d.slot; $('inpOutfitSlot').value = d.slot; }
      validateXml();
      toast('Outfit carregado: slot ' + d.slot, 'info');
      break;
    case 'serverMsg':
      toast(d.message, d.msgType || 'info');
      break;
  }
});

// ─── INIT ─────────────────────────────────────────────────────
setupCamSliders();
