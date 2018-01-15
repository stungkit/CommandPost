--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.apple.finalcutpro.main.Playhead ===
---
--- Playhead Module.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local axutils							= require("cp.ui.axutils")
local geometry							= require("hs.geometry")
local prop								= require("cp.prop")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local Playhead = {}

-- TODO: Add documentation
function Playhead.matches(element)
	return element and element:attributeValue("AXRole") == "AXValueIndicator"
end

-- TODO: Add documentation
-- Finds the playhead (either persistent or skimming) in the specified container.
-- Defaults to persistent.
function Playhead.find(containerUI, skimming)
	local ui = containerUI
	if ui and #ui > 0 then
		-- The playhead is typically one of the last two children
		local persistentPlayhead = ui[#ui-1]
		local skimmingPlayhead = ui[#ui]
		if not Playhead.matches(persistentPlayhead) then
			persistentPlayhead = skimmingPlayhead
			skimmingPlayhead = nil
			if Playhead.matches(skimmingPlayhead) then
				persistentPlayhead = nil
			end
		end
		if skimming then
			return skimmingPlayhead
		else
			return persistentPlayhead
		end
	end
	return nil
end

--- cp.apple.finalcutpro.main.Playhead:new(parent, skimming, containerFn) -> Playhead
--- Constructor
--- Constructs a new Playhead
---
--- Parameters:
--- * parent 		- The parent object
--- * skimming		- (optional) if `true`, this links to the 'skimming' playhead created under the mouse, if present.
--- * containerFn 	- (optional) a function which returns the container axuielement which contains the playheads. If not present, it will use the parent's UI element.
---
--- Returns:
--- * The new `Playhead` instance.
function Playhead:new(parent, skimming, containerFn)
	local o = {_parent = parent, _skimming = skimming, containerUI = containerFn}
	prop.extend(o, Playhead)

-- TODO: Add documentation
	o.UI = prop(function(self)
		local ui = self.containerUI and self:containerUI() or self:parent():UI()
		return Playhead.find(ui, self:isSkimming())
	end):bind(o)

-- TODO: Add documentation
	o.persistent = prop.new(function(self)
		return not self._skimming
	end):bind(o)
	o.isPersistent = o.persistent

-- TODO: Add documentation
	o.skimming = prop.new(function(self)
		return self._skimming == true
	end):bind(o)
	o.isSkimming = o.skimming

-- TODO: Add documentation
	o.showing = o.UI:mutate(function(ui, self)
		return ui ~= nil
	end):bind(o)

	return o
end

-- TODO: Add documentation
function Playhead:parent()
	return self._parent
end

-- TODO: Add documentation
function Playhead:app()
	return self:parent():app()
end

-----------------------------------------------------------------------
--
-- BROWSER UI:
--
-----------------------------------------------------------------------

-- TODO: Add documentation
function Playhead:show()
	local parent = self:parent()
	-- show the parent.
	if parent:show():showing() then
		-- ensure the playhead is visible
		if parent.viewFrame then
			local viewFrame = parent:viewFrame()
			local position = self:getPosition()
			if position < viewFrame.x or position > (viewFrame.x + viewFrame.w) then
				-- Need to move the scrollbar
				local timelineFrame = parent:timelineFrame()
				local scrollWidth = timelineFrame.w - viewFrame.w
				local scrollPoint = position - viewFrame.w/2 - timelineFrame.x
				local scrollTarget = scrollPoint/scrollWidth
				parent:scrollHorizontalTo(scrollTarget)
			end
		end
	end
	return self
end

-- TODO: Add documentation
function Playhead:hide()
	return self:parent():hide()
end

-- TODO: Add documentation
function Playhead:getTimecode()
	local ui = self:UI()
	return ui and ui:attributeValue("AXValue")
end

-- TODO: Add documentation
function Playhead:getX()
	local ui = self:UI()
	return ui and ui:position().x
end

-- TODO: Add documentation
function Playhead:getFrame()
	local ui = self:UI()
	return ui and ui:frame()
end

-- TODO: Add documentation
function Playhead:getPosition()
	local frame = self:getFrame()
	return frame and (frame.x + frame.w/2 + 1.0)
end

-- TODO: Add documentation
function Playhead:getCenter()
	local frame = self:getFrame()
	return frame and geometry.rect(frame).center
end

return Playhead