-- Multi-window scratchpad stash.
--
-- Storage: one special workspace per slot, named "special:stash-<n>". The slot
-- number *is* the insertion order, so no state file / in-memory table is needed
-- and everything survives `hyprctl reload`. misc.close_special_on_empty = true
-- (already set in modules/misc.lua) means a slot's special workspace vanishes on
-- its own once its window closes, so gaps in the numbering are expected and fine.
--
-- Identity: a recalled window is tagged "stash" so SUPER+S can tell whether the
-- focused window came out of the stash (push it back) or not (pop the newest).

local M = {}

local PREFIX = "stash-"
local TAG = "stash"

-- "-" is a Lua-pattern magic character (lazy "0 or more"), not a literal
-- hyphen, so PREFIX must be escaped before use inside :match(). Since PREFIX
-- is a fixed constant we control, this could be hardcoded, but escaping it
-- here keeps the invariant (SLOT_PATTERN always matches whatever PREFIX names)
-- from silently breaking if PREFIX is ever edited.
local SLOT_PATTERN = "^special:" .. PREFIX:gsub("%-", "%%-") .. "(%d+)$"

---@return integer[] sorted list of occupied slot numbers
local function slots()
	local out = {}
	for _, ws in ipairs(hl.get_workspaces()) do
		local n = ws.name:match(SLOT_PATTERN)
		if n then
			out[#out + 1] = tonumber(n)
		end
	end
	table.sort(out)
	return out
end

---@param win HL.Window
---@return boolean
local function has_tag(win)
	local tags = win.tags
	if type(tags) == "table" then
		for _, t in ipairs(tags) do
			if t == TAG then
				return true
			end
		end
		return false
	end
	return tags == TAG
end

---Stash a window into the stack (defaults to the focused window).
---
---Returns a no-op dispatcher rather than nothing: `hyprctl dispatch` in this
---Lua config always wraps its argument as `hl.dispatch(<expr>)`, so the
---expression's return value must itself be a dispatcher, even though all the
---real work already happened above via the explicit hl.dispatch(...) calls.
---@param win HL.Window|nil
---@return HL.Dispatcher
function M.push(win)
	win = win or hl.get_active_window()
	if not win then
		return hl.dsp.no_op()
	end

	local occupied = slots()
	local n = (occupied[#occupied] or 0) + 1

	hl.dispatch(hl.dsp.window.move({
		workspace = "special:" .. PREFIX .. n,
		window = win,
		follow = false,
	}))
	hl.dispatch(hl.dsp.window.tag({ window = win, tag = "-" .. TAG }))
	return hl.dsp.no_op()
end

---Recall the window in a given slot to the currently active workspace and focus it.
---@param n integer
local function recall_slot(n)
	local ws_name = "special:" .. PREFIX .. n
	local windows = hl.get_workspace_windows(ws_name)
	local win = windows and windows[1]
	if not win then
		return
	end

	local target = hl.get_active_workspace()
	if not target then
		return
	end

	hl.dispatch(hl.dsp.window.move({ workspace = target.id, window = win, follow = false }))
	hl.dispatch(hl.dsp.focus({ window = win }))
	hl.dispatch(hl.dsp.window.tag({ window = win, tag = "+" .. TAG }))
end

local function notify_empty()
	hl.notification.create({ text = "stash empty", timeout = 1000 })
end

---Recall the newest stashed window (LIFO).
---@return HL.Dispatcher
function M.pop()
	local occupied = slots()
	if #occupied == 0 then
		notify_empty()
		return hl.dsp.no_op()
	end
	recall_slot(occupied[#occupied])
	return hl.dsp.no_op()
end

---Recall the oldest stashed window (FIFO).
---@return HL.Dispatcher
function M.shift()
	local occupied = slots()
	if #occupied == 0 then
		notify_empty()
		return hl.dsp.no_op()
	end
	recall_slot(occupied[1])
	return hl.dsp.no_op()
end

---Recall a specific slot by number (used by the picker).
---@param n integer
---@return HL.Dispatcher
function M.recall(n)
	recall_slot(n)
	return hl.dsp.no_op()
end

---SUPER+S smart toggle: push the focused window back if it's a stashed one,
---otherwise pop the newest stashed window.
---@return HL.Dispatcher
function M.toggle()
	local win = hl.get_active_window()
	if win and has_tag(win) then
		M.push(win)
	else
		M.pop()
	end
	return hl.dsp.no_op()
end

---List stashed windows, sorted oldest-first, for the picker.
---@return table[] { slot, class, title, address }
function M.list()
	local out = {}
	for _, n in ipairs(slots()) do
		local windows = hl.get_workspace_windows("special:" .. PREFIX .. n)
		local win = windows and windows[1]
		if win then
			out[#out + 1] = { slot = n, class = win.class, title = win.title, address = win.address }
		end
	end
	return out
end

-- Exposed so `hyprctl dispatch 'Stash.recall(n)'` can be called from the fuzzel
-- picker script without an extra IPC surface.
_G.Stash = M

return M
