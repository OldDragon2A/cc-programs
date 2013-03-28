-- Efficient Miner

-- Fuel will be pulled from the internal
-- slot first, chest if equipped and then
-- from the drop slots. When the drop
-- slots are full the turtle will either
-- use the ender chest or return and drop
-- behind the starting point.

local position         = { 0, 0, 0, 3 }
local drop_position    = { 0, 0, 0, 1 }
local drop_slots       = { 1, 11 }
local drop_chest_slot  = 12
local torch_slot       = 13
local torch_chest_slot = 14
local fuel_slot        = 15
local fuel_chest_slot  = 16
local refuel_level     = 0
local torch_spacing    = 7

local state = {
  verbose          = 0,
  use_torches      = true,
  torch_wait       = false,
  dig_mode         = false,
  dropping         = false,
  log_file         = nil
}
local log_handle       = nil

-- Function Definitions
local dropOff, refuel

local function deepcopy(orig)
  local orig_type = type(orig)
  local copy
  if orig_type == 'table' then
    copy = {}
    for orig_key, orig_value in next, orig, nil do
      copy[deepcopy(orig_key)] = deepcopy(orig_value)
    end
    setmetatable(copy, deepcopy(getmetatable(orig)))
  else
    copy = orig
  end
  return copy
end
local function getopt(optstring, ...)
  local opts = { }
  local args = { ... }

  for optc, optv in optstring:gmatch"(%a)(:?)" do
    opts[optc] = { hasarg = optv == ":" }
  end

  return coroutine.wrap(function()
    local yield = coroutine.yield
    local i = 1

    while i <= #args do
      local arg = args[i]

      i = i + 1

      if arg == "--" then
        break
      elseif arg:sub(1, 1) == "-" then
        for j = 2, #arg do
          local opt = arg:sub(j, j)

          if opts[opt] then
            if opts[opt].hasarg then
              if j == #arg then
                if args[i] then
                  yield(opt, args[i])
                  i = i + 1
                elseif optstring:sub(1, 1) == ":" then
                  yield(':', opt)
                else
                  yield('?', opt)
                end
              else
                yield(opt, arg:sub(j + 1))
              end

              break
            else
              yield(opt, false)
            end
          else
            yield('?', opt)
          end
        end
      else
        yield(false, arg)
      end
    end

    for i = i, #args do
      yield(false, args[i])
    end
  end)
end
local function writeLog(msg)
  if state.log_file ~= nil then
    writeLog = function (msg)
      log_handle = fs.open(state.log_file, 'a')
      log_handle.writeLine(msg)
      log_handle.close()
    end
  else
    writeLog = print
  end
  writeLog(msg)
end

local function formatPosition(p)
  return p[1]..","..p[2]..","..p[3]..(p[4] == nil and "" or "," .. p[4])
end
local function updatePosition(axis, value)
  if axis == 4 then
    position[axis] = (position[axis] + value) % 4
  else
    position[axis] = position[axis] + value
  end
end
local function inPosition(p)
  return p ~= nil and position[1] == p[1] and position[2] == p[2] and position[3] == p[3]
end

local function getEmptySlots()
  local numslots = 0
  for i = drop_slots[1], drop_slots[2] do
    if turtle.getItemCount(i) == 0 then
      numslots = numslots + 1
    end
  end
  return numslots
end

local function dig(all)
  if all == nil then all = true end
  if not state.dig_mode then return end
  while turtle.detect() do
    while turtle.suck() do if getEmptySlots() < 2 then dropOff() end end
    if turtle.dig() and getEmptySlots() < 2 then dropOff() end
    if not all then break end
    sleep(0.4)
  end
end
local function digUp(all)
  if all == nil then all = true end
  if not state.dig_mode then return end
  while turtle.detectUp() do
    while turtle.suckUp() do if getEmptySlots() < 2 then dropOff() end end
    if turtle.digUp() and getEmptySlots() < 2 then dropOff() end
    if not all then break end
    sleep(0.4)
  end
end
local function digDown()
  if not state.dig_mode then return end
  while turtle.suckDown() do if getEmptySlots() < 2 then dropOff() end end
  if turtle.digDown() and getEmptySlots() < 2 then dropOff() end
end

local move = {}
function move.forward()
  turtle.attack()
  dig()
  if turtle.getFuelLevel() <= refuel_level then refuel() end
  if turtle.forward() then
    if     (position[4] == 0) then updatePosition(3,1)
    elseif (position[4] == 1) then updatePosition(1,-1)
    elseif (position[4] == 2) then updatePosition(3,-1)
    elseif (position[4] == 3) then updatePosition(1,1)
    end
    return true
  else
    return false
  end
end
function move.back()
  if turtle.getFuelLevel() <= refuel_level then refuel() end
  if turtle.back() then
    if     (position[4] == 0) then updatePosition(3,-1)
    elseif (position[4] == 1) then updatePosition(1,1)
    elseif (position[4] == 2) then updatePosition(3,1)
    elseif (position[4] == 3) then updatePosition(1,-1)
    end
    return true
  else
    return false
  end
end
function move.up()
  turtle.attackUp()
  digUp()
  if turtle.getFuelLevel() <= refuel_level then refuel() end
  local state = turtle.up()
  if (state) then updatePosition(2,1) end
  return state
end
function move.down()
  turtle.attackDown()
  digDown()
  if turtle.getFuelLevel() <= refuel_level then refuel() end
  local state = turtle.down()
  if (state) then updatePosition(2,-1) end
  return state
end
function move.right()
  updatePosition(4,1)
  turtle.turnRight()
end
function move.left()
  updatePosition(4,-1)
  turtle.turnLeft()
end
function move.turn(d)
  if (d == nil) then return end
  while position[4] ~= d do
    local diff = position[4] - d
    if diff == 1 or diff == -3 then move.left() else move.right() end
  end
end

local function moveX(x, wait)
  if (wait == nil) then wait = false end
  local result = true
  if (position[1] == x) then return result end
  move.turn(position[1] < x and 3 or 1)
  while position[1] ~= x do
    result = move.forward()
    if (not result and not wait) then break end
  end
  return result
end
local function moveY(y, wait)
  if (wait == nil) then wait = false end
  local result = true
  if (position[2] == y) then return result end
  while position[2] ~= y do
    result = position[2] < y and move.up() or move.down()
    if (not result and not wait) then break end
  end
  return result
end
local function moveZ(z, wait)
  if (wait == nil) then wait = false end
  local result = true
  if (position[3] == z) then return result end
  move.turn(position[3] < z and 0 or 2)
  while position[3] ~= z do
    result = move.forward()
    if (not result and not wait) then break end
  end
  return result
end
local function gotoMine(p, wait)
  moveX(p[1], wait)
  moveZ(p[3], wait)
  moveY(p[2], wait)
  if (p[4] ~= nil) then move.turn(p[4]) end
end
local function gotoSimple(p, wait)
  if (wait == nil) then wait = true end
  while not inPosition(p) do
    if(p[3] == nil) then
      moveX(p[1], false)
      moveZ(p[3], false)
    else
      moveX(p[1], false)
      moveZ(p[3], false)
      moveY(p[2], false)
    end
    if wait then sleep(0.1) else break end
  end
  if (p[4] ~= nil) then move.turn(p[4]) end
end
local function pathFind(level)
  if level%5 == 0 then
    move.left()
    for cl = 0,level,1 do
      move.forward()
      cl=cl+1
    end
  elseif level%5 == 1 then
    move.left()
    for cl = 0,level,1 do
      move.forward()
      move.up()
    end
  elseif level%5 == 2 then
    move.left()
    for cl = 0,level,1 do
      move.up()
    end
  elseif level%5 == 3 then
    move.right()
    for cl = 0,level,1 do
      move.forward()
      move.up()
    end
  elseif level%5 == 4 then
    move.right()
    for cl = 0,level,1 do
      move.forward()
    end
  end
end
local function gotoSmart(p)
  if (p == nil) then return false end
  
  local last
  for tries = 0,8,1 do
    if position[2] <= p[2] then moveY(p[2]) end
    if (tries%2) == 0 then
      moveX(p[1])
      moveZ(p[3])
    else
      moveZ(p[3])
      moveX(p[1])
    end
    if position[2] > p[2] then moveY(p[2]) end
    
    if inPosition(p) then break end
    
    if inPosition(last) then
      pathFind(tries)
    end
    last = deepcopy(position)
  end
  
  if not inPosition(p) then gotoSimple(p, false) end
  if (p[4] ~= nil) then move.turn(p[4]) end
  return inPosition(p)
end

local function getOpenSpace()
  local result = {}
  if not turtle.detectUp() then
    result.place  = turtle.placeUp
    result.detect = turtle.detectUp
    result.drop   = turtle.dropUp
    result.suck   = turtle.suckUp
    result.dig    = turtle.digUp
  elseif not turtle.detectUp() then
    result.place  = turtle.placeUp
    result.detect = turtle.detectUp
    result.drop   = turtle.dropUp
    result.suck   = turtle.suckUp
    result.dig    = turtle.digUp
  elseif not turtle.detectDown() then
    result.place  = turtle.placeDown
    result.detect = turtle.detectDown
    result.drop   = turtle.dropDown
    result.suck   = turtle.suckDown
    result.dig    = turtle.digDown
  else
    result        = nil
  end
  return result
end
local function useChest(slot, callback, param)
  local chest = getOpenSpace()
  local result = false
  local op = false
  if chest ~= nil then
    turtle.select(slot)
    if chest.place() then
      result = true
      if callback ~= nil then result = callback(chest, param) end
      turtle.select(slot)
      chest.dig()
    else
      op = true
    end
  end
  if op then
    move.left()
    move.left()
    if turtle.detect() then
      turtle.select(slot)
      if turtle.place() then
        result = true
        if callback ~= nil then result = callback(chest, param) end
        turtle.select(slot)
        turtle.dig()
      end
    end
    move.left()
    move.left()
  end
  return result
end
local function dropItemsInChest(chest)
  local result = false
  if chest.detect() then
    for i = drop_slots[1], drop_slots[2] do
      turtle.select(i)
      chest.drop()
    end
    result = true
  end
  return result
end
local function getItemFromChest(chest, param)
  turtle.select(param)
  return chest.detect() and chest.suck()
end

dropOff = function ()
  if state.dropping then return true end
  if state.verbose then writeLog("Drop Off") end
  local nochest
  state.dropping = true
  state.dig_mode = false
  local resume = deepcopy(position)
  repeat
    if not useChest(drop_chest_slot, dropItemsInChest) then
      gotoSmart(drop_position)
      if turtle.detect() then
        for i = drop_slots[1], drop_slots[2] do
          turtle.select(i)
          turtle.drop()
        end
      else
        writeLog("No Chest Found")
        sleep(1)
      end
    end
  until getEmptySlots() > 1
  gotoSmart(resume)
  state.dig_mode = true
  state.dropping = false
  turtle.select(drop_slots[1])
  if state.verbose then writeLog("Resuming") end
end

local function refuelFrom(slot)
  local result
  turtle.select(slot)
  while turtle.getItemCount(slot) ~= 0 and (turtle.getFuelLevel() < refuel_level or turtle.getFuelLevel() == 0) do
    if not turtle.refuel(1) then break end
  end
end
refuel = function ()
  if state.verbose then writeLog("Refueling") end
  while turtle.getFuelLevel() == 0 do
    if turtle.getItemCount(fuel_slot) ~= 0 or useChest(fuel_chest_slot, getItemFromChest, fuel_slot) then
      if state.verbose > 1 then writeLog("Checking Fuel Slot") end
      refuelFrom(fuel_slot)
    else
      if state.verbose > 1 then writeLog("Searching Drop Slots") end
      for i = drop_slots[1], drop_slots[2] do
        refuelFrom(i)
        if turtle.getFuelLevel() >= refuel_level then break end
      end
    end
    if turtle.getFuelLevel() == 0 then sleep(1) end
  end
  turtle.select(drop_slots[1])
  if state.verbose then writeLog("Resuming") end
end

local function placeTorch(face, surface)
  local isDown, result
  isDown = face == -1
  if not isDown then move.turn(face) end
  turtle.select(torch_slot)
  result = isDown and turtle.placeDown() or turtle.place()
  return result
end
local function torch(face, surface)
  if not state.use_torches then return true end
  if surface == nil then surface = face end
  local placed = false
  if state.verbose == 1 then writeLog("Torch")
  elseif state.verbose > 1 then writeLog("Torch (" .. face .. "," .. surface .. ")") end
  repeat
    if turtle.getItemCount(torch_slot) ~= 0 or useChest(torch_chest_slot, getItemFromChest, torch_slot) then
      placed = placeTorch(face, surface)
    elseif state.torch_wait then
      sleep(1)
    end
  until placed or not state.torch_wait
  turtle.select(drop_slots[1])
end

local function getDirection(s, e)
  return {
    s[1] - e[1] <= 0 and 1 or -1,
    s[2] - e[2] <= 0 and 1 or -1,
    s[3] - e[3] <= 0 and 1 or -1
  }
end

local function mine(size)
  local current = deepcopy(position)
  current[4] = nil
  local initial = deepcopy(current)
  local final   = { initial[1] + size[1], initial[2] + size[2], initial[3] + size[3] }
  local rest    = deepcopy(position)

  local d          = getDirection(current, final)
  local y,  ye, yf = initial[2], final[2] + d[2], math.min(initial[2], final[2])
  local ya         = yf + 1
  local xs, xe, xd = nil, nil, '?'
  local zs, ze, zd = nil, nil, '?'
  local xts        = math.ceil(math.min(final[1], torch_spacing)/2)
  local zts        = math.ceil(math.min(final[3], torch_spacing)/2)
  local xf, xfi, xff, xfb, zf, zfi, zff, zfb
  local h, h2, h3
  xf, zf = '?', '?'
  if d[1] == 1 then xfi, xff = 1, 3 else xfi, xff = 3, 1 end
  if d[3] == 1 then zfi, zff = 2, 0 else zfi, zff = 0, 2 end
  if d[2] == 1 then h2, h3 = digDown, digUp else h2, h3 = digUp, digDown end
  
  if state.verbose > 0 then writeLog("Mining") end
  state.dig_mode = true
  if state.verbose > 1 then writeLog("yf: " .. yf .. "  xts: " .. xts .. "  zts: " .. zts) end
  turtle.select(drop_slots[1])
  -- Y axis
  while y ~= final[2] + d[2] do
    -- check if mining above and/or below would help
    if y == final[2] then
      h = 1
    elseif y + d[2] == final[2] then
      h = 2
      y = y + d[2]
    else
      h = 3
      y = y + d[2]
    end
    current[2] = y
    gotoMine(current)
    if state.verbose > 2 then writeLog("Y: " .. formatPosition(position) .. " h=" .. h .. " xf=" .. xf .." xd=" .. xd .. " zf=" .. zf .." zd=" .. zd) end

    -- Z axis
    if current[3] == initial[3] then
      zs, ze, zd = initial[3], final[3],  d[3]
    else
      zs, ze, zd = final[3], initial[3], -d[3]
    end
    if state.use_torches then
      zfb = zd == 1 and 2 or 0
    end

    for z = zs,ze,zd do
      current[3] = z
      gotoMine(current)
      if state.verbose > 2 then writeLog("Z: " .. formatPosition(position) .. " h=" .. h .. " xf=" .. xf .." xd=" .. xd .. " zf=" .. zf .." zd=" .. zd) end

      -- X axis
      if current[1] == initial[1] then
        xs, xe, xd = initial[1], final[1],  d[1]
      else
        xs, xe, xd = final[1], initial[1], -d[1]
      end
      if state.use_torches then
        xfb = xd == 1 and 1 or 3
        zf = math.fmod(current[3], torch_spacing)
      end
      
      for x = xs,xe,xd do
        current[1] = x
        gotoMine(current)
        if h > 1 then h2() end
        if h > 2 then h3() end
        if state.verbose > 2 then writeLog("X: " .. formatPosition(position) .. " h=" .. h .. " xf=" .. xf .." xd=" .. xd .. " zf=" .. zf .." zd=" .. zd) end
        
        -- Over grown torch placement
        if state.use_torches then
          xf = math.fmod(current[1], torch_spacing)
              if current[3] == initial[3]        and zd ~= d[3] and xf - xd == xts then torch(xfb)
          elseif current[3] == final[3]          and zd == d[3] and xf - xd == xts then torch(xfb)
          elseif current[3] == initial[3] + d[3] and zd == d[3] and xf      == xts then torch(zfi)
          elseif current[3] == final[3]   - d[3] and zd ~= d[3] and xf      == xts then torch(zff)
          elseif current[1] == initial[1]        and                zf - zd == zts then torch(zfb)
          elseif current[1] == final[1]          and                zf - zd == zts then torch(zfb)
          elseif current[2] == yf and zf == zts + zd and xf == xts then torch(zfb, -1)
          elseif current[2] == yf and xf == xts + xd and zf == zts then torch(xfb, -1)
          elseif current[2] == ya and zf == zts + zd and xf == xts then move.down() torch(zfb, -1) move.up()
          elseif current[2] == ya and xf == xts + xd and zf == zts then move.down() torch(xfb, -1) move.up()
          end
        end
        
        sleep(0)
      end
    end

    -- adjust for height
    if h == 3 then y = y + d[2] end
    y = y + d[2]
  end
  state.dig_mode = false
  gotoSmart(drop_position)
  dropOff()
  gotoSimple(rest)
  if state.verbose then writeLog("Done") end
end

local function usage()
  print("usage: mine [options] -- <x> <y> <z>")
  print()
  print("  -f level  set minimum fuel level")
  print("  -l file   log verbose output to file")
  print("  -n        no torches")
  print("  -s space  set the torch spacing")
  print("  -t        wait for torches if out")
  print("  -v level  enable verbose output")
  print()
  print("Drop EC: " .. drop_chest_slot)
  print("Torch: " .. torch_slot .. " (EC: " .. torch_chest_slot .. ")")
  print("Fuel: " .. fuel_slot .. " (EC: " .. fuel_chest_slot .. ")")
end
local function main(...)
  local tArgs = {}
  for opt, arg in getopt(":f:l:ns:tv:", ...) do
    if     opt == 'f' then refuel_level = tonumber(arg)
    elseif opt == 'l' then state.log_file = arg
    elseif opt == 'n' then state.use_torches = false
    elseif opt == 's' then torch_spacing = tonumber(arg)
    elseif opt == 't' then state.torch_wait = true
    elseif opt == 'v' then state.verbose = tonumber(arg)
    else                   table.insert(tArgs, arg)
    end
  end
  if #tArgs == 3 then
    mine({tonumber(tArgs[1]), tonumber(tArgs[2]), tonumber(tArgs[3]), 0})
  else
    usage()
  end
end

main(...)