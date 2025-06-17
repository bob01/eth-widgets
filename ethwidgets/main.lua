--[[
#########################################################################
#                                                                       #
# ethwidgets for FrSky ETHOS                                            #
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
-- Date: 2024, 2025

-- Collection of layouts and widgets for the ETHOS operating system
local version = "v1.0.4"


-- initialize / register layouts and widgets
local function init()
    -- layouts
    local layouts = assert(loadfile("layouts/layouts.lua"))()
    layouts.init(version)

    -- widgets
    local ebitmap = assert(loadfile("widget/ebitmap/ebitmap.lua"))()
    ebitmap.init(version)

    local egovernor = assert(loadfile("widget/egovernor/egovernor.lua"))()
    egovernor.init(version)

    local epowerbar = assert(loadfile("widget/epowerbar/epowerbar.lua"))()
    epowerbar.init(version)
end

return { init = init }