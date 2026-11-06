-- Gera os tiles do pântano a partir dos tiles dos campos: outras cores e novos detalhes.
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

-- Verde vira oliva escuro, terra vira lama, vermelho vira roxo de cogumelo.
local function swamp(c)
  local r, g, b, a = pc.rgbaR(c), pc.rgbaG(c), pc.rgbaB(c), pc.rgbaA(c)
  if a == 0 or r + g + b < 110 then return c end
  if g > r and g > b then
    return pc.rgba(clamp(r * 0.72 + 12), clamp(g * 0.74), clamp(b * 0.8 + 26), a)
  elseif r > 180 and r > g * 2 and r > b * 2 then
    return rgb("b58fe0")
  elseif r > g and g > b then
    return pc.rgba(clamp(r * 0.62), clamp(g * 0.6), clamp(b * 0.62 + 14), a)
  end
  return pc.rgba(clamp(r * 0.85), clamp(g * 0.92), clamp(b * 0.88), a)
end

local spr = app.open(ROOT .. "/art/tiles.aseprite")
local out = Image(spr.spec)
out:drawSprite(spr, 1)
spr:close()
for y = 0, out.height - 1 do
  for x = 0, out.width - 1 do
    out:drawPixel(x, y, swamp(out:getPixel(x, y)))
  end
end

local function fill(x, y, w, h, hex)
  for py = y, y + h - 1 do
    for px = x, x + w - 1 do
      out:drawPixel(px, py, rgb(hex))
    end
  end
end

-- Poça rasa com brilho.
local function puddle(x, y)
  fill(x + 1, y, 8, 1, "26505a"); fill(x, y + 1, 10, 3, "2f6470"); fill(x + 1, y + 4, 8, 1, "26505a")
  fill(x + 2, y + 1, 3, 1, "6fb0b0")
end

-- Vitória-régia sobre a poça.
local function lily(x, y)
  fill(x, y, 4, 2, "6fa84e"); fill(x + 1, y, 1, 1, "2f6470")
end

puddle(TILE * 1 + 12, 18)
puddle(TILE * 3 + 5, 7)
lily(TILE * 3 + 9, 9)

-- O arbusto dá lugar a uma touceira de taboas, com a sombra na mesma posição.
local reedX = TILE * 4
for py = 0, 26 do
  for px = reedX, reedX + TILE - 1 do
    out:drawPixel(px, py, pc.rgba(0, 0, 0, 0))
  end
end
local OUTLINE = "1b1626"
local function reed(x, top)
  fill(reedX + x - 1, top - 1, 5, 7, OUTLINE)
  fill(reedX + x, top, 3, 5, "7a4a2c")
  fill(reedX + x, top, 1, 5, "9c6a3f")
  fill(reedX + x, top + 6, 3, 24 - top - 6, OUTLINE)
  fill(reedX + x + 1, top + 5, 1, 25 - top - 5, "8fae5a")
end
for _, r in ipairs({ {6, 4}, {14, 1}, {21, 6}, {10, 9}, {18, 10} }) do
  reed(r[1], r[2])
end
for _, blade in ipairs({ {4, 18}, {12, 20}, {24, 19} }) do
  fill(reedX + blade[1] - 1, blade[2] - 1, 3, 26 - blade[2], OUTLINE)
  fill(reedX + blade[1], blade[2], 1, 25 - blade[2], "6f8f4a")
end

local swampSprite = Sprite(ImageSpec{ width = out.width, height = out.height, colorMode = ColorMode.RGB })
swampSprite.cels[1].image = out
swampSprite:saveAs(ROOT .. "/art/tiles_swamp.aseprite")
out:saveAs(ROOT .. "/assets/tiles/tiles_swamp.png")
swampSprite:close()
print("tiles_swamp", out.width, out.height)
