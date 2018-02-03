-- chain for vita, by svennd, slightly modded by Eix
-- version 0.2
-- application variables
VERSION = "0.2"

local MENU = {MENU = 0, START = 1, HELP = 2, EXIT = 3, MIN = 1, MAX = 3}
local state = MENU.MENU

-- font
local fnt_main = Font.load("app0:/assets/xolonium.ttf")

-- temp
store_writes = ""

handle = System.openFile("ux0:/data/file.txt", FCREATE)
function dmsg(msg)
	if string.len(store_writes) < 100 then
		store_writes = store_writes .. msg
	else
		System.writeFile(handle, store_writes .. msg, string.len(store_writes .. msg))
		store_writes = ""
	end
end

-- main function
function main()
	
	-- try to get out, I dare you.
	while true do
		if state == MENU.MENU then
			-- loading screen
			-- menu
			-- adapts state
			dofile("app0:/menu.lua")
			
		elseif state == MENU.START then
			dofile("app0:/game.lua")
		
		elseif state == MENU.HELP then
			-- help returns to game.state = 0
			dofile("app0:/help.lua")
			
		elseif state == MENU.EXIT then
			-- exit
			clean_exit()
		end	
	end
	
	-- end of execution
	-- fuck restarting the goddamn app.
	clean_exit()
end

-- close all resources
-- while not strictly necessary, its clean
function clean_exit()
	
	-- font
	Font.unload(fnt_main)
	-- kill app
	System.exit()
	
end

-- run the code
main()
