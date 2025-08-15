local _ = require("gettext")
local FFIUtil = require("ffi/util")
local Template = FFIUtil.template

local UIManager = require("ui/uimanager")
local SpingWidget = require("ui/widget/spinwidget")
local RadioButtonWidget = require("ui/widget/radiobuttonwidget")
local InputDialog = require("ui/widget/inputdialog")

local KarmtkaMenu = {}

function KarmtkaMenu:getSubItemTable(karmtka_settings)
    return {
        {
            text = _("Enable"),
            checked_func = function ()
                return karmtka_settings.settings:readSetting("enabled", DEFAULT_ENABLED)
            end,
            callback = function ()
                karmtka_settings.settings:toggle("enabled")
            end,
        },
        {
            text = _("Settings"),
            sub_item_table = {
                {
                    text = _("Display warning before copying"),
                    separator = true,
                    checked_func = function ()
                        return karmtka_settings.settings:readSetting("display_warning", DEFAULT_WARNING)
                    end,
                    callback = function ()
                        karmtka_settings.settings:toggle("display_warning")
                    end,
                },
                {
                    text_func = function ()
                        return Template(_("Custom path to the karMtka executable: %1"),
                            (#karmtka_settings.settings:readSetting("exe_path", "") > 0 and "Set" or "Not set"))
                    end,
                    separator = true,
                    callback = function (touchmenu_instance)
                        self.dialog = InputDialog:new{
                            title = "Custom path to the karMtka executable",
                            description = "If the executable can't be found in directories included in PATH, \
provide the full path manually. It will be used only as a fallback path.",
                            input = karmtka_settings.settings:readSetting("exe_path", ""),
                            buttons = {
                                {
                                    {
                                        text = _("Cancel"),
                                        callback = function()
                                            UIManager:close(self.dialog)
                                        end,
                                    },
                                    {
                                        text = _("Set"),
                                        callback = function ()
                                            karmtka_settings.settings:saveSetting("exe_path", self.dialog:getInputText())
                                            UIManager:close(self.dialog)
                                            touchmenu_instance:updateItems()
                                        end
                                    },
                                },
                            },
                        }
                        UIManager:show(self.dialog)
                    end,
                    keep_menu_open = true,
                },
                {
                    text_func = function ()
                        return Template(_("Page Margin: %1"), 
                            karmtka_settings.settings:readSetting("margin", DEFAULT_MARGIN))
                    end,
                    callback = function (touchmenu_instance)
                        UIManager:show(SpingWidget:new{
                            value = karmtka_settings.settings:readSetting("margin", DEFAULT_MARGIN),
                            value_min = 0,
                            value_max = 600,
                            value_step = 1,
                            value_hold_step = 50,
                            default_value = DEFAULT_MARGIN,
                            title_text = _("Page Margin"),
                            info_text = _("Set the size of page margin in pixels"),
                            callback = function (spin)
                                karmtka_settings.settings:saveSetting("margin", spin.value)
                                touchmenu_instance:updateItems()
                            end,
                        })
                    end,
                    keep_menu_open = true,
                },
                {
                    text_func = function ()
                        return Template(_("Inject Mode: %1"), 
                            karmtka_settings.settings:readSetting("inject_mode", DEFAULT_MODE))
                    end,
                    callback = function (touchmenu_instance)
                        UIManager:show(RadioButtonWidget:new{
                            title_text = _("Inject Mode"),
                            info_text=  _("Select the way in which copied text should be injected into xochitl"),
                            radio_buttons = {
                                {
                                    {
                                        text = "Append",
                                        provider = "append",
                                        checked = string.lower(karmtka_settings.settings:readSetting(
                                            "inject_mode", DEFAULT_MODE)) == "append"
                                    },
                                    {
                                        text = "Current",
                                        provider = "current",
                                        checked = string.lower(karmtka_settings.settings:readSetting(
                                            "inject_mode", DEFAULT_MODE)) == "current"
                                    },
                                },
                                {
                                    {
                                        text = "Next",
                                        provider = "next",
                                        checked = string.lower(karmtka_settings.settings:readSetting(
                                            "inject_mode", DEFAULT_MODE)) == "next"
                                    },
                                    {
                                        text = "Last",
                                        provider = "last",
                                        checked = string.lower(karmtka_settings.settings:readSetting(
                                            "inject_mode", DEFAULT_MODE)) == "last"
                                    },
                                },
                            },
                            callback = function (radio)
                                karmtka_settings.settings:saveSetting("inject_mode", radio.provider)
                                touchmenu_instance:updateItems()
                            end
                        })
                    end,
                    keep_menu_open = true,
                },
            },
        }   
    }
end

return KarmtkaMenu