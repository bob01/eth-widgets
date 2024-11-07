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
-- Date: 2024
local version = "v0.9.4"

-- metadata
local widgetDir = "/scripts/widget-powerbar/"

local translations = { en="Powerbar" }

local function name(widget)
    local locale = system.getLocale()
    return translations[locale] or translations["en"]
end


-- ctor
local function create()
    local widget =
    {
        -- sensors
        voltageSensor = nil,
        mahSensor = nil,
        fuelSensor = nil,

        -- display
        minimal = false,

        -- pack
        cellCount = 6,

        -- state
        volts = nil,
        mah = nil,
        fuel = nil,

        linked = false,
        textColor = BLACK,

        -- pre-rendered text
        textVolts = nil,
        textMah = nil,
        textFuel = nil,

        -- audio state
        lastCapa = 100,
        nextCapa = 0,

        --thresholds
        reserve = 20,
        low = 10,

        -- methods
        getCritical = function (widget)
            return widget.reserve > 0 and 0 or 20
        end
    }

    return widget
end


-- color for bar
local function getBarColor(widget)
    local critical = widget:getCritical()
    if widget.fuel <= critical then
        -- red
        return lcd.RGB(0xff, 0, 0)
    elseif widget.fuel <= critical + 20 then
        -- yellow
        return lcd.RGB(0xff, 0xff, 0)
    else
        -- green
        return lcd.RGB(0, 0xff, 0)
    end
end


-- paint canvas
local function paint(widget)
    -- canvas dimensions
    local w, h = lcd.getWindowSize()
    local box_top, box_height = 2, h - 4
    local box_left, box_width = 2, w - 4

    -- background
    lcd.color(lcd.RGB(200, 200, 200))
    lcd.drawFilledRectangle(box_left, box_top, box_width, box_height)

    -- bar
    if widget.fuel then
        local fill = widget.fuel > 0 and widget.fuel or 100
        local bar_width = math.floor((((box_width - 2) / 100) * fill) + 2)
        lcd.color(getBarColor(widget))
        lcd.drawFilledRectangle(box_left, box_top, bar_width, box_height)

        lcd.color(lcd.RGB(160, 160, 160))
        lcd.drawLine(box_left + bar_width, box_top, box_left + bar_width, box_top + box_height)
    end

    -- outline
    lcd.color(BLACK)
    lcd.drawRectangle(box_left, box_top, box_width, box_height)

    -- text
    lcd.color(widget.textColor)

    -- voltage
    if widget.textVolts then
        lcd.font(widget.minimal and FONT_XL or FONT_L_BOLD)
        local _, text_h = lcd.getTextSize("")
        lcd.drawText(box_left + 8, 12, widget.textVolts)
    end

    -- mah
    if widget.textMah then
        lcd.font(FONT_L_BOLD)
        local _, text_h = lcd.getTextSize("")
        lcd.drawText(box_left + 8, box_top + (box_height - text_h) - 4, widget.textMah)
    end

    -- fuel
    lcd.font(FONT_XXL)
    _, text_h = lcd.getTextSize("")
    lcd.drawText(box_left + box_width - 4, box_top + (box_height - text_h) + 2, widget.textFuel or "--- %", RIGHT)
end


-- get system time
local function getSysTime()
    local time = math.ceil(os.clock() * 1000)
    return time
end


-- call fuel consumption on the 10's (singles when critical)
local function announceFuel(widget)
    -- silent if not linked or no fuel value
    if not widget.linked or widget.fuel == nil then
        return
    end

    local critical = widget:getCritical()

    -- report 10's if not below low threshold
    local capa
    if widget.fuel > critical + widget.low then
        capa = math.ceil(widget.fuel / 10) * 10
    else
        capa = math.ceil(widget.fuel)
    end

    -- time to report?
    if (widget.lastCapa ~= capa or capa <= 0) and getSysTime() > widget.nextCapa then
        -- skip initial report
        if widget.nextCapa ~= 0 then
            local locale = "en"

            -- urgency?
            if capa > critical + widget.low then
                system.playFile(widgetDir .. "sounds/" .. locale .. "/battry.wav")
            elseif capa > critical then
                system.playFile(widgetDir .. "sounds/" .. locale .. "/batlow.wav")
            else
                system.playFile(widgetDir .. "sounds/" .. locale .. "/batcrt.wav")
                -- system.playHaptic(". .")
            end

            -- -- play capa if >= 0
            if capa > 0 then
                system.playNumber(capa, UNIT_PERCENT, 0)
            end
        end

        -- schedule next
        widget.lastCapa = capa
        widget.nextCapa = getSysTime() + 5000
    end
end


-- process sensors, pre-render and announce
local function wakeup(widget)
    -- telemetry active?
    local linked = widget.voltageSensor and widget.voltageSensor:state()
    if widget.linked ~= linked then
        widget.linked = linked
        widget.textColor = linked and BLACK or lcd.GREY(0x7F)
        lcd.invalidate()
    end

    -- voltage
    local volts = widget.linked and widget.voltageSensor and widget.voltageSensor:value() or nil
    if volts and widget.volts ~= volts then
        widget.volts = volts
        widget.textVolts = volts
            and (widget.minimal and string.format("%.2fv", volts / widget.cellCount) or string.format("%.1fv / %.2fv", volts, volts / widget.cellCount))
            or nil
        lcd.invalidate()
    end

    -- mah
    local mah = widget.linked and widget.mahSensor and widget.mahSensor:value() or nil
    if mah and widget.mah ~= mah then
        widget.mah = mah
        widget.textMah = mah and string.format("%.0f mah", mah) or nil
        lcd.invalidate()
    end

    -- fuel
    local fuel = nil
    if widget.linked and widget.fuelSensor then
        fuel = widget.fuelSensor:value()
        if fuel then
            if fuel < widget.reserve then
                fuel = fuel - widget.reserve
            else
                local usable = 100 - widget.reserve
                fuel = (fuel - widget.reserve) / usable * 100
            end
        end
    end
    if fuel and widget.fuel ~= fuel then
        widget.fuel = fuel
        widget.textFuel = fuel and string.format("%.0f%%", fuel) or nil
        lcd.invalidate()
    end

    announceFuel(widget)
end


-- config UI
local function configure(widget)
    -- Sensor choices
    line = form.addLine("Voltage (v) Sensor")
    form.addSourceField(line, nil, function() return widget.voltageSensor end, function(value) widget.voltageSensor = value end)

    line = form.addLine("Consumption (mAh) Sensor")
    form.addSourceField(line, nil, function() return widget.mahSensor end, function(value) widget.mahSensor = value end)

    line = form.addLine("Fuel (%) Sensor")
    form.addSourceField(line, nil, function() return widget.fuelSensor end, function(value) widget.fuelSensor = value end)

    -- Reserve
    line = form.addLine("LiPo Reserve (%)")
    local field = form.addNumberField(line, nil, 0, 40, function() return widget.reserve end, function(value) widget.reserve = value end)
    field:suffix("%")
    field:default(20)

    -- Low threshold
    line = form.addLine("Low Battery Threshold (%)")
    field = form.addNumberField(line, nil, 0, 30, function() return widget.low end, function(value) widget.low = value end)
    field:suffix("%")
    field:default(10)

    -- Cell count
    line = form.addLine("Cell Count")
    field = form.addNumberField(line, nil, 2, 16, function() return widget.cellCount end, function(value) widget.cellCount = value end)
    field:suffix("s")
    field:default(6)

    -- minimal display
    line = form.addLine("Minimal Display")
    form.addBooleanField(line, nil, function() return widget.minimal end, function(newValue) widget.volts = nil widget.minimal = newValue end)

    -- version
    line = form.addLine("Version")
    form.addStaticText(line, nil, version)
end


-- load config
local function read(widget)
    widget.voltageSensor = storage.read("voltageSensor")
    widget.mahSensor = storage.read("mahSensor")
    widget.fuelSensor = storage.read("fuelSensor")
    widget.reserve = storage.read("reserve") or 20
    widget.low = storage.read("low") or 10
    widget.cellCount = storage.read("cellCount") or 6
    widget.minimal = storage.read("minimal") or false
end


-- save config
local function write(widget)
    storage.write("voltageSensor", widget.voltageSensor)
    storage.write("mahSensor", widget.mahSensor)
    storage.write("fuelSensor", widget.fuelSensor)
    storage.write("reserve", widget.reserve)
    storage.write("low", widget.low)
    storage.write("cellCount", widget.cellCount)
    storage.write("minimal", widget.minimal)
end


-- initialize / register widget
local function init()
    system.registerWidget({ key = "rngpbar", name = name, create = create, paint = paint, wakeup = wakeup, configure = configure, read = read, write = write })
end

return { init = init }