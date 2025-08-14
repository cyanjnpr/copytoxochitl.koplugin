local _ = require("gettext")

local UIManager = require("ui/uimanager")
local WidgetContainer = require("ui/widget/container/widgetcontainer")
local Notification = require("ui/widget/notification")

local Karmtka = WidgetContainer:extend{
    name = "karMtka",
    is_doc_only = false
}

function Karmtka:init()
    if self.ui.highlight then
        self:addToHighlightDialog()
    end
end

function Karmtka:copyToXochitl(text)
    local handle = io.popen("/home/root/karmtka -x -i current --overwrite", 'w')
    if handle ~= nil then
        handle:write(text)
        handle:close()
    end
end

function Karmtka:isInstalled()
    local handle = io.popen("which karmtka", 'r')
    local which = ""
    if handle ~= nil then
        which = handle:read('a')
        handle:close()
    end
    return #which > 0
end

function Karmtka:addToHighlightDialog()
    -- overwrite default copy button
    self.ui.highlight:addToHighlightDialog("03_copy", function (this)
        return {
            text = _("Copy to Xochitl"),
            enabled = self:isInstalled(),
            callback = function ()
                self:copyToXochitl(this.selected_text.text)
                UIManager:show(Notification:new{
                    text = _("Selection copied to xochitl."),
                })
                this:onClose()
            end,
        }
    end)
end

return Karmtka