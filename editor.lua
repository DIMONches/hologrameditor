local unicode = require('unicode')
local event = require('event')
local term = require('term')
local fs = require('filesystem')
local com = require('component')
local gpu = com.gpu
local h= com.hologram

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
goldcolor = 0xFFDF00
--      ***      --
-- Инициализация --
holo = {}
holo[1]= {}
holo[1][1]= {}

-- ========================================= H O L O G R A P H I C S ========================================= --

function set(x, y, z, value)
  if holo[x] == nil then holo[x] = {} end
  if holo[x][y] == nil then holo[x][y] = {} end
  holo[x][y][z] = value
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
    return true
  else
    --print("[ОШИБКА] Файл "..filename.." не найден.")
    return false
  end
end


-- ============================================= G R A P H I C S ============================================= --
-- проверка разрешения экрана, для комфортной работы необходимо разрешение > HOLOW по высоте и ширине
OLDWIDTH, OLDHEIGHT = gpu.getResolution()
WIDTH, HEIGHT = gpu.maxResolution()
if HEIGHT < HOLOW+2 then
  error("[ОШИБКА] Ваш монитор/видеокарта не поддерживает требуемое разрешение.")
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
  gpu.fill(x, y, HOLOW, HOLOW, ' ')
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
BUTTONW = 12

-- рисуем меню выбора "кисти"
function drawColorSelector()
  frame(MENUX, 3, WIDTH-2, 16, "[ Цвета ]")
  for i=0, 3 do
    drawRect(MENUX+1+i*8, 5, hexcolortable[i])
  end
  gpu.set(MENUX+1, 10, "R:")
  gpu.set(MENUX+1, 11, "G:")
  gpu.set(MENUX+1, 12, "B:")
end
function drawColorCursor(force)
  if brush.color*8 ~= brush.x then brush.x = brush.color*8 end
  if force or brush.gx ~= brush.x then
    gpu.set(MENUX+1+brush.gx, 8, "        ")
    if brush.gx < brush.x then brush.gx = brush.gx + 1 end
    if brush.gx > brush.x then brush.gx = brush.gx - 1 end
    gpu.set(MENUX+1+brush.gx, 8, " -^--^- ")
  end
end
function drawLayerSelector()
  frame(MENUX, 16, WIDTH-2, 23, "[ Слой ]")
  gpu.set(MENUX+13, 18, "Уровень голограммы:")
end
function drawButtonsPanel()
  frame(MENUX, 23, WIDTH-2, 34, "[ Управление ]")
end

function mainScreen()
  term.clear()
  frame(1,1, WIDTH, HEIGHT, "{ Hologram Editor }")
  -- "холст"
  drawLayer()
  drawColorSelector()
  drawColorCursor(true)
  drawLayerSelector()
  drawButtonsPanel()
  buttonsDraw()
  textboxesDraw()
  gpu.set(MENUX, HEIGHT-2, "Выход: 'Q' или ")
end
function drawHologram()
   h.clear()
   for x=1,#holo do
      for y=1,#holo[x] do
         for z=1,#holo[x][y] do
            if holo[x][y][z] ~= nil
              then
                 h.set(x,y,z,holo[x][y][z])
              end
         end
      end      
   end

end


-- =============================================== L A Y E R S =============================================== --
GRIDX = 3
GRIDY = 2
function drawLayer()
  drawGrid(GRIDX, GRIDY)
  for x=1, HOLOW do
    for z=1, HOLOW do
      n = get(x, layer, z)
      if n ~= 0 then
        gpu.setForeground(hexcolortable[n])
        gpu.set((GRIDX-2) + x*2, (GRIDY-1) + z, "██")
      end
    end
  end
  gpu.setForeground(forecolor)
end
function fillLayer()
  for x=1, HOLOW do
    for z=1, HOLOW do
      set(x, layer, z, brush.color)
    end
  end
  drawLayer()
end
function clearLayer()
  for x=1, HOLOW do
    if holo[x] ~= nil then holo[x][layer] = nil end
  end
  drawLayer()
end


-- ============================================== B U T T O N S ============================================== --
Button = {}
Button.__index = Button
function Button.new(func, x, y, text, color, width)
  self = setmetatable({}, Button)

  self.form = '[ '
  if width == nil then width = 0
    else width = (width - unicode.len(text))-4 end
  for i=1, math.floor(width/2) do
    self.form = self.form.. ' '
  end
  self.form = self.form..text
  for i=1, math.ceil(width/2) do
    self.form = self.form.. ' '
  end
  self.form = self.form..' ]'

  self.func = func

  self.x = x; self.y = y
  self.color = color
  self.visible = true

  return self
end
function Button:draw(color)
  if self.visible then
    local color = color or self.color
    gpu.setBackground(color)
    if color > 0x888888 then gpu.setForeground(backcolor) end
    gpu.set(self.x, self.y, self.form)
    gpu.setBackground(backcolor)
    if color > 0x888888 then gpu.setForeground(forecolor) end
  end
end
function Button:click(x, y)
  if self.visible then
    if y == self.y then
      if x >= self.x and x <= self.x+#self.form then
        self.func()
        self:draw(self.color/2)
        os.sleep(0.1)
        self:draw()
        return true
      end
    end
  end
  return false
end
buttons = {}
function buttonsNew(func, x, y, text, color, width)
  table.insert(buttons, Button.new(func, x, y, text, color, width))
end 
function buttonsDraw()
  for i=1, #buttons do
    buttons[i]:draw()
  end
end
function buttonsClick(x, y)
  for i=1, #buttons do
    buttons[i]:click(x, y)
  end
end

-- ================================ B U T T O N S   F U N C T I O N A L I T Y ================================ --
function exit() running = false end
function nextLayer()
  if layer < HOLOH then 
    layer = layer + 1
    tb_layer:setValue(layer)
    tb_layer:draw(true)
    drawLayer()
  end
end
function prevLayer()
  if layer > 1 then 
    layer = layer - 1 
    tb_layer:setValue(layer)
    tb_layer:draw(true)
    drawLayer()
  end
end
function setLayer(value)
  n = tonumber(value)
  if n == nil or n < 1 or n > HOLOH then return false end
  layer = n
  drawLayer()
  return true
end

function rgb2hex(r,g,b)
  return r*65536+g*256+b
end

function changeRed(value) return changeColor(1, value) end
function changeGreen(value) return changeColor(2, value) end
function changeBlue(value) return changeColor(3, value) end
function changeColor(rgb, value)
  if value == nil then return false end
  n = tonumber(value)
  if n == nil or n < 0 or n > 255 then return false end
  -- сохраняем данные в таблицу
  colortable[brush.color][rgb] = n
  hexcolortable[brush.color] = 
      rgb2hex(colortable[brush.color][1],
              colortable[brush.color][2],
              colortable[brush.color][3])
  -- обновляем цвета на панельке
  for i=0, 3 do
    drawRect(MENUX+1+i*8, 5, hexcolortable[i])
  end
  return true
end


-- ============================================ T E X T B O X E S ============================================ --
Textbox = {}
Textbox.__index = Textbox
function Textbox.new(func, x, y, value, width)
  self = setmetatable({}, Textbox)

  self.form = '>'
  if width == nil then width = 10 end
  for i=1, width-1 do
    self.form = self.form..' '
  end

  self.func = func
  self.value = tostring(value)

  self.x = x; self.y = y
  self.visible = true

  return self
end
function Textbox:draw(content)
  if self.visible then
    if content then gpu.setBackground(graycolor) end
    gpu.set(self.x, self.y, self.form)
    if content then gpu.set(self.x+2, self.y, self.value) end
    gpu.setBackground(backcolor)
  end
end
function Textbox:click(x, y)
  if self.visible then
    if y == self.y then
      if x >= self.x and x <= self.x+#self.form then
        self:draw(false)
        term.setCursor(self.x+2, self.y)
        value = string.sub(term.read({self.value}), 1, -2)
        if self.func(value) then
          self.value = value
        end
        self:draw(true)
        return true
      end
    end
  end
  return false
end
function Textbox:setValue(value)
  self.value = tostring(value)
end
textboxes = {}
function textboxesNew(func, x, y, value, width)
  textbox = Textbox.new(func, x, y, value, width)
  table.insert(textboxes, textbox)
  return textbox
end 
function textboxesDraw()
  for i=1, #textboxes do
    textboxes[i]:draw(true)
  end
end
function textboxesClick(x, y)
  for i=1, #textboxes do
    textboxes[i]:click(x, y)
  end
end


-- =========================================== M A I N   C Y C L E =========================================== --
-- инициализация
hexcolortable = {0xFF0000, 0x00FF00, 0x0066FF}
hexcolortable[0] = 0x000000
colortable = {{255, 0, 0}, {0, 255, 0}, {0, 102, 255}}
colortable[0] = {0, 0, 0}
brush = {color = 1, x = 8, gx = 8}
layer = 1
running = true

buttonsNew(exit, WIDTH-BUTTONW-2, HEIGHT-2, 'Выход', errorcolor, BUTTONW)
buttonsNew(drawLayer, MENUX+1, 14, 'Обновить', goldcolor, BUTTONW)
buttonsNew(prevLayer, MENUX+1, 19, '-', infocolor, 5)
buttonsNew(nextLayer, MENUX+7, 19, '+', infocolor, 5)
buttonsNew(clearLayer, MENUX+1, 21, 'Очистить', infocolor, BUTTONW)
buttonsNew(fillLayer, MENUX+2+BUTTONW, 21, 'Залить', infocolor, BUTTONW)
tb_red = textboxesNew(changeRed, MENUX+5, 10, '255', WIDTH-MENUX-7)
tb_green = textboxesNew(changeGreen, MENUX+5, 11, '0', WIDTH-MENUX-7)
tb_blue = textboxesNew(changeBlue, MENUX+5, 12, '0', WIDTH-MENUX-7)
tb_layer = textboxesNew(setLayer, MENUX+13, 19, '1', WIDTH-MENUX-15)
mainScreen()

while running do
  if brush.x ~= brush.gx then name, add, x, y, b = event.pull(0.02)
  else name, add, x, y, b = event.pull(1.0) end

  if name == 'key_down' then 
    -- если нажата 'Q' - выходим
    if y == 16 then break end
  elseif name == 'touch' then
    buttonsClick(x, y)
    textboxesClick(x, y)

    -- выбор цвета
    if x>MENUX+1 and x<MENUX+37 then
      if y>4 and y<8 then
        brush.color = math.floor((x-MENUX-1)/8)
        tb_red:setValue(colortable[brush.color][1]); tb_red:draw(true)
        tb_green:setValue(colortable[brush.color][2]); tb_green:draw(true)
        tb_blue:setValue(colortable[brush.color][3]); tb_blue:draw(true)
      end
    end
  end
  if name == 'touch' or name == 'drag' then
    -- "рисование"
    if x>=GRIDX and x<GRIDX+HOLOW*2 then
      if y>=GRIDY and y<GRIDY+HOLOW then
        dx = math.floor((x-GRIDX)/2)+1
        dy = y-GRIDY+1
        if b == 0 then
          set(dx, layer, dy, brush.color)
          gpu.setForeground(hexcolortable[brush.color])
        else
          set(dx, layer, dy, 0)
          gpu.setForeground(hexcolortable[0])
        end
        gpu.set((GRIDX-2) + dx*2, (GRIDY-1) + dy, "██")
        gpu.setForeground(forecolor)
      end
    end
  end
<<<<<<< HEAD
       drawHologram()
=======

  drawColorCursor()
>>>>>>> 468a45dbc94ceaa0a9fc9af63b77d065f583d76a
end

-- завершение
term.clear()
gpu.setResolution(OLDWIDTH, OLDHEIGHT)