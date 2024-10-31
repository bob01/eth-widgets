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

-- Author: Rob Gayle (bob00@rogers.com)
-- Date: 2024
-- ver: 0.1.0
]]

local translations = { en="Powerbar" }

local function name(widget)
    local locale = system.getLocale()
    return translations[locale] or translations["en"]
end

local function create()
    local widget =
    {
        -- sensors
        voltageSensor = nil,
        mahSensor = nil,
        fuelSensor = nil,

        -- pack
        cellCount = 12,

        -- state
        volts = nil,
        mah = nil,
        fuel = nil,

        linked = false,
        textColor = BLACK,

        -- methods
        setReserve = function(widget, value)
            widget.reserve = value
            widget.critical = widget.reserve > 0 and widget.reserve or 20
        end
    }

    return widget
end

-- color for bar
local function getBarColor(widget)
    local critical = widget.reserve == 0 and widget.critical or 0
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

local function paint(widget)
    local w, h = lcd.getWindowSize()

    -- canvas
    local box_top, box_height = 2, h - 4
    local box_left, box_width = 2, w - 4

    -- background
    lcd.color(lcd.RGB(200, 200, 200))
    lcd.drawFilledRectangle(box_left, box_top, box_width, box_height)

    -- bar
    if widget.fuel then
        local fill = widget.fuel >= 0 and widget.fuel or 100
        local bar_width = math.floor((((box_width - 2) / 100) * fill) + 2)
        lcd.color(getBarColor(widget))
        lcd.drawFilledRectangle(box_left, box_top, bar_width, box_height)
    end

    -- outline
    lcd.color(BLACK)
    lcd.drawRectangle(box_left, box_top, box_width, box_height)

    -- Source name and value
    lcd.font(FONT_L_BOLD)
    lcd.color(widget.textColor)
    local text_w, text_h = lcd.getTextSize("")

    -- voltage
    if widget.voltageSensor and widget.volts then
        local text = string.format("%.1fv / %.2fv (%.0fs)", widget.volts, widget.volts / widget.cellCount, widget.cellCount)
        lcd.drawText(box_left + 8, 12, text)
    end

    -- mah
    if widget.mahSensor and widget.mah then
        local text = string.format("%.0f mah", widget.mah)
        lcd.drawText(box_left + 8, box_top + (box_height - text_h) - 4, text)
    end

    -- fuel
    lcd.font(FONT_XXL)
    _, text_h = lcd.getTextSize("")
    if widget.fuelSensor and widget.fuel then
        local text = string.format("%.0f%%", widget.fuel)
        lcd.drawText(box_left + box_width - 4, box_top + (box_height - text_h) + 2, text, RIGHT)
    else
        lcd.drawText(box_left + box_width - 4, box_top + (box_height - text_h) + 2, "--- %", RIGHT)
    end
end

local function wakeup(widget)
    -- connection state
    local linked = widget.voltageSensor and widget.voltageSensor:state()
    if widget.linked ~= linked then
        widget.linked = linked
        widget.textColor = linked and BLACK or lcd.GREY(0x30)
        lcd.invalidate()
    end


    -- voltage
    local volts = widget.voltageSensor and widget.voltageSensor:value() or nil
    if widget.volts ~= volts then
        widget.volts = volts
        lcd.invalidate()
    end

    -- mah
    local mah = widget.mahSensor and widget.mahSensor:value() or nil
    if widget.mah ~= mah then
        widget.mah = mah
        lcd.invalidate()
    end

    -- fuel
    local fuel = nil
    if widget.fuelSensor then
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
    if widget.fuel ~= fuel then
        widget.fuel = fuel
        lcd.invalidate()
    end
end

local function configure(widget)
    -- Sensor choices
    line = form.addLine("Voltage (v) Sensor")
    form.addSourceField(line, nil, function() return widget.voltageSensor end, function(value) widget.voltageSensor = value end)

    line = form.addLine("Consumption (mAh) Sensor")
    form.addSourceField(line, nil, function() return widget.mahSensor end, function(value) widget.mahSensor = value end)

    line = form.addLine("Fuel (%) Sensor")
    form.addSourceField(line, nil, function() return widget.fuelSensor end, function(value) widget.fuelSensor = value end)

    -- Reserve
    line = form.addLine("Reserve")
    form.addNumberField(line, nil, 0, 40, function() return widget.reserve end, function(value) widget:setReserve(value) end)
    
    -- Cell count
    line = form.addLine("Cell Count")
    form.addNumberField(line, nil, 2, 16, function() return widget.cellCount end, function(value) widget.cellCount = value end)
end

local function read(widget)
    widget.voltageSensor = storage.read("voltageSensor")
    widget.mahSensor = storage.read("mahSensor")
    widget.fuelSensor = storage.read("fuelSensor")
    widget:setReserve(storage.read("reserve") or 20)
    widget.cellCount = storage.read("cellCount") or 6
end

local function write(widget)
    storage.write("voltageSensor", widget.voltageSensor)
    storage.write("mahSensor", widget.mahSensor)
    storage.write("fuelSensor", widget.fuelSensor)
    storage.write("reserve", widget.reserve)
    storage.write("cellCount", widget.cellCount)
end

local function init()
    system.registerWidget({ key = "rngpbar", name = name, create = create, paint = paint, wakeup = wakeup, configure = configure, read = read, write = write })
end

return {init=init}