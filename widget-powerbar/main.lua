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
    return { color=lcd.RGB(0xEA, 0x5E, 0x00), source=nil, min=-1024, max=1024, value=0 }
end

local function paint(widget)
    local w, h = lcd.getWindowSize()

    if widget.source == nil then
        return
    end

    -- canvas
    local box_top, box_height = 2, h - 4
    local box_left, box_width = 2, w - 4

    -- Compute percentage
    local percent = (widget.value - widget.min) / (widget.max - widget.min) * 100
    if percent > 100 then
        percent = 100
    elseif percent < 0 then
        percent = 0
    end

    -- Gauge background
    gauge_width = math.floor((((box_width - 2) / 100) * percent) + 2)
    lcd.color(lcd.RGB(200, 200, 200))
    lcd.drawFilledRectangle(box_left, box_top, box_width, box_height)

    -- Gauge color
    lcd.color(widget.color)

    -- Gauge bar
    lcd.drawFilledRectangle(box_left, box_top, gauge_width, box_height)

    -- Gauge frame outline
    lcd.color(BLACK)
    lcd.drawRectangle(box_left, box_top, box_width, box_height)

    -- Source name and value
    lcd.font(FONT_L_BOLD)
    local text_w, text_h = lcd.getTextSize("")
    lcd.drawText(box_left + 8, 12, "26.7v / 3.81v (12s)")
    lcd.drawText(box_left + 8, box_top + (box_height - text_h) - 4, "4200 mah")

    -- Gauge percentage
    lcd.font(FONT_XXL)
    text_w, text_h = lcd.getTextSize("")
    lcd.drawText(box_left + box_width - 4, box_top + (box_height - text_h) + 2, math.floor(percent).."%", RIGHT)
end

local function wakeup(widget)
    if widget.source then
        local newValue = widget.source:value()
        if widget.value ~= newValue then
            widget.value = newValue
            lcd.invalidate()
        end
    end
end

local function configure(widget)
    -- Source choice
    line = form.addLine("Source")
    form.addSourceField(line, nil, function() return widget.source end, function(value) widget.source = value end)

    -- Color
    line = form.addLine("Color")
    form.addColorField(line, nil, function() return widget.color end, function(color) widget.color = color end)

    -- Min & Max
    line = form.addLine("Range")
    local slots = form.getFieldSlots(line, {0, "-", 0})
    form.addNumberField(line, slots[1], -1024, 1024, function() return widget.min end, function(value) widget.min = value end)
    form.addStaticText(line, slots[2], "-")
    form.addNumberField(line, slots[3], -1024, 1024, function() return widget.max end, function(value) widget.max = value end)
end

local function read(widget)
    widget.source = storage.read("source")
    widget.min = storage.read("min")
    widget.max = storage.read("max")
    widget.color = storage.read("color")
end

local function write(widget)
    storage.write("source", widget.source)
    storage.write("min", widget.min)
    storage.write("max", widget.max)
    storage.write("color", widget.color)
end

local function init()
    system.registerWidget({key="rngpbar", name=name, create=create, paint=paint, wakeup=wakeup, configure=configure, read=read, write=write})
end

return {init=init}
