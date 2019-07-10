
local composer = require( "composer" )

local widget = require( "widget" )

local scene = composer.newScene()

-- -----------------------------------------------------------------------------------
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via "composer.removeScene()"
-- -----------------------------------------------------------------------------------
 
local physics = require( "physics" )
physics.start()
physics.setGravity( 0, 0 )

-- image sheet for blue orb (upgrade)
local sheetOptionsBlueOrb =
{
    width = 318,
    height = 318,
    numFrames = 6,
}

-- sequences table
local sequences_blueOrb = {
    -- consecutive frames sequence
    {
        name = "blueOrb",
        start = 1,
        count = 6,
        time = 800,
        loopCount = 0,
        loopDirection = "forward"
    }
}
-- image sheet for explode
local sheetOptionsExplode =
{
    width = 128,
    height = 128,
    numFrames = 3,
}

-- sequences table
local sequences_explode = {
    -- consecutive frames sequence
    {
        name = "explode",
        start = 1,
        count = 3,
        time = 500,
        loopCount = 0,
        loopDirection = "forward"
    }
}
-- 設定 image sheet
local sheetOptions =
{
    frames =
    {
        {   -- 1) 隕石 1
            x = 0,
            y = 0,
            width = 102,
            height = 85
        },
        {   -- 2) 隕石 2
            x = 0,
            y = 85,
            width = 90,
            height = 83
        },
        {   -- 3) 隕石 3
            x = 0,
            y = 168,
            width = 100,
            height = 97
        },
        {   -- 4) 太空船 4
            x = 0,
            y = 265,
            width = 98,
            height = 79
        },
        {   -- 5) 雷射 5
            x = 98,
            y = 265,
            width = 14,
            height = 40
        },
    },
}
local objectSheet = graphics.newImageSheet( "gameObjects.png", sheetOptions )
local blueOrbSheet = graphics.newImageSheet( "blueOrbs.png", sheetOptionsBlueOrb )
local explodeSheet = graphics.newImageSheet( "explodeSheet.png", sheetOptionsExplode )

-- 初始化變數
local lives = 3
local bossLives = 200
local bossLivesMax = bossLives
local score = 0
local died = false
local stopLaser = false
 
local asteroidsTable = {}
 
local ship
local boss
local gameLoopTimer
local laserLoopTimer
local bossLoopTimer
local livesText
local scoreText
local bossLifeBar
local skillBtn

local backGroup = display.newGroup()
local mainGroup = display.newGroup()
local uiGroup = display.newGroup()

local explosionSound
local fireSound
local musicTrack
local bossMusicTrack
local bg1
local bg2
local runtime = 0
local scrollSpeed = 1.4

local bossPhase = false

local function addScrollableBg()
    local bgImage = { type="image", filename="background.png" }

    -- Add First bg image
    bg1 = display.newRect(backGroup, 0, 0, 800, 1400)
    bg1.fill = bgImage
    bg1.x = display.contentCenterX
    bg1.y = display.contentCenterY

    -- Add Second bg image
    bg2 = display.newRect(backGroup, 0, 0, 800, 1400)
    bg2.fill = bgImage
    bg2.x = display.contentCenterX
    bg2.y = display.contentCenterY - 1400
end


local function moveBg(dt)
    bg1.y = bg1.y + scrollSpeed * dt
    bg2.y = bg2.y + scrollSpeed * dt

    if (bg1.y - display.contentHeight/2) > 1400 then
        bg1:translate(0, -bg1.contentHeight * 2)
    end
    if (bg2.y - display.contentHeight/2) > 1400 then
        bg2:translate(0, -bg2.contentHeight * 2)
    end
end


local function getDeltaTime()
   local temp = system.getTimer()
   local dt = (temp-runtime) / (1000/60)
   runtime = temp
   return dt
end


local function enterFrame()
    local dt = getDeltaTime()
    moveBg(dt)
end


local function updateText()
    livesText.text = "Lives: " .. lives
    scoreText.text = "Score: " .. score
    if ( bossPhase == true ) then
       bossLifeBar:setProgress( bossLives/bossLivesMax )
   end
end

 
local function createAsteroid()
 
    local newAsteroid = display.newImageRect( mainGroup, objectSheet, 1, 102, 85 )
    table.insert( asteroidsTable, newAsteroid )
    physics.addBody( newAsteroid, "dynamic", { radius=40, bounce=0.8 } )
    newAsteroid.myName = "asteroid"
 
    local whereFrom = math.random( 3 )

    if ( whereFrom == 1 ) then
        -- 來自左邊
        newAsteroid.x = -60
        newAsteroid.y = math.random( 500 )
        newAsteroid:setLinearVelocity( math.random( 40,120 ), math.random( 20,60 ) )
    elseif ( whereFrom == 2 ) then
        -- 來自上方
        newAsteroid.x = math.random( display.contentWidth )
        newAsteroid.y = -60
        newAsteroid:setLinearVelocity( math.random( -40,40 ), math.random( 40,120 ) )
    elseif ( whereFrom == 3 ) then
        -- 來自右邊
        newAsteroid.x = display.contentWidth + 60
        newAsteroid.y = math.random( 500 )
        newAsteroid:setLinearVelocity( math.random( -120,-40 ), math.random( 20,60 ) )
    end

    newAsteroid:applyTorque( math.random( -6,6 ) )
end
 
 
local function fireLaser()

	if ( stopLaser == true )then
		return
	end
 
    -- 播放雷射音效!
    audio.play( fireSound )
 
    local newLaser = display.newImageRect( mainGroup, objectSheet, 5, 14, 40 )
    physics.addBody( newLaser, "dynamic", { isSensor=true } )
    newLaser.isBullet = true
    newLaser.myName = "laser"
 
    newLaser.x = ship.x
    newLaser.y = ship.y
    newLaser:toBack()
 
    transition.to( newLaser, { y=-40, time=500,
        onComplete = function() display.remove( newLaser ) end
    } )
end

local function missleExplode(x, y)
    local explode = display.newSprite( uiGroup, explodeSheet, sequences_explode )
	physics.addBody( explode, "dynamic", { isSensor = true, radius=300} )
	explode:play()
	explode:scale( 5, 5 )
	explode.x = x
	explode.y = y
	explode:toBack();
    explode.myName = "explode"
    transition.to( explode, { alpha = 0, time=2000,
        onComplete = function() display.remove( explode ) end
    } )
end

local function useSkill()

	if (stopLaser == true)then
		return
	end

	local missle = display.newImageRect( mainGroup, "missle.png", 100, 100)
    missle.x = display.contentCenterX
    missle.y = ship.y
    missle:toBack()
 
    transition.to( missle, { y=ship.y - 700, time=500,
        onComplete = function() 
        	missleExplode(missle.x,missle.y)
        	display.remove(missle)
        end
    } )
end


 
 
local function dragShip( event )
 
    local ship = event.target
    local phase = event.phase
 
    if ( "began" == phase ) then
        -- 設定Touch Event focus 在太空船上
        display.currentStage:setFocus( ship )
        -- 儲存一開始觸摸的位置
        ship.touchOffsetX = event.x - ship.x

    elseif ( "moved" == phase ) then
    	if ( ship.touchOffsetX == nil)then
        	display.currentStage:setFocus( ship )
        	ship.touchOffsetX = event.x - ship.x
    	end
        -- 移動太空船到新的位置
        ship.x = event.x - ship.touchOffsetX
 
    elseif ( "ended" == phase or "cancelled" == phase ) then
        -- 解除太空船的focus狀態
        display.currentStage:setFocus( nil )
    end
 
    return true  -- 避免Touch事件往下傳遞
end
 
 
local function gameLoop()
 
    -- 產生新的隕石
   	if ( bossPhase == false ) then
    	createAsteroid()
    end

    -- 清理螢幕外面的隕石    
    for i = #asteroidsTable, 1, -1 do
        local thisAsteroid = asteroidsTable[i]
 
        if ( thisAsteroid.x < -100 or
             thisAsteroid.x > display.contentWidth + 100 or
             thisAsteroid.y < -100 or
             thisAsteroid.y > display.contentHeight + 100 )
        then
            display.remove( thisAsteroid )
            table.remove( asteroidsTable, i )
        end
    end
end


local function bossAttack()
	-- 播放雷射音效!
    audio.play( fireSound )
 
    local newLaser = display.newImageRect( mainGroup, objectSheet, 5, 14, 40 )
    physics.addBody( newLaser, "dynamic", { isSensor=true } )
    newLaser.isBullet = true
    newLaser.myName = "asteroid"
 
    newLaser.x = boss.x
    newLaser.y = boss.y
    newLaser:toBack()
 
    transition.to( newLaser, { y=boss.y+800, time=500,
        onComplete = function() display.remove( newLaser ) end
    } )
end

local function bossLoop()
	bossAttack()
end
 
 
local function restoreShip()
 
    ship.isBodyActive = false
    ship.x = display.contentCenterX
    ship.y = display.contentHeight - 100
    stopLaser = false
 
    -- 讓太空船淡入
    transition.to( ship, { alpha=1, time=4000,
        onComplete = function()
            ship.isBodyActive = true
            died = false
        end
    } )
end

local function bossMovement()

	transition.to(boss,{time=1000, x=math.random(80,680), y=math.random(30,580), onComplete=bossMovement})
end

local function createBoss()

    audio.stop(1)
	audio.play( bossMusicTrack, { channel=1, loops=-1 } )
	boss = display.newImageRect( mainGroup, "ufo.png", 200, 200 )
	boss.alpha = 0
	boss.x = display.contentCenterX
	boss.y = 200
	physics.addBody( boss, { radius=60, isSensor=true } )
	boss.isBodyActive = false
	boss.myName = "boss"
	bossLifeBar = widget.newProgressView(
	    {
	        left = 50,
	        top = 100,
	        width = display.contentWidth - 100,
	        isAnimated = true
	    }
	)
	bossLifeBar:setProgress( 1 )
	-- 讓太空船淡入
    transition.to( boss, { alpha=1, time=2000,
        onComplete = function()
			boss.isBodyActive = true
			bossMovement()
    		bossLoopTimer = timer.performWithDelay( 500, bossLoop, 0 )
        end
    } )

end

local function createBlueOrb( event )
    local blueOrb = display.newSprite( mainGroup, blueOrbSheet, sequences_blueOrb )
	physics.addBody( blueOrb, "dynamic", { radius=20, isSensor=true } )
	blueOrb:play()
	blueOrb:scale( 0.2, 0.2 )
	blueOrb.x = event.source.params.x
	blueOrb.y = event.source.params.y
	blueOrb:toBack();
    blueOrb.myName = "upgradeBlueOrb"
    transition.to( blueOrb, { y=display.contentHeight+40, time=3000,
        onComplete = function() display.remove( blueOrb ) end
    } )
end
 

local function endGame()
    composer.setVariable( "finalScore", score )
    composer.gotoScene( "highscores", { time=800, effect="crossFade" } )
end
 

local function onCollision( event )
 
    if ( event.phase == "began" ) then
 
        local obj1 = event.object1
        local obj2 = event.object2
 
        if ( ( obj1.myName == "laser" and obj2.myName == "asteroid" ) or
             ( obj1.myName == "asteroid" and obj2.myName == "laser" ) )
        then

        	local upgradeGenRate = math.random( 100 )

        	if ( upgradeGenRate >= 50 ) then
        		local _asteroid
        		if ( obj1.myName == "asteroid" ) then
        			_asteroid = obj1
        		else
        			_asteroid = obj2
        		end
        		local tm = timer.performWithDelay( 50, createBlueOrb )
        		tm.params = {x = _asteroid.x, y = _asteroid.y}
        		
        	end

            -- 移除雷射與隕石
            display.remove( obj1 )
            display.remove( obj2 )
 
            -- 播放爆炸音效!
            audio.play( explosionSound )
 
            for i = #asteroidsTable, 1, -1 do
                if ( asteroidsTable[i] == obj1 or asteroidsTable[i] == obj2 ) then
                    table.remove( asteroidsTable, i )
                    break
                end
            end

            -- 更新分數
            score = score + 100
            updateText()
            if ( score >= 3000 ) then
            	for i = #asteroidsTable, 1, -1 do
            		display.remove( asteroidsTable[i] )
	                table.remove( asteroidsTable, i )
	            end
        		if ( bossPhase == false )then
        			bossPhase = true
	            	timer.performWithDelay(50, createBoss)
	            end
            end

        elseif ( ( obj1.myName == "ship" and obj2.myName == "asteroid" ) or
                 ( obj1.myName == "asteroid" and obj2.myName == "ship" ) )
        then
            if ( died == false ) then
                died = true
                stopLaser = true

                -- 播放爆炸音效!
            	audio.play( explosionSound )
 
                -- 更新生命值
                lives = lives - 1
                livesText.text = "Lives: " .. lives
 
                if ( lives == 0 ) then
                    display.remove( ship )
                    timer.performWithDelay( 2000, endGame )
                else
                    ship.alpha = 0
                    timer.performWithDelay( 1000, restoreShip )
                end
            end
        elseif ( ( obj1.myName == "laser" and obj2.myName == "boss" ) or
                 ( obj1.myName == "boss" and obj2.myName == "laser" ) )
        then
            -- 播放爆炸音效!
            audio.play( explosionSound )
            if ( obj1.myName == "laser" ) then
            	display.remove( obj1 )
            else
            	display.remove( obj2 )
            end
            bossLives = bossLives - 1
            score = score + 500
            if (bossLives <= 0) then
                display.remove( ship )
                display.remove( boss )
                timer.performWithDelay( 2000, endGame )
            end
            updateText()
        elseif ( ( obj1.myName == "ship" and obj2.myName == "upgradeBlueOrb" ) or
                 ( obj1.myName == "upgradeBlueOrb" and obj2.myName == "ship" ) )
        then

        	if ( obj1.myName == "upgradeBlueOrb" ) then
        		display.remove(obj1)
        	else
        		display.remove(obj2)
        	end
        	lives = lives + 1
        	laserLoopTimer._delay = laserLoopTimer._delay*0.9
            updateText()
        elseif ( ( obj1.myName == "asteroid" and obj2.myName == "explode" ) or
                 ( obj1.myName == "explode" and obj2.myName == "asteroid" ) )
        then

        	for i = #asteroidsTable, 1, -1 do
                if ( asteroidsTable[i] == obj1 or asteroidsTable[i] == obj2 ) then
                    display.remove(asteroidsTable[i])
                    table.remove( asteroidsTable, i )
                    break
                end
            end
        elseif ( ( obj1.myName == "boss" and obj2.myName == "explode" ) or
                 ( obj1.myName == "explode" and obj2.myName == "boss" ) )
        then
        	bossLives = bossLives - 20
        	updateText()
        end
    end
end


-- -----------------------------------------------------------------------------------
-- Scene event functions
-- -----------------------------------------------------------------------------------

-- create()
function scene:create( event )

	local sceneGroup = self.view
	-- Code here runs when the scene is first created but has not yet appeared on screen

    physics.pause()  -- 暫時停止物理引擎

    -- 設定 Display groups
	backGroup = display.newGroup()  -- 放背景圖片的 Display group
    sceneGroup:insert( backGroup )  -- 將backGroup放入scene的display group

	mainGroup = display.newGroup()  -- 放隕石、太空船、雷射等遊戲物件的 Display group
    sceneGroup:insert( mainGroup )  -- 將mainGroup放入scene的display group

	uiGroup = display.newGroup()    -- 放UI物件，像是得分版的 Display group
    sceneGroup:insert( uiGroup )  	-- 將uiGroup放入scene的display group

    -- 載入背景
	addScrollableBg()

	ship = display.newImageRect( mainGroup, objectSheet, 4, 98, 79 )
	ship.x = display.contentCenterX
	ship.y = display.contentHeight - 100
	physics.addBody( ship, { radius=30, isSensor=true } )
	ship.myName = "ship"

	-- 顯示生命與記分板
	livesText = display.newText( uiGroup, "Lives: " .. lives, 200, 10, native.systemFont, 36 )
	scoreText = display.newText( uiGroup, "Score: " .. score, 400, 10, native.systemFont, 36 )

    -- ship:addEventListener( "tap", fireLaser )
    ship:addEventListener( "touch", dragShip )

    -- 加入按鈕
    skillBtn = widget.newButton({defaultFile="missle.png",onRelease=useSkill})
    skillBtn.x = display.contentWidth-100
    skillBtn.y = display.contentHeight-10
    skillBtn.cd = 5
    backGroup:insert(skillBtn)

    explosionSound = audio.loadSound( "audio/explosion.wav" )
    fireSound = audio.loadSound( "audio/fire.wav" )
    musicTrack = audio.loadStream( "audio/80s-Space-Game_Looping.wav")
    bossMusicTrack = audio.loadStream( "audio/toby fox - UNDERTALE Soundtrack - 98 Battle Against a True Hero.mp3")
end


-- show()
function scene:show( event )
 
    local sceneGroup = self.view
    local phase = event.phase
 
    if ( phase == "will" ) then
        -- Code here runs when the scene is still off screen (but is about to come on screen)
 
    elseif ( phase == "did" ) then
        -- Code here runs when the scene is entirely on screen
        physics.start()
        Runtime:addEventListener( "collision", onCollision )
        Runtime:addEventListener( "enterFrame", enterFrame )
        gameLoopTimer = timer.performWithDelay( 500, gameLoop, 0 )
        laserLoopTimer = timer.performWithDelay( 500, fireLaser, 0 )
        -- 播放背景音樂!
        audio.play( musicTrack, { channel=1, loops=-1 } )
    end
end


-- hide()
function scene:hide( event )
 
    local sceneGroup = self.view
    local phase = event.phase
 
    if ( phase == "will" ) then
        -- Code here runs when the scene is on screen (but is about to go off screen)
        display.remove(bossLifeBar)
        display.remove(skillBtn)
        timer.cancel( gameLoopTimer )
        timer.cancel( laserLoopTimer )
        timer.cancel( bossLoopTimer )
 
    elseif ( phase == "did" ) then
        -- Code here runs immediately after the scene goes entirely off screen
        Runtime:removeEventListener( "collision", onCollision )
        Runtime:removeEventListener( "enterFrame", enterFrame );
        physics.pause()
        -- 停止音樂!
        audio.stop( 1 )
        composer.removeScene( "game" )
    end
end


-- destroy()
function scene:destroy( event )
 
    local sceneGroup = self.view
    -- Code here runs prior to the removal of scene's view
    -- 釋放音效!
    audio.dispose( explosionSound )
    audio.dispose( fireSound )
    audio.dispose( musicTrack )
end


-- -----------------------------------------------------------------------------------
-- Scene event function listeners
-- -----------------------------------------------------------------------------------
scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )
-- -----------------------------------------------------------------------------------

return scene
