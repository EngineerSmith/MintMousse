-- This script should be called from your project's `conf.lua` to prepare MintMousse
local PATH = (...):match("^(.-)[^%.]+$")
local DIRECTORY_PATH = PATH:gsub("%.", "/")

local love = love

assert(love ~= nil, "MintMousse: Library is missing dependency LÖVE")
assert(jit ~= nil, "MintMousse: Library is missing dependency LuaJIT. This is usually packaged with LÖVE.")
assert(pcall(require, "string.buffer"), "MintMousse: Library is missing dependency LuaJIT's String Buffer Library. This is packaged with LÖVE from 11.4.")

require(PATH .. "setupLove")

local mintmousse = require(PATH .. "conf")
mintmousse._setupLogging()

if not love.isThread then
  local channel = love.thread.getChannel(mintmousse.READONLY_THREAD_LOCATION)
  local thread = love.thread.newThread(DIRECTORY_PATH .. "thread/init.lua")
  -- thread:start(PATH .. "thread.") -- disabled for refactoring
  channel:performAtomic(function()
    channel:clear()
    channel:push(thread)
  end)
end

if love.isMintMousseThread then
  mintmousse._threadID = "MintMousse"
elseif not love.isThread then
  mintmousse._threadID = "main"
else
  local lm = love.math
  if not lm then lm = require("love.math") end
  local threadIDLength = 8
  mintmousse._threadID = ("x"):rep(threadIDLength):gsub("[x]", function()
      return ("%x"):format(lm.random(0, 15))
    end)
end

local util = require(PATH .. "util")
mintmousse.cleanupTraceback = util.cleanupTraceback
-- mintmousse.sanitizeText = util.sanitizeText -- Do users need access to this? Or have I programmed good

local logging = require(PATH .. "logging")
mintmousse.flushLogs = logging.flushLogs
mintmousse.newLogger = logging.newLogger
mintmousse.addLogSink = logging.addLogSink
mintmousse.logUncaughtError = logging.logUncaughtError

mintmousse.flushLogs()
if love.isMintMousseThread then
  return mintmousse
end

if not love.isThread then -- is Main thread
  local threadController = require(PATH .. "threadController")
  mintmousse.start = threadController.start
  mintmousse.stop = threadController.stop
  mintmousse.wait = threadController.wait

  mintmousse.setIcon = threadController.setIcon
  mintmousse.setIconRaw = threadController.setIconRaw
  mintmousse.setIconRFG = threadController.setIconRFG

  mintmousse.setTitle = threadController.setTitle

  mintmousse.notify = threadController.notify

  local eventManager = require(PATH .. "eventManager")
  mintmousse.addCallback = eventManager.addCallback
  mintmousse.removeCallback = eventManager.removeCallback
end

local proxyTable = require(PATH .. "proxyTable")
proxyTable.loadComponentManager() -- prevent circular dependency

local componentManager = require(PATH .. "componentManager")
mintmousse.newTab = componentManager.newTab
mintmousse.get = componentManager.get
mintmousse.removeComponent = componentManager.removeComponent

local syncPoll = require(PATH .. "syncPoll")
mintmousse.poll = syncPoll.poll

mintmousse.flushLogs()

local contract = require(PATH .. "contract")
contract.waitForComponents()

mintmousse.flushLogs()

return mintmousse