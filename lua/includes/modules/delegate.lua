local pairs = pairs
local setmetatable = setmetatable
local is_function = is_function
local type = type
local table = table
local select = select


local print = print
local error = error
local mandatory_params = 0

module('Delegate')

local function is_function(fun)
  if fun and type(fun) == 'function' then
      return true
  else
      return false
  end
end

local function add_subscriber(event, fun, ...)
  if not is_function(fun) and not fun.__subscribers then return end
  table.insert(event.__subscribers, fun)
end

-- local function remove_subscriber(event, fun)
--   if not is_function(fun) then return end
--   event.__subscribers[fun] = nil
-- end

local function clear_subscribers(event, fun)
  event.__subscribers = {}
end

function new()
  return setmetatable({
    __subscribers = {},
    add        = add_subscriber,
    remove     = remove_subscriber,
    remove_all = clear_subscribers,
  }, {
  __call = function(self, ...)
      if #self.__subscribers == 0 then
        error("Delegate not implemented")
        return
      end

      local mandatory_params = 0
      local params = select('#', ...) - 1
      if mandatory_params ~= params then
        error("Delegate called with invalid parameters")
        return
      end
      for index, f in pairs(self.__subscribers) do
        f(...)
      end
  end,
  })
end

function new_one_param()
  return setmetatable({
    __subscribers = {},
    add        = add_subscriber,
    remove     = remove_subscriber,
    remove_all = clear_subscribers,
  }, {
  __call = function(self, ...)
      if #self.__subscribers == 0 then
        error("Delegate not implemented")
        return
      end

      local mandatory_params = 1
      local params = select('#', ...) - 1
      if mandatory_params ~= params then
        error("Delegate called with invalid parameters")
        return
      end
      for index, f in pairs(self.__subscribers) do
        f(...)
      end
  end,
  })
end