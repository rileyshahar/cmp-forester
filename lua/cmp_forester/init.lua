local cmp = require('cmp')

local source = {}

source.new = function()
	return setmetatable({}, { __index = source })
end

source.is_available = function()
	return vim.o.filetype == "forester"
end

-- start completing on a (
source.get_trigger_characters = function()
	return { '(' }
end

-- source.get_keyword_pattern = function()
-- 	return [[%((.*)]]
-- end

source._run_cmd = function(cmd, callback)
	local lines = { "" }

	local cmd = vim.fn.expandcmd(cmd)

	local function on_write(_, data, _)
		if data then
			vim.list_extend(lines, data)
		end
	end

	local function on_exit(_, status, _)
		if status ~= 0 then
			local message = table.concat(lines, "\n")
			vim.notify("error in cmp-forester:\n\n" .. message, vim.diagnostic.severity.E)
		else
			callback(lines)
		end
	end

	local _ = vim.fn.jobstart(cmd, {
		on_stderr = on_write,
		on_stdout = on_write,
		on_exit = on_exit,
		stdout_buffered = true,
		stderr_buffered = true,
	})
end

source._split_once = function(str, sep)
	local prefix, suffix = str:match("(.-)%" .. sep .. "(.+)")
	local t = {}
	table.insert(t, prefix)
	table.insert(t, suffix)
	return t
end

source.complete = function(self, params, cmp_callback)
	local command = "forester complete trees/"

	local callback = function(lines)
		local items = {}
		for _, line in ipairs(lines) do
			if line ~= "" then
				local data = self._split_once(line, ", ")
				local item = {}
				item.insertText = data[1]
				item.label = data[2]
				item.filterText = data[2]
				item.insertTextFormat = cmp.lsp.InsertTextFormat.Snippet
				item.kind = cmp.lsp.CompletionItemKind.File

				table.insert(items, item)
			end
		end

		cmp_callback({ items = items })
	end

	self._run_cmd(command, callback)
end

return source
