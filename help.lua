-- help screen for chain

-- load background
local img_background = Graphics.loadImage("app0:/assets/bg.png")
local img_touch = Graphics.loadImage("app0:/assets/touch.png")
local img_help = Graphics.loadImage("app0:/assets/help_mechanism.png")

-- font
local fnt_main = Font.load("app0:/assets/xolonium.ttf")

-- menu vars
local oldpad = SCE_CTRL_RTRIGGER -- input init
local return_value = false
local screen = {current = 1, max = 3}
local play = Timer.new()
local last_input = 0
local animate_touch = 1
local animate_touch_direction = 1

-- draw function
local function help_draw()
	-- init
	Graphics.initBlend()
	
	-- plot the background (this one is a bit larger)
	Graphics.drawImage(0,0, img_background)
		
	-- text field background
	Graphics.fillRect(
		120,
		830,
		40,
		400,
		Color.new(229,144,134,235)) -- little bit alpha

	-- set font size
	Font.setPixelSizes(fnt_main, 25)
	
	if screen.current == 1 then
		-- text
		Font.print(fnt_main, 140, 60, "This game uses the front touch screen of the vita.", white)
			
	elseif screen.current == 2 then
		Font.print(fnt_main, 140, 60, "The target of the game is to create a chain reaction.", white)
		
		-- mechanism
		Graphics.drawImage(140, 100, img_help)
		
	elseif screen.current == 3 then
		Font.print(fnt_main, 140, 60, "Different atoms have different effects.", white)
		
		
		Font.setPixelSizes(fnt_main, 20)
		Graphics.fillCircle(140, 100, 7, yellow)
		Font.print(fnt_main,160, 85, "size : 5     score : 10", white)
		
		Graphics.fillCircle(140, 120, 7, red)
		Font.print(fnt_main, 160, 105, "size : 4     score : 15", white)
		
		Graphics.fillCircle(140, 140, 7, green)
		Font.print(fnt_main, 160, 125, "size : 3.5  score : 25", white)
		
		Graphics.fillCircle(140, 160, 7, blue)
		Font.print(fnt_main, 160, 145, "size : 2     score : 35", white)
		
		Graphics.fillCircle(140, 180, 7, purple)
		Font.print(fnt_main, 160, 165, "size : 1.7  score : 50", white)
		
		Graphics.fillCircle(140, 200, 7, orange)
		Font.print(fnt_main, 160, 185, "size : 1.5   score : 70", white)
		
	end
	
	-- touch tip
	Graphics.drawImage(140, 100, img_touch, Color.new(255,255,255, 50 + math.floor(animate_touch/3)))
	
	Graphics.termBlend()
	Screen.flip()
end

local function go_next()
	if screen.current < screen.max then
		screen.current = screen.current + 1
	else
		return_value = MENU.MENU
	end
end

local function help_user_input()
	local pad = Controls.read()
	local now = Timer.getTime(play)
	local dt = now - last_input 
	
	-- select
	if (Controls.check(pad, SCE_CTRL_CROSS) and not Controls.check(oldpad, SCE_CTRL_CROSS)) or (Controls.check(pad, SCE_CTRL_CIRCLE) and not Controls.check(oldpad, SCE_CTRL_CIRCLE)) then
		go_next()
		last_input = now
	end
	
	if dt > 100 then -- delay of .3 s between 2 touches
		-- read touch control
		local x, y = Controls.readTouch()

		-- first input only
		if x ~= nil then
			-- any touch go back to menu
			go_next()
		end
		last_input = now
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
		-- we get about 180 fps (not essential)
		if 150*3 < animate_touch then
			animate_touch_direction = -1
		elseif animate_touch < 1 then
			animate_touch_direction = 1
		
		end
		animate_touch = animate_touch + animate_touch_direction
	end
	
	-- free it again
	Graphics.freeImage(img_help)
	Graphics.freeImage(img_touch)
	Graphics.freeImage(img_background)
	Font.unload(fnt_main)
	
	-- return
	state = return_value
end

help()
