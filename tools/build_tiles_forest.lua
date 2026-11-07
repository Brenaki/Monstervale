-- Gera os tiles da floresta a partir dos tiles dos campos: outras cores e novos detalhes.
-- Uso: rode com o MCP do Aseprite, definindo PROJECT_ROOT. Depois rode tools/build_assets.gd.

local ROOT = PROJECT_ROOT or "."
local pc = app.pixelColor
local TILE = 32

local function rgb(hex)
  return pc.rgba(tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16), 255)
end

local function clamp(v)
  return math.max(0, math.min(255, math.floor(v + 0.5)))
end

-- Verde vira verde frio e profundo, terra vira terra escura de folhas.
local function forest(c)
  local r, g, b, a = pc.rgbaR(c), pc.rgbaG(c), pc.rgbaB(c), pc.rgbaA(c)
  if a == 0 or r + g + b < 110 then return c end
  if g > r and g > b then
    return pc.rgba(clamp(r * 0.5), clamp(g * 0.72), clamp(b * 0.78 + 8), a)
  elseif r > 180 and r > g * 2 and r > b * 2 then
    return rgb("e8913a")
  elseif r > g and g > b then
    return pc.rgba(clamp(r * 0.68), clamp(g * 0.62), clamp(b * 0.6), a)
  end
  return pc.rgba(clamp(r * 0.8), clamp(g * 0.88), clamp(b * 0.82), a)
end

local spr = app.open(ROOT .. "/art/tiles.aseprite")
local out = Image(spr.spec)
out:drawSprite(spr, 1)
spr:close()
for y = 0, out.height - 1 do
  for x = 0, out.width - 1 do
    out:drawPixel(x, y, forest(out:getPixel(x, y)))
  end
end

local function fill(x, y, w, h, hex)
  for py = y, y + h - 1 do
    for px = x, x + w - 1 do
      out:drawPixel(px, py, rgb(hex))
    end
  end
end

-- Folhas caídas sobre a grama.
local function leaves(x, y)
  fill(x, y, 2, 1, "b5812f"); fill(x + 5, y + 3, 2, 1, "8f5c35"); fill(x + 2, y + 6, 2, 1, "c9622f")
end
leaves(TILE * 1 + 10, 8)
leaves(TILE * 3 + 6, 16)

-- O arbusto dá lugar a um pinheiro, com a sombra na mesma posição.
local OUTLINE = "1b1626"
local pineX = TILE * 4
for py = 0, 26 do
  for px = pineX, pineX + TILE - 1 do
    out:drawPixel(px, py, pc.rgba(0, 0, 0, 0))
  end
end
local function tier(top, half, height)
  for row = 0, height - 1 do
    local w = 1 + math.floor(half * (row + 1) / height)
    fill(pineX + 16 - w - 1, top + row, w * 2 + 2, 1, OUTLINE)
  end
  fill(pineX + 16 - half - 1, top + height, half * 2 + 2, 1, OUTLINE)
  for row = 0, height - 1 do
    local w = math.floor(half * (row + 1) / height)
    fill(pineX + 16 - w, top + row, w, 1, "4f8f5a")
    fill(pineX + 16, top + row, w, 1, "2f6650")
    if row > 0 then fill(pineX + 16 - w, top + row, 1, 1, "7fbb6e") end
  end
end
fill(pineX + 13, 21, 6, 6, OUTLINE)
fill(pineX + 14, 21, 4, 5, "6b4228")
fill(pineX + 14, 21, 1, 5, "8a5a3a")
tier(1, 6, 7)
tier(6, 9, 8)
tier(12, 12, 9)

local forestSprite = Sprite(ImageSpec{ width = out.width, height = out.height, colorMode = ColorMode.RGB })
forestSprite.cels[1].image = out
forestSprite:saveAs(ROOT .. "/art/tiles_forest.aseprite")
out:saveAs(ROOT .. "/assets/tiles/tiles_forest.png")
forestSprite:close()
print("tiles_forest", out.width, out.height)
