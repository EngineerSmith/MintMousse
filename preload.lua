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
  -- thread:start(PATH, DIRECTORY_PATH) -- disabled for refactoring; do we really need to pass PATH and DIR into the thread? Can't it work that out itself?
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
mintmousse.sanitizeText = util.sanitizeText

local logging = require(PATH .. "logging")
mintmousse.flushLogs = logging.flushLogs
mintmousse.newLogger = logging.newLogger
mintmousse.addLogSink = logging.addLogSink
mintmousse.logUncaughtError = logging.logUncaughtError

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

  local eventManager = require(PATH .. "eventManager")
  mintmousse.addCallback = eventManager.addCallback
  mintmousse.removeCallback = eventManager.removeCallback
end

local createProxyTable = require(PATH .. "proxyTable")
mintmousse._proxyComponents = { }
mintmousse.get = function(id, componentTypeHint)
  if type(componentTypeHint) == "string" then
    love.mintmousse.addToLocalHinting(id, componentTypeHint)
  end
  local proxyTable = mintmousse._proxyComponents[id]
  if proxyTable then
    return proxyTable
  end
  proxyTable = createProxyTable({ id = id })
  mintmousse._proxyComponents[id] = proxyTable
  return proxyTable
end

local threadContract = require(PATH .. "threadContract")
mintmousse.addLocalType = threadContract.addLocalType
mintmousse.addComponent = threadContract.addComponent
mintmousse.newTab = threadContract.newTab
mintmousse.removeComponent = threadContract.removeComponent

-- require(PATH .. "threadHinting")


threadContract.blockUntilComplete()

return mintmousse