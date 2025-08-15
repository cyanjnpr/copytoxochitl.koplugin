local Device = require("device")

if not Device.isRemarkable() then
    return { disabled = true, }
end

local UIManager = require("ui/uimanager")
local WidgetContainer = require("ui/widget/container/widgetcontainer")
local Notification = require("ui/widget/notification")
local ConfirmBox = require("ui/widget/confirmbox")

local _ = require("gettext")

local KarmtkaMenu = require("menu")
local KarmtkaSettings = require("settings")

local Karmtka = WidgetContainer:extend{
    name = "karmtka",
    is_doc_only = false,
    config_file = "karmtka.lua",
}

function Karmtka:init()
    KarmtkaSettings:load(self.config_file)
    if self.ui.menu then
        self.ui.menu:registerToMainMenu(self)
    end
    if self.ui.highlight and KarmtkaSettings.settings:readSetting("enabled", DEFAULT_ENABLED) then
        self:addToHighlightDialog()
    end
end

function Karmtka:addToMainMenu(menu_items)
    menu_items.karmtka = {
        text = "KarMtka",
        sorting_hint = "tools",
        sub_item_table = KarmtkaMenu:getSubItemTable(KarmtkaSettings),
    }
end

function Karmtka:onFlushSettings()
    KarmtkaSettings:save()
end

function Karmtka:buildCommand()
    local executable = (Karmtka:isInstalledInPath() and 
        "karmtka" or 
        KarmtkaSettings.settings:readSetting("exe_path", ""))
    local command = {}
    table.insert(command, executable)
    table.insert(command, " --device ")
    table.insert(command, (Device.model == "reMarkable Ferrari" and "rmpp" or "rm"))
    table.insert(command, " --xochitl ")
    table.insert(command, "--inject ")
    table.insert(command, KarmtkaSettings.settings:readSetting("inject_mode", DEFAULT_MODE))
    table.insert(command, " ")
    table.insert(command, "--margin ")
    table.insert(command, KarmtkaSettings.settings:readSetting("margin", DEFAULT_MARGIN))
    table.insert(command, " ")
    table.insert(command, "--overwrite")
    return table.concat(command)
end

function Karmtka:copyToXochitl(text)
    local handle = io.popen(self:buildCommand(), 'w')
    if handle then
        handle:write(text)
        handle:close()
    end
    UIManager:show(Notification:new{
        text = _("Selection copied to xochitl."),
    })
end

function Karmtka:WarnCopyToXochitl(text)
    UIManager:show(ConfirmBox:new{
        text = _("Copy to Xochitl - Proceed? \n\n\z
Some of the injection modes can overwrite existing pages in your notebook. \z
Make sure you understand the risks.\n\n\z
You can disable this warning in the settings."),
        icon = "notice-warning",
        ok_text = _("Copy"),
        ok_callback = function()
            self:copyToXochitl(text)
        end,
    })
end

function Karmtka:isInstalled()
    local exe_path = KarmtkaSettings.settings:readSetting("exe_path", "")
    return self:isInstalledInPath() or self:fileExists(exe_path)
end

function Karmtka:isInstalledInPath()
    local handle = io.popen("which karmtka", 'r')
    local which = ""
    if handle then
        which = handle:read('a')
        handle:close()
    end
    return #which > 0
end

function Karmtka:fileExists(filename)
   local f=io.open(filename, 'r')
   if f~=nil then 
        io.close(f) 
        return true 
    else 
        return false 
    end
end

function Karmtka:addToHighlightDialog()
    -- overwrite default copy button
    self.ui.highlight:addToHighlightDialog("03_copy", function (this)
        return {
            text = _("Copy to Xochitl"),
            enabled = self:isInstalled(),
            callback = function ()
                if true or KarmtkaSettings.settings:readSetting("display_warning", DEFAULT_WARNING) then
                    self:WarnCopyToXochitl(this.selected_text.text)
                else
                    self:copyToXochitl(this.selected_text.text)
                end
                this:onClose()
            end,
        }
    end)
end

return Karmtka
