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
local version = "v0.2.2"

local function init()
    -- extents
    local sx = 0
    local sy
    local sw
    local sh
    local sp = 8

    -- get screen size
    local version = system.getVersion()
    sw = version.lcdWidth
    if version.lcdHeight == 480 then
      -- X20S family (800x480)
      sy = 95
      sh = 336
    elseif version.lcdHeight == 320 then
      -- X18 family (480x320)
      sy = 60
      sh = 240
    else
      -- unsupported
      sy = 60
      sh = 240
    end

    -- left pane width, cell heights
    local cwl = sw * 2 / 3
    local ch = sh / 4

    -- layout
    local widgets = {}

    -- row 1
    local x = sx
    local y = sy
    local cwb = cwl / 4
    local cw = cwb
    widgets[#widgets + 1] = { x = x,        y = y,          w = cwb - sp,       h = ch - sp }

    x = x + cw
    widgets[#widgets + 1] = { x = x,        y = y,          w = cw - sp,        h = ch - sp }

    x = x + cw
    widgets[#widgets + 1] = { x = x,        y = y,          w = cw - sp,        h = ch - sp }

    x = x + cw
    widgets[#widgets + 1] = { x = x,        y = y,          w = cw - sp,        h = ch - sp }

    -- row 2
    x = sx
    y = y + ch
    widgets[#widgets + 1] = { x = x,        y = y,          w = cwl - sp,       h = ch - sp }

    -- row 3
    x = sx
    y = y + ch
    cwb = cwl / 2
    cw = cwb
    widgets[#widgets + 1] = { x = x,        y = y,          w = cw - sp,        h = ch - sp }

    x = x + cw
    widgets[#widgets + 1] = { x = x,        y = y,          w = cw - sp,        h = ch - sp }

    -- row 4
    x = sx
    y = y + ch
    cw = cwl
    widgets[#widgets + 1] = { x = x,        y = y,          w = cw - sp,        h = ch - sp }

    x = x + cw
    cw = sw - cwl
    widgets[#widgets + 1] = { x = x,        y = y,          w = cw,             h = ch - sp }

    -- image
    y = sy
    widgets[#widgets + 1] = { x = cwl,      y = y,          w = sw - cwl,       h = ch * 3 - sp }

    -- register
    system.registerLayout({ key = "rngelay0", widgets = widgets })
  end

  return { init = init }