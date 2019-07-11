-----------------------------------------------------------------------------------------
--
-- game.lua
--
-----------------------------------------------------------------------------------------

local composer = require( "composer" )

local scene = composer.newScene()

-- -----------------------------------------------------------------------------------
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via "composer.removeScene()"
-- -----------------------------------------------------------------------------------
local physics = require( "physics" )
physics.start()
physics.setGravity( 0, 0 )

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

-- 初始化變數
local lives = 3
local score = 0
local died = false
 
local asteroidsTable = {}
 
local ship
local gameLoopTimer
local livesText
local scoreText

-- 設定 Display groups
local backGroup
local mainGroup
local uiGroup


local function updateText()
    livesText.text = "Lives: " .. lives
    scoreText.text = "Score: " .. score
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
 
 
local function dragShip( event )
 
    local ship = event.target
    local phase = event.phase
 
    if ( "began" == phase ) then
        -- 設定Touch Event focus 在太空船上
        display.currentStage:setFocus( ship )

        ship.isFocus = true
        -- 儲存一開始觸摸的位置
        ship.touchOffsetX = event.x - ship.x

    elseif ( "moved" == phase ) then

        if ( ship.isFocus == false ) then
            -- 設定Touch Event focus 在太空船上
            display.currentStage:setFocus( ship )

            ship.isFocus = true
            -- 儲存一開始觸摸的位置
            ship.touchOffsetX = event.x - ship.x
        end
        -- 移動太空船到新的位置
        ship.x = event.x - ship.touchOffsetX
 
    elseif ( "ended" == phase or "cancelled" == phase ) then
        -- 解除太空船的focus狀態
        display.currentStage:setFocus( nil )
        ship.isFocus = false
    end
 
    return true  -- 避免Touch事件往下傳遞
end
 
 
local function gameLoop()
 
    -- 產生新的隕石
    createAsteroid()

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
 
 
local function restoreShip()
 
    ship.isBodyActive = false
    ship.x = display.contentCenterX
    ship.y = display.contentHeight - 100
 
    -- 讓太空船淡入
    transition.to( ship, { alpha=1, time=4000,
        onComplete = function()
            ship.isBodyActive = true
            died = false
        end
    } )
end

local function endGame()
    composer.setVariable("finalScore", score);
    composer.gotoScene( "highscores", { time=800, effect="crossFade" } )
end
 
 
local function onCollision( event )
 
    if ( event.phase == "began" ) then
 
        local obj1 = event.object1
        local obj2 = event.object2
 
        if ( ( obj1.myName == "laser" and obj2.myName == "asteroid" ) or
             ( obj1.myName == "asteroid" and obj2.myName == "laser" ) )
        then
            -- 移除雷射與隕石
            display.remove( obj1 )
            display.remove( obj2 )
 
            for i = #asteroidsTable, 1, -1 do
                if ( asteroidsTable[i] == obj1 or asteroidsTable[i] == obj2 ) then
                    table.remove( asteroidsTable, i )
                    break
                end
            end

            -- 更新分數
            score = score + 100
            updateText()

        elseif ( ( obj1.myName == "ship" and obj2.myName == "asteroid" ) or
                 ( obj1.myName == "asteroid" and obj2.myName == "ship" ) )
        then
            if ( died == false ) then
                died = true
 
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
        end
    end
end

-- -----------------------------------------------------------------------------------
-- Scene event functions
-- -----------------------------------------------------------------------------------

-- create()
function scene:create( event )

    local sceneGroup = self.view
    physics.pause()
    -- Code here runs when the scene is first created but has not yet appeared on screen
    -- 設定 Display groups
    backGroup = display.newGroup()  -- 放背景圖片的 Display group
    sceneGroup:insert( backGroup )  -- 將backGroup放入scene的display group

    mainGroup = display.newGroup()  -- 放隕石、太空船、雷射等遊戲物件的 Display group
    sceneGroup:insert( mainGroup )  -- 將mainGroup放入scene的display group

    uiGroup = display.newGroup()    -- 放UI物件，像是得分版的 Display group
    sceneGroup:insert( uiGroup )    -- 將uiGroup放入scene的display group

    -- 載入背景
    local background = display.newImageRect( backGroup, "background.png", 800, 1400 )
    background.x = display.contentCenterX
    background.y = display.contentCenterY

    ship = display.newImageRect( mainGroup, objectSheet, 4, 98, 79 )
    ship.x = display.contentCenterX
    ship.y = display.contentHeight - 100
    physics.addBody( ship, { radius=30, isSensor=true } )
    ship.myName = "ship"
    ship.isFocus = false


    -- 顯示生命與記分板
    livesText = display.newText( uiGroup, "Lives: " .. lives, 200, 80, native.systemFont, 36 )
    scoreText = display.newText( uiGroup, "Score: " .. score, 400, 80, native.systemFont, 36 )

    ship:addEventListener( "tap", fireLaser )
    ship:addEventListener( "touch", dragShip )
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
        gameLoopTimer = timer.performWithDelay( 500, gameLoop, 0 )
    end
end


-- hide()
function scene:hide( event )

    local sceneGroup = self.view
    local phase = event.phase

    if ( phase == "will" ) then
        -- Code here runs when the scene is on screen (but is about to go off screen)
        timer.cancel( gameLoopTimer )
    elseif ( phase == "did" ) then
        -- Code here runs immediately after the scene goes entirely off screen
        Runtime:removeEventListener( "collision", onCollision )
        physics.pause()
        composer.removeScene( "game" )
    end
end


-- destroy()
function scene:destroy( event )

    local sceneGroup = self.view
    -- Code here runs prior to the removal of scene's view

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
