local DISABLE_COLORS = false

local pretty = require 'pl.pretty'
local io = io
local type = type
local ipairs = ipairs
local string_format = string.format
local io_write = io.write
local io_flush = io.flush

local colors

if DISABLE_COLORS then
  colors = setmetatable({}, {__index = function() return function(s) return s end end})
else
    local term = require 'term'
    colors = require 'term.colors'
end

return function(options)
  local busted = require 'busted'
  local handler = require 'busted.outputHandlers.base'()
  handler.failures_headers = {}
  options.verbose = true
  options.deferPrint = true

  local repeatSuiteString = '\nRepeating all tests (run %u of %u) . . .\n\n'
  local randomizeString  = colors.yellow('Note: Randomizing test order with a seed of %u.\n')
  local fileStartString  = colors.green  ('[------]') .. ' Running tests: %s\n'
  local runString        = colors.green  ('[ RUN  ]') .. ' %s\n'
  local successString    = colors.green  ('[  OK  ]') .. ' %s (%.2f ms)\n'
  local skippedString    = colors.yellow ('[ SKIP ]') .. ' %s (%.2f ms)\n'
  local failureString    = colors.red    ('[ FAIL ]') .. ' %s (%.2f ms)\n'
  local errorString      = colors.magenta('[ ERR  ]') .. ' %s (%.2f ms)\n'
  local fileEndString    = colors.green  ('[------]') .. colors.magenta(' %u %s from %s') ..' (%.2f ms total)\n\n'
  local globalTeardown   = colors.green  ('[------]') .. ' Test environment teardown\n'
  local suiteEndString   = colors.green  ('[======]') .. ' %u %s from %u test %s ran. (%.2f ms total)\n'
  local successStatus    = colors.green  ('[ PASS ]') .. ' %u %s\n'

  local summaryStrings = {
    skipped = {
      header = colors.yellow ('[ SKIP ]') .. ' %u %s, listed below:\n',
      test   = colors.yellow ('[ SKIP ]') .. ' %s\n',
      footer = ' %u SKIPPED %s\n',
    },

    failure = {
      header = colors.red    ('[ FAIL ]') .. ' %u %s, listed below:\n',
      test   = colors.red    ('[ FAIL ]') .. ' %s\n',
      footer = ' %u FAILED %s\n',
    },

    error = {
      header = colors.magenta('[ ERR  ]') .. ' %u %s, listed below:\n',
      test   = colors.magenta('[ ERR  ]') .. ' %s\n',
      footer = ' %u %s\n',
    },
  }

  local fileCount = 0
  local fileTestCount = 0
  local testCount = 0
  local successCount = 0
  local skippedCount = 0
  local failureCount = 0
  local errorCount = 0

  local pendingDescription = function(pending)
    local string = ''

    if type(pending.message) == 'string' then
      string = string .. pending.message .. '\n'
    elseif pending.message ~= nil then
      string = string .. pretty.write(pending.message) .. '\n'
    end

    return string
  end

  local failureDescription = function(failure)
    local string = failure.randomseed and ('Random seed: ' .. failure.randomseed .. '\n') or ''
    if type(failure.message) == 'string' then
      string = string .. failure.message
    elseif failure.message == nil then
      string = string .. 'Nil error'
    else
      string = string .. pretty.write(failure.message)
    end

    string = string .. '\n'

    if options.verbose and failure.trace and failure.trace.traceback then
      string = string .. failure.trace.traceback .. '\n'
    end

    return string
  end

  local getFileLine = function(element)
    local fileline = ''
    if element.trace or element.trace.short_src then
      fileline = colors.cyan(element.trace.short_src) .. ' @ ' ..
                 colors.cyan(element.trace.currentline) .. ': '
    end
    return fileline
  end

  -- Debug glua crash here
  local getTestList = function(status, count, list, getDescription)
    local string = ''
    local separator_listed = "================================================================================\n"
    local header = summaryStrings[status].header
      .. colors.yellow(separator_listed)
    if count > 0 and header then
      local tests = (count == 1 and 'test' or 'tests')
      local errors = (count == 1 and 'error' or 'errors')
      string = string_format(header, count, status == 'error' and errors or tests)

      local testString = summaryStrings[status].test
      if testString then
        for _, t in ipairs(list) do
          local fullname = getFileLine(t.element) .. colors.white(handler.failures_headers[_]) .. ": " .. colors.yellow(t.name)
          string = string .. string_format(testString, fullname)
          if options.deferPrint then
            string = string .. getDescription(t)
          end
        end
      end
    end
    return string
  end

  local getSummary = function(status, count)
    local string = ''
    local footer = summaryStrings[status].footer
    if count > 0 and footer then
      local tests = (count == 1 and 'TEST' or 'TESTS')
      local errors = (count == 1 and 'ERROR' or 'ERRORS')
      string = string_format(footer, count, status == 'error' and errors or tests)
    end
    return string
  end

  local getSummaryString = function()
    local tests = (successCount == 1 and 'test' or 'tests')
    local string = string_format(successStatus, successCount, tests)

    string = string .. getTestList('skipped', skippedCount, handler.pendings, pendingDescription)
    string = string .. getTestList('failure', failureCount, handler.failures, failureDescription)
    string = string .. getTestList('error', errorCount, handler.errors, failureDescription)

    string = string .. ((skippedCount + failureCount + errorCount) > 0 and '\n' or '')
    string = string .. getSummary('skipped', skippedCount)
    string = string .. getSummary('failure', failureCount)
    string = string .. getSummary('error', errorCount)

    return string
  end

  local function getTest(element)
    local element_tests = {}
    element_tests.it = {}
    element_tests.name = element.name

    if element.describe ~= nil then
        for k, test_context in pairs(element.describe) do
            table.insert(element_tests, 1, getTest(test_context))
        end
    end

    if element.it ~= nil then
        for k, test in pairs(element.it) do
            table.insert(element_tests.it, 1, test)
        end
    end

    if element.describe ~= nil and element.it ~= nil then
        element_tests.descriptor = "both"
    else
        element_tests.descriptor = element.descriptor
    end
    return element_tests
  end

  local function getTests(tests_file)
    local element = nil
    local elements = {}
    for k, test_file in pairs(tests_file) do
        if test_file.describe ~= nil then
            for k, suite in pairs(test_file.describe) do
                if suite ~= nil then
                    table.insert(elements, 1, getTest(suite))
                end
            end
        end
    end
    return elements
  end

  local suite_start = false
  local function formatTests(tests)
    local result = ""
    if tests.it ~= nil then
        for k, test in pairs(tests.it) do
            local name = test.name or test.descriptor
            if k == 1 then
                result = name .. "]"
            else
                result = name .. "." .. result
            end
            if k == #tests.it then
                result = "[" .. result
            end
        end
    end
    for k, test in pairs(tests) do
        if tonumber(k) == nil then
            break
        end
        local name = test.name or test.descriptor
        if not suite_start then
            suite_start = true
        else
            name = " > " .. name
        end
        result = result .. name .. formatTests(test)
    end
    return result
  end

    local function formatTest(tests)
        local result = ""
        if tests.it ~= nil then
            for k, test in pairs(tests.it) do
                local name = test.name or test.descriptor
                if k == 1 then
                    result = name .. "]"
                else
                    result = name .. "." .. result
                end
                if k == #tests.it then
                    result = "[" .. result
                end
            end
        end
        for k, test in pairs(tests) do
            if tonumber(k) == nil then
                break
            end
            local name = test.name or test.descriptor
            if not suite_start then
                suite_start = true
            else
                name = " > " .. name
            end
            result = result .. name .. formatTests(test)
        end
        return result
    end

  local getFullName = function(element)
    local parent = busted.parent(element)
    local names = { (element.name or element.descriptor) }
    local name = ""
    while parent and (parent.name or parent.descriptor) and
        parent.descriptor ~= 'file' and parent.attributes.envmode == nil do
        if parent.descriptor == "describe" and element.descriptor == "it" then
            -- new describe context
            name = colors.yellow(parent.name or parent.descriptor) .. colors.red(" >")
        else
            name = parent.name or parent.descriptor
        end

        table.insert(names, 1, colors.yellow(name))
        parent = busted.parent(parent)
    end

    return table.concat(names, ' ')
  end

  handler.suiteReset = function()
    fileCount = 0
    fileTestCount = 0
    testCount = 0
    successCount = 0
    skippedCount = 0
    failureCount = 0
    errorCount = 0

    return nil, true
  end

  handler.suiteStart = function(suite, count, total, randomseed)
    if total > 1 then
      io_write(string_format(repeatSuiteString, count, total))
    end
    if randomseed then
      io_write(string_format(randomizeString, randomseed))
    end
    io_flush()
    return nil, true
  end

  handler.suiteEnd = function(suite, count, total)
    local elapsedTime_ms = suite.duration * 1000
    local tests = (testCount == 1 and 'test' or 'tests')
    local files = (fileCount == 1 and 'file' or 'files')

    io_write(globalTeardown)
    io_write(getSummaryString())
    io_flush()

    -- Workaround to support tests in multiple files
    if (#handler.failures > 0) then
      io_write(colors.red("============================================================================================\n"))
      io_flush()
      for _, failure in pairs(handler.failures) do
          io_write(failureDescription(failure))
      end
      io_flush()
      if not _G.continue_busted then os.exit(0, true) end
    end
    return nil, true
  end

  handler.fileStart = function(file)
    fileTestCount = 0
    io_write(string_format(fileStartString, file.name))
    io_flush()
    return nil, true
  end

  handler.fileEnd = function(file)
    local elapsedTime_ms = file.duration * 1000
    local tests = (fileTestCount == 1 and 'test' or 'tests')
    fileCount = fileCount + 1
    io_write(string_format(fileEndString, fileTestCount, tests, file.name, elapsedTime_ms))
    io_flush()
    return nil, true
  end

  local last_suite = ""
  handler.testStart = function(element, parent)
    local suite = busted.parent(parent)
    while suite do
        if suite.descriptor == "suite" or
            busted.parent(suite).descriptor == "file" then
            break
        else
            suite = busted.parent(suite)
        end
    end
    if suite.name ~= nil and last_suite ~= suite.name then
        io_write("\n", getFileLine(element), colors.white("Testing: "), colors.white(suite.name), "\n")
        io_flush()
        last_suite = suite.name
    end
    return nil, true
  end

  handler.testEnd = function(element, parent, status, debug)
    local elapsedTime_ms = element.duration * 1000
    local string

    fileTestCount = fileTestCount + 1
    testCount = testCount + 1
    if status == 'success' then
      successCount = successCount + 1
      string = successString
    elseif status == 'pending' then
      skippedCount = skippedCount + 1
      string = skippedString
    elseif status == 'failure' then
      while parent.attributes.envmode == nil do
        parent = busted.parent(parent)
      end
      failureCount = failureCount + 1
      string = failureString
      handler.failures_headers[#handler.failures_headers + 1] = parent.name
    elseif status == 'error' then
      errorCount = errorCount + 1
      string = errorString
    end

    io_write(string_format(string, getFullName(element), elapsedTime_ms))
    io_flush()

    return nil, true
  end

  handler.testFailure = function(element, parent, message, debug)
    local custom_element = {}
    custom_element.message = message
    custom_element.element = {}
    custom_element.element.trace = element.trace
    custom_element.element.trace.short_src = element.trace.short_src
    custom_element.element.trace.currentline = element.trace.currentline
    custom_element.name = element.name
    handler.failures[#handler.failures] = custom_element
    return nil, true
  end

  handler.testError = function(element, parent, message, debug)
    if not options.deferPrint then
      io_write(failureDescription(handler.errors[#handler.errors]))
      io_flush()
    end
    return nil, true
  end

  handler.error = function(element, parent, message, debug)
    if element.descriptor ~= 'it' then
      if not options.deferPrint then
        io_write(failureDescription(handler.errors[#handler.errors]))
        io_flush()
      end
      errorCount = errorCount + 1
    end

    return nil, true
  end

  busted.subscribe({ 'suite', 'reset' }, handler.suiteReset)
  busted.subscribe({ 'suite', 'start' }, handler.suiteStart)
  busted.subscribe({ 'suite', 'end' }, handler.suiteEnd)
  busted.subscribe({ 'file', 'start' }, handler.fileStart)
  busted.subscribe({ 'file', 'end' }, handler.fileEnd)
  busted.subscribe({ 'test', 'start' }, handler.testStart, { predicate = handler.cancelOnPending })
  busted.subscribe({ 'test', 'end' }, handler.testEnd, { predicate = handler.cancelOnPending })
  busted.subscribe({ 'failure', 'it' }, handler.testFailure)
  busted.subscribe({ 'error', 'it' }, handler.testError)
  busted.subscribe({ 'failure' }, handler.error)
  busted.subscribe({ 'error' }, handler.error)

  return handler
end
