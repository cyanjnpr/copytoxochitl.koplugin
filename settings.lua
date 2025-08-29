local DataStorage = require("datastorage")
local LuaSettings = require("luasettings")

DEFAULT_ENABLED = true -- plugin enabled
DEFAULT_WARNING = true -- display confirmation dialog before copying
DEFAULT_MARGIN = 234 -- page margin in pixels
DEFAULT_MODE = "current" -- which page should be changed during copy op
DEFAULT_SIZE = 1 -- font size, 1-3, 1 - small, 2 - large, 3 - medium
DEFAULT_NOTEBOOOK_QUERY = false -- always ask for target notebook before copy operation

local KarmtkaSettings = {
    settings = nil
}

function KarmtkaSettings:load(file_name)
    self.settings = LuaSettings:open(("%s/%s"):format(DataStorage:getSettingsDir(), file_name))
end

function KarmtkaSettings:save()
    if self.settings then
        self.settings:flush()
    end
end

return KarmtkaSettings
