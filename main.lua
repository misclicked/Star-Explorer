-----------------------------------------------------------------------------------------
--
-- main.lua
--
-----------------------------------------------------------------------------------------

local composer = require( "composer" )
 
-- 隱藏狀態列
display.setStatusBar( display.HiddenStatusBar )
 
-- 設定亂數種子
math.randomseed( os.time() )
 
-- 移動到 menu 場景
composer.gotoScene( "menu" )

-- 保留頻道1給背景音樂使用
audio.reserveChannels( 1 )
-- 降低頻道1的音量至50%
audio.setVolume( 0.5, { channel=1 } )