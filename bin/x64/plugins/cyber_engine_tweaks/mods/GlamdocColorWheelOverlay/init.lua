local CONFIG_FILE = "gcw_colors.txt"

local visible = false
local colA = { 0.85, 0.10, 0.10 }
local colB = { 0.10, 0.60, 0.95 }
local active = false
local status = "pick colors and press Apply"

local inSession = false
local pollTicks = 0
local lastSig = nil
local sigAcquired = false
local sessionStartClock = 0
local scheduleFired = 0
local SCHEDULE = { 10, 25, 45 }

local function log(s)
  local f = io.open("gcw_overlay.log", "a")
  if f then f:write(os.date("[%H:%M:%S] ") .. s .. "\n") f:close() end
end

local function packRGB(c)
  return (math.floor(c[1] * 255 + 0.5) * 65536)
       + (math.floor(c[2] * 255 + 0.5) * 256)
       +  math.floor(c[3] * 255 + 0.5)
end

local function unpackRGB(v)
  if type(v) ~= "number" or v <= 0 or v >= 16777216 then return nil end
  v = math.floor(v)
  return {
    (math.floor(v / 65536) % 256) / 255,
    (math.floor(v / 256) % 256) / 255,
    (v % 256) / 255,
  }
end

local function saveConfig()
  local f = io.open(CONFIG_FILE, "w")
  if not f then log("cannot write config") return end
  f:write("1 " .. packRGB(colA) .. " " .. packRGB(colB) .. "\n")
  f:close()
  active = true
  log("config saved: a=" .. packRGB(colA) .. " b=" .. packRGB(colB))
end

local function loadConfig()
  local f = io.open(CONFIG_FILE, "r")
  if not f then return false end
  local line = f:read("*l")
  f:close()
  if not line then return false end
  local a, b = line:match("^1%s+(%-?%d+)%s+(%-?%d+)$")
  if not a or not b then return false end
  a = tonumber(a) b = tonumber(b)
  local ca = unpackRGB(a)
  local cb = unpackRGB(b)
  if ca then colA = ca end
  if cb then colB = cb end
  active = true
  log("config loaded: a=" .. a .. " b=" .. b)
  return true
end

local function makeColor(r255, g255, b255)
  local ok2, c2 = pcall(function() return Color.new() end)
  if ok2 and c2 ~= nil then
    pcall(function() c2.Red = r255 end)
    pcall(function() c2.Green = g255 end)
    pcall(function() c2.Blue = b255 end)
    pcall(function() c2.Alpha = 255 end)
    local okR2, vr2 = pcall(function() return c2.Red end)
    if okR2 and type(vr2) == "number" and math.floor(vr2 + 0.5) == r255 then
      return c2
    end
    log("Color field assignment failed (Red readback=" .. tostring(vr2) .. ")")
  else
    log("Color.new() threw: " .. tostring(c2))
  end
  return nil
end

local function getSystem()
  local ok, sys = pcall(function()
    return Game.GetScriptableSystemsContainer():Get("CyberwareCustomizationSystem")
  end)
  if ok and sys ~= nil then return sys end
  return nil
end

local function currentSignature(sys)
  local ok, sd = pcall(function() return sys:GetSavedData() end)
  if not ok or sd == nil then
    return nil
  end
  local okB, brand = pcall(function() return tostring(sd.brandDataID) end)
  local okS, sw = pcall(function() return tostring(sd.switcherIndex) end)
  if okB and okS then
    return brand .. "|" .. sw
  end
  return nil
end

local function applyColors(source)
  local a255 = { math.floor(colA[1] * 255 + 0.5), math.floor(colA[2] * 255 + 0.5), math.floor(colA[3] * 255 + 0.5) }
  local b255 = { math.floor(colB[1] * 255 + 0.5), math.floor(colB[2] * 255 + 0.5), math.floor(colB[3] * 255 + 0.5) }

  local cA = makeColor(a255[1], a255[2], a255[3])
  local cB = makeColor(b255[1], b255[2], b255[3])
  if not cA or not cB then
    status = "color construction failed - see log"
    return false
  end

  local sys = getSystem()
  if not sys then
    log("system unreachable (" .. source .. ")")
    return false
  end

  local ok1, res1 = pcall(function() sys:SetCustomizationParameters(true, cA, cB) end)
  log("SetCustomizationParameters(true) [" .. source .. "]: " .. tostring(ok1) .. " " .. tostring(res1))
  if not ok1 then
    status = "apply call failed - see log"
    return false
  end

  status = "applied (" .. source .. ")"
  log("applied via " .. source .. ": a=" .. table.concat(a255, ",") .. " b=" .. table.concat(b255, ","))
  return true
end

local function syncSig()
  local sys = getSystem()
  if sys then
    local sig = currentSignature(sys)
    if sig then lastSig = sig end
  end
end

registerForEvent("onInit", function()
  loadConfig()
  log("mod initialized (active=" .. tostring(active) .. ")")
end)

registerHotkey("gcwOpen", "Open Glamdoc Color Wheel", function()
  visible = not visible
  if visible and active then
    applyColors("window opened")
    syncSig()
  end
end)

registerForEvent("onUpdate", function(dt)
  local okP, player = pcall(function() return Game.GetPlayer() end)
  local playerExists = okP and player ~= nil
  if playerExists and not inSession then
    inSession = true
    lastSig = nil
    sigAcquired = false
    scheduleFired = 0
    sessionStartClock = os.clock()
    loadConfig()
    log("session detected - watcher armed (active=" .. tostring(active) .. ")")
  elseif not playerExists and inSession then
    inSession = false
    lastSig = nil
    log("session ended")
  end

  if not inSession or not active then return end

  pollTicks = pollTicks + 1
  if pollTicks % 60 ~= 0 then return end

  local elapsed = os.clock() - sessionStartClock
  if scheduleFired < #SCHEDULE and elapsed >= SCHEDULE[scheduleFired + 1] then
    scheduleFired = scheduleFired + 1
    applyColors("scheduled +" .. SCHEDULE[scheduleFired] .. "s")
    syncSig()
  end

  local sys = getSystem()
  if not sys then return end
  local sig = currentSignature(sys)
  if sig ~= nil then
    if not sigAcquired then
      sigAcquired = true
      lastSig = sig
      log("signature acquired: " .. sig)
    elseif sig ~= lastSig then
      lastSig = sig
      applyColors("style change")
    end
  end
end)

registerForEvent("onDraw", function()
  if not visible then return end
  if ImGui.Begin("Arm Cyberware Colors", ImGuiWindowFlags.AlwaysAutoResize) then
    ImGui.Text("Primary color")
    colA = ImGui.ColorPicker3("##primary", colA)
    ImGui.Text("Secondary color")
    colB = ImGui.ColorPicker3("##secondary", colB)
    ImGui.Separator()
    if ImGui.Button("Apply") then
      saveConfig()
      applyColors("overlay")
      syncSig()
    end
    ImGui.SameLine()
    if ImGui.Button("Close") then visible = false end
    ImGui.Separator()
    ImGui.TextWrapped(status)
    ImGui.TextWrapped("Colors are stored in this mod's folder and re-applied")
    ImGui.TextWrapped("automatically on load and on style changes.")
  end
  ImGui.End()
end)
