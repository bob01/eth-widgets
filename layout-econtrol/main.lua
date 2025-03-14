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
local version = "v0.2.8"

local function init()
    -- extents
    local sx = 0
    local sy
    local sw
    local sh
    local sp = 8
    local trimx
    local trimy
    local twl

    -- get screen size
    local version = system.getVersion()
    sw = version.lcdWidth
    if version.lcdHeight == 480 then
      -- X20S family (800x480)
      sy = 95
      sh = 336
      trimx = 40
      trimy = 40
      twl = sw / 2.65
    elseif version.lcdHeight == 320 then
      -- X18 family (480x320)
      sy = 60
      sh = 240
      trimx = 24
      trimy = 24
      twl = sw / 2.4
    else
      -- unsupported
      sy = 60
      sh = 240
      trimx = 24
      trimy = 24
      twl = sw / 2.4
    end

    -- left pane width, cell heights
    local cwl = sw * 2 / 3
    local ch = sh / 4

    -- heli control layout (no trims)
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

    -- air control layout (trims)
    widgets = {}
    local trims = {}

    -- left pane width, cell heights
    local tx = trimx
    local ty = sy
    local tw = sw - trimx * 2
    local th = sh - trimy + sp
    local cwl = tw * 2 / 3
    local ch = th / 4

    -- row 1
    x = tx
    y = ty
    cwb = cwl / 4
    cw = cwb
    widgets[#widgets + 1] = { x = x,        y = y,          w = cwb - sp,       h = ch - sp }
    x = x + cw
    widgets[#widgets + 1] = { x = x,        y = y,          w = cw - sp,        h = ch - sp }
    x = x + cw
    widgets[#widgets + 1] = { x = x,        y = y,          w = cw - sp,        h = ch - sp }
    x = x + cw
    widgets[#widgets + 1] = { x = x,        y = y,          w = cw - sp,        h = ch - sp }

    -- row 2
    x = tx
    y = y + ch
    cw = cwl - sp
    widgets[#widgets + 1] = { x = x,        y = y,          w = cw,             h = ch - sp }

    -- row 3
    x = tx
    y = y + ch
    cwb = cwl / 2
    cw = cwb
    widgets[#widgets + 1] = { x = x,        y = y,          w = cw - sp,        h = ch - sp }
    x = x + cw
    widgets[#widgets + 1] = { x = x,        y = y,          w = cw - sp,        h = ch - sp }

    -- row 4
    x = tx
    y = y + ch
    cw = cwl
    widgets[#widgets + 1] = { x = x,        y = y,          w = cw - sp,        h = ch - sp }
    x = x + cw
    cw = tw - cwl
    widgets[#widgets + 1] = { x = x,        y = y,          w = cw,             h = ch - sp }

    -- image
    x = tx + cwl
    y = ty
    cw = tw - cwl
    widgets[#widgets + 1] = { x = x,        y = y,          w = cw,             h = ch * 3 - sp }

    -- trims
    -- rudder
    x = sx + trimx + sp
    y = ty + th - sp
    local w = (tw - trimx) / 2
    trims[#trims + 1] =     { x = x,         y = y,        w = w,              h = trimy }
    -- throttle
    x = sx
    y = sy + sp * 2
    local h = th
    trims[#trims + 1] =     { x = x,         y = y,        w = trimx,          h = h }
    -- elevator
    x = sx + sw - trimx
    y = sy + sp * 2
    h = th
    trims[#trims + 1] =     { x = x,         y = y,        w = trimx,          h = h }
    -- aileron
    x = sw - (twl + sp)
    y = ty + th - sp
    w = (tw - trimx) / 2
    trims[#trims + 1] =     { x = x,         y = y,        w = w,              h = trimy }

    -- register
    system.registerLayout({ key = "rngeair0", widgets = widgets, trims = trims })


    -- summary layout
    widgets = {}
    cw = sw / 4
    ch = sh / 3

    y = sy
    for row = 1, 3 do
      -- for each row
      x = sx + sp / 2
      for col = 1, 4 do
        -- for each column
        widgets[#widgets + 1] = { x = x,    y = y,          w = cw - sp,        h = ch - sp }
        x = x + cw
      end
      y = y + ch
    end

    -- register
    system.registerLayout({ key = "rngesum0", widgets = widgets })
  end

  return { init = init }