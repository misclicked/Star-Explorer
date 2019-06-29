-----------------------------------------------------------------------------------------
--
-- main.lua
--
-----------------------------------------------------------------------------------------

local physics = require( "physics" )
physics.start()
physics.setGravity( 0, 0 )
 
-- 設定亂數種子
math.randomseed( os.time() )

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
        {   -- 4) 太空船
            x = 0,
            y = 265,
            width = 98,
            height = 79
        },
        {   -- 5) 雷射
            x = 98,
            y = 265,
            width = 14,
            height = 40
        },
    },
}