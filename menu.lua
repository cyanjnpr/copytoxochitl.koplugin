local UIManager = require("ui/uimanager")

local SpingWidget = require("ui/widget/spinwidget")
local RadioButtonWidget = require("ui/widget/radiobuttonwidget")
local InputDialog = require("ui/widget/inputdialog")
local ButtonDialog = require("ui/widget/buttondialog")
local Notification = require("ui/widget/notification")

local _ = require("gettext")
local FFIUtil = require("ffi/util")
local T = FFIUtil.template

local KarmtkaMenu = {}

function KarmtkaMenu:getNotebookSelectionDialog(notebooks, callback)
    local buttons = {}
    for _, value in pairs(notebooks) do
        table.insert(buttons, {{
            text = value,
            callback = function ()
                callback(value)
                self.notebookSelectionDialog:onClose()
            end,
        }})
    end
    self.notebookSelectionDialog = ButtonDialog:new{
        title = _("Select target notebook"),
        buttons = buttons,
    }
    return self.notebookSelectionDialog
end

function KarmtkaMenu:getSubItemTable(karmtka_settings)
    return {
        {
            text = _("Enabled"),
            checked_func = function ()
                return karmtka_settings.settings:readSetting("enabled", DEFAULT_ENABLED)
            end,
            callback = function ()
                karmtka_settings.settings:toggle("enabled")
            end,
        },
        {
            text = _("Save settings"),
            callback = function ()
                karmtka_settings:save()
                UIManager:show(Notification:new{
                    text = _("Settings saved."),
                })
            end,
            keep_menu_open = true,
        },
        {
            text = _("Settings"),
            sub_item_table = {
                {
                    text = _("Display confirmation dialog before copying"),
                    checked_func = function ()
                        return karmtka_settings.settings:readSetting("display_warning", DEFAULT_WARNING)
                    end,
                    callback = function ()
                        karmtka_settings.settings:toggle("display_warning")
                    end,
                },
                {
                    text = _("Always ask for the target notebook"),
                    separator = true,
                    checked_func = function ()
                        return karmtka_settings.settings:readSetting("display_notebook_query", DEFAULT_NOTEBOOOK_QUERY)
                    end,
                    callback = function ()
                        karmtka_settings.settings:toggle("display_notebook_query")
                    end,
                },
                {
                    text_func = function ()
                        return T(_("Custom path to the karMtka executable: %1"),
                            (#karmtka_settings.settings:readSetting("exe_path", "") > 0 and "Set" or "Not set"))
                    end,
                    separator = true,
                    callback = function (touchmenu_instance)
                        self.dialog = InputDialog:new{
                            title = _("Custom path to the karMtka executable"),
                            description = _("If the executable cannot be found in directories included in PATH, \z
provide the full path manually. It will be used only as a fallback path."),
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
                        return T(_("Page Margin: %1 px"), 
                            karmtka_settings.settings:readSetting("margin", DEFAULT_MARGIN))
                    end,
                    callback = function (touchmenu_instance)
                        UIManager:show(SpingWidget:new{
                            value = karmtka_settings.settings:readSetting("margin", DEFAULT_MARGIN),
                            value_min = 0,
                            value_max = 600,
                            value_step = 1,
                            value_hold_step = 50,
                            unit = "px",
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
                        return T(_("Copy Mode: %1"), 
                            karmtka_settings.settings:readSetting("inject_mode", DEFAULT_MODE))
                    end,
                    callback = function (touchmenu_instance)
                        UIManager:show(RadioButtonWidget:new{
                            title_text = _("Copy Mode"),
                            info_text=  _("Select page into which highlighted text should be copied"),
                            radio_buttons = {
                                {
                                    {
                                        text = _("Append"),
                                        provider = "append",
                                        checked = string.lower(karmtka_settings.settings:readSetting(
                                            "inject_mode", DEFAULT_MODE)) == "append"
                                    },
                                    {
                                        text = _("Current"),
                                        provider = "current",
                                        checked = string.lower(karmtka_settings.settings:readSetting(
                                            "inject_mode", DEFAULT_MODE)) == "current"
                                    },
                                },
                                {
                                    {
                                        text = _("Next"),
                                        provider = "next",
                                        checked = string.lower(karmtka_settings.settings:readSetting(
                                            "inject_mode", DEFAULT_MODE)) == "next"
                                    },
                                    {
                                        text = _("Last"),
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
                {
                    text_func = function ()
                        local size = karmtka_settings.settings:readSetting("font_size", DEFAULT_SIZE)
                        return T(_("Font size: %1"), 
                            (size == 1 and "small" or (size == 3 and "medium" or "large")))
                    end,
                    callback = function (touchmenu_instance)
                        UIManager:show(RadioButtonWidget:new{
                            title_text = _("Font Size"),
                            info_text=  _("Choose font size of the copied content"),
                            radio_buttons = {
                                {
                                    {
                                        text = _("Small"),
                                        provider = 1,
                                        checked = karmtka_settings.settings:readSetting(
                                            "font_size", DEFAULT_SIZE) == 1
                                    },
                                },
                                {
                                    {
                                        text = _("Medium"),
                                        provider = 3,
                                        checked = karmtka_settings.settings:readSetting(
                                            "font_size", DEFAULT_SIZE) == 3
                                    },
                                },
                                {
                                    {
                                        text = _("Large"),
                                        provider = 2,
                                        checked = karmtka_settings.settings:readSetting(
                                            "font_size", DEFAULT_SIZE) == 2
                                    },
                                },
                            },
                            callback = function (radio)
                                karmtka_settings.settings:saveSetting("font_size", radio.provider)
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
