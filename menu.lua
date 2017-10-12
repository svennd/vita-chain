-- menu file for chain

-- vita constants
local DISPLAY_WIDTH = 960
local DISPLAY_HEIGHT = 544

-- color definitions
local white 	= Color.new(255, 255, 255)
local black 	= Color.new(0, 0, 0)

-- load background
local background = Graphics.loadImage("app0:/assets/bg.png")

-- load font
local main_font = Font.load("app0:/assets/ArchivoNarrow-Regular.ttf")

-- draw function
function draw()
	-- init
	Graphics.initBlend()
	
	-- plot the background (this one is a bit larger)
	Graphics.drawImage(0,0, background)
	
	-- set font size
	Font.setPixelSizes(main_font, 30)
	
	-- plot menu back
	Graphics.fillRect(
		587,
		895,
		62,
		361,
		Color.new(229,144,134,235)) -- little bit alpha
	
	-- menu options
	-- start
	Graphics.fillRect(
		598,
		880,
		78,
		161,
		Color.new(234,182,143))
	Font.print(main_font, 645, 99, "START", white)
		
	-- help
	Graphics.fillRect(
		598,
		880,
		78,
		161,
		Color.new(234,182,143))
	Font.print(main_font, 645, 193, "HELP", white)
		
	-- exit
	Graphics.fillRect(
		598,
		880,
		78,
		161,
		Color.new(234,182,143))
	Font.print(main_font, 645, 284, "EXIT", white)
		
	Graphics.termBlend()
	Screen.flip()
end

local oldpad = SCE_CTRL_RTRIGGER

MENU = {START = 1, HELP = 2, EXIT = 3, MIN = 1, MAX = 3}

current_menu = 0

function user_input()
	local pad = Controls.read()
	
	-- select
	if (Controls.check(pad, SCE_CTRL_CROSS) and not Controls.check(oldpad, SCE_CTRL_CROSS)) or (Controls.check(pad, SCE_CTRL_CIRCLE) and not Controls.check(oldpad, SCE_CTRL_CIRCLE)) then
		-- pick choise
		
	-- down
	elseif Controls.check(pad, SCE_CTRL_DOWN) and not Controls.check(oldpad, SCE_CTRL_DOWN) then
		current_menu = current_menu + 1
		if current_menu < MENU.MAX then
			current_menu = 1
		end
		
	-- up
	elseif Controls.check(pad, SCE_CTRL_UP) and not Controls.check(oldpad, SCE_CTRL_UP) then
		current_menu = current_menu - 1
		if current_menu < MENU.MIN then
			current_menu = 3
		end
	end
	
	-- remember
	opad = pad
	
	-- read touch control
	local x, y = Controls.readTouch()

	-- first input only
	if x ~= nil then
		user.x = x
		user.y = y
	end
end

-- main menu call
function menu()
	-- gameloop
	while true do
		draw()
		user_input()
	end
end


-- call menu function
menu()
