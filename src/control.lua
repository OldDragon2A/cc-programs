local dig = false
local attack = false

function forward()
  if attack then turtle.attack() end
  if turtle.detect() and dig then turtle.dig() end
  if turtle.getFuelLevel() == 0 then print("Out of Fuel")
  elseif turtle.forward() then print("Moved Forward - Fuel: " .. turtle.getFuelLevel())
  else print("Did Not Move")
  end
end
function back()
  if turtle.getFuelLevel() == 0 then print("Out of Fuel")
  elseif turtle.back() then print("Moved Back - Fuel: " .. turtle.getFuelLevel())
  else print("Did Not Move")
  end
end
function up()
  if attack then turtle.attackUp() end
  if turtle.detectUp() and dig then turtle.digUp() end
  if turtle.getFuelLevel() == 0 then print("Out of Fuel")
  elseif turtle.up() then print("Descended - Fuel: " .. turtle.getFuelLevel())
  else print("Did not move")
  end
end
function down()
  if attack then turtle.attackDown() end
  if turtle.detectDown() and dig then turtle.digDown() end
  if turtle.getFuelLevel() == 0 then print("Out of Fuel")
  elseif turtle.down() then print("Ascended - Fuel: " .. turtle.getFuelLevel())
  else print("Did not move")
  end
end
function right()
  turtle.turnRight()
  print("Turned Right")
end
function left()
  turtle.turnLeft()
  print("Turned Left")
end

function refuel(ammount)
  if ammount == nil then ammount = 1 end
  for i = 1, 16 do
    if turtle.getItemCount(i) ~= 0 then
      turtle.select(i)
      if turtle.refuel(ammount) then
        print("Refueled - Fuel: " .. turtle.getFuelLevel())
        return
      end
    end
  end
  print("No Fuel Found")
end

print("Controls:")
print("  Arrow Keys - Move")
print("         a/z - Ascend/Descend")
print("         A/d - Toggle Attack/Dig Mode")
print("         r/R - Refuel/Refuel Stack")
print("           q - Release")
print("")
print('Assuming Control')
print("Attack Mode " .. (dig and "On" or "Off"))
print("Dig Mode " .. (dig and "On" or "Off"))
while (true) do
  event, key = os.pullEvent()
  if     key == 203 then left()
  elseif key == 200 then forward()
  elseif key == 205 then right()
  elseif key == 208 then back()
  elseif key == 'a' then up()
  elseif key == 'z' then down()
  elseif key == 'A' then attack = not attack print("Attack Mode " .. (dig and "On" or "Off"))
  elseif key == 'd' then dig = not dig print("Dig Mode " .. (dig and "On" or "Off"))
  elseif key == 'r' then refuel()
  elseif key == 'R' then refuel(64)
  elseif key == 'q' then break
  end
end
print('Releasing Control')