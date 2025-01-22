function love.load()
    animations = {}

    defaultBall = {}
    defaultBall.x = love.graphics.getWidth()/2
    defaultBall.y = love.graphics.getHeight()/2
    defaultBall.size = 10
    defaultBall.speed = 300

    ball = {}
    
    defaultPaddle = {}
    defaultPaddle.height = 100
    defaultPaddle.width = 20
    defaultPaddle.speed = 300

    p1 = {}
    p1.height = defaultPaddle.height
    p1.width = defaultPaddle.width
    p1.x = 0
    p1.y = love.graphics.getHeight()/2 - p1.height/2
    p1.speed = defaultPaddle.speed
    p1.dy = 0
    p2 = {}
    p2.height = defaultPaddle.height
    p2.width = defaultPaddle.width
    p2.x = love.graphics.getWidth() - p2.width
    p2.y = love.graphics.getHeight()/2 - p2.height/2
    p2.speed = defaultPaddle.speed
    p2.dy = 0

    powers = {}

    state = "Title"
    hits = 0
    p1score = 0
    p2score = 0
    timer = 0
    paused = false
    powerUpSpawnCD = 10 --seconds
    countdownTime = powerUpSpawnCD
    startTime = 3
    computerOffset = 0

    myFont = love.graphics.newFont(40)
    music = love.audio.newSource("Lines of Code.mp3", "stream") -- the "stream" tells LÖVE to stream the file from disk, good for longer music tracks
    hit = love.audio.newSource("Kerplunk.wav", "static")
    hit:setVolume(0.5)
    powerHit = love.audio.newSource("PowerUp.ogg", "static")
    powerHit:setVolume(0.5)
    score = love.audio.newSource("Score.wav", "static")
    score:setVolume(0.25)
    scorePitch = 0.5
    music:setVolume(0.15)
    music:play()
end

local function makePowerup()
    local num = math.random(1,7)
    power = {}
    if num == 1 then
        --increase paddle size
        power.r = 0
        power.g = 1
        power.b = 0
        power.image = "PowerUp_Green.png"
        power.num = 1
    elseif num == 2 then
        --decrease opponent paddle size
        power.r = 1
        power.g = 1
        power.b = 0
        power.image = "PowerUp_Yellow.png"
        power.num = 2
    elseif num == 3 then
        --increase ball speed
        power.r = 0
        power.g = 0
        power.b = 1
        power.image = "PowerUp_Blue.png"
        power.num = 3
    elseif num == 4 then
        --decrease ball size
        power.r = 1
        power.g = 0
        power.b = 0
        power.image = "PowerUp_Red.png"
        power.num = 4
    elseif num == 5 then
        --teleport ball
        power.r = 1
        power.g = 0
        power.b = 1
        power.image = "PowerUp_Purple.png"
        power.num = 5
    elseif num == 6 then
        --reduce opposing paddle speed
        power.r = 0
        power.g = 1
        power.b = 1
        power.image = "PowerUp_Cyan.png"
        power.num = 6
    elseif num == 7 then
        --teleport opponents paddle
        power.r = 1
        power.g = 1
        power.b = 1
        power.image = "PowerUp_White.png"
        power.num = 7
    end
    power.size = 15
    power.x = math.random(love.graphics.getWidth()/7, 6*love.graphics.getWidth()/7)
    power.y = math.random(love.graphics.getHeight()/16, 15*love.graphics.getHeight()/16)
    power.imageW = 16
    power.imageH = 16
    table.insert(powers, power)
    animation = newAnimation(love.graphics.newImage(power.image), power.imageW, power.imageH, 0.5, power.x , power.y)
    table.insert(animations, animation)
end

local function getDistBetween(obj1, obj2)
    return math.sqrt((obj1.x - obj2.x)^2 + (obj1.y - obj2.y)^2)
end

local function getAngleBetween(obj, ball)
    local dx = ball.x - obj.x
    local dy = -(ball.y - obj.y) -- same as obj.y - ball.y
    local rad = math.atan2(dy, dx)
    return rad < 0 and rad + math.pi*2 or rad
end

function getClosestPointOnRectangle(x, y, width, height, pointX, pointY)
    point = {}
    if (pointX <= x and pointY <= y) then
        point.x = x
        point.y = y
    elseif (pointX <= x + width and pointY <= y)  then
        point.x = pointX
        point.y = y
    elseif (x + width <= pointX and pointY <= y)  then
        point.x = x + width
        point.y = y
    elseif (pointX <= x  and pointY <= y + height)  then
        point.x = x
        point.y = pointY
    elseif (pointX <= x + width and pointY <= y + height)  then
        point.x = pointX
        point.y = pointY
    elseif (x + width <= pointX and pointY <= y + height)  then
        point.x = x + width
        point.y = pointY
    elseif (pointX <= x  and y + height <= pointY)  then
        point.x = x
        point.y = y + height
    elseif (pointX <= x + width and y + height <= pointY)  then
        point.x = pointX
        point.y = y + height
    elseif (x + width <= pointX and y + height <= pointY)  then
        point.x = x + width
        point.y = y + height
    else
        point.x = pointX
        point.y = pointY
    end
    return point
end

local function checkPowerupCollision()
    for i, power in pairs(powers) do
        if (power.size + ball.size) >= getDistBetween(power, ball) then
            if powerHit:isPlaying() then
                powerHit:stop()
            end
            powerHit:setPitch(math.random(90,110)/100)
            powerHit:play()
            table.remove(powers, i)
            table.remove(animations, i)
            if power.num == 1 then
                --increase paddle size
                if ball.lastHit == "p1" then
                    prevHeight = p1.height
                    p1.height = p1.height * 1.25
                    p1.y = p1.y - (p1.height - prevHeight)/2
                elseif ball.lastHit == "p2" then
                    prevHeight = p2.height
                    p2.height = p2.height * 1.25
                    p2.y = p2.y - (p2.height - prevHeight)/2
                end
            elseif power.num == 2 then
                --decrease opponent paddle size
                if ball.lastHit == "p2" then
                    if p1.height > 30 then
                        prevHeight = p1.height
                        p1.height = p1.height * 0.75
                        p1.y = p1.y + (prevHeight - p1.height)/2
                    end
                elseif ball.lastHit == "p1" then
                    if p2.height > 30 then
                        prevHeight = p2.height
                        p2.height = p2.height * 0.75
                        p2.y = p2.y + (prevHeight - p2.height)/2
                    end
                end
            elseif power.num == 3 then
                --increase ball speed
                ball.speed = ball.speed * 1.1
            elseif power.num == 4 then
                --decrease ball size
                ball.size = 3*ball.size/4
            elseif power.num == 5 then
                --teleport ball
                ball.y = math.random(0, love.graphics.getHeight())
            elseif power.num == 6 then
                --reduce opposing paddle speed
                if ball.lastHit == "p1" then
                    p2.speed = p2.speed * 0.95
                elseif ball.lastHit == "p2" then
                    p1.speed = p1.speed * 0.95
                end
            elseif power.num == 7 then
                --teleport opposing paddle
                if ball.lastHit == "p1" then
                    p2.y = math.random(0, love.graphics.getHeight() - p2.height)
                elseif ball.lastHit == "p2" then
                    p1.y = math.random(0, love.graphics.getHeight() - p1.height)
                end
            end

        end
    end
end

local function moveBall(dt)
    pointP1 = getClosestPointOnRectangle(p1.x, p1.y, p1.width, p1.height, ball.x, ball.y)
    pointP2 = getClosestPointOnRectangle(p2.x, p2.y, p2.width, p2.height, ball.x, ball.y)
    
    if (ball.x < ball.size) then --p1 lost
        if score:isPlaying() then
            score:stop()
        end    
        score:setPitch(scorePitch + math.random(-10,10)/100)
        score:play()
        p2score = p2score + 1
        roundReset()
    elseif ball.x > (love.graphics.getWidth() - ball.size) then --p2 lost
        if score:isPlaying() then
            score:stop()
        end
        score:setPitch(scorePitch + math.random(-10,10)/100)
        score:play()
        p1score = p1score + 1
        roundReset()
    elseif ball.y < ball.size then
        ball.dy = ball.dy * -1
        ball.y = ball.size
    elseif ball.y > (love.graphics.getHeight() - ball.size) then
        ball.dy = ball.dy * -1
        ball.y = love.graphics.getHeight() - ball.size
    elseif (getDistBetween(pointP1, ball) <= ball.size) then
        --p1 hits the ball
        hits = hits + 1
        if math.fmod(hits, 3) == 0 then
            makePowerup()
        end
        if math.fmod(hits, 5) == 0 then
            p1.speed = p1.speed * 1.1
            p2.speed = p2.speed * 1.1
            ball.speed = ball.speed * 1.1
        end
        if hit:isPlaying() then
            hit:stop()
        end
        hit:setPitch(math.random(90,110)/100)
        hit:play()
        ball.lastHit = "p1"
        local center ={}
        center.x = p1.x
        center.y = p1.y + (p1.height/2)
        ball.angle = getAngleBetween(center, ball)
        ball.dx = math.cos(ball.angle)
        ball.dy = -1 * math.sin(ball.angle)
    elseif (getDistBetween(pointP2, ball) <= ball.size) then
        --p2 hits the ball
        computerOffset = math.random(-4*(p2.height/2)/5, 4*(p2.height/2)/5)
        hits = hits + 1
        if math.fmod(hits, 3) == 0 then
            makePowerup()
        end
        if math.fmod(hits, 5) == 0 then
            p1.speed = p1.speed + 0.2
            p2.speed = p2.speed + 0.2
            ball.speed = ball.speed + 0.2
        end
        hit:setPitch(math.random(90,110)/100)
        hit:play()
        ball.lastHit = "p2"
        local center = {}
        center.x = p2.width  + p2.x
        center.y = p2.y + (p2.height/2)
        ball.angle = getAngleBetween(center, ball)
        ball.dx = math.cos(ball.angle)
        ball.dy = -1 * math.sin(ball.angle)
    elseif (0 < (ball.y - p2.y)) and ((ball.y - p2.y) < p1.height) and (ball.x > (love.graphics.getWidth() - (p2.width + ball.size))) then
    end
    ball.x = ball.x + ball.speed * ball.dx * dt
    ball.y = ball.y + ball.speed * ball.dy * dt
    checkPowerupCollision()
end

local function movePaddles(paddle, dt)
    if paddle.y < 0 then
        paddle.y = 0
    elseif paddle.y > love.graphics.getHeight()-paddle.height then
        paddle.y = love.graphics.getHeight()-paddle.height
    else
        paddle.y = paddle.y + (paddle.speed * paddle.dy) * dt
    end
end

function roundReset()
    ball.x = love.graphics.getWidth()/2
    ball.y = love.graphics.getHeight()/2
    ball.angle = math.random(2 * math.pi)
    while ((3*math.pi/8 < ball.angle) and (ball.angle < 5*math.pi/8)) or ((11*math.pi/8 < ball.angle) and (ball.angle < 13*math.pi/8)) do
        ball.angle = math.random(2 * math.pi)
    end
    --ball.angle = 0
    ball.speed = defaultBall.speed
    ball.size = defaultBall.size
    ball.dx = math.cos(ball.angle)
    ball.dy = math.sin(ball.angle)
    ball.lastHit = nil
    p1.speed = defaultPaddle.speed
    p2.speed = defaultPaddle.speed
    p1.height = defaultPaddle.height
    p2.height = defaultPaddle.height
    p1.width = defaultPaddle.width
    p2.width = defaultPaddle.width
    p1.x = 0
    p1.y = love.graphics.getHeight()/2 - p1.height/2
    p2.x = love.graphics.getWidth() - p2.width
    p2.y = love.graphics.getHeight()/2 - p2.height/2
    powers = {}
    animations = {}
    startTime = 1.5
    if state == "Practice" then
        state = "PReady"
    elseif state == "Active" then
        state = "AReady"
    end
end

local function spawnPowerUp(dt)
    countdownTime = countdownTime - dt
    if  countdownTime <= 0 then
         makePowerup()
         countdownTime = countdownTime + powerUpSpawnCD
    end
end

local function moveInsaneComputerPaddle()
    p2.y = ball.y - p2.height/2
end

local function moveComputerPaddle(dt)
    if ball.y + computerOffset > (p2.y + p2.height/2) then
        p2.y = p2.y + p2.speed*dt
    elseif ball.y + computerOffset == p2.y + p2.height/2 then
        --do nothing
    else
        p2.y = p2.y - p2.speed*dt
    end
end

local function startingGame(dt)
    startTime = startTime - dt
    if  startTime <= 0 then
        if state == "PReady" then
            state = "Practice"
        elseif state == "AReady" then
            state = "Active"
        end
    end
end

function love.update(dt)
    if not music:isPlaying( ) then
		music:play()
	end
    for i, animation in pairs(animations) do
        animation.currentTime = animation.currentTime + dt
        if animation.currentTime >= animation.duration then
            animation.currentTime = animation.currentTime - animation.duration
        end
    end
    if state == "Active" then
        moveBall(dt)
        spawnPowerUp(dt)
        movePaddles(p1, dt)
        movePaddles(p2, dt)
    elseif state == "PReady" or state == "AReady" then
        startingGame(dt)
    elseif state == "Practice" then
        moveBall(dt)
        spawnPowerUp(dt)
        movePaddles(p1, dt)
        moveComputerPaddle(dt)
        movePaddles(p2, dt)
    end
end

local function drawCenteredText(rectX, rectY, rectWidth, rectHeight, text)
	local font       = love.graphics.getFont()
	local textWidth  = font:getWidth(text)
	local textHeight = font:getHeight()
	love.graphics.print(text, rectX+rectWidth/2, rectY+rectHeight/2, 0, 1, 1, textWidth/2, textHeight/2)
end

function newAnimation(image, width, height, duration, x, y)
    local animation = {}
    animation.spriteSheet = image;
    animation.quads = {};
    animation.x = x
    animation.y = y
    animation.width = width
    animation.height = height
    for y = 0, image:getHeight() - height, height do
        for x = 0, image:getWidth() - width, width do
            table.insert(animation.quads, love.graphics.newQuad(x, y, width, height, image:getDimensions()))
        end
    end
    animation.offset = math.random(0, #animation.quads)
    animation.duration = duration or 1
    animation.currentTime = 0

    return animation
end

function love.draw()
    if state == "Title" then
        love.graphics.setColor(1,1,1)
        love.graphics.setFont(myFont)
        local w, h = 120, 40
        local x, y = (love.graphics.getWidth()/2)-w/2, 0
        drawCenteredText(x, y, w, h, "SPACE = Start | P = Practice")
        
    elseif state == "Active" or state == "Practice" or state == "AReady" or state == "PReady" then
        love.graphics.setColor(1,1,1)
        love.graphics.setFont(myFont)
        local w, h = 120, 40
        local x, y = (love.graphics.getWidth()/2)-w/2, 0
        love.graphics.rectangle("line", x, y, w, h)
        drawCenteredText(x, y, w, h, p1score.." - "..p2score)
        love.graphics.setColor(1,0,0)
        love.graphics.rectangle("fill", p1.x, p1.y, p1.width, p1.height)
        love.graphics.setColor(0,0,1)
        love.graphics.rectangle("fill", p2.x, p2.y, p2.width, p2.height)
        love.graphics.setColor(1,1,1)
        love.graphics.circle("fill", ball.x, ball.y, ball.size)
    end

    --for i,power in pairs(powers) do
    --    love.graphics.setColor(power.r, power.g, power.b)
    --    love.graphics.circle("line", power.x, power.y, power.size)
    --end

    love.graphics.setColor(1,1,1)
    for i, animation in pairs(animations) do
        local spriteNum = (math.floor(animation.currentTime / animation.duration * #animation.quads)) + 1
        love.graphics.draw(animation.spriteSheet, animation.quads[(spriteNum + animation.offset)%#animation.quads + 1], animation.x - (4*animation.width/2), animation.y - (4*animation.height/2), 0, 4)
    end
end

function love.keypressed( key, scancode, isrepeat )
    if state == "Active" or state == "Practice" then
        if key == "w" then
            p1.dy = -1
        elseif key == "s" then
            p1.dy = 1
        elseif key == "up" then
            p2.dy = -1
        elseif key == "down" then
            p2.dy = 1
        end
    elseif state == "Title" then
        if key == "p" then
            roundReset()
            state = "PReady"
        elseif key == "space" then
            roundReset()
            state = "AReady"
        end
    end
end

function love.keyreleased(key)
    if key == "w" or key == "s" then
        p1.dy = 0
    elseif key == "up" or key == "down" then
        p2.dy = 0
    end
end


