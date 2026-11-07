-- Gera os tiles dos arredores do vilarejo a partir dos tiles dos campos: grama de fim de verão e coisas da roça.
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

-- Grama puxada para o amarelo e terra mais quente, de estrada de roça.
local function outskirts(c)
  local r, g, b, a = pc.rgbaR(c), pc.rgbaG(c), pc.rgbaB(c), pc.rgbaA(c)
  if a == 0 or r + g + b < 110 then return c end
  if g > r and g > b then
    return pc.rgba(clamp(r * 0.95 + 26), clamp(g * 0.97 + 4), clamp(b * 0.62), a)
  elseif r > g and g > b then
    return pc.rgba(clamp(r * 1.02 + 8), clamp(g * 0.96 + 2), clamp(b * 0.82), a)
  end
  return c
end

local spr = app.open(ROOT .. "/art/tiles.aseprite")
local out = Image(spr.spec)
out:drawSprite(spr, 1)
spr:close()
for y = 0, out.height - 1 do
  for x = 0, out.width - 1 do
    out:drawPixel(x, y, outskirts(out:getPixel(x, y)))
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

local HAY = { K = OUTLINE, H = "f6e4a0", L = "ecc96a", M = "d4a94a", D = "a87d32", E = "7a5a26", T = "8e2f36", G = "6f7a34" }

-- Fardo de feno amarrado, no lugar do arbusto.
clear(4)
rows(4, 9, {
  "......KKKKKKKKKKKKKKKKKKKK......",
  ".....KHHHHHHHHHHHHHHHHHHHLK.....",
  "....KHHLHHHHHHHHHHHHHHHLLLDK....",
  "....KLLLLLLLLLLLLLLLLLLLLDDK....",
  "....KLMMMTMMMMMMMMMMMTMMMMDK....",
  "....KLMDMTMMMMDMMMMMMTMMDMDK....",
  "....KLMMMTMMMMMMMMDMMTMMMMDK....",
  "....KLMMMTMDMMMMMMMMMTMMMMDK....",
  "....KLMMMTMMMMMMDMMMMTMDMMDK....",
  "....KLMDMTMMMMMMMMMMMTMMMDDK....",
  "....KMMMMTMMMDMMMMMMMTMMMDDK....",
  "....KMMMMTMMMMMMMMDMMTMMDDDK....",
  "....KDMMMTMMMMMMMMMMMTMMDDEK....",
  "....KDDDDTDDDDDDDDDDDTDDDEEK....",
  "...KKEEEEEEEEEEEEEEEEEEEEEEKK...",
  "...KGGKKKKKKKKKKKKKKKKKKKKKGGK..",
}, HAY)

-- Feixe de trigo amarrado, no lugar do arbusto com frutinhas.
clear(6)
rows(6, 5, {
  "...........K..K..K..K...........",
  "..........KHKKHKKHKKHK..........",
  ".........KHLHKHLKHLKHLHK........",
  "........KHLMKHLMHLMKHLMMK.......",
  ".......KLLMKLLMKLLMKLLMDK.......",
  ".......KLMKKLMKKLMKKLMDDK.......",
  "........KKLMMKLMMKLMMDDK........",
  ".........KLMLMLMLMLMDDK.........",
  "..........KLMLMLMLMDDK..........",
  "...........KLMLMLMLDK...........",
  "...........KLMLMLMDDK...........",
  "...........KTTTTTTTTK...........",
  "...........KTTTTTTTTK...........",
  "...........KLMLMLMDDK...........",
  "..........KLMLMLMLMDDK..........",
  ".........KLMLMLMLMLMDDK.........",
  "........KLMLMLMLMLMLMDDK........",
  "........KLMLMLMLMLMLMDDK........",
  ".......KLMLMLMLMLMLMLMDDK.......",
  ".......KDMDMDMDMDMDMDMDEK.......",
  "......KKEEEEEEEEEEEEEEEEKK......",
  "......KGGKKKKKKKKKKKKKKGGK......",
}, HAY)

-- Espantalho de chapéu de palha, no lugar da pedra.
clear(7)
rows(7, 1, {
  "..............KKKK..............",
  ".............KHLLMK.............",
  "...........KKHLLMMDKK...........",
  "..........KHHLLLLMMMDK..........",
  "..........KKKKKKKKKKKK..........",
  "............KSSSSssK............",
  "............KSKSSKsK............",
  "............KSSSSssK............",
  "............KSKKKKsK............",
  "...KKKKKKKKKKKSSssKKKKKKKKKKK...",
  "..KHKBBBBBBBBBBBBBBBBBBBBBbKHK..",
  "...KKBBBBBBBBBBRBBBBBBBBBbbKK...",
  ".....KKKKKKBBBBBBBBBBbKKKKK.....",
  "...........KBBBBRBBBbK..........",
  "...........KBBBBBBBbbK..........",
  "...........KBBBBRBBbbK..........",
  "...........KDDDDDDDDDK..........",
  "...........KHK.KWK.KHK..........",
  "...............KWK..............",
  "...............KWK..............",
  "...............KWK..............",
  "...............KWK..............",
  "...............KwK..............",
  "...............KwK..............",
  "..............KKwKK.............",
  ".............KGGGGGK............",
  "..............KKKKK.............",
}, { K = OUTLINE, H = "f6e4a0", L = "ecc96a", M = "d4a94a", D = "a87d32", S = "e8c9a0", s = "c79f72",
     B = "5a7fb0", b = "3d5a85", R = "8e2f36", W = "8a5a3a", w = "6b4228", G = "6f7a34" })

local tilesSprite = Sprite(ImageSpec{ width = out.width, height = out.height, colorMode = ColorMode.RGB })
tilesSprite.cels[1].image = out
tilesSprite:saveAs(ROOT .. "/art/tiles_outskirts.aseprite")
out:saveAs(ROOT .. "/assets/tiles/tiles_outskirts.png")
tilesSprite:close()
print("tiles_outskirts", out.width, out.height)
