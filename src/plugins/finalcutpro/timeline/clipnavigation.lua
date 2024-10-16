--- === plugins.finalcutpro.timeline.clipnavigation ===
---
--- Clip Navigation Actions.

local require = require

--local log               = require "hs.logger".new "clipnavigation"

local audiodevice       = require "hs.audiodevice"
local timer             = require "hs.timer"

local deferred          = require "cp.deferred"
local dialog            = require "cp.dialog"
local fcp               = require "cp.apple.finalcutpro"
local flicks            = require "cp.time.flicks"
local i18n              = require "cp.i18n"

local displayMessage    = dialog.displayMessage
local doAfter           = timer.doAfter

local plugin = {
    id = "finalcutpro.timeline.clipnavigation",
    group = "finalcutpro",
    dependencies = {
        ["finalcutpro.commands"]    = "fcpxCmds",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Only load plugin if Final Cut Pro is supported:
    --------------------------------------------------------------------------------
    if not fcp:isSupported() then return end

    local fcpxCmds = deps.fcpxCmds

    --------------------------------------------------------------------------------
    -- Select Middle of Next Clip In Same Storyline:
    --------------------------------------------------------------------------------
    fcpxCmds
        :add("selectMiddleOfNextClipInSameLane")
        :whenActivated(function()
            local timeline = fcp.timeline
            local contents = timeline.contents
            local selectedClips = contents:selectedClipsUI()
            if selectedClips and #selectedClips == 1 then
                local selectedClip = selectedClips[1]
                local clips = contents:clipsUI(true, function(clip)
                    local frame = clip:attributeValue("AXFrame")
                    local selectedClipFrame = selectedClip:attributeValue("AXFrame")
                    if frame.y == selectedClipFrame.y and frame.x >= (selectedClipFrame.x + selectedClipFrame.w) then
                        return true
                    end
                end)

                local nextClip
                for _, clip in pairs(clips) do
                    if not nextClip then
                        nextClip = clip
                    else
                        if clip:attributeValue("AXFrame").x < nextClip:attributeValue("AXFrame").x then
                            nextClip = clip
                        end
                    end
                end

                if nextClip then
                    contents:selectClip(nextClip)
                    --------------------------------------------------------------------------------
                    -- Annoyingly, we can't work out the timecode of clips in a secondary storyline.
                    --------------------------------------------------------------------------------
                    if nextClip:attributeValue("AXParent"):attributeValue("AXRole") == "AXLayoutArea" then
                        local frameRate = fcp.viewer:framerate() or 25

                        local startTC = nextClip:attributeValue("AXChildren")[1]:attributeValue("AXValue")
                        local endTC = nextClip:attributeValue("AXChildren")[2]:attributeValue("AXValue")

                        local startTCinFlicks = flicks.parse(startTC, frameRate)
                        local endTCinFlicks = flicks.parse(endTC, frameRate)

                        local duration = endTCinFlicks - startTCinFlicks

                        local newPosition = startTCinFlicks + duration / 2

                        local newPositionInTC = newPosition:toTimecode(frameRate, ":")

                        timeline.playhead:timecode(newPositionInTC)
                    end
                end
            else
                displayMessage(i18n("mustHaveSingleClipSelectedInTimeline"))
            end
        end)
        :titled(i18n("selectMiddleOfNextClipInSameStoryline"))

    --------------------------------------------------------------------------------
    -- Select Middle of Previous Clip In Same Storyline:
    --------------------------------------------------------------------------------
    fcpxCmds
        :add("selectMiddleOfPreviousClipInSameLane")
        :whenActivated(function()
            local timeline = fcp.timeline
            local contents = timeline.contents
            local selectedClips = contents:selectedClipsUI()
            if selectedClips and #selectedClips == 1 then
                local selectedClip = selectedClips[1]
                local clips = contents:clipsUI(true, function(clip)
                    local frame = clip:attributeValue("AXFrame")
                    local selectedClipFrame = selectedClip:attributeValue("AXFrame")
                    if frame.y == selectedClipFrame.y and frame.x < selectedClipFrame.x then
                        return true
                    end
                end)

                local previousClip
                for _, clip in pairs(clips) do
                    if not previousClip then
                        previousClip = clip
                    else
                        if clip:attributeValue("AXFrame").x > previousClip:attributeValue("AXFrame").x then
                            previousClip = clip
                        end
                    end
                end

                if previousClip then
                    contents:selectClip(previousClip)
                    --------------------------------------------------------------------------------
                    -- Annoyingly, we can't work out the timecode of clips in a secondary storyline.
                    --------------------------------------------------------------------------------
                    if previousClip:attributeValue("AXParent"):attributeValue("AXRole") == "AXLayoutArea" then
                        local frameRate = fcp.viewer:framerate() or 25

                        local startTC = previousClip:attributeValue("AXChildren")[1]:attributeValue("AXValue")
                        local endTC = previousClip:attributeValue("AXChildren")[2]:attributeValue("AXValue")

                        local startTCinFlicks = flicks.parse(startTC, frameRate)
                        local endTCinFlicks = flicks.parse(endTC, frameRate)

                        local duration = endTCinFlicks - startTCinFlicks

                        local newPosition = startTCinFlicks + duration / 2

                        local newPositionInTC = newPosition:toTimecode(frameRate, ":")

                        timeline.playhead:timecode(newPositionInTC)
                    end
                end
            else
                displayMessage(i18n("mustHaveSingleClipSelectedInTimeline"))
            end
        end)
        :titled(i18n("selectMiddleOfPreviousClipInSameStoryline"))

    --------------------------------------------------------------------------------
    -- Go to Next Frame (with muted audio):
    --------------------------------------------------------------------------------
    local nextFrame = deferred.new(0.01):action(function()
        local defaultOutputDevice = audiodevice.defaultOutputDevice()
        defaultOutputDevice:setMuted(true)
        fcp:doShortcut("JumpToNextFrame"):Now()
        doAfter(0.5, function() defaultOutputDevice:setMuted(false) end)
    end)
    fcpxCmds
        :add("goToNextFrameWithMutedAudio")
        :whenActivated(function()
            nextFrame()
        end)
        :titled(i18n("goToNextFrameWithMutedAudio"))
        :subtitled(i18n("goToNextFrameWithMutedAudioDescription"))

    --------------------------------------------------------------------------------
    -- Go to Previous Frame (with muted audio):
    --------------------------------------------------------------------------------
    local previousFrame = deferred.new(0.01):action(function()
        local defaultOutputDevice = audiodevice.defaultOutputDevice()
        defaultOutputDevice:setMuted(true)
        fcp:doShortcut("JumpToPreviousFrame"):Now()
        doAfter(0.5, function() defaultOutputDevice:setMuted(false) end)
    end)
    fcpxCmds
        :add("goToPreviousFrameWithMutedAudio")
        :whenActivated(function()
            previousFrame()
        end)
        :titled(i18n("goToPreviousFrameWithMutedAudio"))
        :subtitled(i18n("goToPreviousFrameWithMutedAudioDescription"))

end

return plugin
