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
  local w, h = img.width, img.height
  for y = 0, h - 1 do
    for x = 0, w - 1 do
      if pc.rgbaA(copy:getPixel(x, y)) == 0 then
        local near = (x > 0 and pc.rgbaA(copy:getPixel(x - 1, y)) > 0)
          or (x < w - 1 and pc.rgbaA(copy:getPixel(x + 1, y)) > 0)
          or (y > 0 and pc.rgbaA(copy:getPixel(x, y - 1)) > 0)
          or (y < h - 1 and pc.rgbaA(copy:getPixel(x, y + 1)) > 0)
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

-- spec troca a tela padrão por uma maior, como a do chefe.
local function frame(ms, draw, post, final, spec)
  local img = Image(spec or SPEC)
  draw(img)
  outlined(img)
  if post then post(img) end
  if final then img = final(img) end
  return { image = img, ms = ms }
end

local function build(name, frames, tags, spec)
  local spr = Sprite(spec or SPEC)
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

local GOBLIN_PARTS = {
  base = GOBLIN_BASE, head = GOBLIN_HEAD, hurt = GOBLIN_HURT, torso = GOBLIN_TORSO, hand = GOBLIN_HAND,
  stand = GOBLIN_STAND, stepA = GOBLIN_STEP_A, stepB = GOBLIN_STEP_B, passA = GOBLIN_PASS_A, passB = GOBLIN_PASS_B,
  handFront = GOBLIN_HAND_FRONT, headX = 0,
}

-- Corpo de monstro cabeçudo de duas pernas: parts traz as peças, weapon a arma e extras os acessórios.
local function biped(name, parts, palette, weapon, extras)
  local L = legendOf(merged(parts.base, palette))
  extras = extras or {}

  local function backHand(img, x, y)
    if extras.shield then
      stamp(img, extras.shield, L, x - 2, y - 2)
    elseif extras.secondDagger then
      stamp(img, parts.hand, L, x, y)
      stamp(img, { "B", "B", "b" }, L, x + 1, y - 3)
    else
      stamp(img, parts.hand, L, x, y)
    end
  end
  local function headWear(img, dx, dy)
    if extras.bandana then
      stamp(img, BANDANA, L, 3 + dx, 3 + dy)
      stamp(img, BANDANA_TAIL, L, 0 + dx, 2 + dy)
    end
    if extras.helmet then
      stamp(img, extras.helmet, L, 2 + dx, -1 + dy)
    end
    if extras.crest then
      stamp(img, extras.crest, L, 6 + dx, -4 + dy)
    end
  end
  local function body(img, dx, dy, h)
    stamp(img, parts.torso, L, 6 + dx, 12 + dy)
    stamp(img, h or parts.head, L, parts.headX + dx, 0 + dy)
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
    frame(120, walk(parts.stepA, 17, 0, -1, 1)),
    frame(120, walk(parts.passA, 16, -1, 0, 0)),
    frame(120, walk(parts.stepB, 17, 0, 1, -1)),
    frame(120, walk(parts.passB, 16, -1, 0, 0)),
    -- preparação: arma atrás da cabeça, corpo inclinado para trás
    frame(180, function(img)
      stamp(img, weapon.up, L, 5, weapon.upY - 8)
      backHand(img, 0, 12)
      stamp(img, parts.stand, L, 5, 17)
      body(img, -2, 0)
    end),
    -- golpe: corpo à frente, arma esticada e rastro
    frame(70, function(img)
      backHand(img, 3, 14)
      stamp(img, parts.stand, L, 5, 17)
      body(img, 2, 1)
      stamp(img, weapon.forward, L, 18, 11)
    end, function(img)
      line(img, 24, 0, 30, 3, SMEAR); line(img, 30, 3, 33, 8, SMEAR); line(img, 25, 1, 29, 4, SMEAR)
    end),
    -- recuperação: arma baixa
    frame(110, function(img)
      backHand(img, 2, 13)
      stamp(img, parts.stand, L, 5, 17)
      body(img, 1, 0)
      line(img, 23, 12, low[1], low[2], rgb(weapon.lowColors[1]), rgb(weapon.lowColors[2]))
      stamp(img, parts.handFront, L, 18, 10)
    end),
  }
  if parts.death then
    frames[8] = frame(120, function(img) parts.death.falling(img, L, headWear) end)
    frames[9] = frame(320, function(img) parts.death.pile(img, L, headWear) end)
  else
    -- morte: recuo com olhos fechados e a arma solta
    frames[8] = frame(120, function(img)
      stamp(img, parts.hand, L, -1, 8)
      stamp(img, parts.stand, L, 5, 17)
      stamp(img, parts.torso, L, 5, 12)
      stamp(img, parts.hurt, L, -3 + parts.headX, 2)
      headWear(img, -3, 2)
      stamp(img, parts.hand, L, 18, 5)
    end)
    frames[9] = frame(320, function(img)
      stamp(img, parts.stand, L, 5, 17)
      stamp(img, parts.torso, L, 6, 12)
      stamp(img, parts.hurt, L, parts.headX, 0)
      headWear(img, 0, 0)
      stamp(img, parts.hand, L, 1, 13)
      stamp(img, parts.hand, L, 15, 13)
    end, nil, lying)
  end
  build(name, frames, { {"walk", 1, 4}, {"attack", 5, 7}, {"death", 8, 9} })
end

local function goblin(name, palette, weapon, extras)
  biped(name, GOBLIN_PARTS, palette, weapon, extras)
end

goblin("goblin", nil, GOBLIN_SWORD)
goblin("goblin_fast", { L = "ecdd72", M = "c9b84a", D = "8f8a35", E = "6f6a2a" }, GOBLIN_DAGGER,
  { bandana = true, secondDagger = true })
goblin("goblin_shield", { L = "8fc7a0", M = "5fa37c", D = "3a7558", E = "2a5a44" }, GOBLIN_MACE,
  { shield = SMALL_SHIELD, helmet = HELMET })

---------------------------------------------------------------- ESQUELETOS

local SKULL = {
  "....LLLLLLMM....", "..LLLLLLLLMMMM..", ".LLLLLLLLLMMMMM.", ".LLLLLLLLMMMMMD.", "LLLLLLLLMMMMMMMD",
  "LLLLLMMKKKMMKKKD", "LLLLMMMKKKMMKKKD", "LLLMMMMKKKMMKKKD", ".LMMMMMMMMKMMMD.", "..MMMMMMMMMMMD..",
  "...DMMSKSKSKD...", "....DDSKSKSD....",
}
-- Crânio solto na morte: as órbitas se apagam em duas frestas.
local SKULL_OFF = {
  "....LLLLLLMM....", "..LLLLLLLLMMMM..", ".LLLLLLLLLMMMMM.", ".LLLLLLLLMMMMMD.", "LLLLLLLLMMMMMMMD",
  "LLLLLMMMMMMMMMMD", "LLLLMMMKKKMMKKKD", "LLLMMMMMMMMMMMMD", ".LMMMMMMMMKMMMD.", "..MMMMMMMMMMMD..",
  "...DMMSKSKSKD...", "....DDSKSKSD....",
}
local RIBS = { ".LMMMD..", "LKKMKKD.", "LMMMMMD.", ".KKMKK..", "..MMDD.." }
local BONE_HAND = { ".LM.", "LMMD", "MMMD", ".DD." }
local BONE_HAND_FRONT = { ".LM..", "LMMMD", "DMMMD", ".WWW." }
local BONE_STAND = { "...MD..MD..", "...MD..MD..", "..DDDD.DDDD" }
local BONE_STEP_A = { "..MD...DD..", ".MD.....DD.", "DDD.....EEE" }
local BONE_STEP_B = { "..DD...MD..", ".DD.....MD.", "EEE.....DDD" }
local BONE_PASS_A = { "....MMD....", "....MMD....", "....MMD....", "....DDDD..." }
local BONE_PASS_B = { "....DMD....", "....DMD....", "....DMD....", "....DDDD..." }

-- Desfaz-se em ossos: as peças se soltam no ar e terminam numa pilha no chão.
local SKELETON_DEATH = {
  falling = function(img, L, headWear)
    stamp(img, SKULL_OFF, L, 2, 4)
    headWear(img, 0, 4)
    stamp(img, RIBS, L, 7, 14)
    line(img, -3, 12, 2, 15, L.M, L.D)
    line(img, 20, 13, 25, 17, L.M, L.D)
    stamp(img, BONE_STAND, L, 5, 17)
  end,
  pile = function(img, L, headWear)
    line(img, -2, 19, 8, 19, L.M, L.D)
    line(img, 13, 18, 24, 19, L.M, L.D)
    line(img, 3, 17, 15, 19, L.L, L.D)
    stamp(img, RIBS, L, 12, 15)
    stamp(img, SKULL_OFF, L, 0, 8)
    headWear(img, -2, 8)
  end,
}

local SKELETON_PARTS = {
  base = merged(GOBLIN_BASE, { L = "f4f1de", M = "d8d0b8", D = "a89f8a", E = "7a7264", S = "f4f7f8" }),
  head = SKULL, hurt = SKULL_OFF, torso = RIBS, hand = BONE_HAND, stand = BONE_STAND,
  stepA = BONE_STEP_A, stepB = BONE_STEP_B, passA = BONE_PASS_A, passB = BONE_PASS_B,
  handFront = BONE_HAND_FRONT, headX = 2, death = SKELETON_DEATH,
}

-- Espada enferrujada: o perfurante pouco faz contra ossos.
biped("skeleton", SKELETON_PARTS, { B = "c9b89a", b = "8f7a60", W = "5e3a2a" }, merged(GOBLIN_SWORD, { lowColors = { "c9b89a", "8f7a60" } }))

local KNIGHT_ARMOR = { ".IIii...", "IIiiiijj", "IIiiiijj", "jjjjjjjj", "iiijjj.." }
local KNIGHT_HELM = { "..jjjjjjjjjj....", ".jIIiiiiiiiijj..", "jIIIiiiiiiiiiij.", "jjjjjjjjjjjjjjjj" }
local KNIGHT_CREST = { ".RRRR.", "RRRRrr", "..Rr.." }
local KNIGHT_SHIELD = {
  "jjjjjjjjj", "jRRRRRrrj", "jRRIIRrrj", "jRRIIRrrj", "jRRRRRrrj", ".jRRRrrj.", "..jRrrj..", "...jjj...",
}
biped("skeleton_knight", merged(SKELETON_PARTS, { torso = KNIGHT_ARMOR }), { B = "eef2f5", b = "9aa7b3", W = "6b2a2e" },
  GOBLIN_SWORD, { shield = KNIGHT_SHIELD, helmet = KNIGHT_HELM, crest = KNIGHT_CREST })

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

local function robed(name, level, set)
  local L = legendOf(merged(set.base, set.levels[level]))
  local top = set.tops[level]

  local function head(img, dx, dy, face)
    stamp(img, set.hat, L, 2 + dx, -4 + dy)
    stamp(img, face or set.face, L, 2 + dx, 4 + dy)
  end
  local function staff(img, x, dy)
    stamp(img, top.rows, L, x + top.x, dy + top.y + 3)
    line(img, x, dy + 3, x, 17, L.W)
    line(img, x + 1, dy + 3, x + 1, 17, L.w)
    stamp(img, set.hand, L, x - 1, 10 + dy)
  end
  local function stand(img, dx, dy)
    stamp(img, set.feet, L, 5, 19)
    stamp(img, set.robe, L, 5 + dx, 11)
    head(img, dx, dy)
  end
  local arcs = rgb(set.arcs[level])

  local frames = {
    frame(500, function(img)
      stamp(img, set.hand, L, 2, 13); stand(img, 0, 0); staff(img, 20, 0)
    end),
    frame(500, function(img)
      stamp(img, set.hand, L, 2, 14); stand(img, 0, 1); staff(img, 20, 1)
    end),
    -- concentra: cajado erguido atrás, corpo para trás
    frame(190, function(img)
      stamp(img, set.hand, L, 1, 12); stand(img, -2, 0); staff(img, 17, -3)
    end),
    -- lança: cajado à frente, com faíscas na ponta
    frame(80, function(img)
      stamp(img, set.hand, L, 4, 13); stand(img, 2, 1)
      line(img, 21, 16, 27, 5, L.W, L.w)
      stamp(img, top.rows, L, 27 + top.x, 5 + top.y)
      stamp(img, set.hand, L, 21, 9)
    end, function(img)
      line(img, 29, 0, 33, -3, arcs); line(img, 31, 4, 36, 4, arcs); line(img, 29, 8, 33, 11, arcs)
    end),
    -- recuperação
    frame(120, function(img)
      stamp(img, set.hand, L, 3, 13); stand(img, 1, 0); staff(img, 21, 0)
    end),
    -- queda: ajoelha com os olhos fechados e o cajado baixo
    frame(130, function(img)
      stamp(img, set.robe, L, 5, 12)
      head(img, 0, 2, set.hurt)
      stamp(img, set.hand, L, 1, 15)
      line(img, 20, 18, 33, 18, L.W)
    end),
    frame(320, function(img)
      stamp(img, set.feet, L, 5, 19)
      stamp(img, set.robe, L, 5, 11)
      head(img, 0, 0, set.hurt)
      stamp(img, set.hand, L, 1, 13)
    end, nil, lying),
  }
  build(name, frames, { {"idle", 1, 2}, {"attack", 3, 5}, {"fall", 6, 7} })
end

local MAGE_SET = {
  base = MAGE_BASE, levels = MAGE_LEVELS, tops = STAFF_TOP, hat = MAGE_HAT, face = MAGE_FACE, hurt = MAGE_HURT,
  robe = MAGE_ROBE, feet = MAGE_FEET, hand = MAGE_HAND, arcs = { "8fe0f0", "8fe0f0", "f6e05e" },
}
robed("mage", 1, MAGE_SET)
robed("mage_2", 2, MAGE_SET)
robed("mage_3", 3, MAGE_SET)

---------------------------------------------------------------- DRUIDA

-- Capuz de folhas com galhadas: o único humano com silhueta de chifres.
local DRUID_SET = {
  base = {
    R = "5f8a3a", r = "42682c", n = "2f4d22", H = "2f4d22", S = "e0a877", A = "b87d50", K = "1b1626",
    W = "8a5a3a", w = "6b4228", G = "7fbb4e", g = "5f8a3a", T = "c9a24a", k = "3d4757", t = "8a5a3a",
    F = "f4a6c0", f = "d9534a", V = "4f9d4a", v = "2f6f3a",
  },
  levels = {
    {},
    { R = "4a7a4a", r = "32603a", n = "234a2c", T = "e0c060" },
    { R = "2f7a5a", r = "1f5c44", n = "16432f", T = "f6e05e", W = "6b4228", w = "4a2e1c" },
  },
  tops = {
    { rows = { ".GG.", "GGVv", ".Vv." }, x = -1, y = -3 },
    { rows = { "..GG.", ".GGVv", "GGVVv", ".VVv.", "..v.." }, x = -2, y = -5 },
    -- Vinhas descem pelo cajado no nível 3, o destaque da habilidade de prender.
    { rows = { "..F..", ".FfF.", "GGFGG", "GVVVv", ".VVv.", "V.v.V", "V...v", ".V.v.", "..V..", "..v..", ".V..." }, x = -2, y = -11 },
  },
  hat = {
    "..t.......t....", "..t.t...t.t....", "...tt...tt.....", "....GGGGGGg....",
    "...GGGGGGGgg...", "..GGGGGGGGggg..", "..GGGGGGGGggg..", ".GGGGGGGGGgggg.",
  },
  face = {
    "..nSSSSSSSSSn..", "..nSSSKSSKSSn..", "..nSSSKSSKSSn..", "..nSSSSSSSSAn..",
    "..nnSSSSSSAnn..", "...nnAAAAAnn...", "....nnnnnn.....",
  },
  hurt = {
    "..nSSSSSSSSSn..", "..nSSKKSKKSSn..", "..nSSSSSSSSSn..", "..nSSSSSSSSAn..",
    "..nnSSSSSSAnn..", "...nnAAAAAnn...", "....nnnnnn.....",
  },
  robe = MAGE_ROBE,
  feet = MAGE_FEET,
  hand = { ".SS.", "SSSA", "ASSA", ".AA." },
  arcs = { "7fbb4e", "7fbb4e", "f4a6c0" },
}
robed("druid", 1, DRUID_SET)
robed("druid_2", 2, DRUID_SET)
robed("druid_3", 3, DRUID_SET)

---------------------------------------------------------------- LANCEIRO

local SPEARMAN_BASE = {
  I = "dfe6ea", i = "9aa7b3", j = "5d6a7a", k = "3d4757", S = "f2c391", A = "d2905f", K = "1b1626",
  B = "d9823a", b = "a85a2a", W = "b47a42", w = "8f5c35", X = "f4f7f8", x = "b6c2cc",
  R = "d9534a", r = "a2303a", Y = "f6e05e", y = "e8913a",
}
local SPEARMAN_LEVELS = {
  {},
  { B = "c9622f", b = "94401f", j = "4d5a6a" },
  { B = "b5392f", b = "7f2420", I = "f6e05e", i = "e8913a", j = "8f5c35" },
}
-- Chapéu de ferro de aba larga, diferente do elmo fechado do guerreiro.
local SPEARMAN_HEAD = {
  "....IIIiiii...", "...IIIIiiiij..", "..IIIIiiiiiij.", "jjjjjjjjjjjjjj", ".kkSSSSSSSSSk.",
  ".kkSSSKSSKSSk.", ".kkSSSKSSKSSk.", ".kkSSSSSSSSAk.", "..kAAAAAAAAk..", "...kkkkkkkk...",
}
local SPEARMAN_HURT = {
  "....IIIiiii...", "...IIIIiiiij..", "..IIIIiiiiiij.", "jjjjjjjjjjjjjj", ".kkSSSSSSSSSk.",
  ".kkSSKKSKKSSk.", ".kkSSSSSSSSSk.", ".kkSSSSSSSSAk.", "..kAAAAAAAAk..", "...kkkkkkkk...",
}
local SPEARMAN_TORSO = { "BBBBBB..", "BBBBBBbb", "BBBBBBbb", "jjjjjjjj", "BBBBBbb.", "BBBBBbb." }
local SPEARMAN_LEGS = { "jjk.jjk" }
local SPEARMAN_FEET = { "kkkk.kkkk" }
local SPEARMAN_HAND = { ".SSS.", "SSSSS", "ASSSA" }
local SPEAR_TIPS = {
  { up = { "..X..", ".XXx.", ".XXx.", ".XXx." }, ahead = { "X...", "XXX.", "XXxx", "xx.." }, top = -3 },
  { up = { "..X..", ".XXx.", ".XXx.", "XXXxx", ".XXx." }, ahead = { "X...", "XXX.", "XXxx", "xx.." }, top = -5 },
  -- Lança mais longa e dourada no nível 3, com flâmula, o destaque do golpe em linha.
  { up = { "..Y..", ".YYy.", ".YYy.", ".YYy.", "YYYyy" }, ahead = { "Y...", "YYY.", "YYyy", "yy.." }, top = -9 },
}

local function spearman(name, level)
  local L = legendOf(merged(SPEARMAN_BASE, SPEARMAN_LEVELS[level]))
  local tip = SPEAR_TIPS[level]
  local function head(img, dx, dy, face)
    stamp(img, face or SPEARMAN_HEAD, L, 2 + dx, 1 + dy)
    if level == 2 then stamp(img, { ".RRR.", "RRRRr" }, L, 7 + dx, -1 + dy) end
    if level == 3 then stamp(img, { ".YYy.", "YYYyy", ".RRr." }, L, 7 + dx, -2 + dy) end
  end
  local function stand(img, dx, dy, face)
    stamp(img, SPEARMAN_FEET, L, 4, 19)
    stamp(img, SPEARMAN_LEGS, L, 5, 18)
    stamp(img, SPEARMAN_TORSO, L, 5 + dx, 12)
    head(img, dx, dy, face)
  end
  local function spear(img, x, dy)
    local top = tip.top + dy
    stamp(img, tip.up, L, x - 2, top - 5)
    line(img, x, top, x, 17, L.W)
    line(img, x + 1, top, x + 1, 17, L.w)
    if level == 3 then stamp(img, { "RRRR", "RRr.", "Rr.." }, L, x + 2, top + 1) end
    stamp(img, SPEARMAN_HAND, L, x - 2, 11 + dy)
  end
  local function aimed(img, from, to, y)
    line(img, from, y, to, y, L.W, L.w)
    stamp(img, tip.ahead, L, to + 1, y - 1)
  end

  local frames = {
    frame(500, function(img)
      stamp(img, SPEARMAN_HAND, L, 1, 13); stand(img, 0, 0); spear(img, 20, 0)
    end),
    frame(500, function(img)
      stamp(img, SPEARMAN_HAND, L, 1, 14); stand(img, 0, 1); spear(img, 20, 1)
    end),
    -- recua: lança na horizontal, puxada para trás
    frame(170, function(img)
      stand(img, -2, 0)
      aimed(img, -6, 22, 13)
      stamp(img, SPEARMAN_HAND, L, 6, 12); stamp(img, SPEARMAN_HAND, L, 15, 12)
    end),
    -- estocada: corpo à frente e a lança esticada ao máximo, com rastro
    frame(80, function(img)
      stand(img, 2, 1)
      aimed(img, 6, 31, 13)
      stamp(img, SPEARMAN_HAND, L, 12, 12); stamp(img, SPEARMAN_HAND, L, 21, 12)
    end, function(img)
      line(img, 18, 11, 30, 11, SMEAR); line(img, 22, 17, 31, 17, SMEAR)
    end),
    -- recuperação
    frame(120, function(img)
      stamp(img, SPEARMAN_HAND, L, 2, 13); stand(img, 1, 0); spear(img, 21, 0)
    end),
    -- queda: ajoelha com os olhos fechados e a lança no chão
    frame(130, function(img)
      stamp(img, SPEARMAN_TORSO, L, 5, 13)
      head(img, 0, 3, SPEARMAN_HURT)
      stamp(img, SPEARMAN_HAND, L, 1, 15)
      line(img, 18, 18, 34, 18, L.W)
    end),
    frame(320, function(img)
      stamp(img, SPEARMAN_FEET, L, 4, 19)
      stamp(img, SPEARMAN_LEGS, L, 5, 18)
      stamp(img, SPEARMAN_TORSO, L, 5, 12)
      head(img, 0, 0, SPEARMAN_HURT)
      stamp(img, SPEARMAN_HAND, L, 1, 13)
    end, nil, lying),
  }
  build(name, frames, { {"idle", 1, 2}, {"attack", 3, 5}, {"fall", 6, 7} })
end

spearman("spearman", 1)
spearman("spearman_2", 2)
spearman("spearman_3", 3)

---------------------------------------------------------------- MONGE

local MONK_BASE = {
  S = "f2c391", A = "d2905f", K = "1b1626", G = "e8e2cf", g = "b8b09a", R = "d9534a", r = "a2303a",
  W = "b47a42", w = "8f5c35", k = "8f5c35", O = "8fe0f0", o = "4fa0c8", Y = "f6e05e", y = "e8913a",
}
local MONK_LEVELS = {
  {},
  { G = "e0b84a", g = "b08a2f" },
  { G = "e8913a", g = "b5602a", R = "f6e05e", r = "e8913a", W = "f6e05e", w = "e8913a" },
}
local MONK_HEAD = {
  "....SSSSSSS...", "..SSSSSSSSSSA.", ".SSSSSSSSSSSSA", ".SSSSSSSSSSSSA", ".RRRRRRRRRRRRr",
  ".SSSSSSSKSSKSA", ".SSSSSSSKSSKSA", ".SSSSSSSSSSSSA", "..ASSSSSSSSSA.", "...AAAAAAAAA..",
}
local MONK_HURT = {
  "....SSSSSSS...", "..SSSSSSSSSSA.", ".SSSSSSSSSSSSA", ".SSSSSSSSSSSSA", ".RRRRRRRRRRRRr",
  ".SSSSSSKKSKKSA", ".SSSSSSSSSSSSA", ".SSSSSSSSSSSSA", "..ASSSSSSSSSA.", "...AAAAAAAAA..",
}
local MONK_BAND_TAIL = { "RR.", ".Rr", ".Rr" }
local MONK_TORSO = { "GGGGGG..", "GGGSSGgg", "GGGGGGgg", "RRRRRRrr", "GGGGGgg.", "GGGGGgg." }
local MONK_LEGS = { "GGg.GGg" }
local MONK_FEET = { "AAAA.AAAA" }
local MONK_FIST = { ".WWW.", "WSSSW", "WSSSW", ".WWW." }
-- Aura nos punhos no nível 3, o destaque da habilidade de atordoar.
local MONK_AURA = { ".O.O.O.", "O.....o", ".......", "O.....o", ".......", "O.....o", ".o.o.o." }

local function monk(name, level)
  local L = legendOf(merged(MONK_BASE, MONK_LEVELS[level]))
  local function head(img, dx, dy, face)
    stamp(img, MONK_BAND_TAIL, L, 0 + dx, 4 + dy)
    stamp(img, face or MONK_HEAD, L, 2 + dx, 1 + dy)
    if level == 2 then stamp(img, { "W.W.W.W.W" }, L, 6 + dx, 11 + dy) end
  end
  local function stand(img, dx, dy, face)
    stamp(img, MONK_FEET, L, 4, 19)
    stamp(img, MONK_LEGS, L, 5, 18)
    stamp(img, MONK_TORSO, L, 5 + dx, 12)
    head(img, dx, dy, face)
  end
  local function fist(img, x, y)
    stamp(img, MONK_FIST, L, x, y)
  end
  local function aura(x, y)
    return function(img)
      if level >= 3 then stamp(img, MONK_AURA, L, x - 1, y - 2) end
    end
  end

  local frames = {
    -- guarda alta, punhos à frente
    frame(500, function(img)
      fist(img, 1, 13); stand(img, 0, 0); fist(img, 19, 10)
    end, aura(19, 10)),
    frame(500, function(img)
      fist(img, 1, 14); stand(img, 0, 1); fist(img, 19, 11)
    end, aura(19, 11)),
    -- prepara: punho recolhido ao lado do corpo
    frame(90, function(img)
      stand(img, -2, 0); fist(img, 1, 13); fist(img, 13, 12)
    end, aura(13, 12)),
    -- soco: braço esticado e rastro
    frame(60, function(img)
      fist(img, 3, 14); stand(img, 2, 1)
      line(img, 14, 14, 24, 14, L.S, L.A)
      fist(img, 25, 12)
    end, function(img)
      line(img, 16, 10, 25, 10, SMEAR); line(img, 18, 18, 26, 18, SMEAR)
      if level >= 3 then stamp(img, MONK_AURA, L, 24, 10) end
    end),
    -- recuperação
    frame(80, function(img)
      fist(img, 2, 13); stand(img, 1, 0); fist(img, 20, 11)
    end, aura(20, 11)),
    -- queda: ajoelha com os olhos fechados
    frame(130, function(img)
      stamp(img, MONK_TORSO, L, 5, 13)
      head(img, 0, 3, MONK_HURT)
      fist(img, 1, 15); fist(img, 16, 15)
    end),
    frame(320, function(img)
      stamp(img, MONK_FEET, L, 4, 19)
      stamp(img, MONK_LEGS, L, 5, 18)
      stamp(img, MONK_TORSO, L, 5, 12)
      head(img, 0, 0, MONK_HURT)
      fist(img, 1, 13)
    end, nil, lying),
  }
  build(name, frames, { {"idle", 1, 2}, {"attack", 3, 5}, {"fall", 6, 7} })
end

monk("monk", 1)
monk("monk_2", 2)
monk("monk_3", 3)

---------------------------------------------------------------- LADINO

local ROGUE_BASE = {
  H = "4a4560", h = "332f47", n = "221f33", S = "f2c391", A = "d2905f", K = "1b1626", F = "a2303a", f = "7a2430",
  U = "5e3a2a", B = "dfe6ea", b = "9aa7b3", W = "8f5c35", Y = "f6e05e", y = "e8913a",
}
local ROGUE_LEVELS = {
  {},
  { H = "3f5a60", h = "2a4248", n = "1c2f33", B = "f4f7f8" },
  { H = "3a3350", h = "261f3a", n = "1a1428", B = "f6e05e", b = "e8913a" },
}
local ROGUE_HEAD = {
  "....HHHHhhhh...", "..HHHHHHhhhhhh.", ".HHHHHhhhhhhhh.", ".HHHhhhSSSSSSSn", ".HHhhhSSKSSKSSn",
  ".HHhhhSSKSSKSSn", "hHhhhhFFFFFFFFn", "hhhhhFFFFFFFFFn", ".hhhhfFFFFFFFn.", ".nhhhhhhhhhhn..", "..nnhhhhhhnn...",
}
local ROGUE_HURT = {
  "....HHHHhhhh...", "..HHHHHHhhhhhh.", ".HHHHHhhhhhhhh.", ".HHHhhhSSSSSSSn", ".HHhhhSKKSKKSSn",
  ".HHhhhSSSSSSSSn", "hHhhhhFFFFFFFFn", "hhhhhFFFFFFFFFn", ".hhhhfFFFFFFFn.", ".nhhhhhhhhhhn..", "..nnhhhhhhnn...",
}
local ROGUE_TORSO = { "HHHHHH..", ".HHHHHH.", "HHHHHhh.", "HHhhhhh.", "UUUUUUU.", "HHHHHhh." }
local ROGUE_LEGS = { ".hhn.hhn.", ".hhn.hhn.", "nnnn.nnnn" }
local ROGUE_HAND = { ".SS.", "SSSA", "ASSA", ".AA." }
local ROGUE_DAGGER = { "..B..", ".BBb.", ".BBb.", ".BBb.", "WWWWW" }
-- Bolsa de ouro no cinto no nível 3, o destaque da habilidade de lucrar com os abates.
local GOLD_BAG = { ".UU.", "YYYy", "YYYy", ".yy." }

local function rogue(name, level)
  local L = legendOf(merged(ROGUE_BASE, ROGUE_LEVELS[level]))
  local function body(img, dx, dy, face)
    stamp(img, ROGUE_TORSO, L, 6 + dx, 11)
    stamp(img, face or ROGUE_HEAD, L, 2 + dx, dy)
    if level >= 3 then stamp(img, GOLD_BAG, L, 3 + dx, 14) end
  end
  local function armed(img, x, y)
    stamp(img, ROGUE_DAGGER, L, x, y - 5)
    stamp(img, ROGUE_HAND, L, x, y)
  end

  local frames = {
    frame(500, function(img)
      armed(img, 0, 13); stamp(img, ROGUE_LEGS, L, 6, 17); body(img, 0, 0); armed(img, 18, 11)
    end),
    frame(500, function(img)
      armed(img, 0, 14); stamp(img, ROGUE_LEGS, L, 6, 17); body(img, 0, 1); armed(img, 18, 12)
    end),
    -- prepara: adaga erguida atrás da cabeça
    frame(150, function(img)
      armed(img, 0, 13); stamp(img, ROGUE_LEGS, L, 6, 17); body(img, -2, 0); armed(img, 3, 3)
    end),
    -- arremesso: braço à frente, a adaga voa com rastro
    frame(70, function(img)
      armed(img, 3, 14); stamp(img, ROGUE_LEGS, L, 6, 17); body(img, 2, 1)
      stamp(img, ROGUE_HAND, L, 20, 10)
      line(img, 27, 11, 33, 11, L.B, L.b)
    end, function(img)
      line(img, 24, 9, 29, 9, SMEAR); line(img, 24, 14, 30, 14, SMEAR)
    end),
    -- recuperação: outra adaga na mão
    frame(110, function(img)
      armed(img, 1, 13); stamp(img, ROGUE_LEGS, L, 6, 17); body(img, 1, 0); armed(img, 19, 11)
    end),
    -- queda: ajoelha com os olhos fechados
    frame(130, function(img)
      stamp(img, { "nnnn.nnnn" }, L, 6, 19)
      stamp(img, ROGUE_TORSO, L, 6, 13)
      stamp(img, ROGUE_HURT, L, 2, 3)
      if level >= 3 then stamp(img, GOLD_BAG, L, 3, 16) end
      stamp(img, ROGUE_HAND, L, 1, 15)
      stamp(img, ROGUE_HAND, L, 18, 15)
      line(img, 23, 18, 28, 18, L.B)
    end),
    frame(320, function(img)
      stamp(img, ROGUE_LEGS, L, 6, 17)
      stamp(img, ROGUE_TORSO, L, 6, 11)
      stamp(img, ROGUE_HURT, L, 2, 0)
      if level >= 3 then stamp(img, GOLD_BAG, L, 3, 14) end
      stamp(img, ROGUE_HAND, L, 1, 13)
    end, nil, lying),
  }
  build(name, frames, { {"idle", 1, 2}, {"attack", 3, 5}, {"fall", 6, 7} })
end

rogue("rogue", 1)
rogue("rogue_2", 2)
rogue("rogue_3", 3)

---------------------------------------------------------------- LOBO

local WOLF = legendOf({
  L = "b4becb", M = "838fa0", D = "5a6474", E = "3f4755", C = "d6cfbd", Y = "f6e05e", K = "1b1626",
  S = "f4f7f8", R = "d9534a", r = "a2303a",
})
local WOLF_BODY = {
  "..EEEEDDDDDDDDLLLL..", ".EEEEEDDDDDDDLLLLLL.", "DDDDDDMMMMMMMMLLLCCD", "LMMMMMMMMMMMMMMLCCCD",
  "MMMMMMMMMMMMMMMMCCDD", "DMMMMMMMMMMMCCCCCDD.", ".DDDMMMMMMCCCCCCD...", "...DDDDDDDDDDDD.....",
}
local WOLF_TAIL = { "...LMMD", ".LLMMMD", "LLMMMD.", "LMMDD..", "MDD...." }
local WOLF_HEAD = {
  "...E......E.......", "..LME....LME......", "..LMMD..LMMD......", ".LLMMMMMMMMMD.....",
  ".LMMMMMMMMMMMD....", "LLMMMMMYYKMMMD....", "LMMMMMMMMDMMMMMMK.", "DMMMMMMMMMMMMMMMMK",
  "DMMMMMMMCCMMMMMDD.", ".DMMMMCCCCCCCCC...", "..DDCCCCCCDDD.....", "....DDDDDD........",
}
local WOLF_BITE = {
  "...E......E.......", "..LME....LME......", "..LMMD..LMMD......", ".LLMMMMMMMMMD.....",
  ".LMMMMMMMMMMMD....", "LLMMMMMYYKMMMD....", "LMMMMMMMMDMMMMMMK.", "DMMMMMMMMMMMMMMMMK",
  "DMMMMMMSSSSSSSSS..", ".DMMMMRRRRRRR.....", "..DDCCRRRRSSS.....", "....DDCCCCCCCC....",
}
local WOLF_HURT = {
  "...E......E.......", "..LME....LME......", "..LMMD..LMMD......", ".LLMMMMMMMMMD.....",
  ".LMMMMMMMMMMMD....", "LLMMMMMKMKMMMD....", "LMMMMMMMKMMMMMMMK.", "DMMMMMMKMKMMMMMMMK",
  "DMMMMMMMCCMMMMMDD.", ".DMMMMCCCCCCCCC...", "..DDCCCCCCDDD.....", "....DDDDDD........",
}

-- Uma pata vai do corpo (topX) até o chão (footX), com a almofada na última linha.
local function wolfLeg(img, topX, footX, color, paw)
  for row = 0, 3 do
    local x = topX + math.floor((footX - topX) * row / 3 + 0.5)
    for dx = 0, 2 do put(img, X0 + x + dx, Y0 + 15 + row, dx == 2 and WOLF.E or color) end
  end
  for dx = 0, 3 do put(img, X0 + footX + dx, Y0 + 19, paw) end
end

local function wolfBody(img, dx, dy, head, headDy)
  stamp(img, WOLF_TAIL, WOLF, -5 + dx, 9 + dy)
  stamp(img, WOLF_BODY, WOLF, dx, 8 + dy)
  stamp(img, head or WOLF_HEAD, WOLF, 16 + dx, 1 + dy + (headDy or 0))
end

-- pose: posição no chão das patas de trás e da frente, de longe e de perto.
local function wolfWalk(farBack, farFront, nearBack, nearFront, dy)
  return function(img)
    wolfLeg(img, 3, farBack, WOLF.D, WOLF.E)
    wolfLeg(img, 15, farFront, WOLF.D, WOLF.E)
    wolfBody(img, 0, dy)
    wolfLeg(img, 1, nearBack, WOLF.M, WOLF.D)
    wolfLeg(img, 13, nearFront, WOLF.M, WOLF.D)
  end
end

build("wolf", {
  frame(90, wolfWalk(6, 12, -1, 17, 0)),
  frame(90, wolfWalk(3, 15, 2, 14, -1)),
  frame(90, wolfWalk(-1, 18, 6, 11, 0)),
  frame(90, wolfWalk(2, 14, 3, 15, -1)),
  -- prepara: agacha e recolhe a cabeça
  frame(170, function(img)
    wolfLeg(img, 3, 3, WOLF.D, WOLF.E); wolfLeg(img, 14, 14, WOLF.D, WOLF.E)
    wolfBody(img, -2, 1, nil, 1)
    wolfLeg(img, 1, 0, WOLF.M, WOLF.D); wolfLeg(img, 12, 12, WOLF.M, WOLF.D)
  end),
  -- morde: salta à frente de boca aberta
  frame(70, function(img)
    wolfLeg(img, 3, 1, WOLF.D, WOLF.E); wolfLeg(img, 15, 18, WOLF.D, WOLF.E)
    wolfBody(img, 2, 0, WOLF_BITE)
    wolfLeg(img, 1, -1, WOLF.M, WOLF.D); wolfLeg(img, 14, 17, WOLF.M, WOLF.D)
  end, function(img)
    line(img, 30, 2, 34, 4, SMEAR); line(img, 31, 14, 35, 12, SMEAR)
  end),
  frame(110, function(img)
    wolfLeg(img, 3, 2, WOLF.D, WOLF.E); wolfLeg(img, 15, 15, WOLF.D, WOLF.E)
    wolfBody(img, 1, 0)
    wolfLeg(img, 1, 1, WOLF.M, WOLF.D); wolfLeg(img, 13, 14, WOLF.M, WOLF.D)
  end),
  -- morte: recua de olhos fechados e deita de lado
  frame(120, function(img)
    wolfLeg(img, 3, 1, WOLF.D, WOLF.E); wolfLeg(img, 15, 13, WOLF.D, WOLF.E)
    wolfBody(img, -2, 1, WOLF_HURT, 1)
    wolfLeg(img, 1, -1, WOLF.M, WOLF.D); wolfLeg(img, 13, 11, WOLF.M, WOLF.D)
  end),
  frame(320, function(img)
    stamp(img, WOLF_TAIL, WOLF, -5, 13)
    stamp(img, WOLF_BODY, WOLF, 0, 12)
    stamp(img, WOLF_HURT, WOLF, 16, 9)
  end),
}, { {"walk", 1, 4}, {"attack", 5, 7}, {"death", 8, 9} })

---------------------------------------------------------------- SLIMES

local SLIME = { L = "9ff0c8", M = "5fd4ae", D = "2f9f94", E = "1f6f74", S = "eafff4" }
local SLIME_CX, SLIME_BASE = 28, 35

-- Domo de base reta, com luz no alto à esquerda e sombra embaixo à direita.
local function blob(img, palette, cx, base, w, h, eyes)
  for row = 0, h - 1 do
    local t = row / h
    local half = (w / 2) * math.sqrt(1 - t * t)
    if row == 0 then half = half - 1 end
    local y = base - row
    for x = cx - math.floor(half + 0.5), cx + math.floor(half + 0.5) - 1 do
      local nx = (x + 0.5 - cx) / (w / 2)
      local light = -nx * 0.55 + t * 0.9
      local hex = palette.M
      if row == 0 then hex = palette.E
      elseif light > 0.62 then hex = palette.L
      elseif light < -0.02 then hex = palette.D end
      img:drawPixel(x, y, rgb(hex))
    end
  end
  local shineW = math.max(1, w // 7)
  local shineX = cx - w // 4
  local shineY = base - math.floor(h * 0.74)
  for x = shineX, shineX + shineW do img:drawPixel(x, shineY, rgb(palette.S)) end
  if eyes then
    local eyeY = base - math.floor(h * 0.52)
    for _, fraction in ipairs({ eyes.left, eyes.right }) do
      local ex = cx + math.floor(w * fraction + 0.5)
      for dx = 0, eyes.w - 1 do
        for dy = 0, eyes.h - 1 do
          img:drawPixel(ex + dx, eyeY + dy, K)
        end
      end
      if eyes.w > 1 then img:drawPixel(ex, eyeY, rgb(palette.S)) end
    end
  end
end

local function slimeBody(img, w, h, eyes)
  blob(img, SLIME, SLIME_CX, SLIME_BASE, w, h, eyes)
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

---------------------------------------------------------------- REI SLIME

-- Chefe da Fase 5: um slime de outro verde, muito maior, com coroa e cara brava, numa tela própria.
local KING_SPEC = ImageSpec{ width = 96, height = 72, colorMode = ColorMode.RGB }
local KING = { L = "8de3b0", M = "45b98c", D = "238073", E = "16545a", S = "e9fff3" }
local KING_CX, KING_BASE = 48, 67
local KING_EYES = { left = 0.04, right = 0.24, w = 4, h = 6 }
local CROWN = {
  "..H.........H.........H..",
  ".HYy.......HYy.......HYy.",
  ".YYy...H...YYy...H...YYy.",
  ".YYy..HYy..YRy..HYy..YYy.",
  ".YYYYYYYYYYYYYYYYYYYYYYy.",
  ".YRYYYYBYYYYRYYYYBYYYRYy.",
  ".yyyyyyyyyyyyyyyyyyyyyyy.",
}
local CROWN_LEGEND = legendOf({ H = "fff3b0", Y = "f6e05e", y = "c99a2e", R = "d9534a", B = "5aa9e6" })

local function crown(img, x, y)
  for r, row in ipairs(CROWN) do
    for i = 1, #row do
      local c = CROWN_LEGEND[row:sub(i, i)]
      if c then img:drawPixel(x + i - 1, y + r - 1, c) end
    end
  end
end

-- Sobrancelhas que descem para o meio e uma boca com dois dentes.
local function kingFace(img, w, h)
  local eyeY = KING_BASE - math.floor(h * 0.52)
  local left = KING_CX + math.floor(w * KING_EYES.left + 0.5)
  local right = KING_CX + math.floor(w * KING_EYES.right + 0.5)
  for i = 0, 4 do
    img:drawPixel(left - 1 + i, eyeY - 4 + i // 2, K)
    img:drawPixel(right + 4 - i, eyeY - 4 + i // 2, K)
  end
  local mouthY = eyeY + KING_EYES.h + 2
  for x = left + 1, right + 2 do img:drawPixel(x, mouthY, K) end
  img:drawPixel(left + 2, mouthY + 1, rgb(KING.S))
  img:drawPixel(right + 1, mouthY + 1, rgb(KING.S))
end

local function kingBody(img, w, h, face)
  blob(img, KING, KING_CX, KING_BASE, w, h, face and KING_EYES or nil)
  if face then kingFace(img, w, h) end
  crown(img, KING_CX + math.floor(w * 0.14 + 0.5) - 12, KING_BASE - h - 3)
end

local function kingDrops(img, list, palette)
  for _, d in ipairs(list) do
    for x = 0, d[3] - 1 do
      for y = 0, d[3] - 1 do
        img:drawPixel(KING_CX + d[1] + x, KING_BASE - d[2] + y, rgb((palette or KING).M))
      end
    end
  end
end

local function kingFrame(ms, draw)
  return frame(ms, draw, nil, nil, KING_SPEC)
end

local function kingStep(ms, w, h)
  return kingFrame(ms, function(img) kingBody(img, w, h, true) end)
end

build("slime_king", {
  kingStep(160, 58, 40), kingStep(160, 68, 31), kingStep(160, 50, 48), kingStep(160, 56, 42),
  -- ataque: estica para cima, cai esparramando e volta
  kingStep(150, 46, 52),
  kingFrame(130, function(img)
    kingBody(img, 78, 26, true)
    kingDrops(img, { { -40, 10, 2 }, { 38, 12, 2 }, { -30, 18, 1 }, { 30, 20, 1 } })
  end),
  kingStep(150, 60, 38),
  -- perde um pedaço: treme e solta dois slimes comuns pelos lados
  kingFrame(130, function(img)
    kingBody(img, 64, 36, true)
    blob(img, SLIME, KING_CX - 30, KING_BASE - 24, 10, 8, nil)
    blob(img, SLIME, KING_CX + 30, KING_BASE - 26, 10, 8, nil)
  end),
  kingFrame(160, function(img)
    kingBody(img, 54, 42, true)
    blob(img, SLIME, KING_CX - 36, KING_BASE - 6, 10, 7, nil)
    blob(img, SLIME, KING_CX + 36, KING_BASE - 6, 10, 7, nil)
  end),
  -- morte: esparrama e vira poça, com a coroa caída ao lado
  kingFrame(140, function(img)
    blob(img, KING, KING_CX, KING_BASE, 80, 18, nil)
    kingDrops(img, { { -42, 14, 3 }, { 40, 16, 3 }, { -24, 26, 2 }, { 22, 28, 2 } })
    crown(img, KING_CX - 4, KING_BASE - 36)
  end),
  kingFrame(400, function(img)
    blob(img, KING, KING_CX, KING_BASE, 66, 4, nil)
    kingDrops(img, { { -40, 1, 2 }, { 38, 1, 2 } })
    crown(img, KING_CX + 6, KING_BASE - 9)
  end),
}, { {"walk", 1, 4}, {"attack", 5, 7}, {"split", 8, 9}, {"death", 10, 11} }, KING_SPEC)
