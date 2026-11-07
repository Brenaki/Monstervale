-- Desenha a vila medieval, uma camada por construção, e as peças que caem quando ela toma dano.
-- Uso: rode com o MCP do Aseprite, definindo PROJECT_ROOT.
-- Saída: art/village.aseprite (camadas), assets/sprites/village.png (a vila inteira, usada nas
-- cenas) e assets/sprites/village_parts.png/json: cada peça, os escombros e a poeira, com a
-- região na folha e onde a peça fica dentro da vila (at).

local ROOT = PROJECT_ROOT or "."
local pc = app.pixelColor
local SIZE = 160
local SHEET_W, SHEET_H = 352, 192
local CLEAR = pc.rgba(0, 0, 0, 0)
local DUST_FRAMES = 5
local DUST_W, DUST_H = 28, 20

local function rgb(hex)
  return pc.rgba(tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16), 255)
end

local K = "1b1626"
local PLASTER = { "f0e2c4", "dccaa2", "c9b08a" }
local BEAM = { "8f5c35", "5e3a2a" }
local WOOD = { "c98d50", "b47a42", "8f5c35", "5e3a2a" }
local STONE = { "b8b0a2", "8c8579", "5e5853" }
local IRON = "4a4550"
local GLOW = { "f6e05e", "e8913a" }
local THATCH = { "f6e05e", "e8b94a", "c08e3a", "7a5a2a" }
local TILES = { "e87a68", "c4483e", "8a2c30" }
local WORN_TILES = { "c4483e", "a2303a", "6e2228" }
local SHINGLES = { "b47a42", "8f5c35", "5e3a2a" }
local WATER = { "4f8fd0", "2f6bb0" }

-- Sorteio fixo: a vila sai sempre igual.
local function hash(a, b, c)
  local n = (a * 73856093) ~ (b * 19349663) ~ ((c or 0) * 83492791)
  return (n % 1000 + 1000) % 1000
end

local function new_image(w, h)
  local img = Image(ImageSpec{ width = w, height = h, colorMode = ColorMode.RGB })
  img:clear(CLEAR)
  return img
end

local function px(img, x, y, hex)
  if x >= 0 and y >= 0 and x < img.width and y < img.height then
    img:drawPixel(x, y, rgb(hex))
  end
end

local function rect(img, x, y, w, h, hex)
  for py = y, y + h - 1 do
    for qx = x, x + w - 1 do
      px(img, qx, py, hex)
    end
  end
end

local function rows(img, x, y, list, legend)
  for r, row in ipairs(list) do
    for i = 1, #row do
      local hex = legend[row:sub(i, i)]
      if hex then px(img, x + i - 1, y + r - 1, hex) end
    end
  end
end

local function solid(img, x, y)
  return x >= 0 and y >= 0 and x < img.width and y < img.height and pc.rgbaA(img:getPixel(x, y)) > 0
end

-- Contorno escuro de 1 px em volta de tudo o que há na imagem.
local function outline(img)
  local copy = img:clone()
  for y = 0, img.height - 1 do
    for x = 0, img.width - 1 do
      if not solid(copy, x, y) and (solid(copy, x - 1, y) or solid(copy, x + 1, y) or solid(copy, x, y - 1) or solid(copy, x, y + 1)) then
        img:drawPixel(x, y, rgb(K))
      end
    end
  end
end

local function used(img)
  local x0, y0, x1, y1 = img.width, img.height, -1, -1
  for y = 0, img.height - 1 do
    for x = 0, img.width - 1 do
      if solid(img, x, y) then
        x0, y0, x1, y1 = math.min(x0, x), math.min(y0, y), math.max(x1, x), math.max(y1, y)
      end
    end
  end
  return x0, y0, x1 - x0 + 1, y1 - y0 + 1
end

-- Peças de construção ----------------------------------------------------------

-- Pedras desencontradas em fiadas de 3 px; com shade, o lado direito fica na sombra (poço redondo).
local function masonry(img, x, y, w, h, seed, shade)
  for r = 0, h - 1 do
    local course, lr = r // 3, r % 3
    local c, stone = x - hash(course, 1, seed) % 4, 0
    while c < x + w do
      local sw = 3 + hash(stone, course, seed) % 4
      for i = 0, sw - 1 do
        local cx = c + i
        if cx >= x and cx < x + w then
          local color
          if i == sw - 1 or lr == 2 then
            color = STONE[3]
          elseif lr == 0 and i < sw - 2 then
            color = STONE[1]
          else
            color = STONE[2]
          end
          if shade and cx - x >= w * 0.72 and color == STONE[1] then color = STONE[2] end
          px(img, cx, y + r, color)
        end
      end
      c, stone = c + sw, stone + 1
    end
  end
end

local function line2(img, x0, y0, x1, y1, light, dark)
  local steps = math.max(math.abs(x1 - x0), math.abs(y1 - y0))
  for i = 0, steps do
    local x = math.floor(x0 + (x1 - x0) * i / steps + 0.5)
    local y = math.floor(y0 + (y1 - y0) * i / steps + 0.5)
    px(img, x, y, light)
    px(img, x + 1, y, dark)
  end
end

-- Enxaimel: reboco claro entre vigas escuras, com escoras em diagonal e reboco gasto.
local function timber(img, x, y, w, h, posts, braces, seed)
  rect(img, x, y, w, h, PLASTER[1])
  for i = 0, w * h // 70 do
    local hx, hy = x + 3 + hash(i, 1, seed) % (w - 6), y + 3 + hash(i, 2, seed) % (h - 5)
    px(img, hx, hy, PLASTER[2])
    px(img, hx + 1, hy, PLASTER[2])
  end
  rect(img, x, y + h - 3, w, 1, PLASTER[2])
  for _, b in ipairs(braces) do
    line2(img, x + b[1], y + 2, x + b[2], y + h - 3, BEAM[1], BEAM[2])
  end
  rect(img, x, y, w, 1, BEAM[1])
  rect(img, x, y + 1, w, 1, BEAM[2])
  rect(img, x, y + h - 2, w, 1, BEAM[1])
  rect(img, x, y + h - 1, w, 1, BEAM[2])
  for _, p in ipairs(posts) do
    rect(img, x + p, y, 1, h, BEAM[1])
    rect(img, x + p + 1, y, 1, h, BEAM[2])
  end
end

-- Janela pequena de luz de vela, com mainel no meio e venezianas de tábua abertas.
local function window(img, x, y, w, h)
  rect(img, x - 3, y, 3, h, WOOD[2])
  rect(img, x - 2, y, 1, h, WOOD[3])
  rect(img, x - 3, y, 1, h, BEAM[2])
  rect(img, x + w, y, 3, h, WOOD[2])
  rect(img, x + w + 1, y, 1, h, WOOD[3])
  rect(img, x + w + 2, y, 1, h, BEAM[2])
  rect(img, x, y, w, h, BEAM[2])
  rect(img, x + 1, y + 1, w - 2, h - 2, GLOW[2])
  rect(img, x + 1, y + 1, (w - 2) // 2, 2, GLOW[1])
  rect(img, x + w // 2, y + 1, 1, h - 2, BEAM[2])
  rect(img, x - 1, y + h, w + 2, 1, WOOD[2])
end

-- Porta de tábuas em arco, com duas cintas de ferro e argola.
local function door(img, x, y, w, h)
  for py = y, y + h - 1 do
    for qx = x, x + w - 1 do
      local lx, ly = qx - x, py - y
      local arch = ly == 0 and (lx < 2 or lx > w - 3) or ly == 1 and (lx == 0 or lx == w - 1)
      if not arch then
        local edge = lx == 0 or lx == w - 1 or ly == 0 or (ly == 1 and (lx == 1 or lx == w - 2))
        local color
        if edge then
          color = BEAM[2]
        elseif ly == 3 or ly == h - 4 then
          color = IRON
        elseif lx % 3 == 0 then
          color = WOOD[4]
        elseif lx % 3 == 1 then
          color = WOOD[2]
        else
          color = WOOD[3]
        end
        px(img, qx, py, color)
      end
    end
  end
  px(img, x + w - 3, y + h // 2, STONE[1])
end

-- Rampa de três cores do telhado, mais clara à esquerda (a luz vem de cima à esquerda).
local function roof_span(x, w, h, r, slope)
  local inset = math.floor((h - 1 - r) * slope + 0.5)
  return x + inset, x + w - 1 - inset
end

-- Palha grossa: fios na vertical, fiadas onduladas e franja solta embaixo.
local function thatch(img, x, y, w, h, slope, seed)
  for r = 0, h - 1 do
    local l, rr = roof_span(x, w, h, r, slope)
    for c = l, rr do
      local corner = r == 0 and (c == l or c == rr)
      if not corner then
        local t = (c - l) / math.max(1, rr - l)
        local strand = hash(c, r // 3, seed) % 6
        local course = (r + hash(c // 3, 1, seed) % 2) % 6 == 5
        local color = t < 0.5 and THATCH[1] or THATCH[2]
        if strand < 2 then color = THATCH[2] end
        if t > 0.7 and strand < 4 then color = THATCH[3] end
        if strand == 5 or course then color = THATCH[3] end
        if course and t > 0.7 then color = THATCH[4] end
        px(img, c, y + r, color)
      end
    end
  end
  for c = x + 1, x + w - 2 do
    if hash(c, 9, seed) % 3 ~= 0 then px(img, c, y + h, THATCH[3]) end
  end
  local l, rr = roof_span(x, w, h, 0, slope)
  rect(img, l + 1, y, rr - l - 1, 1, THATCH[4])
end

-- Telhas de barro em fiadas, algumas mais gastas e escuras.
local function tiles(img, x, y, w, h, slope, seed)
  for r = 0, h - 1 do
    local l, rr = roof_span(x, w, h, r, slope)
    local course, lr = r // 3, r % 3
    local shift = (course % 2) * 2
    for c = l, rr do
      local lc = (c - x + shift) % 4
      local ramp = hash((c - x + shift) // 4, course, seed) % 6 == 0 and WORN_TILES or TILES
      local color
      if lr == 2 or lc == 3 then
        color = ramp[3]
      elseif lr == 0 and lc < 2 and c - l < (rr - l) * 0.6 then
        color = ramp[1]
      else
        color = ramp[2]
      end
      px(img, c, y + r, color)
    end
  end
  local l, rr = roof_span(x, w, h, 0, slope)
  rect(img, l, y, rr - l + 1, 1, TILES[3])
end

-- Tábuas de madeira sobrepostas, de larguras diferentes.
local function shingles(img, x, y, w, h, slope, seed)
  for r = 0, h - 1 do
    local l, rr = roof_span(x, w, h, r, slope)
    local course, lr = r // 3, r % 3
    local c, board = x - hash(course, 3, seed) % 5, 0
    while c <= x + w do
      local bw = 3 + hash(board, course, seed) % 4
      for i = 0, bw - 1 do
        local cx = c + i
        if cx >= l and cx <= rr then
          local color
          if lr == 2 or i == bw - 1 then
            color = SHINGLES[3]
          elseif lr == 0 and cx - l < (rr - l) * 0.6 then
            color = SHINGLES[1]
          else
            color = SHINGLES[2]
          end
          px(img, cx, y + r, color)
        end
      end
      c, board = c + bw, board + 1
    end
  end
  local l, rr = roof_span(x, w, h, 0, slope)
  rect(img, l, y, rr - l + 1, 1, SHINGLES[3])
end

local function chimney(img, x, y, w, h, seed)
  masonry(img, x, y + 2, w, h - 2, seed)
  rect(img, x - 1, y, w + 2, 2, STONE[2])
  rect(img, x - 1, y, w + 2, 1, STONE[1])
end

-- Construções ------------------------------------------------------------------

local layers = {}

-- Casa de telhado vermelho: chalé de enxaimel com telhas de barro e chaminé de pedra.
local red = new_image(SIZE, SIZE)
chimney(red, 40, 13, 6, 14, 11)
masonry(red, 6, 57, 45, 5, 12)
timber(red, 6, 37, 45, 21, { 0, 22, 43 }, { { 3, 11 }, { 40, 32 } }, 13)
rect(red, 6, 37, 45, 2, PLASTER[3])
window(red, 31, 44, 8, 7)
door(red, 12, 46, 8, 16)
tiles(red, 2, 15, 53, 24, 0.75, 14)
outline(red)
layers.red_house = red

-- Casa de telhado marrom: taverna de dois andares, térreo de pedra e andar de cima em balanço.
local brown = new_image(SIZE, SIZE)
chimney(brown, 118, 6, 7, 14, 21)
masonry(brown, 73, 45, 56, 17, 22)
rect(brown, 73, 45, 56, 1, STONE[3])
timber(brown, 71, 30, 60, 15, { 0, 14, 29, 44, 58 }, { { 3, 12 }, { 26, 17 }, { 32, 41 }, { 55, 47 } }, 23)
rect(brown, 71, 30, 60, 2, PLASTER[3])
window(brown, 79, 35, 6, 6)
window(brown, 115, 35, 6, 6)
door(brown, 95, 48, 11, 14)
window(brown, 113, 50, 7, 6)
shingles(brown, 68, 8, 65, 23, 0.7, 24)
-- Placa da taverna pendurada num braço de ferro, com uma caneca pintada.
rect(brown, 63, 46, 10, 1, IRON)
px(brown, 64, 47, IRON)
px(brown, 70, 47, IRON)
rows(brown, 63, 48, {
  "KKKKKKKKK",
  "KBBBBBBdK",
  "KBFFFBBdK",
  "KByyyyydK",
  "KByyyBydK",
  "KByyyyydK",
  "KBByyyBdK",
  "KKKKKKKKK",
}, { K = K, B = WOOD[2], d = WOOD[3], F = PLASTER[1], y = THATCH[2] })
outline(brown)
layers.brown_house = brown

-- Casa amarela: telhado de palha grosso, porta em arco e janela com venezianas.
local yellow = new_image(SIZE, SIZE)
masonry(yellow, 94, 148, 52, 4, 31)
timber(yellow, 94, 127, 52, 22, { 0, 24, 50 }, { { 4, 12 }, { 47, 39 } }, 32)
rect(yellow, 94, 127, 52, 3, PLASTER[3])
door(yellow, 105, 136, 9, 16)
window(yellow, 124, 136, 8, 7)
thatch(yellow, 88, 101, 64, 29, 0.62, 33)
outline(yellow)
layers.yellow_house = yellow

-- Poço de pedra com telhadinho, manivela e balde.
local well = new_image(SIZE, SIZE)
rect(well, 29, 106, 2, 14, WOOD[3])
rect(well, 30, 106, 1, 14, WOOD[4])
rect(well, 47, 106, 2, 14, WOOD[3])
rect(well, 48, 106, 1, 14, WOOD[4])
rect(well, 29, 109, 20, 2, WOOD[4])
rect(well, 29, 109, 20, 1, WOOD[3])
rows(well, 49, 107, { "II.", ".I.", ".II" }, { I = IRON })
shingles(well, 26, 101, 26, 6, 1.2, 41)
masonry(well, 29, 119, 20, 12, 42, true)
for y = 115, 120 do
  for x = 28, 49 do
    local dx, dy = (x - 38.5) / 10.6, (y - 118) / 3.2
    local d = dx * dx + dy * dy
    if d <= 1.0 then
      local inner = ((x - 38.5) / 7.2) ^ 2 + ((y - 117.6) / 1.8) ^ 2
      px(well, x, y, inner <= 1.0 and WATER[2] or (y < 118 and STONE[1] or STONE[2]))
    end
  end
end
rows(well, 38, 111, { "y", "y" }, { y = PLASTER[3] })
rows(well, 36, 113, { "IIII", "BBBd", "BBBd" }, { I = IRON, B = WOOD[2], d = WOOD[3] })
outline(well)
layers.well = well

-- Chão: cercas de galhos trançados, barris e feno, que ficam de pé até o fim.
local base = new_image(SIZE, SIZE)
local function wattle(x, y, w, h, seed)
  -- Galhos de 2 px, cada um passando por fora e por dentro das estacas, alternados.
  for r = y + 3, y + h - 3 do
    local branch = (r - y - 3) // 2
    for c = x, x + w - 1 do
      local outside = ((c - x + 4) // 8 + branch) % 2 == 0
      local upper = (r - y - 3) % 2 == 0
      local color = upper and (outside and WOOD[1] or WOOD[2]) or (outside and WOOD[3] or WOOD[4])
      px(base, c, r, color)
    end
  end
  local post = 0
  for c = x + 1, x + w - 2, 8 do
    local top = y + hash(post, 2, seed) % 2
    rect(base, c, top, 2, y + h - top, WOOD[3])
    rect(base, c + 1, top, 1, y + h - top, WOOD[4])
    post = post + 1
  end
end
wattle(133, 64, 26, 13, 51)
wattle(5, 143, 72, 13, 52)
local BARREL = {
  ".KKKKKK.",
  "KddddddK",
  "KLBBBBdK",
  "KIIIIIIK",
  "KLBBBBdK",
  "KLBBBBdK",
  "KIIIIIIK",
  "KLBBBBdK",
  ".KKKKKK.",
}
local barrel_legend = { K = K, d = WOOD[4], L = WOOD[1], B = WOOD[2], I = IRON }
rows(base, 52, 52, BARREL, barrel_legend)
rows(base, 79, 145, BARREL, barrel_legend)
rows(base, 132, 47, {
  "....KKKKKK....",
  "..KKYYYyyyKK..",
  ".KYYYyYYYyycK.",
  "KYYyYYYYyyycdK",
  "KyYYYyYYyycddK",
  ".KKKKKKKKKKKK.",
}, { K = K, Y = THATCH[1], y = THATCH[2], c = THATCH[3], d = THATCH[4] })
outline(base)
layers.base = base

-- Escombros e poeira ---------------------------------------------------------------

local sheet = new_image(SHEET_W, SHEET_H)
local regions = {}
local slot_x, slot_y, row_h = 164, 0, 0

local function place(w, h)
  if slot_x + w > SHEET_W then
    slot_x, slot_y, row_h = 164, slot_y + row_h + 2, 0
  end
  local x, y = slot_x, slot_y
  slot_x = slot_x + w + 2
  row_h = math.max(row_h, h)
  return x, y
end

local function region(name, x, y, w, h, at_x, at_y, frames)
  regions[name] = { x = x, y = y, w = w, h = h, at_x = at_x, at_y = at_y, frames = frames or 1 }
end

-- Monte baixo de pedaços quebrados com frestas escuras: pedra embaixo, telha e parede em cima,
-- e uma viga partida apontando para fora.
local function rubble(name, box, roof)
  local bx, by, bw, bh = table.unpack(box)
  local w = roof and bw - 8 or bw - 4
  local h = roof and 16 or 10
  local x0, y0 = place(w, h)
  local stone = STONE
  local wall = { PLASTER[1], PLASTER[3], BEAM[1] }
  local center = (w - 1) / 2
  local piece = new_image(w, h)
  local function top(qx)
    local d = math.abs(qx - center) / (w / 2)
    return math.floor(h - 1 - (h - 2) * math.sqrt(math.max(0, 1 - d * d)) ^ 0.8)
  end
  local function chunk(cx, cy, cw, ch, ramp)
    for py = cy, cy + ch - 1 do
      for qx = cx, cx + cw - 1 do
        local corner = (qx == cx or qx == cx + cw - 1) and (py == cy or py == cy + ch - 1)
        local lx, ly = qx - cx, py - cy
        if qx >= 0 and qx < w and py >= top(qx) and py < h and not corner then
          local color
          if lx == cw - 1 or ly == ch - 1 then
            color = K
          elseif ly == 0 then
            color = ramp[1]
          elseif lx == cw - 2 or ly == ch - 2 then
            color = ramp[3]
          else
            color = ramp[2]
          end
          px(piece, qx, py, color)
        end
      end
    end
  end
  local py, row = h - 4, 0
  while py > -4 do
    local qx, col = -((row * 3) % 5), 0
    while qx < w do
      local roll = hash(col, row, #name)
      local cw = 4 + roll % 4
      local ch = 3 + (roll // 7) % 2
      local ramp
      if roof == nil then
        ramp = roll % 5 == 0 and wall or stone
      elseif py > h - 6 then
        ramp = roll % 3 == 0 and wall or stone
      else
        ramp = roll % 5 < 3 and roof or wall
      end
      chunk(qx, py - (roll // 11) % 2, cw, ch, ramp)
      qx, col = qx + cw - 1, col + 1
    end
    py, row = py - 3, row + 1
  end
  if roof then
    local beam_x = math.floor(w * 0.62)
    for i = 0, 6 do
      px(piece, beam_x - i, top(beam_x) - 3 + i, WOOD[2])
      px(piece, beam_x - i + 1, top(beam_x) - 3 + i, WOOD[3])
    end
  else
    for qx = 1, 5 do
      px(piece, qx, h - 2, WATER[2])
    end
  end
  local framed = new_image(w + 2, h + 2)
  framed:drawImage(piece, Point(1, 1))
  outline(framed)
  sheet:drawImage(framed, Point(x0 - 1, y0 - 1))
  region(name, x0 - 1, y0 - 1, w + 2, h + 2, bx + (bw - w) // 2 - 1, by + bh - h - 1)
end

sheet:drawImage(layers.base, Point(0, 0))
region("base", 0, 0, SIZE, SIZE, 0, 0)

-- Ordem em que caem: o poço primeiro, a casa amarela por último.
local ORDER = { "well", "red_house", "brown_house", "yellow_house" }
local ROOFS = { red_house = TILES, brown_house = SHINGLES, yellow_house = THATCH }
local boxes = {}
for _, name in ipairs(ORDER) do
  local bx, by, bw, bh = used(layers[name])
  boxes[name] = { bx, by, bw, bh }
  local x, y = place(bw, bh)
  sheet:drawImage(Image(layers[name], Rectangle(bx, by, bw, bh)), Point(x, y))
  region(name, x, y, bw, bh, bx, by)
end
for _, name in ipairs(ORDER) do
  rubble(name .. "_rubble", boxes[name], ROOFS[name])
end

-- Nuvem que cresce, se abre em bolinhas e some: uma fileira de quadros do mesmo tamanho.
local DUST = {
  { { 14, 15, 4 }, { 9, 16, 3 }, { 19, 16, 3 } },
  { { 14, 13, 6 }, { 7, 15, 4 }, { 21, 15, 4 } },
  { { 14, 11, 7 }, { 6, 13, 5 }, { 22, 13, 5 }, { 14, 4, 3 } },
  { { 9, 8, 4 }, { 19, 8, 4 }, { 5, 13, 3 }, { 23, 13, 3 }, { 14, 3, 2 } },
  { { 7, 5, 2 }, { 21, 5, 2 }, { 3, 11, 1 }, { 25, 11, 1 }, { 14, 1, 1 } },
}
local dust_x, dust_y = place(DUST_W * DUST_FRAMES, DUST_H)
for frame, circles in ipairs(DUST) do
  local fx = dust_x + (frame - 1) * DUST_W
  for _, c in ipairs(circles) do
    local cx, cy, r = table.unpack(c)
    for py = cy - r, cy + r do
      for qx = cx - r, cx + r do
        local dx, dy = qx - cx, py - cy
        if dx * dx + dy * dy <= r * r + r and qx >= 0 and py >= 0 and qx < DUST_W and py < DUST_H then
          px(sheet, fx + qx, dust_y + py, (dy > r / 3 or dx > r / 2) and PLASTER[3] or PLASTER[1])
        end
      end
    end
  end
end
region("dust", dust_x, dust_y, DUST_W, DUST_H, 0, 0, DUST_FRAMES)

-- Saída ------------------------------------------------------------------------

local spr = Sprite(SIZE, SIZE, ColorMode.RGB)
spr.layers[1].name = "base"
spr:newCel(spr.layers[1], 1, layers.base, Point(0, 0))
for _, name in ipairs(ORDER) do
  local layer = spr:newLayer()
  layer.name = name
  spr:newCel(layer, 1, layers[name], Point(0, 0))
end
spr:saveAs(ROOT .. "/art/village.aseprite")
spr:saveCopyAs(ROOT .. "/assets/sprites/village.png")
spr:close()

local out = Sprite(SHEET_W, SHEET_H, ColorMode.RGB)
out:newCel(out.layers[1], 1, sheet, Point(0, 0))
out:saveCopyAs(ROOT .. "/assets/sprites/village_parts.png")
out:close()

local names = {}
for name in pairs(regions) do names[#names + 1] = name end
table.sort(names)
local parts = {}
for _, name in ipairs(names) do
  local r = regions[name]
  parts[#parts + 1] = string.format('\t"%s": {"x": %d, "y": %d, "w": %d, "h": %d, "at": [%d, %d], "frames": %d}',
    name, r.x, r.y, r.w, r.h, r.at_x, r.at_y, r.frames)
end
local file = io.open(ROOT .. "/assets/sprites/village_parts.json", "w")
file:write("{\n" .. table.concat(parts, ",\n") .. "\n}\n")
file:close()
print("altura usada", slot_y + row_h)
