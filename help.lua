-- help screen for chain

-- load background
local background = Graphics.loadImage("app0:/assets/bg.png")
local arrow_left = Graphics.loadImage("app0:/assets/arrow_left.png")

-- menu vars
local oldpad = SCE_CTRL_RTRIGGER -- input init
local current_menu = 0 -- menu position
local return_value = false

-- draw function
local function help_draw()
	-- init
	Graphics.initBlend()
	
	-- plot the background (this one is a bit larger)
	Graphics.drawImage(0,0, background)
	
	-- go back img
	Graphics.drawImage(850, 500, arrow_left)
	
	-- text field background
	Graphics.fillRect(
		120,
		820,
		40,
		400,
		Color.new(229,144,134,235)) -- little bit alpha

	-- set font size
	Font.setPixelSizes(main_font, 25)
	
	Font.print(main_font, 140, 60, "This game is about touching the right spot \nto create the right chain reaction.", white)

	Graphics.termBlend()
	Screen.flip()
end

local function help_user_input()
	local pad = Controls.read()
	
	-- select
	if (Controls.check(pad, SCE_CTRL_CROSS) and not Controls.check(oldpad, SCE_CTRL_CROSS)) or (Controls.check(pad, SCE_CTRL_CIRCLE) and not Controls.check(oldpad, SCE_CTRL_CIRCLE)) then
		-- go back to menu
		return_value = current_menu
	end
	
	-- read touch control
	local x, y = Controls.readTouch()

	-- first input only
	if x ~= nil then
		-- any touch go back to menu
		return_value = current_menu
	end
	
	-- remember
	oldpad = pad
end

-- main menu call
function help()
	-- gameloop
	while not return_value do
		help_draw()
		help_user_input()
	end
	
	-- free it again
	Graphics.freeImage(background)
	Graphics.freeImage(arrow_left)
	
	-- return
	game.state = return_value
end

help()
