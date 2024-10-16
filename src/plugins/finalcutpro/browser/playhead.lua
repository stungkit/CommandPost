--- === plugins.finalcutpro.browser.playhead ===
---
--- Browser Playhead Plugin.

local require           = require

local dialog            = require "hs.dialog"
local drawing           = require "hs.drawing"
local geometry          = require "hs.geometry"
local timer             = require "hs.timer"

local config            = require "cp.config"
local fcp               = require "cp.apple.finalcutpro"
local i18n              = require "cp.i18n"
local tools             = require "cp.tools"
local ui                = require "cp.web.ui"

local doAfter           = timer.doAfter
local doEvery           = timer.doEvery

local mod = {}

-- DEFAULT_TIME -> number
-- Constant
-- Default Time
local DEFAULT_TIME = 3

-- DEFAULT_COLOR -> string
-- Constant
-- Default Color
local DEFAULT_COLOR = "Red"

-- SHAPE_RECTANGLE -> string
-- Constant
-- Rectangle Shape
local SHAPE_RECTANGLE = "Rectangle"

-- SHAPE_CIRCLE -> string
-- Constant
-- Circle Shape
local SHAPE_CIRCLE = "Circle"

-- SHAPE_DIAMOND -> string
-- Constant
-- Diamond Shape
local SHAPE_DIAMOND = "Diamond"

--- plugins.finalcutpro.browser.playhead.getHighlightColor() -> table
--- Function
--- Returns the current highlight colour.
---
--- Parameters:
---  * None
---
--- Returns:
---  * An RGB table with the selected colour (see `hs.drawing.color`) or `nil`
function mod.getHighlightColor()
    return config.get("displayHighlightColour", DEFAULT_COLOR)
end

--- plugins.finalcutpro.browser.playhead.setHighlightColor([value]) -> none
--- Function
--- Sets the Playhead Highlight Colour.
---
--- Parameters:
---  * value - An RGB table with the selected colour (see `hs.drawing.color`)
---
--- Returns:
---  * None
function mod.setHighlightColor(value)
    config.set("displayHighlightColour", value)
end

--- plugins.finalcutpro.browser.playhead.getHighlightCustomColor() -> table
--- Function
--- Returns the current custom highlight colour.
---
--- Parameters:
---  * None
---
--- Returns:
---  * An RGB table with the selected colour (see `hs.drawing.color`) or `nil`
function mod.getHighlightCustomColor()
    return config.get("displayHighlightCustomColour")
end

--- plugins.finalcutpro.browser.playhead.setHighlightCustomColor([value]) -> none
--- Function
--- Sets the Custom Playhead Highlight Colour.
---
--- Parameters:
---  * value - An RGB table with the selected colour (see `hs.drawing.color`)
---
--- Returns:
---  * None
function mod.setHighlightCustomColor(value)
    config.set("displayHighlightCustomColour", value)
end

--- plugins.finalcutpro.browser.playhead.changeHighlightColor([value]) -> none
--- Function
--- Prompts the user to change the Playhead Highlight Colour.
---
--- Parameters:
---  * value - An RGB table with the selected colour (see `hs.drawing.color`)
---
--- Returns:
---  * None
function mod.changeHighlightColor(value)
    mod.setHighlightColor(value)
    if value=="Custom" then
        local currentColor = mod.getHighlightCustomColor()
        if currentColor then
            dialog.color.color(currentColor)
        end
        dialog.color.callback(function(color)
            mod.setHighlightCustomColor(color)
        end)
        dialog.color.show()
    end
end

--- plugins.finalcutpro.browser.playhead.getHighlightShape() -> string
--- Function
--- Returns the current highlight shape.
---
--- Parameters:
---  * None
---
--- Returns:
---  * "Rectangle", "Circle" or "Diamond" or `nil`.
function mod.getHighlightShape()
    return config.get("displayHighlightShape", SHAPE_RECTANGLE)
end

--- plugins.finalcutpro.browser.playhead.setHighlightShape([value]) -> none
--- Function
--- Sets the Custom Playhead Highlight Shape.
---
--- Parameters:
---  * value - A string which can be "Rectangle", "Circle" or "Diamond".
---
--- Returns:
---  * None
function mod.setHighlightShape(value)
    config.set("displayHighlightShape", value)
end

--- plugins.finalcutpro.browser.playhead.getHighlightTime() -> number
--- Function
--- Returns the current highlight playhead time.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A number or `nil`
function mod.getHighlightTime()
    return tonumber(config.get("highlightPlayheadTime", DEFAULT_TIME))
end

--- plugins.finalcutpro.browser.playhead.setHighlightTime([value]) -> none
--- Function
--- Sets the Custom Playhead Highlight Time.
---
--- Parameters:
---  * value - A number
---
--- Returns:
---  * None
function mod.setHighlightTime(value)
    config.set("highlightPlayheadTime", value)
end

--- plugins.finalcutpro.browser.playhead.highlight() -> none
--- Function
--- Highlight's the Final Cut Pro Browser Playhead.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.highlight()

    --------------------------------------------------------------------------------
    -- Delete any pre-existing highlights:
    --------------------------------------------------------------------------------
    mod.deleteHighlight()

    --------------------------------------------------------------------------------
    -- Get Browser Persistent Playhead:
    --------------------------------------------------------------------------------
    local playhead = fcp.libraries:playhead()
    if playhead:isShowing() then
        mod.highlightFrame(playhead:frame())
    end
end

--- plugins.finalcutpro.browser.playhead.highlightFrame([frame]) -> none
--- Function
--- Highlights a specific frame.
---
--- Parameters:
---  * frame - Frame as per `hs.geometry.rect`
---
--- Returns:
---  * None
function mod.highlightFrame(frame)
    --------------------------------------------------------------------------------
    -- Delete Previous Highlights:
    --------------------------------------------------------------------------------
    mod.deleteHighlight()

    --------------------------------------------------------------------------------
    -- Get Sizing Preferences:
    --------------------------------------------------------------------------------
    local displayHighlightShape
    displayHighlightShape = config.get("displayHighlightShape")
    if displayHighlightShape == nil then displayHighlightShape = "Rectangle" end

    --------------------------------------------------------------------------------
    -- Get Highlight Colour Preferences:
    --------------------------------------------------------------------------------
    local displayHighlightColour = config.get("displayHighlightColour", "Red")
    if displayHighlightColour == "Red" then     displayHighlightColour = {["red"]=1,["blue"]=0,["green"]=0,["alpha"]=1}     end
    if displayHighlightColour == "Blue" then    displayHighlightColour = {["red"]=0,["blue"]=1,["green"]=0,["alpha"]=1}     end
    if displayHighlightColour == "Green" then   displayHighlightColour = {["red"]=0,["blue"]=0,["green"]=1,["alpha"]=1}     end
    if displayHighlightColour == "Yellow" then  displayHighlightColour = {["red"]=1,["blue"]=0,["green"]=1,["alpha"]=1}     end
    if displayHighlightColour == "Custom" then
        local displayHighlightCustomColour = config.get("displayHighlightCustomColour")
        displayHighlightColour = {red=displayHighlightCustomColour["red"],blue=displayHighlightCustomColour["blue"],green=displayHighlightCustomColour["green"],alpha=1}
    end

    --------------------------------------------------------------------------------
    -- Highlight the FCPX Browser Playhead:
    --------------------------------------------------------------------------------
    if displayHighlightShape == SHAPE_RECTANGLE then
        mod.browserHighlight = drawing.rectangle(geometry.rect(frame.x, frame.y, frame.w, frame.h - 12))
    elseif displayHighlightShape == SHAPE_CIRCLE then
        mod.browserHighlight = drawing.circle(geometry.rect((frame.x-(frame.h/2)+10), frame.y, frame.h-12,frame.h-12))
    elseif displayHighlightShape == SHAPE_DIAMOND then
        mod.browserHighlight = drawing.circle(geometry.rect(frame.x, frame.y, frame.w, frame.h - 12))
    end
    mod.browserHighlight:setStrokeColor(displayHighlightColour)
                        :setFill(false)
                        :setStrokeWidth(5)
                        :bringToFront(true)
                        :show()

    --------------------------------------------------------------------------------
    -- Update the Highlight position every 0.01 seconds:
    --------------------------------------------------------------------------------
    mod.updateTimer = doEvery(0.01, function()
        local f = fcp.libraries:playhead():frame()
        if mod.browserHighlight and f then
            if displayHighlightShape == SHAPE_RECTANGLE then
                mod.browserHighlight:setFrame(geometry.rect(f.x, f.y, f.w, f.h - 12))
            elseif displayHighlightShape == SHAPE_CIRCLE then
                mod.browserHighlight:setFrame(geometry.rect((f.x-(f.h/2)+10), f.y, f.h-12,f.h-12))
            elseif displayHighlightShape == SHAPE_DIAMOND then
                mod.browserHighlight:setFrame(geometry.rect(f.x, f.y, f.w, f.h - 12))
            end
        end
    end)

    --------------------------------------------------------------------------------
    -- Set a timer to delete the circle after the configured time:
    --------------------------------------------------------------------------------
    mod.browserHighlightTimer = doAfter(mod.getHighlightTime(), mod.deleteHighlight)
end

--- plugins.finalcutpro.browser.playhead.deleteHighlight() -> none
--- Function
--- Delete's the highlight if it's currently visible on the screen.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.deleteHighlight()
    if mod.updateTimer then
        mod.updateTimer:stop()
        mod.updateTimer = nil
    end
    if mod.browserHighlightTimer then
        mod.browserHighlightTimer:stop()
        mod.browserHighlightTimer = nil
    end
    if mod.browserHighlight then
        mod.browserHighlight:delete()
        mod.browserHighlight = nil
    end
end

-- timeOptions() -> none
-- Function
-- Returns a list of time options for the select.
--
-- Parameters:
--  * None
--
-- Returns:
--  * table
local function timeOptions()
    local timeOptionsTable = {}
    for i=1, 10 do
        timeOptionsTable[#timeOptionsTable + 1] = {
            label = i18n(string.lower(tools.numberToWord(i))) .. " " .. i18n("secs", {count=i}),
            value = i,
        }
    end
    return timeOptionsTable
end

local plugin = {
    id              = "finalcutpro.browser.playhead",
    group           = "finalcutpro",
    dependencies    = {
        ["finalcutpro.commands"]        = "fcpxCmds",
        ["finalcutpro.preferences.manager"] = "prefs",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Only load plugin if FCPX is supported:
    --------------------------------------------------------------------------------
    if not fcp:isSupported() then return end

    --------------------------------------------------------------------------------
    -- Remove Highlight when Final Cut Pro is inactive:
    --------------------------------------------------------------------------------
    fcp.app.frontmost:watch(function(frontmost)
        if not frontmost then
            mod.deleteHighlight()
        end
    end)

    --------------------------------------------------------------------------------
    -- Remove Highlight when a modal window like Command Editor is open:
    --------------------------------------------------------------------------------
    fcp.app.modalDialogOpen:watch(function(open)
        if open then
            mod.deleteHighlight()
        end
    end)

    --------------------------------------------------------------------------------
    -- Setup Preferences Panel:
    --------------------------------------------------------------------------------
    local panel = deps.prefs.panel
    if panel then
        panel

            :addContent(2000, ui.style ([[
                .highLightPlayheadSelect {
                    width: 100px;
                    float: left;
                }
                .highlightPlayheadDiv::after {
                  content: "";
                  clear: both;
                  display: table;
                }
            ]]))
            :addContent(2000.1,[[<div class="highlightPlayheadDiv">]], false)
            :addHeading(2000.2, i18n("highlightPlayhead"))
            :addSelect(2000.3,
            {
                label       = i18n("highlightPlayheadColour"),
                value       = mod.getHighlightColor,
                options     = {
                    {
                        label = i18n("red"),
                        value = "Red",
                    },
                    {
                        label = i18n("blue"),
                        value = "Blue",
                    },
                    {
                        label = i18n("green"),
                        value = "Green",
                    },
                    {
                        label = i18n("yellow"),
                        value = "Yellow",
                    },
                    {
                        label = i18n("custom"),
                        value = "Custom",
                    },
                },
                required    = true,
                onchange    = function(_, params) mod.changeHighlightColor(params.value) end,
                class       = "highLightPlayheadSelect",
            })
            :addSelect(2000.4,
            {
                label       = i18n("highlightPlayheadShape"),
                value       = mod.getHighlightShape,
                options     = {
                    {
                        label = i18n("rectangle"),
                        value = SHAPE_RECTANGLE,
                    },
                    {
                        label = i18n("circle"),
                        value = SHAPE_CIRCLE,
                    },
                    {
                        label = i18n("diamond"),
                        value = SHAPE_DIAMOND,
                    },
                },
                required    = true,
                onchange    = function(_, params) mod.setHighlightShape(params.value) end,
                class       = "highLightPlayheadSelect",
            })
            :addSelect(2000.5,
            {
                label       = i18n("highlightPlayheadTime"),
                value       = mod.getHighlightTime,
                options     = timeOptions(),
                required    = true,
                onchange    = function(_, params) mod.setHighlightTime(params.value) end,
                class       = "highLightPlayheadSelect",
            })
            :addContent(2000.6,"</div>", false)
    end

    --------------------------------------------------------------------------------
    -- Setup Commands:
    --------------------------------------------------------------------------------
    deps.fcpxCmds:add("cpHighlightBrowserPlayhead")
        :groupedBy("browser")
        :activatedBy():cmd():option():ctrl("h")
        :whenActivated(mod.highlight)

    return mod
end

return plugin
