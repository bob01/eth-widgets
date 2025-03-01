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
local widgetDir = "/scripts/widget-ebitmap/"
local bmpDir = "/bitmaps/models/"

local translations = { en="eBitmap" }

local function name(widget)
    local locale = system.getLocale()
    return translations[locale] or translations["en"]
end

--------------------------------------------------------------
-- constants

local COLOR_DISABLED = lcd.GREY(0x7F)

-- ctor
local function create()
    local widget =
    {
        -- sensors
        sensorModelId = system.getSource("Model ID"),

        -- options
        bitmap = nil,
        bitmapLast = nil,
        textColor = WHITE,

        -- state
        active = false,

        bmpNone = lcd.loadBitmap(widgetDir .. "bitmaps/heli_bitmap.png"),
        modelId = nil,
        bmp = nil,

        craftName = nil,
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

    -- text
    lcd.font(FONT_L_BOLD)
    local _, text_h = lcd.getTextSize("")

    -- bitmap
    local bmp = widget.bmp or  widget.bmpNone
    if bmp then
        local bw = bmp:width()
        local bh = bmp:height()
        lcd.setClipping()
        lcd.drawBitmap(box_left + (box_width - bw) / 2, box_top + text_h + (box_height - bh) / 2, bmp)
    end

    -- title
    lcd.color(widget.active and widget.textColor or COLOR_DISABLED)
    lcd.drawText(box_left + margin * 2, box_top + margin, widget.craftName or "---")
end


-- process sensors, pre-render
local function wakeup(widget)
    -- telemetry active?
    local active = widget.sensorModelId and widget.sensorModelId:state()
    if widget.active ~= active then
        widget.active = active
        lcd.invalidate()
    end

    -- craft name (use model name until name from FBL available)
    local craftName = model.name()
    -- print(craftName)
    if widget.craftName ~= craftName then
        widget.craftName = craftName
        lcd.invalidate()
    end

    -- bitmap
    if widget.bitmapLast ~= widget.bitmap then
        widget.bitmapLast = widget.bitmap
        lcd.invalidate()

        -- use new bitmap (or not)
        widget.bmp = widget.bitmap and lcd.loadBitmap(bmpDir .. widget.bitmap) or nil

        -- force model ID recalc
        if widget.bitmap == nil then
            widget.modelId = nil
        end
    end

    -- model ID
    local modelId = widget.sensorModelId and widget.sensorModelId:value()
    if widget.modelId ~= modelId then
        widget.modelId = modelId
        lcd.invalidate()

        if widget.bitmap == nil then
            -- bitmap not explicitly specified, use modelId
            if modelId then
                -- derive from model ID
                local bitmapFile = string.format("%sheli-%.0f", bmpDir, modelId)
                -- print(bitmapFile)
                widget.bmp = lcd.loadBitmap(bitmapFile .. ".bmp") or lcd.loadBitmap(bitmapFile .. ".png")
            else
                -- none available
                widget.bmp = nil
            end
        end
    end
end


-- config UI
local function configure(widget)
    -- Sensor choices
    local line = form.addLine("Picture")
    form.addBitmapField(line, nil, bmpDir, function() return widget.bitmap end, function(newValue) widget.bitmap = #newValue > 0 and newValue or nil end)

    line = form.addLine("Text color")
    form.addColorField(line, nil, function() return widget.textColor end, function(value) widget.textColor = value end)

end


-- load config
local function read(widget)
    local version = storage.read("version")

    widget.picture = storage.read("bitmap")
    widget.textColor = storage.read("textColor")
end


-- save config
local function write(widget)
    storage.write("version", 1)

    storage.write("bitmap", widget.bitmap)
    storage.write("textColor", widget.textColor)
end


-- initialize / register widget
local function init()
    system.registerWidget({ key = "rngebmp", name = name, create = create, paint = paint, wakeup = wakeup, configure = configure, read = read, write = write })
end

return { init = init }