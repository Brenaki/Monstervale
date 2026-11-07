-- Gera o kit de interface: molduras, botões, escudo de preço e ícones, numa folha só.
-- Uso: rode com o MCP do Aseprite, definindo PROJECT_ROOT.
-- Saída: art/ui.aseprite, assets/ui/ui.png e assets/ui/ui.json com a região de cada peça.

local ROOT = PROJECT_ROOT or "."
local pc = app.pixelColor
local SHEET_W, SHEET_H = 256, 128
local CELL = 16
local CLEAR = pc.rgba(0, 0, 0, 0)

local function rgb(hex)
  return pc.rgba(tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16), 255)
end

local K = "1b1626"
local sheet = Image(ImageSpec{ width = SHEET_W, height = SHEET_H, colorMode = ColorMode.RGB })
sheet:clear(CLEAR)
local regions = {}

local function rows(x, y, list, legend)
  for r, row in ipairs(list) do
    for i = 1, #row do
      local hex = legend[row:sub(i, i)]
      if hex then sheet:drawPixel(x + i - 1, y + r - 1, rgb(hex)) end
    end
  end
end

local function region(name, x, y, w, h, margin)
  regions[name] = { x = x, y = y, w = w, h = h, margin = margin }
end

-- Contorno escuro de 1 px em volta do que já foi desenhado na área.
local function outline(x, y, w, h)
  local copy = sheet:clone()
  local function solid(px, py)
    return px >= x and py >= y and px < x + w and py < y + h and pc.rgbaA(copy:getPixel(px, py)) > 0
  end
  for py = y, y + h - 1 do
    for px = x, x + w - 1 do
      if not solid(px, py) and (solid(px - 1, py) or solid(px + 1, py) or solid(px, py - 1) or solid(px, py + 1)) then
        sheet:drawPixel(px, py, rgb(K))
      end
    end
  end
end

-- Molduras e botões ------------------------------------------------------------

-- Painel de pedra azulada com rebites dourados nos cantos; o miolo escuro se estica.
local PANEL = {
  ".KKKKKKKKKK.",
  "KYLLLLLLLLYK",
  "KLMMMMMMMMSK",
  "KLMkkkkkkMSK",
  "KLMkIIIIkMSK",
  "KLMkIIIIkMSK",
  "KLMkIIIIkMSK",
  "KLMkIIIIkMSK",
  "KLMkkkkkkMSK",
  "KLMMMMMMMMSK",
  "KYSSSSSSSSYK",
  ".KKKKKKKKKK.",
}
rows(0, 0, PANEL, { K = K, Y = "f6e05e", L = "a9b6c3", M = "5d6a7a", S = "3d4757", k = "141019", I = "2a2438" })
region("panel", 0, 0, 12, 12, 4)

-- Botão com luz em cima e sombra embaixo; apertado, a face desce 1 px.
local BUTTON = {
  ".KKKKKKKKK.",
  "KHHHHHHHHHK",
  "KHFFFFFFFDK",
  "KHFFFFFFFDK",
  "KHFFFFFFFDK",
  "KHFFFFFFFDK",
  "KHFFFFFFFDK",
  "KDDDDDDDDDK",
  "KDDDDDDDDDK",
  ".KKKKKKKKK.",
}
local BUTTON_PRESSED = {
  ".KKKKKKKKK.",
  "KDDDDDDDDDK",
  "KDHHHHHHHHK",
  "KDHFFFFFFFK",
  "KDHFFFFFFFK",
  "KDHFFFFFFFK",
  "KDHFFFFFFFK",
  "KDHFFFFFFFK",
  "KDHFFFFFFFK",
  ".KKKKKKKKK.",
}
local BUTTONS = {
  { "button", { H = "a9b6c3", F = "56647a", D = "3d4757" }, { H = "c9d1d9", F = "6b7a8f", D = "4a5668" }, { H = "5fa8e8", F = "2f6bb0", D = "1f4f86" }, { H = "3d3550", F = "2a2438", D = "231d30" } },
  { "green", { H = "a5d86e", F = "4f9d4a", D = "2f6b34" }, { H = "c0e88a", F = "63b35a", D = "3a7d3d" }, { H = "c0e88a", F = "4f9d4a", D = "2f6b34" }, { H = "3d3550", F = "2a2438", D = "231d30" } },
}
for b, spec in ipairs(BUTTONS) do
  local y = 16 + (b - 1) * 12
  local states = { "normal", "hover", "pressed", "disabled" }
  for s, state in ipairs(states) do
    local colors = spec[s + 1]
    local legend = { K = K, H = colors.H, F = colors.F, D = colors.D }
    local x = (s - 1) * 12
    rows(x, y, state == "pressed" and BUTTON_PRESSED or BUTTON, legend)
    region(spec[1] .. "_" .. state, x, y, 11, 10, 3)
  end
end

-- Botão redondo do anel em volta do humano.
local function disc(x, y, size, colors)
  local r = size / 2
  local cx, cy = x + r - 0.5, y + r - 0.5
  for py = y, y + size - 1 do
    for px = x, x + size - 1 do
      local dx, dy = px - cx, py - cy
      local d = math.sqrt(dx * dx + dy * dy)
      if d <= r - 0.5 then
        local c = colors.F
        if d > r - 1.5 then c = K
        elseif d > r - 3.5 and dx + dy < 0 then c = colors.H
        elseif d > r - 3.5 then c = colors.D end
        sheet:drawPixel(px, py, rgb(c))
      end
    end
  end
end
local RING = {
  { "normal", { H = "a9b6c3", F = "56647a", D = "3d4757" } },
  { "hover", { H = "c9d1d9", F = "6b7a8f", D = "4a5668" } },
  { "pressed", { H = "5fa8e8", F = "2f6bb0", D = "1f4f86" } },
  { "disabled", { H = "3d3550", F = "2a2438", D = "231d30" } },
}
for i, item in ipairs(RING) do
  local x = 48 + (i - 1) * 22
  disc(x, 0, 20, item[2])
  region("ring_" .. item[1], x, 0, 20, 20, 0)
end

-- Escudo do preço, de ouro com o miolo escuro, arredondado embaixo.
local BADGE = {
  "YYYYYYYYYYYYYYYYYYYYYY",
  "YIIIIIIIIIIIIIIIIIIIIY",
  "YIIIIIIIIIIIIIIIIIIIIY",
  "YIIIIIIIIIIIIIIIIIIIIY",
  "YIIIIIIIIIIIIIIIIIIIIY",
  "YIIIIIIIIIIIIIIIIIIIIY",
  "YIIIIIIIIIIIIIIIIIIIIY",
  "YIIIIIIIIIIIIIIIIIIIIY",
  ".YIIIIIIIIIIIIIIIIIIY.",
  "..YYIIIIIIIIIIIIIIYY..",
  "....YYYIIIIIIIIYYY....",
  ".......YYYYYYYY.......",
}
rows(49, 25, BADGE, { Y = "e8b33a", I = "2a2438" })
outline(48, 24, 24, 14)
region("badge", 48, 24, 24, 14, 0)

-- Ícones -----------------------------------------------------------------------

local ICONS = {
  heart = { {
    ".RRR.RRR.",
    "RWRRRRRRR",
    "RWRRRRRRR",
    "RRRRRRRRr",
    ".RRRRRRr.",
    "..RRRRr..",
    "...RRr...",
    "....r....",
  }, { R = "d9534a", r = "8e2f36", W = "f4b8a8" } },
  coin = { {
    "..YYYY..",
    ".YWYYYy.",
    "YWYYYYYy",
    "YYYyyYYy",
    "YYYyyYYy",
    "YYYYYYyy",
    ".YYYYyy.",
    "..yyyy..",
  }, { Y = "f6e05e", y = "c98a2b", W = "fff8c8" } },
  skull = { {
    "..WWWWW..",
    ".WWWWWWG.",
    "WWWWWWWWG",
    "WkkWWWkkG",
    "WkkWWWkkG",
    ".WWWkWWG.",
    "..WWWWG..",
    "..W.W.G..",
  }, { W = "f4f7f8", G = "c9d1d9", k = K } },
  pause = { {
    "WW..WW",
    "WW..WW",
    "WW..WW",
    "WW..WW",
    "WW..WW",
    "WW..WW",
    "WW..WW",
  }, { W = "f4f7f8" } },
  play = { {
    "WW.....",
    "WWWW...",
    "WWWWWW.",
    "WWWWWWW",
    "WWWWWW.",
    "WWWW...",
    "WW.....",
  }, { W = "f4f7f8" } },
  fast = { {
    "W...W...",
    "WW..WW..",
    "WWW.WWW.",
    "WWWWWWWW",
    "WWW.WWW.",
    "WW..WW..",
    "W...W...",
  }, { W = "f4f7f8" } },
  menu = { {
    "WWWWWWWW",
    "WWWWWWWW",
    "........",
    "WWWWWWWW",
    "WWWWWWWW",
    "........",
    "WWWWWWWW",
    "WWWWWWWW",
  }, { W = "f4f7f8" } },
  upgrade = { {
    "....N....",
    "...NNN...",
    "..NNNNN..",
    ".NNNNNNN.",
    "NNNNNNNNN",
    "...NNn...",
    "...NNn...",
    "...NNn...",
  }, { N = "7fbb4e", n = "4f9d4a" } },
  target = { {
    "..RRRRR..",
    ".R.....R.",
    "R..RRR..R",
    "R.R...R.R",
    "R.R.W.R.R",
    "R.R...R.R",
    "R..RRR..R",
    ".R.....R.",
    "..RRRRR..",
  }, { R = "d9534a", W = "f4f7f8" } },
  sword = { {
    ".......WW",
    "......WWG",
    ".....WWG.",
    "....WWG..",
    ".O.WWG...",
    "..OWG....",
    "..oO.....",
    ".o..O....",
    "o........",
  }, { W = "f4f7f8", G = "a9b6c3", O = "e8b33a", o = "8a5a3a" } },
  pierce = { {
    ".....WWWW",
    "......WWW",
    ".....O.WW",
    "....O...W",
    "...O.....",
    "YYO......",
    ".Y.......",
    "Y.Y......",
  }, { W = "f4f7f8", O = "b07a4a", Y = "d9534a" } },
  impact = { {
    "GGGGGGG",
    "GWWWWWG",
    "GGGGGGg",
    "..OO...",
    "..OO...",
    "..OO...",
    "..OO...",
    "..oo...",
  }, { G = "a9b6c3", W = "f4f7f8", g = "5d6a7a", O = "b07a4a", o = "6b4228" } },
  magic = { {
    "....P....",
    "....P....",
    "...PWP...",
    "PPPWWWPPP",
    "...PWP...",
    "....P....",
    "....P....",
  }, { P = "c79bf0", W = "f4f7f8" } },
  range = { {
    "..BBBBB..",
    ".B.....B.",
    "B.......B",
    "B...W...B",
    "B.......B",
    ".B.....B.",
    "..BBBBB..",
  }, { B = "5fa8e8", W = "f4f7f8" } },
  cadence = { {
    "OOOOOOO",
    ".YYYYY.",
    "..YYY..",
    "...Y...",
    "..Y.Y..",
    ".YYYYY.",
    "OOOOOOO",
  }, { O = "b07a4a", Y = "f6e05e" } },
  star = { {
    "....Y....",
    "...YYY...",
    "YYYYWYYYY",
    ".YYYYYYY.",
    "..YYYYY..",
    ".YYY.YYY.",
    ".YY...YY.",
  }, { Y = "f6e05e", W = "fff8c8" } },
  star_empty = { {
    "....G....",
    "...G.G...",
    "GGGG.GGGG",
    ".G.....G.",
    "..G...G..",
    ".G.GGG.G.",
    ".GG...GG.",
  }, { G = "5d6a7a" } },
  close = { {
    "WW....WW",
    ".WW..WW.",
    "..WWWW..",
    "...WW...",
    "..WWWW..",
    ".WW..WW.",
    "WW....WW",
  }, { W = "f4f7f8" } },
  lock = { {
    "..GGG..",
    ".G...G.",
    ".G...G.",
    "YYYYYYY",
    "YYYkYYY",
    "YYYkYYY",
    "yyyyyyy",
  }, { G = "a9b6c3", Y = "e8b33a", y = "a8732a", k = K } },
  note = { {
    "..WWWWWW",
    "..WWWWWW",
    "..W....W",
    "..W....W",
    "..W....W",
    "WWW..WWW",
    "WWW..WWW",
    ".W....W.",
  }, { W = "f4f7f8" } },
  speaker = { {
    "...W....",
    "..WW..W.",
    "WWWW.W..",
    "WWWW.W.W",
    "WWWW.W..",
    "..WW..W.",
    "...W....",
  }, { W = "f4f7f8" } },
}

-- Seta do tutorial, apontando para baixo.
ICONS.arrow = { {
  "..YYYYY..",
  "..YWYYy..",
  "..YWYYy..",
  "..YWYYy..",
  "YYYWYYyyy",
  ".YWYYYyy.",
  "..YYYyy..",
  "...Yyy...",
  "....y....",
}, { Y = "f6e05e", y = "c98a2b", W = "fff8c8" } }

-- Troféu das conquistas.
ICONS.trophy = { {
  "..YYYYYYY..",
  "YYYWYYYYyYY",
  "Y.YWYYYYy.Y",
  "Y.YWYYYYy.Y",
  ".YYWYYYYyY.",
  "...YYYYy...",
  "....YYy....",
  "....Yyy....",
  "...YYYyy...",
  "..YYYYYyy..",
}, { Y = "f6e05e", y = "c98a2b", W = "fff8c8" } }

-- Ordem fixa para as posições não mudarem de uma geração para outra.
local ORDER = {
  "heart", "coin", "skull", "pause", "play", "fast", "menu", "upgrade",
  "target", "sword", "pierce", "impact", "magic", "range", "cadence", "star",
  "star_empty", "close", "lock", "speaker", "note", "arrow", "trophy",
}
local ICON_Y = 48
for i, name in ipairs(ORDER) do
  local icon = ICONS[name]
  local cx = ((i - 1) % 16) * CELL
  local cy = ICON_Y + ((i - 1) // 16) * CELL
  local w, h = #icon[1][1], #icon[1]
  local x = cx + (CELL - w) // 2
  local y = cy + (CELL - h) // 2
  rows(x, y, icon[1], icon[2])
  outline(cx, cy, CELL, CELL)
  region("icon_" .. name, cx, cy, CELL, CELL, 0)
end

-- Saída ------------------------------------------------------------------------

local spr = Sprite(sheet.spec)
spr:newCel(spr.layers[1], 1, sheet, Point(0, 0))
app.fs.makeAllDirectories(ROOT .. "/assets/ui")
spr:saveAs(ROOT .. "/art/ui.aseprite")
spr:saveCopyAs(ROOT .. "/assets/ui/ui.png")
spr:close()

local names = {}
for name in pairs(regions) do names[#names + 1] = name end
table.sort(names)
local parts = {}
for _, name in ipairs(names) do
  local r = regions[name]
  parts[#parts + 1] = string.format('\t"%s": {"x": %d, "y": %d, "w": %d, "h": %d, "margin": %d}', name, r.x, r.y, r.w, r.h, r.margin)
end
local file = io.open(ROOT .. "/assets/ui/ui.json", "w")
file:write("{\n" .. table.concat(parts, ",\n") .. "\n}\n")
file:close()
return #names
