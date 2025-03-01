--[[
#########################################################################
#                                                                       #
# Powerbar widget for FrSky Ethos                                       #
# Copyright "Rob 'bob00' Gayle"                                         #
#                                                                       #
# License GPLv3: http://www.gnu.org/licenses/gpl-3.0.html               #
#                                                                       #
# This program is free software; you can redistribute it and/or modify  #
# it under the terms of the GNU General Public License version 3 as     #
# published by the Free Software Foundation.                            #
#                                                                       #
# This program is distributed in the hope that it will be useful        #
# but WITHOUT ANY WARRANTY; without even the implied warranty of        #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         #
# GNU General Public License for more details.                          #
#                                                                       #
#########################################################################
]]
-- Author: Rob Gayle (bob00@rogers.com)
-- Date: 2025
local version = "v0.2.0"

-- metadata
local widgetDir = "/scripts/widget-egovernor/"

local translations = { en="eGovernor" }

local function name(widget)
    local locale = system.getLocale()
    return translations[locale] or translations["en"]
end


-- constants
local COLOR_DISABLED = lcd.GREY(0x7F)

-- ctor
local function create()
    local widget =
    {
        sensorArm = system.getSource("Arming Flags"),
        sensorArmDisabled = system.getSource("Arming Disable"),
        sensorGov = system.getSource("Governor"),
        sensorThr = system.getSource("Throttle %"),
        sensorEscSig = system.getSource("ESC1 Model ID"),
        sensorEscFlags = system.getSource("ESC1 Status"),

        fmode = "",
        throttle = "",

        -- state
        thro = nil,

        active = false,
        armed = false,

        textColor = WHITE,

        text_color = WHITE,
        escstatus_color = 0,
    }

    return widget
end


-- paint canvas
local function paint(widget)
    -- canvas dimensions
    local w, h = lcd.getWindowSize()
    local box_top, box_height = 0, h
    local box_left, box_width = 0, w
    local margin = 8

    -- fmode / gov mode
    lcd.font(FONT_S)
    lcd.color(lcd.GREY(0xBF))
    local _, text_h = lcd.getTextSize("")
    lcd.drawText(box_left + box_width - margin, box_top + 2, widget.fmode, RIGHT)

    -- throttle / safe
    lcd.font(FONT_XXL)
    lcd.color(widget.text_color)
    _, text_h = lcd.getTextSize("")
    lcd.drawText(box_left + box_width - margin, box_top + (box_height - text_h) + 4, widget.throttle, RIGHT)
end


local govStates = {
    [0] = "OFF",
    "IDLE",
    "SPOOLUP",
    "RECOVERY",
    "ACTIVE",
    "THR-OFF",
    "LOST-HS",
    "AUTOROT",
    "BAILOUT",
}

local armDisabledDescs = {
    [0] = "NOGYRO",
    "FAILSAFE",
    "RXLOSS",
    "BADRX",
    "BOXFAILSAFE",
    "RUNAWAY",
    "CRASH",
    "THROTTLE",
    "ANGLE",
    "BOOTGRACE",
    "NOPREARM",
    "LOAD",
    "CALIB",
    "CLI",
    "CMS",
    "BST",
    "MSP",
    "PARALYZE",
    "GPS",
    "RESCUE_SW",
    "RPMFILTER",
    "REBOOT_REQD",
    "DSHOT_BBANG",
    "NO_ACC_CAL",
    "MOTOR_PROTO",
    "ARMSWITCH",
}


-- process sensors, pre-render and announce
local function wakeup(widget)
    -- telemetry active?
    local active = widget.sensorArm and widget.sensorArm:state()
    if widget.active ~= active then
        widget.active = active
        lcd.invalidate()
    end

    if widget.active then
        -- TODO connected stuff ####

        -- armed?
        local val = widget.sensorArm and widget.sensorArm:value()
        local armed = val and (val & 0x01) == 0x01

        if armed then
            -- armed, get ESC throttle if configured
            local thro = widget.sensorThr and widget.sensorThr:value()
            if widget.thro ~= thro then
                widget.thro = thro
                if thro then
                    widget.throttle = string.format("%d%%", thro)
                else
                    widget.throttle = "--"
                end
                lcd.invalidate()
            end
        else
            -- not armed
            widget.thro = nil
            widget.throttle = "Safe"
        end

        -- GOV status
        local govStatus
        local gov = widget.sensorGov and widget.sensorGov:value()
        local armf = widget.sensorArmDisabled and widget.sensorArmDisabled:value()
        if gov ~= nil and armf ~= nil then
            if not armed then
                if armf ~= 0 then
                    govStatus = "";
                    -- find a better message
                    for i = 1, #armDisabledDescs do
                        local bit = i - 1
                        if (armf & (1 << bit)) ~= 0 then
                            local desc = armDisabledDescs[bit]
                            local len = string.len(govStatus)
                            if len + string.len(desc) + 1 > 18 then
                                govStatus = govStatus.." +"
                                break
                            end
                            govStatus = govStatus..(len > 0 and " " or "")..desc
                        end
                    end
                    govStatus = "* "..govStatus
                else
                    govStatus = "DISARMED";
                end
            else
                if gov < #govStates then
                    govStatus = govStates[gov]
                else
                    govStatus = "UNKNOWN("..gov..")"
                end
            end
        else
            govStatus = "--"
        end
        if widget.fmode ~= govStatus then
            widget.fmode = govStatus
            lcd.invalidate()
        end

        -- announce if armed state changed
        if widget.armed ~= armed then
            local locale = "en"
            if armed then
                system.playFile(widgetDir .. "sounds/" .. locale .. "/armed.wav")
            else
                system.playFile(widgetDir .. "sounds/" .. locale .. "/disarm.wav")
            end
            widget.armed = armed
            lcd.invalidate()
        end

        -- colors
        widget.text_color = widget.textColor
    else
        -- not connected
        widget.throttle = "**"
        widget.fmode = ""

        -- reset last armed
        widget.armed = false

        -- colors
        widget.text_color =  COLOR_DISABLED
    end

end


-- config UI
local function configure(widget)
    -- Sensor choices
    local line = form.addLine("Arming flags")
    form.addSourceField(line, nil, function() return widget.sensorArm end, function(value) widget.sensorArm = value end)

    local line = form.addLine("Arming disable flags")
    form.addSourceField(line, nil, function() return widget.sensorArmDisabled end, function(value) widget.sensorArmDisabled = value end)

    local line = form.addLine("Governor state")
    form.addSourceField(line, nil, function() return widget.sensorGov end, function(value) widget.sensorGov = value end)

    local line = form.addLine("ESC or GOV throttle")
    form.addSourceField(line, nil, function() return widget.sensorThr end, function(value) widget.sensorThr = value end)

    local line = form.addLine("ESC model id")
    form.addSourceField(line, nil, function() return widget.sensorEscSig end, function(value) widget.sensorEscSig = value end)

    local line = form.addLine("ESC status")
    form.addSourceField(line, nil, function() return widget.sensorEscFlags end, function(value) widget.sensorEscFlags = value end)

    line = form.addLine("Text color")
    form.addColorField(line, nil, function() return widget.textColor end, function(value) widget.textColor = value end)

end


-- load config
local function read(widget)
    local version = storage.read("version")

    widget.sensorArm = storage.read("sensorArm")
    widget.sensorArmDisabled = storage.read("sensorArmDisabled")
    widget.sensorGov = storage.read("sensorGov")
    widget.sensorThr = storage.read("sensorThr")
    widget.sensorEscSig = storage.read("sensorEscSig")
    widget.sensorEscFlags = storage.read("sensorEscFlags")

    widget.textColor = storage.read("textColor")
end


-- save config
local function write(widget)
    storage.write("version", 1)

    storage.write("sensorArm", widget.sensorArm)
    storage.write("sensorArmDisabled", widget.sensorArmDisabled)
    storage.write("sensorGov", widget.sensorGov)
    storage.write("sensorThr", widget.sensorThr)
    storage.write("sensorEscSig", widget.sensorEscSig)
    storage.write("sensorEscFlags", widget.sensorEscFlags)

    storage.write("textColor", widget.textColor)
end


-- initialize / register widget
local function init()
    system.registerWidget({ key = "rngegov", name = name, create = create, paint = paint, wakeup = wakeup, configure = configure, read = read, write = write })
end

return { init = init }