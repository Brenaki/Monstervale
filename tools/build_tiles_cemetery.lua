-- Gera os tiles do cemitério a partir dos tiles dos campos: outras cores e novos detalhes.
-- Uso: rode com o MCP do Aseprite, definindo PROJECT_ROOT. Depois rode tools/build_assets.gd.

local ROOT = PROJECT_ROOT or "."
local pc = app.pixelColor
local TILE = 32
local OUTLINE = "1b1626"

local function rgb(hex)
  return pc.rgba(tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16), 255)
end

local function clamp(v)
  return math.max(0, math.min(255, math.floor(v + 0.5)))
end

-- Grama apagada de fim de tarde e terra acinzentada.
local function cemetery(c)
  local r, g, b, a = pc.rgbaR(c), pc.rgbaG(c), pc.rgbaB(c), pc.rgbaA(c)
  if a == 0 or r + g + b < 110 then return c end
  if g > r and g > b then
    return pc.rgba(clamp(r * 0.62 + 18), clamp(g * 0.6 + 8), clamp(b * 0.7 + 26), a)
  elseif r > g and g > b then
    return pc.rgba(clamp(r * 0.62 + 6), clamp(g * 0.62 + 8), clamp(b * 0.7 + 16), a)
  end
  return pc.rgba(clamp(r * 0.78), clamp(g * 0.78), clamp(b * 0.86), a)
end

local spr = app.open(ROOT .. "/art/tiles.aseprite")
local out = Image(spr.spec)
out:drawSprite(spr, 1)
spr:close()
for y = 0, out.height - 1 do
  for x = 0, out.width - 1 do
    out:drawPixel(x, y, cemetery(out:getPixel(x, y)))
  end
end

local function fill(x, y, w, h, hex)
  for py = y, y + h - 1 do
    for px = x, x + w - 1 do
      out:drawPixel(px, py, rgb(hex))
    end
  end
end

local function clear(column)
  for py = 0, 26 do
    for px = TILE * column, TILE * column + TILE - 1 do
      out:drawPixel(px, py, pc.rgba(0, 0, 0, 0))
    end
  end
end

-- Linhas de texto com legenda: '.' é transparente.
local function rows(column, y, list, legend)
  for r, row in ipairs(list) do
    for i = 1, #row do
      local hex = legend[row:sub(i, i)]
      if hex then fill(TILE * column + i - 1, y + r - 1, 1, 1, hex) end
    end
  end
end

local STONE = { K = OUTLINE, L = "c7ccd6", M = "9aa3b2", D = "6b7385", E = "4a5165", G = "5f7a58" }

-- Lápide arredondada, no lugar do arbusto.
clear(4)
rows(4, 8, {
  "...........KKKKKKKKKK...........",
  ".........KKLLLLMMMMMDKK.........",
  "........KLLLLLMMMMMMMMDK........",
  ".......KLLLLLMMMMMMMMMMDK.......",
  ".......KLLLLMMMEEMMMMMMDK.......",
  ".......KLLLMMMMEEMMMMMMDK.......",
  ".......KLLMMEEEEEEEEMMMDK.......",
  ".......KLLMMEEEEEEEEMMMDK.......",
  ".......KLMMMMMMEEMMMMMMDK.......",
  ".......KLMMMMMMEEMMMMMMDK.......",
  ".......KLMMMMMMEEMMMMMMDK.......",
  ".......KLMMMMMMMMMMMMMDDK.......",
  ".......KMMMMMMMMMMMMMMDDK.......",
  ".......KMMMMMMMMMMMMMDDDK.......",
  ".......KMMMMMMMMMMMMDDDDK.......",
  ".......KDDDDDDDDDDDDDDDEK.......",
  "......KKEEEEEEEEEEEEEEEEKK......",
  "......KGGEEEEEEEEEEEEEEGGK......",
  ".......KKKKKKKKKKKKKKKKKK.......",
}, STONE)

-- Cruz de pedra, no lugar do arbusto com frutinhas.
clear(6)
rows(6, 5, {
  "..............KKKK..............",
  ".............KLLMDK.............",
  ".............KLMMDK.............",
  ".............KLMMDK.............",
  ".............KLMMDK.............",
  "........KKKKKKLMMDKKKKKK........",
  ".......KLLLLLLLMMMMMMMMDK.......",
  ".......KLMMMMMMMMMMMMMMDK.......",
  ".......KDDDDDDDMMDDDDDDEK.......",
  "........KKKKKKLMMDKKKKKK........",
  ".............KLMMDK.............",
  ".............KLMMDK.............",
  ".............KLMMDK.............",
  ".............KLMMDK.............",
  ".............KLMMDK.............",
  ".............KLMMDK.............",
  ".............KLMDDK.............",
  ".............KLMDDK.............",
  "...........KKKMMDDKKK...........",
  "..........KEEEEEEEEEEK..........",
  "..........KGEEEEEEEEGK..........",
  "...........KKKKKKKKKK...........",
}, STONE)

-- Árvore morta, no lugar da pedra.
clear(7)
rows(7, 7, {
  "......KK..................KK....",
  ".....KTTK................KTTK...",
  "......KTTK..........KK..KTTK....",
  ".......KTTK........KTTKKTTK.....",
  "...KK...KTTK......KTTKTTTK......",
  "..KTTK...KTTK....KTTTTTK........",
  "...KTTK...KTTK..KTTTTK..........",
  "....KTTKK.KTTTKKTTTK............",
  ".....KTTTKKTTTTTTTK.............",
  "......KKTTTTTTTTK...............",
  "........KTTTTSSK................",
  ".........KTTTSSK................",
  ".........KTTTSSK................",
  ".........KTTTSSK................",
  ".........KTTTSSK................",
  ".........KTTTTSSK...............",
  ".........KTTTTSSK...............",
  "........KTTTTTTSSK..............",
  ".......KTTKTTTKTTSK.............",
  "......KKKKKKKKKKKKKK............",
}, { K = OUTLINE, T = "6b5a4f", S = "453a36" })

local tilesSprite = Sprite(ImageSpec{ width = out.width, height = out.height, colorMode = ColorMode.RGB })
tilesSprite.cels[1].image = out
tilesSprite:saveAs(ROOT .. "/art/tiles_cemetery.aseprite")
out:saveAs(ROOT .. "/assets/tiles/tiles_cemetery.png")
tilesSprite:close()
print("tiles_cemetery", out.width, out.height)
