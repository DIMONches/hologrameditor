local term = require('term')
local fs = require('filesystem')
local com = require('component')
local gpu = com.gpu

--   Константы   --
HOLOH = 32
HOLOW = 48

--     Цвета     --
backcolor = 0x000000
forecolor = 0xFFFFFF
infocolor = 0x0066FF
errorcolor = 0xFF0000
helpcolor = 0x00FF00
--      ***      --

-- ============================================= G R A P H I C S ============================================= --
-- проверка разрешения экрана, для комфортной работы необходимо разрешение > HOLOW по высоте и ширине
WIDTH, HEIGHT = gpu.getResolution()
if HEIGHT < HOLOW then 
  WIDTH, HEIGHT = gpu.maxResolution()
  if HEIGHT < HOLOW then
    print("[ОШИБКА] Ваш монитор/видеокарта не поддерживает требуемое разрешение.")
    return false
  else
    gpu.setResolution(WIDTH, HEIGHT)
  end
end

-- рисуем линию
local strLine = "+"
for i=1, width do
  strLine = strLine..'-'
end
function line(x1, x2, y)
  gpu.set(x1,y,string.sub(strLine, 1, x2-x1))
  gpu.set(x2,y,'+')
end

-- рисуем фрейм
function frame(x1, y1, x2, y2, caption)
  line(x1, x2, y1)
  line(x1, x2, y2)

  if caption ~= nil then
    gpu.set(x1+(x2-x1)/2-#caption/2, y1, caption)
  end
end


-- ========================================= H O L O G R A P H I C S ========================================= --
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


-- =========================================== M A I N   C Y C L E =========================================== --



-- end
term.clear()