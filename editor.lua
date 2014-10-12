local term = require('term')
local fs = require('filesystem')
local com = require('component')
local gpu = com.gpu

HOLOH = 32
HOLOW = 48

holo = {}
function set(x, y, z, brush)
  if holo[x] == nil then holo[x] = {} end
  if holo[x][y] == nil then holo[x][y] = {} end
  holo[x][y][z] = brush
end
function get(x, y, z)
  if holo[x] ~= nil and holo[x][y] ~= nil and holo[x][y][z] ~= nil then 
    return holo[x][y][z]
  else
    return 0
  end
end

function save(filename)
  file = io.open(filename, 'wb')
  for x=1, HOLOW do
    for y=1, HOLOH do
      for z=1, HOLOW, 4 do
        a = get(x,y,z)
        b = get(x,y,z+1)
        c = get(x,y,z+2)
        d = get(x,y,z+3)
        byte = d*64 + c*16 + b*4 + a
        file:write(string.char(byte))
      end
    end
  end
  file:close()
end

function load(filename)
  if fs.exists(filename) then
    file = io.open(filename, 'rb')
    holo = {}
    for x=1, HOLOW do
      for y=1, HOLOH do
        for z=1, HOLOW, 4 do
          byte = string.byte(file:read(1))
          for i=0, 3 do
            a = byte % 4
            byte = math.floor(byte / 4)
            if a ~= 0 then set(x,y,z+i, a) end
          end
        end
      end
    end
    file:close()
  else
    print("[ОШИБКА] Файл "..filename.." не найден.")
  end
end

-- init
WIDTH, HEIGHT = gpu.getResolution()



-- end
--term.clear()