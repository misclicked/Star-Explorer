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