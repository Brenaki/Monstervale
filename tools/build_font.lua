-- Gera a fonte de pixel da interface no formato BMFont, que o Godot importa direto.
-- Uso: rode com o MCP do Aseprite, definindo PROJECT_ROOT.
-- Saída: art/font.aseprite, assets/ui/font.png e assets/ui/font.fnt.
--
-- Cada letra tem 11 linhas: 2 para o acento das maiúsculas, 7 da altura da maiúscula
-- e 2 da perna do g, p, q e y. A linha de base fica sob a nona linha.

local ROOT = PROJECT_ROOT or "."
local pc = app.pixelColor
local LINE = 12
local BASE = 9
local CELL_H = 11
local CAP_TOP = 2
local SPACING = 1
local SPACE_ADVANCE = 3
local INK = pc.rgba(255, 255, 255, 255)

-- Linhas a partir do topo da maiúscula; letras com perna têm 9 linhas.
local G = {
  A = { ".###.", "#...#", "#...#", "#####", "#...#", "#...#", "#...#" },
  B = { "####.", "#...#", "#...#", "####.", "#...#", "#...#", "####." },
  C = { ".###.", "#...#", "#....", "#....", "#....", "#...#", ".###." },
  D = { "####.", "#...#", "#...#", "#...#", "#...#", "#...#", "####." },
  E = { "#####", "#....", "#....", "####.", "#....", "#....", "#####" },
  F = { "#####", "#....", "#....", "####.", "#....", "#....", "#...." },
  G = { ".###.", "#...#", "#....", "#.###", "#...#", "#...#", ".####" },
  H = { "#...#", "#...#", "#...#", "#####", "#...#", "#...#", "#...#" },
  I = { "###", ".#.", ".#.", ".#.", ".#.", ".#.", "###" },
  J = { "..###", "...#.", "...#.", "...#.", "#..#.", "#..#.", ".##.." },
  K = { "#...#", "#..#.", "#.#..", "##...", "#.#..", "#..#.", "#...#" },
  L = { "#....", "#....", "#....", "#....", "#....", "#....", "#####" },
  M = { "#...#", "##.##", "#.#.#", "#.#.#", "#...#", "#...#", "#...#" },
  N = { "#...#", "##..#", "#.#.#", "#..##", "#...#", "#...#", "#...#" },
  O = { ".###.", "#...#", "#...#", "#...#", "#...#", "#...#", ".###." },
  P = { "####.", "#...#", "#...#", "####.", "#....", "#....", "#...." },
  Q = { ".###.", "#...#", "#...#", "#...#", "#.#.#", "#..#.", ".##.#" },
  R = { "####.", "#...#", "#...#", "####.", "#.#..", "#..#.", "#...#" },
  S = { ".####", "#....", "#....", ".###.", "....#", "....#", "####." },
  T = { "#####", "..#..", "..#..", "..#..", "..#..", "..#..", "..#.." },
  U = { "#...#", "#...#", "#...#", "#...#", "#...#", "#...#", ".###." },
  V = { "#...#", "#...#", "#...#", "#...#", "#...#", ".#.#.", "..#.." },
  W = { "#...#", "#...#", "#...#", "#.#.#", "#.#.#", "##.##", "#...#" },
  X = { "#...#", "#...#", ".#.#.", "..#..", ".#.#.", "#...#", "#...#" },
  Y = { "#...#", "#...#", ".#.#.", "..#..", "..#..", "..#..", "..#.." },
  Z = { "#####", "....#", "...#.", "..#..", ".#...", "#....", "#####" },

  a = { ".....", ".....", ".###.", "....#", ".####", "#...#", ".####" },
  b = { "#....", "#....", "####.", "#...#", "#...#", "#...#", "####." },
  c = { "....", "....", ".###", "#...", "#...", "#...", ".###" },
  d = { "....#", "....#", ".####", "#...#", "#...#", "#...#", ".####" },
  e = { ".....", ".....", ".###.", "#...#", "#####", "#....", ".###." },
  f = { "..##", ".#..", "####", ".#..", ".#..", ".#..", ".#.." },
  g = { ".....", ".....", ".####", "#...#", "#...#", "#...#", ".####", "....#", ".###." },
  h = { "#....", "#....", "####.", "#...#", "#...#", "#...#", "#...#" },
  i = { "#", ".", "#", "#", "#", "#", "#" },
  j = { "..#", "...", "..#", "..#", "..#", "..#", "..#", "..#", "##." },
  k = { "#...", "#...", "#..#", "#.#.", "##..", "#.#.", "#..#" },
  l = { "#.", "#.", "#.", "#.", "#.", "#.", ".#" },
  m = { ".....", ".....", "##.#.", "#.#.#", "#.#.#", "#.#.#", "#.#.#" },
  n = { ".....", ".....", "####.", "#...#", "#...#", "#...#", "#...#" },
  o = { ".....", ".....", ".###.", "#...#", "#...#", "#...#", ".###." },
  p = { ".....", ".....", "####.", "#...#", "#...#", "#...#", "####.", "#....", "#...." },
  q = { ".....", ".....", ".####", "#...#", "#...#", "#...#", ".####", "....#", "....#" },
  r = { "....", "....", "#.##", "##..", "#...", "#...", "#..." },
  s = { "....", "....", ".###", "#...", ".##.", "...#", "###." },
  t = { ".#..", ".#..", "####", ".#..", ".#..", ".#..", "..##" },
  u = { ".....", ".....", "#...#", "#...#", "#...#", "#...#", ".####" },
  v = { ".....", ".....", "#...#", "#...#", "#...#", ".#.#.", "..#.." },
  w = { ".....", ".....", "#...#", "#...#", "#.#.#", "#.#.#", ".#.#." },
  x = { ".....", ".....", "#...#", ".#.#.", "..#..", ".#.#.", "#...#" },
  y = { ".....", ".....", "#...#", "#...#", "#...#", "#...#", ".####", "....#", ".###." },
  z = { ".....", ".....", "#####", "...#.", "..#..", ".#...", "#####" },

  ["0"] = { ".###.", "#...#", "#..##", "#.#.#", "##..#", "#...#", ".###." },
  ["1"] = { "..#..", ".##..", "..#..", "..#..", "..#..", "..#..", ".###." },
  ["2"] = { ".###.", "#...#", "....#", "...#.", "..#..", ".#...", "#####" },
  ["3"] = { ".###.", "#...#", "....#", "..##.", "....#", "#...#", ".###." },
  ["4"] = { "...#.", "..##.", ".#.#.", "#..#.", "#####", "...#.", "...#." },
  ["5"] = { "#####", "#....", "####.", "....#", "....#", "#...#", ".###." },
  ["6"] = { ".###.", "#....", "#....", "####.", "#...#", "#...#", ".###." },
  ["7"] = { "#####", "....#", "...#.", "..#..", ".#...", ".#...", ".#..." },
  ["8"] = { ".###.", "#...#", "#...#", ".###.", "#...#", "#...#", ".###." },
  ["9"] = { ".###.", "#...#", "#...#", ".####", "....#", "....#", ".###." },

  ["."] = { ".", ".", ".", ".", ".", ".", "#" },
  [","] = { "..", "..", "..", "..", "..", "..", ".#", "#." },
  [":"] = { ".", ".", ".", "#", ".", ".", "#" },
  [";"] = { "..", "..", "..", ".#", "..", "..", ".#", "#." },
  ["!"] = { "#", "#", "#", "#", "#", ".", "#" },
  ["?"] = { ".###.", "#...#", "....#", "...#.", "..#..", ".....", "..#.." },
  ["-"] = { "...", "...", "...", "...", "###", "...", "..." },
  ["+"] = { ".....", ".....", "..#..", "..#..", "#####", "..#..", "..#.." },
  ["="] = { "....", "....", "....", "####", "....", "####", "...." },
  ["/"] = { "....#", "...#.", "...#.", "..#..", ".#...", ".#...", "#...." },
  ["("] = { ".#", "#.", "#.", "#.", "#.", "#.", ".#" },
  [")"] = { "#.", ".#", ".#", ".#", ".#", ".#", "#." },
  ["%"] = { "##..#", "##.#.", "...#.", "..#..", ".#...", ".#.##", "#..##" },
  ["'"] = { "#", "#" },
  ['"'] = { "#.#", "#.#" },
  ["_"] = { ".....", ".....", ".....", ".....", ".....", ".....", ".....", "#####" },
  ["×"] = { ".....", ".....", "#...#", ".#.#.", "..#..", ".#.#.", "#...#" },
}

local ACCENTS = {
  acute = { "...#.", "..#.." },
  grave = { ".#...", "..#.." },
  circumflex = { "..#..", ".#.#." },
  tilde = { ".##.#", "#..#." },
}

-- Minúsculas recebem o acento nas duas linhas livres acima da altura do x;
-- maiúsculas, nas duas linhas acima delas.
local function accented(base, accent, upper)
  local rows = {}
  for i, row in ipairs(G[base]) do rows[i] = row end
  local marks = ACCENTS[accent]
  local width = #rows[1]
  local function fit(mark)
    local pad = (#mark - width) // 2
    return pad > 0 and mark:sub(pad + 1, pad + width) or mark
  end
  if upper then
    return { rows = rows, above = { fit(marks[1]), fit(marks[2]) } }
  end
  rows[1], rows[2] = fit(marks[1]), fit(marks[2])
  return { rows = rows }
end

local EXTRA = {
  ["á"] = accented("a", "acute"), ["à"] = accented("a", "grave"), ["â"] = accented("a", "circumflex"), ["ã"] = accented("a", "tilde"),
  ["é"] = accented("e", "acute"), ["ê"] = accented("e", "circumflex"),
  ["ó"] = accented("o", "acute"), ["ô"] = accented("o", "circumflex"), ["õ"] = accented("o", "tilde"),
  ["ú"] = accented("u", "acute"),
  ["Á"] = accented("A", "acute", true), ["À"] = accented("A", "grave", true), ["Â"] = accented("A", "circumflex", true), ["Ã"] = accented("A", "tilde", true),
  ["É"] = accented("E", "acute", true), ["Ê"] = accented("E", "circumflex", true),
  ["Ó"] = accented("O", "acute", true), ["Ô"] = accented("O", "circumflex", true), ["Õ"] = accented("O", "tilde", true),
  ["Ú"] = accented("U", "acute", true), ["Í"] = accented("I", "acute", true),
}
EXTRA["í"] = { rows = { "..#", ".#.", ".#.", ".#.", ".#.", ".#.", ".#." } }
EXTRA["ç"] = { rows = { "....", "....", ".###", "#...", "#...", "#...", ".###", "..#.", ".##." } }
EXTRA["Ç"] = { rows = { ".###.", "#...#", "#....", "#....", "#....", "#...#", ".###.", "..#..", ".##.." } }

-- Ordem fixa dos caracteres na folha.
local chars = {}
for code = 33, 126 do
  local c = string.char(code)
  if G[c] then chars[#chars + 1] = c end
end
local extra_order = { "×", "á", "à", "â", "ã", "é", "ê", "í", "ó", "ô", "õ", "ú", "ç", "Á", "À", "Â", "Ã", "É", "Ê", "Í", "Ó", "Ô", "Õ", "Ú", "Ç" }
for _, c in ipairs(extra_order) do chars[#chars + 1] = c end

local function glyph(c)
  if EXTRA[c] then return EXTRA[c] end
  return { rows = G[c] }
end

-- Código Unicode de um caractere em UTF-8.
local function codepoint(c)
  local b1, b2 = c:byte(1, 2)
  if b1 < 128 then return b1 end
  return (b1 % 32) * 64 + (b2 % 64)
end

local SHEET_W = 256
local x, y = 0, 0
local placed = {}
for _, c in ipairs(chars) do
  local w = #glyph(c).rows[1]
  if x + w > SHEET_W then x = 0; y = y + CELL_H + 1 end
  placed[#placed + 1] = { c = c, x = x, y = y, w = w }
  x = x + w + 1
end
local sheet = Image(ImageSpec{ width = SHEET_W, height = y + CELL_H, colorMode = ColorMode.RGB })
sheet:clear(pc.rgba(0, 0, 0, 0))
for _, p in ipairs(placed) do
  local g = glyph(p.c)
  for r, row in ipairs(g.rows) do
    for i = 1, #row do
      if row:sub(i, i) == "#" then sheet:drawPixel(p.x + i - 1, p.y + CAP_TOP + r - 1, INK) end
    end
  end
  for r, row in ipairs(g.above or {}) do
    for i = 1, #row do
      if row:sub(i, i) == "#" then sheet:drawPixel(p.x + i - 1, p.y + r - 1, INK) end
    end
  end
end

local spr = Sprite(sheet.spec)
spr:newCel(spr.layers[1], 1, sheet, Point(0, 0))
spr:saveAs(ROOT .. "/art/font.aseprite")
spr:saveCopyAs(ROOT .. "/assets/ui/font.png")
spr:close()

local lines = {
  string.format('info face="DT-SLIME" size=%d bold=0 italic=0 charset="" unicode=1 stretchH=100 smooth=0 aa=1 padding=0,0,0,0 spacing=1,1', LINE),
  string.format("common lineHeight=%d base=%d scaleW=%d scaleH=%d pages=1 packed=0", LINE, BASE, SHEET_W, sheet.height),
  'page id=0 file="font.png"',
  string.format("chars count=%d", #placed + 1),
  string.format("char id=32 x=0 y=0 width=0 height=0 xoffset=0 yoffset=0 xadvance=%d page=0 chnl=15", SPACE_ADVANCE),
}
for _, p in ipairs(placed) do
  lines[#lines + 1] = string.format("char id=%d x=%d y=%d width=%d height=%d xoffset=0 yoffset=0 xadvance=%d page=0 chnl=15",
    codepoint(p.c), p.x, p.y, p.w, CELL_H, p.w + SPACING)
end
local file = io.open(ROOT .. "/assets/ui/font.fnt", "w")
file:write(table.concat(lines, "\n") .. "\n")
file:close()
return #placed
