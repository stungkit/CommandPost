--- === plugins.finalcutpro.browser.soloclip ===
---
--- Solo a clip in the Final Cut Pro Browser.

local require   = require

local log       = require "hs.logger".new "soloclip"

local fcp       = require "cp.apple.finalcutpro"
local tools     = require "cp.tools"

local plugin = {
    id              = "finalcutpro.browser.soloclip",
    group           = "finalcutpro",
    dependencies    = {
        ["finalcutpro.commands"] = "fcpxCmds",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Only load plugin if FCPX is supported:
    --------------------------------------------------------------------------------
    if not fcp:isSupported() then return end

    local soloClip = function()
        --------------------------------------------------------------------------------
        -- Make sure the libraries window is open:
        --------------------------------------------------------------------------------
        fcp.menu:selectMenu({"Window", "Go To", "Libraries"})

        --------------------------------------------------------------------------------
        -- Check that there is exactly one Selected Clip:
        --------------------------------------------------------------------------------
        local libraries = fcp.libraries
        local selectedClips = libraries:selectedClipsUI()
        if not selectedClips or #selectedClips ~= 1 then
            tools.playErrorSound()
            log.df("No clips selected.")
            return
        end

        --------------------------------------------------------------------------------
        -- Get Clip Name from the Viewer
        --------------------------------------------------------------------------------
        local clipName = fcp.viewer:title()

        if clipName then
            --------------------------------------------------------------------------------
            -- Ensure the Search Bar is visible
            --------------------------------------------------------------------------------
            if not libraries.search:isShowing() then
                libraries:searchToggle()
            end

            --------------------------------------------------------------------------------
            -- Search for the title
            --------------------------------------------------------------------------------
            libraries.search(clipName)
        else
            tools.playErrorSound()
            log.ef("Unable to find the clip title.")
        end
    end

    --------------------------------------------------------------------------------
    -- Setup Commands:
    --------------------------------------------------------------------------------
    deps.fcpxCmds:add("cpSoloClipInBrowser")
        :groupedBy("browser")
        :whenActivated(soloClip)
end

return plugin
