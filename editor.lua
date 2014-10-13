local unicode = require('unicode')
local event = require('event')
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
graycolor = 0x080808
--      ***      --

-- ============================================= G R A P H I C S ============================================= --
-- проверка разрешения экрана, для комфортной работы необходимо разрешение > HOLOW по высоте и ширине
OLDWIDTH, OLDHEIGHT = gpu.getResolution()
WIDTH, HEIGHT = gpu.maxResolution()
if HEIGHT < HOLOW+2 then
  --print("[ОШИБКА] Ваш монитор/видеокарта не поддерживает требуемое разрешение.")
  error("[ОШИБКА] Ваш монитор/видеокарта не поддерживает требуемое разрешение.")
  --return false
else
  WIDTH = HOLOW*2+40
  HEIGHT = HOLOW+2
  gpu.setResolution(WIDTH, HEIGHT)
end
gpu.setForeground(forecolor)
gpu.setBackground(backcolor)

-- рисуем линию
local strLine = "+"
for i=1, WIDTH do
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
    gpu.set(x1+(x2-x1)/2-unicode.len(caption)/2, y1, caption)
  end
end

-- рисуем сетку
local strGrid = ""
for i=1, HOLOW/2 do
  strGrid = strGrid.."██  "
end
function drawGrid(x, y)
  gpu.setForeground(graycolor)
  for i=0, HOLOW-1 do
    gpu.set(x+(i%2)*2, y+i, strGrid)
  end
  gpu.setForeground(forecolor)
end

-- рисуем цветной прямоугольник
function drawRect(x, y, color)
  gpu.set(x, y,   "╓──────╖")
  gpu.set(x, y+1, "║      ║")
  gpu.set(x, y+2, "╙──────╜")
  gpu.setForeground(color)
  gpu.set(x+2, y+1, "████")
  gpu.setForeground(forecolor)
end

MENUX = HOLOW*2+5

-- рисуем меню выбора "кисти"
function drawColorSelector()
  frame(MENUX, 3, WIDTH-2, 16, "[ Цвета ]")
  for i=0, 3 do
    drawRect(MENUX+1+i*8, 5, colortable[i])
  end
end
function drawLayerSelector()
  frame(MENUX, 16, WIDTH-2, 21, "[ Слой ]")
end
function drawButtonsPanel()
  frame(MENUX, 21, WIDTH-2, 32, "[ Управление ]")
end

function mainScreen()
  term.clear()
  frame(1,1, WIDTH, HEIGHT, "{ Hologram Editor }")
  -- "холст"
  drawGrid(3,2)
  drawColorSelector()
  drawLayerSelector()
  drawButtonsPanel()
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
-- инициализация
colortable = {0xFF0000, 0x00FF00, 0x0066FF}
colortable[0] = 0x000000

mainScreen()
event.pull('key_down')

-- завершение
term.clear()
gpu.setResolution(OLDWIDTH, OLDHEIGHT)