-- Gera os personagens em art/ e as folhas em assets/sprites/.
-- Uso: aseprite -b --script tools/build_sprites.lua, a partir da raiz do projeto.
-- Depois rode tools/build_assets.gd para gerar os SpriteFrames.

local ROOT = PROJECT_ROOT or "."
local pc = app.pixelColor

local function rgb(hex)
  return pc.rgba(tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16), 255)
end

local W, H = 56, 40
local X0, Y0 = 18, 16
local K = rgb("1b1626")
local SMEAR = rgb("f4f7f8")
local SPEC = ImageSpec{ width = W, height = H, colorMode = ColorMode.RGB }

local function legendOf(t)
  local out = {}
  for k, v in pairs(t) do out[k] = rgb(v) end
  return out
end

local function merged(base, extra)
  local out = {}
  for k, v in pairs(base) do out[k] = v end
  for k, v in pairs(extra or {}) do out[k] = v end
  return out
end

local function put(img, x, y, c)
  if x >= 0 and y >= 0 and x < W and y < H then img:drawPixel(x, y, c) end
end

-- x e y são relativos à origem do corpo (X0, Y0).
local function stamp(img, rows, legend, x, y)
  for r, row in ipairs(rows) do
    for i = 1, #row do
      local c = legend[row:sub(i, i)]
      if c then put(img, X0 + x + i - 1, Y0 + y + r - 1, c) end
    end
  end
end

local function line(img, x0, y0, x1, y1, c, c2)
  local dx, dy = math.abs(x1 - x0), -math.abs(y1 - y0)
  local sx, sy = x0 < x1 and 1 or -1, y0 < y1 and 1 or -1
  local err = dx + dy
  while true do
    put(img, X0 + x0, Y0 + y0, c)
    if c2 then put(img, X0 + x0, Y0 + y0 + 1, c2) end
    if x0 == x1 and y0 == y1 then break end
    local e2 = 2 * err
    if e2 >= dy then err = err + dy; x0 = x0 + sx end
    if e2 <= dx then err = err + dx; y0 = y0 + sy end
  end
end

local function outlined(img)
  local copy = img:clone()
  for y = 0, H - 1 do
    for x = 0, W - 1 do
      if pc.rgbaA(copy:getPixel(x, y)) == 0 then
        local near = (x > 0 and pc.rgbaA(copy:getPixel(x - 1, y)) > 0)
          or (x < W - 1 and pc.rgbaA(copy:getPixel(x + 1, y)) > 0)
          or (y > 0 and pc.rgbaA(copy:getPixel(x, y - 1)) > 0)
          or (y < H - 1 and pc.rgbaA(copy:getPixel(x, y + 1)) > 0)
        if near then img:drawPixel(x, y, K) end
      end
    end
  end
end

-- Deita o corpo no chão, de costas, sem cortar.
local function lying(img)
  local out = Image(SPEC)
  local x0, y0, x1, y1 = W, H, -1, -1
  for y = 0, H - 1 do
    for x = 0, W - 1 do
      if pc.rgbaA(img:getPixel(x, y)) > 0 then
        x0, y0, x1, y1 = math.min(x0, x), math.min(y0, y), math.max(x1, x), math.max(y1, y)
      end
    end
  end
  local width = y1 - y0 + 1
  local left = 28 - width // 2
  local bottom = 36
  for y = y0, y1 do
    for x = x0, x1 do
      local v = img:getPixel(x, y)
      if pc.rgbaA(v) > 0 then
        out:drawPixel(left + (y - y0), bottom - (x - x0), v)
      end
    end
  end
  return out
end

local function frame(ms, draw, post, final)
  local img = Image(SPEC)
  draw(img)
  outlined(img)
  if post then post(img) end
  if final then img = final(img) end
  return { image = img, ms = ms }
end

local function build(name, frames, tags)
  local spr = Sprite(SPEC)
  local layer = spr.layers[1]
  for i = 2, #frames do spr:newEmptyFrame() end
  for i, item in ipairs(frames) do
    spr:newCel(layer, i, item.image, Point(0, 0))
    spr.frames[i].duration = item.ms / 1000
  end
  for _, tag in ipairs(tags) do
    local t = spr:newTag(tag[2], tag[3])
    t.name = tag[1]
  end
  spr:saveAs(ROOT .. "/art/" .. name .. ".aseprite")
  app.command.ExportSpriteSheet{
    ui = false,
    askOverwrite = false,
    type = SpriteSheetType.HORIZONTAL,
    textureFilename = ROOT .. "/assets/sprites/" .. name .. ".png",
    dataFilename = ROOT .. "/assets/sprites/" .. name .. ".json",
    dataFormat = SpriteSheetDataFormat.JSON_ARRAY,
    filenameFormat = "{frame}",
    listTags = true,
  }
  spr:close()
  print(name, #frames)
end

---------------------------------------------------------------- GOBLINS

local GOBLIN_BASE = {
  L = "b6dc58", M = "80bd45", D = "4f8a3a", E = "35632f", Y = "f6e05e", K = "1b1626", S = "f4f1de",
  T = "8a5a3a", U = "5e3a2a", B = "dfe6ea", b = "9aa7b3", W = "8f5c35", R = "d9534a", r = "a2303a",
  I = "dfe6ea", i = "9aa7b3", j = "5d6a7a", P = "b47a42", p = "8f5c35",
}

local GOBLIN_HEAD = {
  "......LLLLMMMM....", "....LLLLLLMMMMMM..", "...LLLLLLMMMMMMMM.", "...LLLLMMMMMMMMMMD",
  "D..LLLMMMMMMMMMMMD", "DD.LLMMMMMMYKMMYKD", "DMDLMMMMMMMYKMMYKD", ".DMMMMMMMMMMMMMMMD",
  "..DMMMMMMMMMSMSMMD", "...DMMMMMMMMMMMMD.", "....DDMMMMMMMMDD..", "......DDDDDDDD....",
}
local GOBLIN_HURT = {
  "......LLLLMMMM....", "....LLLLLLMMMMMM..", "...LLLLLLMMMMMMMM.", "...LLLLMMMMMMMMMMD",
  "D..LLLMMMMMMMMMMMD", "DD.LLMMMMMMKMMMKMD", "DMDLMMMMMMMMKMKMMD", ".DMMMMMMMMMKMMMKMD",
  "..DMMMMMMMMSSSSMMD", "...DMMMMMMMMMMMMD.", "....DDMMMMMMMMDD..", "......DDDDDDDD....",
}
local GOBLIN_TORSO = { ".TTTTTT.", "TTTTTTUU", "TTTTTTUU", "TTTTTTUU", "UUUUUUUU" }
local GOBLIN_HAND = { ".MM.", "LMMD", "MMMD", ".DD." }
local GOBLIN_STAND = { "..MMD.MMD..", "..MMD.MMD..", ".DDDD.DDDD." }
local GOBLIN_STEP_A = { "..MMD.DDD..", ".MMD...DDD.", "DDDD...EEEE" }
local GOBLIN_STEP_B = { "..DDD.MMD..", ".DDD...MMD.", "EEEE...DDDD" }
local GOBLIN_PASS_A = { "...MMMMD...", "...MMMMD...", "...MMMMD...", "...DDDDDD.." }
local GOBLIN_PASS_B = { "...DDMMD...", "...DDMMD...", "...DDMMD...", "...DDDDDD.." }
local GOBLIN_HAND_FRONT = { ".MMM.", "MMMMM", "DMMMD", ".WWW." }

local GOBLIN_SWORD = {
  up = { "...B..", "..BBb.", "..BBb.", "..BBb.", "..BBb.", "..BBb.", "..BBb.", "..BBb.", "..BBb.",
    "WWWWWW", "..MMM.", ".MMMMM", ".DMMMD", "..WWW." },
  upY = 1,
  forward = { ".MMM.W.........", "MMMMMWBBBBBBBBB", "DMMMDWbbbbbbbb.", ".MMM.W........." },
  lowEnd = { 30, 17 },
  lowColors = { "dfe6ea", "9aa7b3" },
}
-- Adaga curta: a variante veloz carrega uma lâmina em cada mão.
local GOBLIN_DAGGER = {
  up = { "...B..", "..BBb.", "..BBb.", "..BBb.", "WWWWWW", "..MMM.", ".MMMMM", ".DMMMD", "..WWW." },
  upY = 6,
  forward = { ".MMM.W....", "MMMMMWBBBB", "DMMMDWbbb.", ".MMM.W...." },
  lowEnd = { 27, 15 },
  lowColors = { "dfe6ea", "9aa7b3" },
}
-- Maça pesada: a variante blindada troca a lâmina por uma arma de impacto.
local GOBLIN_MACE = {
  up = { "..jjj.", ".jIiij", ".jIiij", "..jjj.", "...P..", "...P..", "...P..", "...P..", "...P..",
    "...P..", "..MMM.", ".MMMMM", ".DMMMD", "...p.." },
  upY = 1,
  forward = { ".MMM.......jjj", "MMMMMPPPPPPjIij", "DMMMDppppppjiij", ".MMM.......jjj" },
  lowEnd = { 30, 17 },
  lowColors = { "5d6a7a", "3d4757" },
}

local SMALL_SHIELD = { ".PPPPP.", "PpppppP", "PpjjjpP", "PpjjjpP", "PpppppP", ".PpppP.", "..PPP.." }
local BANDANA = { "RRRRRRRRRRRRRRR" }
local BANDANA_TAIL = { "RR", ".Rr", "..r" }
local HELMET = { "......jjjjjj....", "....jIIiiiiijj..", "...jIIIiiiiiiij.", "..jjjjjjjjjjjjjj" }

local function goblin(name, palette, weapon, extras)
  local L = legendOf(merged(GOBLIN_BASE, palette))
  extras = extras or {}

  local function backHand(img, x, y)
    if extras.shield then
      stamp(img, SMALL_SHIELD, L, x - 2, y - 2)
    elseif extras.secondDagger then
      stamp(img, GOBLIN_HAND, L, x, y)
      stamp(img, { "B", "B", "b" }, L, x + 1, y - 3)
    else
      stamp(img, GOBLIN_HAND, L, x, y)
    end
  end
  local function headWear(img, dx, dy)
    if extras.bandana then
      stamp(img, BANDANA, L, 3 + dx, 3 + dy)
      stamp(img, BANDANA_TAIL, L, 0 + dx, 2 + dy)
    end
    if extras.helmet then
      stamp(img, HELMET, L, 2 + dx, -1 + dy)
    end
  end
  local function body(img, dx, dy, h)
    stamp(img, GOBLIN_TORSO, L, 6 + dx, 12 + dy)
    stamp(img, h or GOBLIN_HEAD, L, 0 + dx, 0 + dy)
    headWear(img, dx, dy)
  end
  local function walk(legs, legRow, dy, handX, weaponX)
    return function(img)
      backHand(img, 1 + handX, 13 + dy)
      stamp(img, legs, L, 5, legRow)
      body(img, 0, dy)
      stamp(img, weapon.up, L, 18 + weaponX, weapon.upY + dy)
    end
  end
  local low = weapon.lowEnd

  local frames = {
    frame(120, walk(GOBLIN_STEP_A, 17, 0, -1, 1)),
    frame(120, walk(GOBLIN_PASS_A, 16, -1, 0, 0)),
    frame(120, walk(GOBLIN_STEP_B, 17, 0, 1, -1)),
    frame(120, walk(GOBLIN_PASS_B, 16, -1, 0, 0)),
    -- preparação: arma atrás da cabeça, corpo inclinado para trás
    frame(180, function(img)
      stamp(img, weapon.up, L, 5, weapon.upY - 8)
      backHand(img, 0, 12)
      stamp(img, GOBLIN_STAND, L, 5, 17)
      body(img, -2, 0)
    end),
    -- golpe: corpo à frente, arma esticada e rastro
    frame(70, function(img)
      backHand(img, 3, 14)
      stamp(img, GOBLIN_STAND, L, 5, 17)
      body(img, 2, 1)
      stamp(img, weapon.forward, L, 18, 11)
    end, function(img)
      line(img, 24, 0, 30, 3, SMEAR); line(img, 30, 3, 33, 8, SMEAR); line(img, 25, 1, 29, 4, SMEAR)
    end),
    -- recuperação: arma baixa
    frame(110, function(img)
      backHand(img, 2, 13)
      stamp(img, GOBLIN_STAND, L, 5, 17)
      body(img, 1, 0)
      line(img, 23, 12, low[1], low[2], rgb(weapon.lowColors[1]), rgb(weapon.lowColors[2]))
      stamp(img, GOBLIN_HAND_FRONT, L, 18, 10)
    end),
    -- morte: recuo com olhos fechados e a arma solta
    frame(120, function(img)
      stamp(img, GOBLIN_HAND, L, -1, 8)
      stamp(img, GOBLIN_STAND, L, 5, 17)
      stamp(img, GOBLIN_TORSO, L, 5, 12)
      stamp(img, GOBLIN_HURT, L, -3, 2)
      headWear(img, -3, 2)
      stamp(img, GOBLIN_HAND, L, 18, 5)
    end),
    frame(320, function(img)
      stamp(img, GOBLIN_STAND, L, 5, 17)
      stamp(img, GOBLIN_TORSO, L, 6, 12)
      stamp(img, GOBLIN_HURT, L, 0, 0)
      headWear(img, 0, 0)
      stamp(img, GOBLIN_HAND, L, 1, 13)
      stamp(img, GOBLIN_HAND, L, 15, 13)
    end, nil, lying),
  }
  build(name, frames, { {"walk", 1, 4}, {"attack", 5, 7}, {"death", 8, 9} })
end

goblin("goblin", nil, GOBLIN_SWORD)
goblin("goblin_fast", { L = "ecdd72", M = "c9b84a", D = "8f8a35", E = "6f6a2a" }, GOBLIN_DAGGER,
  { bandana = true, secondDagger = true })
goblin("goblin_shield", { L = "8fc7a0", M = "5fa37c", D = "3a7558", E = "2a5a44" }, GOBLIN_MACE,
  { shield = true, helmet = true })

---------------------------------------------------------------- ARQUEIRO

local ARCHER_BASE = {
  G = "56b58a", g = "2f8f6b", n = "1f5f4e", S = "f2c391", A = "d2905f", K = "1b1626", H = "7a4a2c",
  t = "3f9f6f", T = "2a7555", U = "5e3a2a", W = "b47a42", w = "8f5c35", Y = "f6e05e", Q = "8a5a3a", q = "5e3a2a",
  F = "f4f1de",
}
local ARCHER_LEVELS = {
  {},
  { W = "8f5c35", w = "5e3a2a" },
  { W = "f6e05e", w = "e8913a", G = "7fd8a8", g = "2fa878", t = "4fb985", T = "2f8f6b" },
}
local ARCHER_HEAD = {
  "....GGGGgggg...", "..GGGGGGgggggg.", ".GGGGGgggggggg.", ".GGGgggSSSSSSSn", ".GGggHHSSSSSSSn",
  ".GGggHSSSKSSKSn", "gGgggHSSSKSSKSn", "ggggggSSSSSSSSn", ".gggggASSSSSSAn", ".nggggAAAAAAAn.", "..nngggggggnn..",
}
local ARCHER_HURT = {
  "....GGGGgggg...", "..GGGGGGgggggg.", ".GGGGGgggggggg.", ".GGGgggSSSSSSSn", ".GGggHHSSSSSSSn",
  ".GGggHSSKKSKKSn", "gGgggHSSSSSSSSn", "ggggggSSSSSSSSn", ".gggggASSSSSSAn", ".nggggAAAAAAAn.", "..nngggggggnn..",
}
local ARCHER_TORSO = { "tttttt..", ".tttttt.", "tttttTT.", "tttTTTT.", "UUUUUUU.", "tttttTT." }
local ARCHER_LEGS = { ".UUn.UUn.", ".UUn.UUn.", "nnnn.nnnn" }
local ARCHER_HAND = { ".SS.", "SSSA", "ASSA", ".AA." }
local ARCHER_BOW_HAND = { ".SSS.", "SSSSS", "ASSSA" }
local ARCHER_BOW = {
  ".WW....", "..WW...", "...WW..", "....WW.", "....WW.", ".....WW", ".....WW", ".....Ww", ".....Ww",
  ".....Ww", "....wWw", "....Ww.", "...Ww..", "..Ww...", ".Ww....", "Ww.....",
}
-- Aljava nas costas a partir do nível 2.
local QUIVER = { "F.F.", "F.F.", "QQQq", "QQQq", "QQQq", "QQQq", "QQQq", ".Qq." }
-- Faixa dourada no capuz no nível 3.
local HOOD_TRIM = { "...YYYYYYY", "..YY......", ".YY......." }

local function archer(name, level)
  local L = legendOf(merged(ARCHER_BASE, ARCHER_LEVELS[level]))
  local STRING = rgb("f4f1de")

  local function gear(img, dx)
    if level >= 2 then stamp(img, QUIVER, L, 0 + dx, 6) end
  end
  local function body(img, dx, dy, h)
    gear(img, dx)
    stamp(img, ARCHER_TORSO, L, 6 + dx, 11)
    stamp(img, h or ARCHER_HEAD, L, 2 + dx, 0 + dy)
    if level >= 3 then stamp(img, HOOD_TRIM, L, 2 + dx, 2 + dy) end
  end
  local function bowAt(img, bx)
    stamp(img, ARCHER_BOW, L, 20 + bx, 0)
    stamp(img, ARCHER_BOW_HAND, L, 19 + bx, 8)
  end
  local function straightString(bx)
    return function(img)
      line(img, 21 + bx, 1, 20 + bx, 7, STRING)
      line(img, 19 + bx, 11, 20 + bx, 14, STRING)
    end
  end
  local arrowShaft = (level >= 3) and rgb("f6e05e") or rgb("c9b08a")

  local frames = {
    frame(500, function(img)
      stamp(img, ARCHER_HAND, L, 1, 13); stamp(img, ARCHER_LEGS, L, 6, 17); body(img, 0, 0); bowAt(img, 0)
    end, straightString(0)),
    frame(500, function(img)
      stamp(img, ARCHER_HAND, L, 1, 14); stamp(img, ARCHER_LEGS, L, 6, 17); body(img, 0, 1); bowAt(img, 0)
    end, straightString(0)),
    -- puxa a corda: mão perto do rosto, flecha armada, corpo para trás
    frame(170, function(img)
      stamp(img, ARCHER_LEGS, L, 6, 17); body(img, -1, 0); bowAt(img, 1)
      stamp(img, ARCHER_HAND, L, 11, 7)
    end, function(img)
      line(img, 22, 1, 14, 8, STRING); line(img, 14, 9, 20, 15, STRING)
      line(img, 14, 9, 27, 9, arrowShaft); line(img, 28, 9, 30, 9, rgb("dfe6ea"))
    end),
    -- soltou: corda vibrando à frente, corpo para a frente
    frame(70, function(img)
      stamp(img, ARCHER_HAND, L, 6, 12); stamp(img, ARCHER_LEGS, L, 6, 17); body(img, 1, 0); bowAt(img, 2)
    end, function(img)
      line(img, 23, 1, 24, 7, STRING); line(img, 21, 11, 22, 15, STRING)
      line(img, 27, 7, 32, 7, SMEAR); line(img, 29, 10, 33, 10, SMEAR)
    end),
    -- recuperação
    frame(120, function(img)
      stamp(img, ARCHER_HAND, L, 3, 13); stamp(img, ARCHER_LEGS, L, 6, 17); body(img, 0, 0); bowAt(img, 1)
    end, straightString(1)),
    -- queda: ajoelha com os olhos fechados e o arco baixo
    frame(130, function(img)
      stamp(img, { "nnnn.nnnn" }, L, 6, 19)
      gear(img, 0)
      stamp(img, ARCHER_TORSO, L, 6, 13)
      stamp(img, ARCHER_HURT, L, 2, 3)
      stamp(img, ARCHER_HAND, L, 1, 15)
      stamp(img, ARCHER_BOW_HAND, L, 18, 15)
      line(img, 23, 18, 33, 18, rgb("b47a42"))
    end),
    frame(320, function(img)
      stamp(img, ARCHER_LEGS, L, 6, 17)
      gear(img, 0)
      stamp(img, ARCHER_TORSO, L, 6, 11)
      stamp(img, ARCHER_HURT, L, 2, 0)
      stamp(img, ARCHER_HAND, L, 1, 13)
    end, nil, lying),
  }
  build(name, frames, { {"idle", 1, 2}, {"attack", 3, 5}, {"fall", 6, 7} })
end

archer("archer", 1)
archer("archer_2", 2)
archer("archer_3", 3)

---------------------------------------------------------------- GUERREIRO

local WARRIOR_BASE = {
  I = "dfe6ea", i = "9aa7b3", j = "5d6a7a", k = "3d4757", S = "f2c391", A = "d2905f", K = "1b1626",
  B = "5aa9e6", b = "2f6bb0", X = "f4f7f8", x = "b6c2cc", W = "b47a42", w = "8f5c35",
  R = "d9534a", r = "a2303a", Y = "f6e05e", y = "e8913a",
}
local WARRIOR_LEVELS = {
  {},
  { B = "4a8fd0", b = "24568f" },
  { B = "3f7fc4", b = "1f4a80", W = "f6e05e" },
}
local WARRIOR_HEAD = {
  "...IIIIiiii...", ".IIIIIIiiiiii.", "IIIIIiiiiiiiij", "IIIiiiiiiiiiij", "IIjjjjjjjjjjjj", "IijSSSSSSSSSSj",
  "iijSSSSKSSKSSj", "iijSSSSKSSKSSj", "iijSSSSSSSSSAj", ".jjAAAAAAAAj..", "..jjjjjjjjj...",
}
local WARRIOR_HURT = {
  "...IIIIiiii...", ".IIIIIIiiiiii.", "IIIIIiiiiiiiij", "IIIiiiiiiiiiij", "IIjjjjjjjjjjjj", "IijSSSSSSSSSSj",
  "iijSSSKKSKKSSj", "iijSSSSSSSSSSj", "iijSSSSSSSSSAj", ".jjAAAAAAAAj..", "..jjjjjjjjj...",
}
local WARRIOR_TORSO = { "BBBBBB..", "BBBBBBbb", "BBBBBBbb", "BBBBBBbb", "jjjjjjjj", "BBBBBbb." }
local WARRIOR_LEGS = { "jjk.jjk", "jjk.jjk" }
local WARRIOR_FEET = { "kkkk.kkkk" }
local SHIELDS = {
  { rows = { ".WWWW.", "WwwwwW", "WwwwwW", "WwwwwW", "WwwwwW", ".WwwW.", "..WW.." }, x = 0, y = 11 },
  { rows = { ".iiii.", "iwwwwi", "iwjjwi", "iwjjwi", "iwwwwi", ".iwwi.", "..ii.." }, x = 0, y = 11 },
  -- Escudo maior do nível 3, o destaque da habilidade de segurar mais monstros.
  { rows = { ".YYYYYYYY.", "YwwwwwwwwY", "YwwYYYYwwY", "YwwYjjYwwY", "YwwYjjYwwY", "YwwYYYYwwY", "YwwwwwwwwY", ".YwwwwwwY.", "..YwwwwY..", "...YYYY..." }, x = -3, y = 9 },
}
local PLUMES = {
  nil,
  { rows = { ".RRR.", "RRRRr", "..Rr." }, x = 9, y = -3 },
  { rows = { ".YYYy", "YYYYy", "..RRr", "..Rr." }, x = 9, y = -4 },
}
local SWORD_UP = { "...XX..", "...XXx.", "...XXx.", "...XXx.", "...XXx.", "...XXx.", "...XXx.", "...XXx.", "...XXx.",
  "WWWWWWW", ".SSSSS.", ".ASSSA.", "..WWW.." }
local SWORD_FORWARD = { ".SSS.W..........", "SSSSSWXXXXXXXXXX", "ASSSAWxxxxxxxxx.", ".WWW.W.........." }
local WARRIOR_HAND = { ".SSS.", "SSSSS", "ASSSA" }

local function warrior(name, level)
  local L = legendOf(merged(WARRIOR_BASE, WARRIOR_LEVELS[level]))
  local shield = SHIELDS[level]
  local plume = PLUMES[level]

  local function stay(img, dx, dy, h)
    stamp(img, WARRIOR_LEGS, L, 7, 17); stamp(img, WARRIOR_FEET, L, 6, 19)
    stamp(img, WARRIOR_TORSO, L, 6 + dx, 11)
    stamp(img, h or WARRIOR_HEAD, L, 3 + dx, dy)
    if plume then stamp(img, plume.rows, L, plume.x + dx, plume.y + dy) end
    stamp(img, shield.rows, L, shield.x + dx, shield.y)
  end

  local frames = {
    frame(500, function(img) stay(img, 0, 0); stamp(img, SWORD_UP, L, 20, 0) end),
    frame(500, function(img) stay(img, 0, 1); stamp(img, SWORD_UP, L, 20, 1) end),
    -- preparação: espada atrás da cabeça
    frame(190, function(img)
      stamp(img, SWORD_UP, L, 6, -8)
      stay(img, -2, 0)
    end),
    -- golpe com rastro
    frame(70, function(img)
      stay(img, 2, 1)
      stamp(img, SWORD_FORWARD, L, 19, 10)
    end, function(img)
      line(img, 18, -3, 28, -1, SMEAR); line(img, 28, -1, 34, 7, SMEAR); line(img, 21, -1, 29, 1, SMEAR); line(img, 29, 1, 33, 6, SMEAR)
    end),
    -- recuperação: lâmina baixa
    frame(120, function(img)
      stay(img, 1, 0)
      line(img, 24, 12, 33, 17, rgb("f4f7f8"), rgb("b6c2cc"))
      line(img, 23, 10, 23, 15, rgb("b47a42"))
      stamp(img, WARRIOR_HAND, L, 18, 11)
    end),
    -- queda: ajoelha com os olhos fechados
    frame(130, function(img)
      stamp(img, WARRIOR_FEET, L, 6, 19)
      stamp(img, WARRIOR_TORSO, L, 6, 13)
      stamp(img, WARRIOR_HURT, L, 3, 3)
      if plume then stamp(img, plume.rows, L, plume.x, plume.y + 3) end
      stamp(img, shield.rows, L, shield.x, math.min(shield.y + 1, 19 - #shield.rows))
      stamp(img, WARRIOR_HAND, L, 18, 15)
      line(img, 23, 18, 33, 18, rgb("f4f7f8"))
    end),
    frame(320, function(img)
      stamp(img, WARRIOR_LEGS, L, 7, 17); stamp(img, WARRIOR_FEET, L, 6, 19)
      stamp(img, WARRIOR_TORSO, L, 6, 11)
      stamp(img, WARRIOR_HURT, L, 3, 0)
      if plume then stamp(img, plume.rows, L, plume.x, plume.y) end
      stamp(img, shield.rows, L, shield.x, shield.y)
    end, nil, lying),
  }
  build(name, frames, { {"idle", 1, 2}, {"attack", 3, 5}, {"fall", 6, 7} })
end

warrior("warrior", 1)
warrior("warrior_2", 2)
warrior("warrior_3", 3)

---------------------------------------------------------------- MAGO

local MAGE_BASE = {
  R = "6a56c8", r = "4a3a9c", n = "33286e", H = "7a4a2c", S = "f2c391", A = "d2905f", K = "1b1626",
  B = "e8e8f0", b = "b6c2cc", W = "b47a42", w = "8f5c35", Y = "f6e05e", y = "e8913a", f = "d9534a",
  O = "8fe0f0", o = "4fa0c8", T = "4a3a9c", k = "3d4757",
}
local MAGE_LEVELS = {
  {},
  { R = "4f6fd0", r = "34509c", n = "24386e", T = "f6e05e" },
  { R = "a2406f", r = "7a2a55", n = "54203e", T = "f6e05e", W = "f6e05e", w = "e8913a" },
}
local MAGE_HAT = {
  ".....RR........", "....RRRr.......", "...RRRRrr......", "...RRRRrrr.....", "..RRRRRrrrr....",
  "..RRRRRRrrrr...", ".TTTTTTTTTTTT..", "RRRRRRRRrrrrrnn",
}
local MAGE_FACE = {
  "..HSSSSSSSSSn..", "..HSSSKSSKSSn..", "..HSSSKSSKSSn..", "..HSSSSSSSSAn..",
  "..HBBBBBBBBBn..", "...BBBBBBBBb...", "....bBBBBb.....",
}
local MAGE_HURT = {
  "..HSSSSSSSSSn..", "..HSSKKSKKSSn..", "..HSSSSSSSSSn..", "..HSSSSSSSSAn..",
  "..HBBBBBBBBBn..", "...BBBBBBBBb...", "....bBBBBb.....",
}
local MAGE_ROBE = {
  ".RRRRRRr.", ".RRRRRRr.", "RRRRRRRrr", "TTTTTTTTT", "RRRRRRrrr", "RRRRRRrrrr", "RRRRRRRrrr", "RRRRRRRrrr",
}
local MAGE_FEET = { ".kkk..kkk." }
local MAGE_HAND = { ".SS.", "SSSA", "ASSA", ".AA." }
local STAFF_TOP = {
  { rows = { ".O.", "OOo", ".o." }, x = -1, y = -3 },
  { rows = { ".YOY.", "YOOoY", "OOOoo", "YOooY", ".YoY." }, x = -2, y = -5 },
  { rows = { "..Y..", ".YY..", ".YyY.", "YYyyY", "YyfyY", ".yfy.", ".YOY.", "YOOoY", "OOOoo", "YOooY", ".YoY." }, x = -2, y = -11 },
}

local function mage(name, level)
  local L = legendOf(merged(MAGE_BASE, MAGE_LEVELS[level]))
  local top = STAFF_TOP[level]

  local function head(img, dx, dy, face)
    stamp(img, MAGE_HAT, L, 2 + dx, -4 + dy)
    stamp(img, face or MAGE_FACE, L, 2 + dx, 4 + dy)
  end
  local function staff(img, x, dy)
    stamp(img, top.rows, L, x + top.x, dy + top.y + 3)
    line(img, x, dy + 3, x, 17, L.W)
    line(img, x + 1, dy + 3, x + 1, 17, L.w)
    stamp(img, MAGE_HAND, L, x - 1, 10 + dy)
  end
  local function stand(img, dx, dy)
    stamp(img, MAGE_FEET, L, 5, 19)
    stamp(img, MAGE_ROBE, L, 5 + dx, 11)
    head(img, dx, dy)
  end
  local arcs = rgb("8fe0f0")
  if level == 3 then arcs = rgb("f6e05e") end

  local frames = {
    frame(500, function(img)
      stamp(img, MAGE_HAND, L, 2, 13); stand(img, 0, 0); staff(img, 20, 0)
    end),
    frame(500, function(img)
      stamp(img, MAGE_HAND, L, 2, 14); stand(img, 0, 1); staff(img, 20, 1)
    end),
    -- concentra: cajado erguido atrás, corpo para trás
    frame(190, function(img)
      stamp(img, MAGE_HAND, L, 1, 12); stand(img, -2, 0); staff(img, 17, -3)
    end),
    -- lança: cajado à frente, com faíscas na ponta
    frame(80, function(img)
      stamp(img, MAGE_HAND, L, 4, 13); stand(img, 2, 1)
      line(img, 21, 16, 27, 5, L.W, L.w)
      stamp(img, top.rows, L, 27 + top.x, 5 + top.y)
      stamp(img, MAGE_HAND, L, 21, 9)
    end, function(img)
      line(img, 29, 0, 33, -3, arcs); line(img, 31, 4, 36, 4, arcs); line(img, 29, 8, 33, 11, arcs)
    end),
    -- recuperação
    frame(120, function(img)
      stamp(img, MAGE_HAND, L, 3, 13); stand(img, 1, 0); staff(img, 21, 0)
    end),
    -- queda: ajoelha com os olhos fechados e o cajado baixo
    frame(130, function(img)
      stamp(img, MAGE_ROBE, L, 5, 12)
      head(img, 0, 2, MAGE_HURT)
      stamp(img, MAGE_HAND, L, 1, 15)
      line(img, 20, 18, 33, 18, L.W)
    end),
    frame(320, function(img)
      stamp(img, MAGE_FEET, L, 5, 19)
      stamp(img, MAGE_ROBE, L, 5, 11)
      head(img, 0, 0, MAGE_HURT)
      stamp(img, MAGE_HAND, L, 1, 13)
    end, nil, lying),
  }
  build(name, frames, { {"idle", 1, 2}, {"attack", 3, 5}, {"fall", 6, 7} })
end

mage("mage", 1)
mage("mage_2", 2)
mage("mage_3", 3)

---------------------------------------------------------------- SLIMES

local SLIME = { L = "9ff0c8", M = "5fd4ae", D = "2f9f94", E = "1f6f74", S = "eafff4" }
local SLIME_CX, SLIME_BASE = 28, 35

-- Domo de base reta, com luz no alto à esquerda e sombra embaixo à direita.
local function slimeBody(img, w, h, eyes)
  for row = 0, h - 1 do
    local t = row / h
    local half = (w / 2) * math.sqrt(1 - t * t)
    if row == 0 then half = half - 1 end
    local y = SLIME_BASE - row
    for x = SLIME_CX - math.floor(half + 0.5), SLIME_CX + math.floor(half + 0.5) - 1 do
      local nx = (x + 0.5 - SLIME_CX) / (w / 2)
      local light = -nx * 0.55 + t * 0.9
      local hex = SLIME.M
      if row == 0 then hex = SLIME.E
      elseif light > 0.62 then hex = SLIME.L
      elseif light < -0.02 then hex = SLIME.D end
      img:drawPixel(x, y, rgb(hex))
    end
  end
  local shineW = math.max(1, w // 7)
  local shineX = SLIME_CX - w // 4
  local shineY = SLIME_BASE - math.floor(h * 0.74)
  for x = shineX, shineX + shineW do img:drawPixel(x, shineY, rgb(SLIME.S)) end
  if eyes then
    local eyeY = SLIME_BASE - math.floor(h * 0.52)
    for _, fraction in ipairs({ eyes.left, eyes.right }) do
      local ex = SLIME_CX + math.floor(w * fraction + 0.5)
      for dx = 0, eyes.w - 1 do
        for dy = 0, eyes.h - 1 do
          img:drawPixel(ex + dx, eyeY + dy, K)
        end
      end
      if eyes.w > 1 then img:drawPixel(ex, eyeY, rgb(SLIME.S)) end
    end
  end
end

local function droplets(img, list)
  for _, d in ipairs(list) do
    for x = 0, d[3] - 1 do
      for y = 0, d[3] - 1 do
        img:drawPixel(SLIME_CX + d[1] + x, SLIME_BASE - d[2] + y, rgb(SLIME.M))
      end
    end
  end
end

local function slime(name, sizes, eyes, spread)
  local function step(pair)
    return frame(130, function(img) slimeBody(img, pair[1], pair[2], eyes) end)
  end
  local frames = { step(sizes[1]), step(sizes[2]), step(sizes[3]), step(sizes[4]) }
  -- morte: achata e espirra gosma, depois vira poça
  frames[5] = frame(110, function(img)
    slimeBody(img, sizes[2][1] + spread // 2, math.max(3, sizes[2][2] // 2), nil)
    droplets(img, { { -spread, 6, 2 }, { spread - 2, 8, 2 }, { -spread // 2, 11, 1 }, { spread // 2, 12, 1 } })
  end)
  frames[6] = frame(300, function(img)
    slimeBody(img, sizes[2][1], 2, nil)
    droplets(img, { { -spread - 2, 1, 1 }, { spread + 1, 1, 1 } })
  end)
  build(name, frames, { {"walk", 1, 4}, {"death", 5, 6} })
end

slime("slime", { {26, 18}, {32, 12}, {20, 24}, {24, 19} }, { left = 0.04, right = 0.26, w = 3, h = 4 }, 16)
slime("slime_medium", { {18, 13}, {23, 8}, {14, 17}, {17, 14} }, { left = 0, right = 0.26, w = 2, h = 3 }, 11)
slime("slime_small", { {11, 8}, {14, 5}, {8, 11}, {10, 9} }, { left = 0, right = 0.26, w = 1, h = 2 }, 7)
