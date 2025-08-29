local Device = require("device")

if not Device.isRemarkable() then
    return { disabled = true, }
end

local UIManager = require("ui/uimanager")
local WidgetContainer = require("ui/widget/container/widgetcontainer")
local Notification = require("ui/widget/notification")
local ConfirmBox = require("ui/widget/confirmbox")

local _ = require("gettext")
local FFIUtil = require("ffi/util")
local T = FFIUtil.template

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
        text = "KarMtka / Copy To Xochitl",
        sorting_hint = "tools",
        sub_item_table = KarmtkaMenu:getSubItemTable(KarmtkaSettings),
    }
end

function Karmtka:onFlushSettings()
    KarmtkaSettings:save()
end

function Karmtka:executable()
    return (Karmtka:isInstalledInPath() and
        "karmtka" or
        KarmtkaSettings.settings:readSetting("exe_path", ""))
end

function Karmtka:buildListCommand()
    local command = {}
    table.insert(command, self:executable())
    table.insert(command, " --xochitl --list")
    return table.concat(command)
end

-- dry run to get information about which notebook/page will be affected during normal run
function Karmtka:buildSimulateCommand(notebook)
    local command = {}
    table.insert(command, self:executable())
    table.insert(command, " --notebook '")
    table.insert(command, notebook)
    table.insert(command, "' --xochitl --inject ")
    table.insert(command, KarmtkaSettings.settings:readSetting("inject_mode", DEFAULT_MODE))
    table.insert(command, " --overwrite --dry")
    return table.concat(command)
end

function Karmtka:buildWriteCommand(notebook)
    local command = {}
    table.insert(command, self:executable())
    table.insert(command, " --device ")
    table.insert(command, (Device.model == "reMarkable Ferrari" and "rmpp" or "rm"))
    table.insert(command, " --notebook '")
    table.insert(command, notebook)
    table.insert(command, "' --xochitl --inject ")
    table.insert(command, KarmtkaSettings.settings:readSetting("inject_mode", DEFAULT_MODE))
    table.insert(command, " --margin ")
    table.insert(command, KarmtkaSettings.settings:readSetting("margin", DEFAULT_MARGIN))
    table.insert(command, " --style ")
    table.insert(command, KarmtkaSettings.settings:readSetting("font_size", DEFAULT_SIZE))
    table.insert(command, " --overwrite")
    return table.concat(command)
end

-- list <max> recent notebooks by full path
function Karmtka:list(max)
    local notebooks = {}
    local handle = io.popen(self:buildListCommand(), 'r')
    if handle then
        ---@type string
        local line = handle:read('l')
        while line and max > 0 do
            -- shell limitations, ignore problematic notebooks
            -- they can always be used as the most recent ones
            -- without picking them by name
            if not line:find("'") then
                table.insert(notebooks, line)
                max = max - 1
            end
            line = handle:read('l')
        end
    end
    return notebooks
end

function Karmtka:copyToXochitl(text, notebook)
    local handle = io.popen(self:buildWriteCommand(notebook), 'w')
    if handle then
        handle:write(text)
        handle:close()
    end
    UIManager:show(Notification:new{
        text = _("Selection copied to xochitl."),
    })
end

-- display which notebook will be affected before copyinng
function Karmtka:WarnCopyToXochitl(text, notebook)
    local handle = io.popen(self:buildSimulateCommand(notebook), 'r')
    local params = {
        ["notebook"] = "UNKNOWN",
        ["page"] = "UNKNOWN",
    }
    if handle then
        ---@type string
        local line = handle:read('l')
        while line do
            print(line)
            local sep = line:find(":")
            if sep then
                local key = line:sub(1, sep-1):lower()
                local val = line:sub(sep+1)
                if params[key] then
                    params[key] = val
                end
            end
            line = handle:read('l')
        end
        handle:close()
    end
    UIManager:show(ConfirmBox:new{
        text = T(_("Copy to Xochitl - Proceed? \n\n\z
Target Notebook: %1\n\z
Target Page: %2"), params["notebook"], params["page"]),
        icon = "notice-warning",
        ok_text = _("Copy"),
        ok_callback = function()
            self:copyToXochitl(text, notebook)
        end,
    })
end

-- display <num_notebooks> recent notebooks to choose from as the target for copy operation
function Karmtka:copySelectNotebook(text, num_notebooks)
    local function copyToNotebook(notebook)
        if KarmtkaSettings.settings:readSetting("display_warning", DEFAULT_WARNING) then
            self:WarnCopyToXochitl(text, notebook)
        else
            self:copyToXochitl(text, notebook)
        end
    end
    local dialog = KarmtkaMenu:getNotebookSelectionDialog(self:list(num_notebooks), copyToNotebook)
    UIManager:show(dialog)
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
                if KarmtkaSettings.settings:readSetting("display_notebook_query", DEFAULT_NOTEBOOOK_QUERY) then
                    self:copySelectNotebook(this.selected_text.text, 7)
                else
                    if KarmtkaSettings.settings:readSetting("display_warning", DEFAULT_WARNING) then
                        self:WarnCopyToXochitl(this.selected_text.text, "")
                    else
                        self:copyToXochitl(this.selected_text.text, "")
                    end
                end
                this:onClose()
            end,
        }
    end)
end

return Karmtka
