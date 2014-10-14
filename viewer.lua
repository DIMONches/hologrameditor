-- загрузка API
local c= require("component")
local fs= require("filesystem")

-- загрузка оборудование--
local h= c.hologram

-- создание и инициализация перемменых--
HOLOH = 32
HOLOW = 48
backcolor = 0x000000
forecolor = 0xFFFFFF
infocolor = 0x0066FF
errorcolor = 0xFF0000
helpcolor = 0x006600
graycolor = 0x080808
goldcolor = 0xFFDF00

holo= {}
holo[1]= {}
holo[1][1]= {}

-- преобразование цветов

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

-- рисование голограммы на проэкторе
function draw()
	for x=1,HOLOW do
		for y=1,HOLOH do
			for z=1,HOLOW do
				if holo[x][y][z] == nil then error("array holo = nil ,fill it")
				h.set(x,y,z,holo[x][y][z])
			end
		end
	end
end
-- загрузка голограммы в массив

function load(filename)
  if filename == nil
  then
     filename= "hologram.3d"
  end
  if fs.exists(filename) then
    file = io.open(filename, 'rb')
    -- загружаем палитру
    for i=1, 3 do
      for c=1, 3 do
        colortable[i][c] = string.byte(file:read(1))
      end
      hexcolortable[i] = 
        rgb2hex(colortable[i][1],
                colortable[i][2],
                colortable[i][3])
    end
    -- загружаем массив
    holo = {}
    for x=1, HOLOW do
      for y=1, HOLOH do
        for z=1, HOLOW, 4 do
          byte = string.byte(file:read(1))
          for i=0, 3 do
            a = byte % 4
            byte = math.floor(byte / 4)
            if a ~= 0 then holo[x][y][z+i]= a end
          end
        end
      end
    end
    file:close()
    return true
  else
    error("[ОШИБКА] Файл "..filename.." не найден.")
  end
end


-- главная функция

function main()

   loadfile(nil)
   draw()

end
main()