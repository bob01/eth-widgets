--[[
#########################################################################
#                                                                       #
# Powerbar widget for FrSky ETHOS                                       #
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
-- Thanks to Rob Thomson for the rfSuite interop
-- Date: 2025
local version = nil

-- metadata
local widgetDir = "/scripts/ethwidgets/"
local bmpDir = "/bitmaps/models/"

local translations = { en="eBitmap" }

local function name(widget)
    local locale = system.getLocale()
    return translations[locale] or translations["en"]
end

--------------------------------------------------------------
-- constants

local COLOR_DISABLED = lcd.GREY(0x7F)

local textAlignment = {
    { "Left", TEXT_LEFT },
    { "Centered", TEXT_CENTERED },
    { "Right", TEXT_RIGHT },
}


--------------------------------------------------------------
-- code

-- ctor
local function create()
    local widget =
    {
        -- options
        useFblParams = rfsuite and rfsuite.session ~= nil,
        textAlignment = TEXT_CENTERED,

        -- constant
        bmpNone = lcd.loadBitmap(widgetDir .. "bitmaps/heli_bitmap.png"),

        -- state
        modelName = nil,
        craftName = nil,
        bitmap = nil,
        bmp = nil,
        craftBmp = nil,
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
    local bmp = widget.craftBmp or widget.bmp or  widget.bmpNone
    if bmp then
        local bw = bmp:width()
        local bh = bmp:height()
        lcd.setClipping()
        lcd.drawBitmap(box_left + (box_width - bw) / 2, box_top + text_h + (box_height - bh) / 2, bmp)
    end

    -- title
    local tx
    if widget.textAlignment == TEXT_LEFT then
        tx = box_left + margin * 2
    elseif widget.textAlignment == TEXT_CENTERED then
        tx = box_left + box_width / 2
    else
        tx = box_left + box_width - margin * 2
    end
    lcd.color(lcd.themeColor(THEME_DEFAULT_COLOR))
    lcd.drawText(tx, box_top + margin, widget.craftName or widget.modelName or "---", widget.textAlignment)
end


-- process sensors, pre-render
local function wakeup(widget)
    -- model name
    if widget.modelName ~= model.name() then
        widget.modelName = model.name()
        lcd.invalidate()
    end

    -- craft name
    if widget.useFblParams then
        -- use rfsuite
        local craftName = rfsuite.session ~= nil and rfsuite.session.craftName or nil
        if craftName and widget.craftName ~= craftName then
            widget.craftName = craftName
            lcd.invalidate()

            -- load craft bitmap
            local bmpFile = bmpDir .. craftName
            local bmp = (os.stat(bmpFile .. ".png") and lcd.loadBitmap(bmpFile .. ".png")) or
                        (os.stat(bmpFile .. ".bmp") and lcd.loadBitmap(bmpFile .. ".bmp")) or nil
            widget.craftBmp = bmp
        end
    elseif widget.craftName or widget.craftBmp then
        -- don't use, dump
        widget.craftName = nil
        widget.craftBmp = nil
    end

    -- bitmap
    local bitmap = model.bitmap()
    if widget.bitmap ~= bitmap then
        widget.bitmap = bitmap
        lcd.invalidate()

        -- use new bitmap (or not)
        widget.bmp = bitmap and #bitmap > 0 and lcd.loadBitmap(widget.bitmap) or nil
    end
end


-- config UI
local function configure(widget)
    local craftNameAvailable = rfsuite and rfsuite.session ~= nil
    local line = form.addLine("Use RotorFlight name / image")
    local field = form.addBooleanField(line, nil, function() return craftNameAvailable and widget.useFblParams end, function(value) widget.useFblParams = value end)
    field:enable(craftNameAvailable)

    line = form.addLine("Text alignment")
    form.addChoiceField(line, nil, textAlignment, function() return widget.textAlignment end, function(value) widget.textAlignment = value end)

    -- version
    line = form.addLine("Version")
    form.addStaticText(line, nil, version)

end


-- load config
local function read(widget)
    local version = storage.read("version")

    widget.useFblParams = storage.read("useFblParams")
    widget.textAlignment = storage.read("textAlignment")
end


-- save config
local function write(widget)
    storage.write("version", 1)

    storage.write("useFblParams", widget.useFblParams)
    storage.write("textAlignment", widget.textAlignment)
end


-- initialize / register widget
local function init(ver)
    -- save global version
    version = ver

    system.registerWidget({ key = "rngebmp", name = name, create = create, paint = paint, wakeup = wakeup, configure = configure, read = read, write = write, title = false })
end

return { init = init }