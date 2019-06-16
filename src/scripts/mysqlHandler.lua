--[[
	To whom it may concern, please note that this script was developed with the 
	intended usecase being FTC's internal scripting, there is no official 
	support for this script and it is recomended that you know basic database
	administration prior to attempting to use this script. If you wish to use
	any of the scripting related to this system, feel free to do so, just note
	that you will also need the file located at `./server/lib/luasql/mysql.so` 
	to actually use this script.
]]--
local driver = require "luasql.mysql"

local mysqlHandler = {}
	
	--Check if LuaSQL is installed correctly
	env = assert (driver.mysql())

	--Confirm script is loaded correctly
	function mysqlHandler.init()
		local message = "FTC-MySQLHandler loaded."
		mysqlHandler.logger(message)
	end

	--For testing if database can be connected to
	--Returns true if successful
	--Returns false if not
	function mysqlHandler.testDB(usr, pass, DB, IP, port)
		if DB ~= nil then
			mysqlHandler.logger("Testing connection to DB " .. DB)
			if IP == nil then
				IP = "localhost"
			end
			if port == nil then
				port = "3306"
			end
			con = env:connect(DB, usr, pass, IP, port)
			con:close()
			--env:close()
			if con ~= nil then
				mysqlHandler.logger("Test successful for DB " .. DB)
				return true
			else
				mysqlHandler.logger("Test failed for DB " .. DB)
			end
		else
			mysqlHandler.logger("testDB called with nil DB, aborting.")
		end
	end

	--Note, none of this is escaped so be real careful what you execute
	--Like, REALLY GOD DAMN CAREFUL
	--I will not be held accountable for any 'DROP TABLES *;' shenanigans
	--Only manditory inputs are "query, usr, pass, DB", rest are auto assigned to local and 3306 if not given
	function mysqlHandler.manualQuery(query, usr, pass, DB, IP, port, pid)
		local executee = ""
		if pid ~= nil then
			executee = Players[pid].name
		else
			executee = "SYSTEM"
		end
		if usr ~= nil and pass ~= nil and query ~= nil and DB ~= nil then
			if IP == nil then
				IP = "localhost"
			end
			if port == nil then
				port = "3306"
			end
			con = assert(env:connect( DB, usr, pass, IP, port))
			con:execute(string.format(query))
			con:close()
			tes3mp.LogMessage(enumerations.log.INFO, "TB Test executed by " .. executee)
			mysqlHandler.queryLog(query)
		else
			tes3mp.LogMessage(enumerations.log.INFO, "Query requested with invalid data from " .. executee)
		end
	end

	--Gets total rows with `val` in `column` in `tableName`
	--Returns 0 if none, incase you weren't sure
	function mysqlHandler.getTotalRows(column, val, tableName, usr, pass, DB, IP, port)
		local SQLInput = "SELECT id FROM " .. tableName .. " WHERE " .. column .. " = '" .. val .. "'"
		local con = assert(env:connect( DB, usr, pass, IP, port))
		local res = con:execute(string.format(SQLInput))
		local resf = res:numrows()
		mysqlHandler.queryLog(SQLInput)
		con:close()
		return resf
	end


	--Message function
	function mysqlHandler.messageRelay(pid, message)
		tes3mp.SendMessage(pid, color.Cyan .. "[MySQL]: " .. color.LightCyan .. message, false)
	end

	--Logger function, prints to server console
	function mysqlHandler.logger(message)
		tes3mp.LogMessage(enumerations.log.INFO, "[MySQL]: " .. message)
	end

	--Logs query to console
	function mysqlHandler.queryLog(message)
		tes3mp.LogMessage(enumerations.log.INFO, "[MySQL]: SYSTEM executed query (" .. message .. ")")
	end

	--Command handler, not quite complete
	function mysqlHandler.commandHandler(pid, cmds)
		if cmds[2] ~= nil then
			if cmds[2] == "test" then
				mysqlHandler.messageRelay("Testing DB..")
				mysqlHandler.logger("testDB called by " .. Players[pid].name)
			else
				mysqlHandler.messageRelay("Invalid MySQL command.")
			end
		else
			local messageL = "MySQL script info called by " .. Players[pid].name
			local messageC = "MySQL script is currently loaded.\nScript by: Nac\nIntended for use by FTC internal scripting."
			mysqlHandler.logger(messageL)
			mysqlHandler.messageRelay(pid, messageC)
		end
	end

	customCommandHooks.registerCommand("mysql", mysqlHandler.commandHandler)
	customEventHooks.registerHandler("OnServerPostInit", mysqlHandler.init)
return mysqlHandler
