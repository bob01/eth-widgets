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

--------------------------------------------------------------
-- constants

local COLOR_DISABLED = lcd.GREY(0x7F)
local COLOR_INFO_GREY = lcd.GREY(0xBF)

local LEVEL_TRACE       = 0
local LEVEL_INFO        = 1
local LEVEL_WARN        = 2
local LEVEL_ERROR       = 3

local escStatusColors = {
    [LEVEL_TRACE] = COLOR_DISABLED,
    [LEVEL_INFO]  = COLOR_INFO_GREY,
    [LEVEL_WARN]  = YELLOW,
    [LEVEL_ERROR] = RED,
}

local LOG_MAX = 128
local YGE_SPN_IGNORE_MAX = 32

local escstatus_text = nil
local escstatus_level = LEVEL_INFO
local escGetStatus = nil
local escResetStatus = nil

local log = {}
local events = 0
local ygeSpnEvents = 0
-- local bootEpoch = getDateTime()
-- local bootTime = getTime()

--------------------------------------------------------------
-- ESC signatures

local ESC_SIG_NONE              = 0x00
local ESC_SIG_BLHELI32          = 0xC8
local ESC_SIG_HW4               = 0x9B
local ESC_SIG_KON               = 0x4B
local ESC_SIG_OMP               = 0xD0
local ESC_SIG_ZTW               = 0xDD
local ESC_SIG_APD               = 0xA0
local ESC_SIG_PL5               = 0xFD
local ESC_SIG_TRIB              = 0x53
local ESC_SIG_OPENYGE           = 0xA5
local ESC_SIG_FLY               = 0x73
local ESC_SIG_RESTART           = 0xFF

--------------------------------------------------------------
-- YGE status

local STATE_MASK                = 0x0F      -- status bit mask
local STATE_DISARMED            = 0x00      -- Motor stopped
local STATE_POWER_CUT           = 0x01      -- Power cut maybe Overvoltage
local STATE_FAST_START          = 0x02      -- "Bailout" State
local STATE_STARTING            = 0x08      -- "Starting"
local STATE_WINDMILLING         = 0x0C      -- still rotating no power drive can be named "Idle"
local STATE_RUNNING_NORM        = 0x0E      -- normal "Running"

local EVENT_MASK                = 0x70      -- event bit mask
local WARN_DEVICE_MASK          = 0xC0      -- device ID bit mask (note WARN_SETPOINT_NOISE = 0xC0)
local WARN_DEVICE_ESC           = 0x00      -- warning indicators are for ESC
local WARN_DEVICE_BEC           = 0x80      -- warning indicators are for BEC
local WARN_OK                   = 0x00      -- Overvoltage if Motor Status == STATE_POWER_CUT
local WARN_UNDERVOLTAGE         = 0x10      -- Fail if Motor Status < STATE_STARTING
local WARN_OVERTEMP             = 0x20      -- Fail if Motor Status == STATE_POWER_CUT
local WARN_OVERAMP              = 0x40      -- Fail if Motor Status == STATE_POWER_CUT
local WARN_SETPOINT_NOISE       = 0xC0      -- note this is special case (can never have OVERAMP w/ BEC hence reuse)

local ygeState = {
    [STATE_DISARMED]            = "OK",
    [STATE_POWER_CUT]           = "Shutdown",
    [STATE_FAST_START]          = "Bailout",
    [STATE_STARTING]            = "Starting",
    [STATE_WINDMILLING]         = "Idle",
    [STATE_RUNNING_NORM]        = "Running",
}

local ygeEvent = {
    [WARN_UNDERVOLTAGE]         = "Under Voltage",
    [WARN_OVERTEMP]             = "Over Temp",
    [WARN_OVERAMP]              = "Current Limit",
}

local function ygeGetStatus(code, changed)
    local text, level
    local scode = (code & 0xFF)
    local dev = (scode & WARN_DEVICE_MASK)
    local state = (scode & STATE_MASK)
    if scode == 0 then
        text = "YGE ESC OK"
        level = LEVEL_INFO
    elseif dev == WARN_SETPOINT_NOISE then
        -- special case
        text = "ESC Setpoint Noise"
        if changed then
            ygeSpnEvents = ygeSpnEvents + 1
        end
        level = (state == STATE_POWER_CUT and LEVEL_ERROR) or 
                (ygeSpnEvents < YGE_SPN_IGNORE_MAX and LEVEL_TRACE) or 
                LEVEL_WARN
    else
        -- device part
        if dev == WARN_DEVICE_BEC then
            text = "BEC "
        else
            text = "ESC "
        end

        -- state text
        local stateText = ygeState[state] or string.format("Code x%02X", state)

        -- event part
        local event = (scode & EVENT_MASK)
        if event == WARN_OK then
            -- special case
            if state == STATE_POWER_CUT then
                text = text.."Over Voltage"
                level = LEVEL_ERROR
            else
                text = text..stateText
                level = LEVEL_INFO
            end
        else
            -- event
            text = text..(ygeEvent[event] or "** unexpected **")
            if event == WARN_UNDERVOLTAGE then
                level = state < STATE_STARTING and LEVEL_ERROR or LEVEL_WARN
            else
                level = state == STATE_POWER_CUT and LEVEL_ERROR or LEVEL_WARN
            end
        end
    end
    text = (level == LEVEL_ERROR) and string.upper(text) or text
    return { text = text, level = level }
end

local function ygeResetStatus()
    escstatus_text = nil
    escstatus_level = LEVEL_INFO

    log = {}
    events = 0
    ygeSpnEvents = 0
end

--------------------------------------------------------------
-- Scorpion status


-- * Scorpion Telemetry
-- *    - Serial protocol is 38400,8N1
-- *    - Frame rate running:10Hz idle:1Hz
-- *    - Little-Endian fields
-- *    - CRC16-CCITT
-- *    - Error Code bits:
-- *         0:  N/A
-- *         1:  BEC voltage error
-- *         2:  Temperature error
-- *         3:  Consumption error
-- *         4:  Input voltage error
-- *         5:  Current error
-- *         6:  N/A
-- *         7:  Throttle error

 local function tribGetStatus(code, changed)
    local text = "Scorpion ESC OK"
    local level = LEVEL_INFO
    -- just report highest order bit
    for bit = 0, 7 do
        if (code & (1 << bit)) ~= 0 then
            local fault = nil
            if bit == 1 then
                fault = "BEC Voltage"
            elseif bit == 2 then
                fault = "ESC Temperature"
            elseif bit == 3 then
                fault = "ESC Consumption"
            elseif bit == 4 then
                fault = "ESC Voltage"
            elseif bit == 5 then
                fault = "ESC Current"
            -- elseif bit == 7 then
            --     fault = "ESC Throttle Error"
            end
            if fault then
                text = fault
                level = LEVEL_ERROR
            end
        end
    end
    return { text = text, level = level }
end

--------------------------------------------------------------
-- HW5 status

-- *    - Fault code bits:
-- *         0:  Motor locked protection
-- *         1:  Over-temp protection
-- *         2:  Input throttle error at startup
-- *         3:  Throttle signal lost
-- *         4:  Over-current error
-- *         5:  Low-voltage error
-- *         6:  Input-voltage error
-- *         7:  Motor connection error

local function pl5GetStatus(code, changed)
   local text = "HobbyWing ESC OK"
   local level = LEVEL_INFO
   -- just report highest order bit
   for bit = 0, 7 do
       if (code & (1 << bit)) ~= 0 then
           local fault = nil
           if bit == 0 then
               fault = "ESC Motor Locked"
            elseif bit == 1 then
                fault = "ESC Over Temp"
            elseif bit == 2 then
                fault = "ESC Throttle Error"
            elseif bit == 3 then
                fault = "ESC Throttle Signal"
            elseif bit == 4 then
                fault = "ESC Over Current"
            elseif bit == 5 then
                fault = "ESC Low Voltage"
            elseif bit == 6 then
                fault = "ESC Input Voltage"
            elseif bit == 7 then
                fault = "ESC Motor Connection"
            end
            if fault then
                text = fault
                level = LEVEL_ERROR
            end
       end
   end
   return { text = text, level = level }
end

--------------------------------------------------------------
-- FLY telemetry

-- * FLYROTOR status
-- *    0x80 Fan Status 
-- *    0x40 Reserved 
-- *    0x20 Reserved 
-- *    0x10 Throttle Signal 
-- *    0x08 Short Circuit Protection 
-- *    0x04 Overcurrent Protection 
-- *    0x02 Low Voltage Protection 
-- *    0x01 Temperature Protection

local function flyGetStatus(code, changed)
   local text = "FLYROTOR ESC OK"
   local level = LEVEL_INFO
   -- just report highest order bit (most severe)
--    if code ~= 0 then
--         text = string.format("code (%02X)", code)
--         level = LEVEL_WARN
--    end
   for bit = 0, 7 do
       if (code & (1 << bit)) ~= 0 then
            if bit == 0 then
                text = "ESC Over Temp"
                level = LEVEL_ERROR
                break
            elseif bit == 1 then
                text = "ESC Low Voltage"
                level = LEVEL_ERROR
                break
            elseif bit == 2 then
                text = "ESC Overcurrent"
                level = LEVEL_ERROR
                break
            elseif bit == 3 then
                text = "ESC Short Circuit"
                level = LEVEL_ERROR
                break
            elseif bit == 4 then
                text = "ESC Throttle Signal"
                level = LEVEL_WARN
                break
            elseif bit == 7 then
                text = "ESC Fan Status"
                level = LEVEL_INFO
                break
            end
       end
   end
   return { text = text, level = level }
end

--------------------------------------------------------------

local function resetStatus()
   escstatus_text = nil
   escstatus_level = LEVEL_INFO

   log = {}
   events = 0
end

-- get log event
local function logGetEv(idx)
    if idx <= events - LOG_MAX then
        return nil
    end
    return log[((idx - 1) % LOG_MAX) + 1]
end

-- log status change, return true if new event logged
local function logPutEv(wgt, scode)
    if events > 0 and (logGetEv(events) & 0xFF) == (scode & 0xFF) then
        return false
    end

    -- local t, _ = math.modf((getTime() - bootTime) / 10)
    local t = 0
    local ev = ((t << 16) | (scode & 0xFF))
    log[(events % LOG_MAX) + 1] = ev
    events = events + 1
    return true
end

--------------------------------------------------------------

-- ctor
local function create()
    local widget =
    {
        -- sensors
        sensorArm = system.getSource("Arming Flags"),
        sensorArmDisabled = system.getSource("Arming Disable"),
        sensorGov = system.getSource("Governor"),
        sensorThr = system.getSource("Throttle %"),
        sensorEscSig = system.getSource("ESC1 Model ID"),
        sensorEscFlags = system.getSource("ESC1 Status"),

        -- options
        textColor = WHITE,

        -- state
        active = false,

        armed = false,
        thro = nil,
        throttle = "",
        fmode = "",
        sig = ESC_SIG_NONE,

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

    -- ESC status
    local text
    local color
    if widget.sig == ESC_SIG_RESTART then
        text = "RESTART ESC"
        color = escStatusColors[LEVEL_ERROR]
    else
        text = escstatus_text
        color = widget.escstatus_color
    end
    -- text = "Scorpion ESC OK"
    -- color = WHITE
    if text then
        lcd.font(FONT_STD)
        lcd.color(color)
        local _, text_h = lcd.getTextSize("")
        lcd.drawText(box_left + margin, box_top + (box_height - text_h) - margin / 2, text)
    end

    -- fmode / gov mode
    lcd.font(FONT_STD)
    lcd.color(COLOR_INFO_GREY)
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

        -- ESC sig
        local escSig = widget.sensorEscSig and widget.sensorEscSig:value()
        local escFlags = widget.sensorEscFlags and widget.sensorEscFlags:value()
        if escSig and escFlags then
            widget.sig = escSig
            if not escGetStatus then
                if escSig == ESC_SIG_OPENYGE then
                    escGetStatus = ygeGetStatus
                    escResetStatus = ygeResetStatus
                elseif escSig == ESC_SIG_TRIB then
                    escGetStatus = tribGetStatus
                    escResetStatus = resetStatus
                elseif escSig == ESC_SIG_PL5 then
                    escGetStatus = pl5GetStatus
                    escResetStatus = resetStatus
                elseif escSig == ESC_SIG_FLY then
                    escGetStatus = flyGetStatus
                    escResetStatus = resetStatus
                elseif escSig ~= ESC_SIG_NONE then
                    escstatus_text = "Unrecognized ESC"..string.format(" (%02X)", escSig)
                end
                escstatus_level = LEVEL_INFO
                lcd.invalidate()
            end
        end

        -- ESC flags
        if escGetStatus then
            local changed = logPutEv(widget, escFlags)
            local status = escGetStatus(escFlags, changed)
            if status.level >= escstatus_level then
                escstatus_text = status.text
                escstatus_level = status.level
                widget.escstatus_color = escStatusColors[status.level]
            end
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