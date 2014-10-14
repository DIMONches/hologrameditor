-- загрузка API
local c= require("component")
local fs= require("filesystem")

-- загрузка оборудование--
local h= c.hologram

-- создание и инициализация переменных--
HOLOH = 32
HOLOW = 48

holo= {}
holo[1]= {}
holo[1][1]= {}
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
