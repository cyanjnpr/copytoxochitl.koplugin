local DataStorage = require("datastorage")
local LuaSettings = require("luasettings")

DEFAULT_ENABLED = true
DEFAULT_WARNING = true
DEFAULT_MARGIN = 234
DEFAULT_MODE = "current"

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