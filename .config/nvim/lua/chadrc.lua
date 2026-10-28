---@type ChadrcConfig

local M = {}
local theme = require "overrides.chadrc"
local mason = require "configs.mason"

M.base46 = theme
M.mason = mason
--M.plugins = 'plugins'
--M.mappings = require "mappings"
return M
