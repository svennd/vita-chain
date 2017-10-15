-- menu file for chain

-- constants
-- for reference
local MENU = {START = 1, HELP = 2, EXIT = 3, MIN = 1, MAX = 3}

-- load background
local img_background = Graphics.loadImage("app0:/assets/bg.png")
local img_touch = Graphics.loadImage("app0:/assets/touch.png")

-- menu vars
local oldpad = SCE_CTRL_RTRIGGER -- input init
local current_menu = 1 -- menu position
local return_value = false
local animate_touch = 1
local animate_touch_direction = 1

-- draw function
local function menu_draw()
	-- init
	Graphics.initBlend()
	
	-- plot the background (this one is a bit larger)
	Graphics.drawImage(0,0, img_background)
	
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
		182,
		254,
		Color.new(234,182,143))
	Font.print(main_font, 645, 193, "HELP", white)
		
	-- exit
	Graphics.fillRect(
		598,
		880,
		273,
		345,
		Color.new(234,182,143))
	Font.print(main_font, 645, 284, "EXIT", white)
		
	-- if pad is used for controll draw that
	if current_menu ~= 0 then
		if current_menu == 1 then
			draw_box(598, 880,
				78,
				161,
				3,white)
		elseif current_menu == 2 then
			draw_box(598, 880,
				182,
				254,
				3,white)
		elseif current_menu == 3 then
			draw_box(598, 880,
				273,
				345,
				3,white)
		end
	end
	
	-- touch tip
	-- dont hide it completely
	Graphics.drawImage(880, 470, img_touch, Color.new(255,255,255, 50 + math.floor(animate_touch/3)))
	
	Graphics.termBlend()
	Screen.flip()
end

local function menu_user_input()
	local pad = Controls.read()
	
	-- select
	if (Controls.check(pad, SCE_CTRL_CROSS) and not Controls.check(oldpad, SCE_CTRL_CROSS)) or (Controls.check(pad, SCE_CTRL_CIRCLE) and not Controls.check(oldpad, SCE_CTRL_CIRCLE)) then
		-- pick choise
		if current_menu ~= 0 then
			return_value = current_menu
		end
	-- down
	elseif Controls.check(pad, SCE_CTRL_DOWN) and not Controls.check(oldpad, SCE_CTRL_DOWN) then
		current_menu = current_menu + 1
		if current_menu > MENU.MAX then
			current_menu = 1
		end
		
	-- up
	elseif Controls.check(pad, SCE_CTRL_UP) and not Controls.check(oldpad, SCE_CTRL_UP) then
		current_menu = current_menu - 1
		if current_menu < MENU.MIN then
			current_menu = 3
		end
	end
	
	
	-- read touch control
	local x, y = Controls.readTouch()

	-- first input only
	if x ~= nil then
		
		-- within bounds of buttons
		if x > 590 and x < 880 then
			if y > 78 and y < 160 then
				return_value = 1
			elseif y > 180 and y < 254 then
				return_value = 2
			elseif y > 273 and y < 345 then
				return_value = 3
			end
		end
	end
	
	-- remember
	oldpad = pad
end

-- main menu call
function menu()
	-- gameloop
	while not return_value do
		menu_draw()
		menu_user_input()
		
		-- we get about 180 fps
		if 150*3 < animate_touch then
			animate_touch_direction = -1
		elseif animate_touch < 1 then
			animate_touch_direction = 1
		
		end
		animate_touch = animate_touch + animate_touch_direction
	end
	
	-- free it again
	Graphics.freeImage(img_background)
	Graphics.freeImage(img_touch)
	
	-- return
	game.state = return_value
end

menu()
