local attack_speed = 0.1
local drop_speed   = 0.1

local active   = false -- false is off by default, true is on by default
local sides    = { "bottom", "left", "front", "right", "back", "top" }
local detected = {}
local drop     = nil
local attack   = {}

local function boot()
  print("Booting Neighbors")
  for k,v in pairs(sides) do
    if peripheral.isPresent(v) then
      local type = peripheral.getType(v)
      detected[v] = type  == "computer" or type == "turtle"
      if detected[v] then
        peripheral.call(v, "turnOn")
      end
    end
  end
end

-- Shutdown any computers in the mix
local function notTurtle()
  sleep(5)
  os.shutdown()
end

-- determine drop and attack directions
local function configure()
  print("Configuring")
  
  -- Label computer if not already labeled
  if (os.getComputerLabel() == nil) then os.setComputerLabel('MBE') end
  
  -- drop based on adjacent turtles or lack of
  if detected["bottom"] then
    drop = turtle.dropDown
  elseif detected["front"] then
    drop = turtle.drop
  elseif detected["top"] and not (detected["left"] or detected["right"] or detected["back"]) then
    drop = turtle.dropDown
  end
  
  -- Attack in open directions
  if not detected['top'] and not turtle.detectUp() then
    table.insert(attack, turtle.attackUp)
  end
  if not detected['front'] and not turtle.detect() then
    table.insert(attack, turtle.attack)
  end
  
  -- Open the modem
  rednet.open("right")
end

local function dropAll()
  -- check all of the slots
  for i = 1, 16 do
    -- skip empty slots
    if turtle.getItemCount(i) ~= 0 then
      turtle.select(i)
      while drop() do sleep(drop_speed) end
    end
  end
  turtle.select(1)
end

local function pastebin(code, filename)
  local response = http.get("http://pastebin.com/raw.php?i=" .. textutils.urlEncode(code))
  if response then
    local file = fs.open(filename, "w")
    file.write(response.readAll())
    file.close()
    response.close()
  end
  return response
end

local function menu()
  clear()
  print("MBE Online")
  print("")
  print("M - Murder")
  print("O - Turn Off")
  print("R - Reboot")
  print("U - Update")
end

-- event handler
local function ready()
  if active then os.startTimer(attack_speed) end
  while true do
    local event, param1, param2, param3 = os.pullEvent()
    if event == "timer" then -- kill things
      for k,v in pairs(attack) do v() end
      if drop then dropAll() end
      if active then os.startTimer(attack_speed) end
    elseif event == "rednet_message" then -- listen for messages
      if param2 == "MBE-Off" then
        active = false
      elseif param2 == "MBE-On" then
        active = true
        os.startTimer(attack_speed)
      elseif param2 == "MBE-Reboot" then
        os.reboot()
      elseif param2 == "MBE-Update" then
        pastebin("", "MBE")
        os.reboot()
      end
    elseif event == "char" then -- handle direct input
      if     param1 == "m" or param1 == "M" then rednet.broadcast("MBE-On")
      elseif param1 == "o" or param1 == "O" then rednet.broadcast("MBE-Off")
      elseif param1 == "r" or param1 == "R" then rednet.broadcast("MBE-Reboot")
      elseif param1 == "u" or param1 == "U" then rednet.broadcast("MBE-Update")
      end
    end
  end
end

local function main()
  boot()
  if turtle == nil then notTurtle() end
  configure()
  menu()
  ready()
end

main()