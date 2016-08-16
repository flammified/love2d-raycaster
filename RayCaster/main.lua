local lines = {}
local char = {x = 350, y = 350, fovdeg = 0, fov = 60}
local map = {x = 0, y = 0, width = 512, height = 393}
local texture
local gunImage

function newLine(x1,y1,x2,y2)
	local line = {}
	line.x1 = x1
	line.y1 = y1
	line.x2 = x2
	line.y2 = y2
	return line
end


function raycast(x, y, fovdeg, fov)
	--Formula intersection point:
	--Formula 1 is the wall
	--Formula 2 is the ray
	--P = Y2 - Y1
	--Q = X1 - X2
	--R = P*X1 + Q*Y1
	--d = P1*Q2 - P2*Q1.

	--X3 = (Q2*R1 - Q1*R2)/d
	--Y3 = (P1*R2 - P2*R1)/d

	local values = {}

	for i = (fovdeg - fov/2), fovdeg + fov/2, fov/map.width do
		local distances = {}
		--print (fovdeg - fov/2)
		--print (fovdeg + fov/2)
		if i > 360 then
			i = i - 360
		elseif i < 0 then
			i = i + 360
		end
		love.graphics.setColor(0, 0, 255)
		local ray = {}
		ray.x1 = x
		ray.y1 = y
		ray.x2 = ray.x1 + 200 * math.cos(math.rad(i))
		ray.y2 = ray.y1 + 200 * math.sin(math.rad(i))
		ray.p = ray.y2 - ray.y1
		ray.q = ray.x1 - ray.x2
		ray.r = (ray.p * ray.x1) + (ray.q * ray.y1)

		for key, line in ipairs(lines) do
			--Use the formulas to calculate the intersection point if there is any
			local d = (line.p * ray.q) - (ray.p*line.q)
			if (d ~= 0) then
				intersection = {}
				intersection.fovdeg = fovdeg
				intersection.i = i
				intersection.line = line
				intersection.x  =((ray.q*line.r) - (line.q*ray.r))/d
				intersection.y  =((line.p*ray.r) - (ray.p*line.r))/d

				--Calculate the distance to the player
				local a = intersection.x - char.x
				local b = intersection.y - char.y
				local dir = math.atan2(b,a)
				while dir > math.pi*2 do
					dir = dir-math.pi*2
				end
				while dir < 0 do
					dir = dir+math.pi*2
				end
					if ( math.abs(dir - math.rad(i)) < 0.01 ) then
						if (intersection.x >= math.min(line.x1, line.x2)-.001 and
						intersection.x <= math.max(line.x1, line.x2)+.001 and
						intersection.y >= math.min(line.y1, line.y2)-.001 and
						intersection.y <= math.max(line.y1, line.y2)+.001) then
							intersection.dist = math.sqrt(math.pow(a,2) + math.pow(b,2))
							table.insert(distances, intersection)
						end
					end
			else

			end

		end
		local hdist = {x = 0, y = 0, dist = 10000}
		for key, dist in ipairs(distances) do
			if dist.dist < hdist.dist then
				hdist = dist
				end
			end
		table.insert(values, hdist)

	end
	return values
end

function love.load()
	love.window.setTitle("Raycaster by Alexander Freeman & Jonathan Tonckens")
	love.window.setMode(map.width,map.height)
	love.graphics.setBackgroundColor(255,255,255)

	--Initialize the line segments
	table.insert(lines, newLine(-100,-100,500,5))
	table.insert(lines, newLine(5,5,500,5))
	table.insert(lines, newLine(500,5,500,400))
	table.insert(lines, newLine(500,400,500,500))
	table.insert(lines, newLine(5,5,5,600))
	table.insert(lines, newLine(5,600,500,500))
	table.insert(lines, newLine(250,100,130,260))
	table.insert(lines, newLine(100,350,200,470))

	--Precalculate the values
	for key, line in ipairs(lines) do
		line.p = line.y2 - line.y1
		line.q = line.x1 - line.x2
		line.r = (line.p * line.x1) + (line.q * line.y1)
	end

	texture = love.graphics.newImage("wall.png")
	gunImage = love.graphics.newImage("gun.png")
end

function map:draw(inters)
	love.graphics.setColor(255,255,255)
		for key, i in ipairs(inters) do
			if (i.fovdeg ~= nil) then
				w,h = love.graphics.getDimensions()
				b = h/2
				distanceToScreen = b/math.tan(math.rad(30))
				dist = math.cos(math.rad(i.fovdeg - i.i)) * i.dist
				heightOnScreen = 32/dist * distanceToScreen
				middleOfCanvas = map.y+(map.height/2)
				--print(dist/500*255)
				local c = dist/600*255
				if c > 255 then
					c = 255
				end
				--love.graphics.setColor(c,0,0)
				--love.graphics.line(map.x+2*key,middleOfCanvas-heightOnScreen,map.x+2*key,middleOfCanvas+heightOnScreen)
				local colum = math.sqrt((i.x-i.line.x1)*(i.x-i.line.x1)+(i.y-i.line.y1)*(i.y-i.line.y1))
				while colum > texture:getWidth() do
					colum = colum-texture:getWidth()
				end
				local q = love.graphics.newQuad(colum, 0, 1, texture:getHeight(), texture:getWidth(), texture:getHeight())
				love.graphics.draw(texture, q, map.x+key, middleOfCanvas-heightOnScreen, 0, 1, (heightOnScreen*2)/texture:getHeight())
			end
		end
end

function love.draw()
	width, height = love.graphics.getDimensions()
	love.graphics.setColor(0, 0, 0)
	love.graphics.print(love.timer.getFPS(),0,0)

	if char.fovdeg > 360 then char.fovdeg = 0 end
	if char.fovdeg < 0 then char.fovdeg = 360 end

	--Calculate the distance for all rays and populate a table with them
	love.graphics.setColor(255, 0, 0)
	local inters = raycast(char.x,char.y,char.fovdeg,char.fov)

	--draw background
	love.graphics.setColor(110, 80, 50)
	love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight()/2)
	love.graphics.setColor(127, 85, 56)
	love.graphics.rectangle("fill", 0, love.graphics.getHeight()/2, love.graphics.getWidth(), love.graphics.getHeight()/2)

	--Draw the image
	map:draw(inters)
	love.graphics.print(love.timer.getFPS(),0,0)
	--draw guns
	love.graphics.draw(gunImage, gunImage:getWidth()*5, love.graphics.getHeight()-gunImage:getHeight()*5, 0, -5, 5)
	love.graphics.draw(gunImage, love.graphics.getWidth()-gunImage:getWidth()*5, love.graphics.getHeight()-gunImage:getHeight()*5, 0, 5, 5)
end

function love.update(dt)
	local x = love.mouse.getX()
	local y = love.mouse.getY()

	if (love.keyboard.isDown("left")) then
		char.fovdeg = char.fovdeg - 110 * dt
	end
	if (love.keyboard.isDown("right")) then
		char.fovdeg = char.fovdeg + 110 * dt
	end
	if (love.keyboard.isDown("w") or love.keyboard.isDown("up")) then
		char.x = char.x + 5*math.cos(math.rad(char.fovdeg))
		char.y = char.y + 5*math.sin(math.rad(char.fovdeg))
	end
	if (love.keyboard.isDown("a")) then
		char.x = char.x - 5*math.cos(math.rad(char.fovdeg) + math.rad(90))
		char.y = char.y - 5*math.sin(math.rad(char.fovdeg) + math.rad(90))
	end
	if (love.keyboard.isDown("s") or love.keyboard.isDown("down")) then
		char.x = char.x - 5*math.cos(math.rad(char.fovdeg))
		char.y = char.y - 5*math.sin(math.rad(char.fovdeg))
	end
	if (love.keyboard.isDown("d")) then
		char.x = char.x + 5*math.cos(math.rad(char.fovdeg) + math.rad(90))
		char.y = char.y + 5*math.sin(math.rad(char.fovdeg) + math.rad(90))
	end

end

function love.mousepressed(x, y, button)

end

function love.mousereleased(x, y, button)

end

function indexOf(t,val) --copied from stackoverflow

end
