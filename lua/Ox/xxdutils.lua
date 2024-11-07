-- check xxd config for misaligned values
-- returns: 0 on success, 1 otherwise
local M={}

M.config_sanity_check = function(config)
   if (config.cols%config.group>0) then
      vim.notify("0x: Hex dump configuration problem: Cols is not divisible by group size!",WARN)
      return 1
   end
   return 0
end

M.get_cmd_params_to_hex = function(config)
	if (M.config_sanity_check(config) ~= 0) then
		return ""
	end
	local ret = "%!" .. config.command .. " "
	ret = ret .. "-c " .. config.cols .. " "
	ret = ret .. "-g " .. config.group .. " "
	return ret
end

M.get_cmd_params_to_text = function(config)
	if (M.config_sanity_check(config) ~= 0) then
		return ""
	end
	local ret = "%!" .. config.command .. " -r"
	return ret
end

return M
