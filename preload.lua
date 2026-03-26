-- This script should be called from your project's `conf.lua` to prepare MintMousse
local PATH_RAW = ...
local PATH = PATH_RAW:match("^(.-)[^%.]+$")
local DIRECTORY_PATH = PATH:gsub("%.", "/")

local attemptError = function(errorMessage)
  error(errorMessage, 3)
  assert(false, errorMessage) -- if error was overridden, try to use assert
  return errorMessage -- if all else fails, try to return the error
end

if PATH_RAW:find("[[/\\]") then
  local errorMessage = "MintMousse: You called require('%s'). "..
                       "Invalid path format, please use dot-notion (e.g. libs.mintmousse) instead of file paths. " ..
                       "Use `.` (periods) in place of `/` (forward slash) or `\\` (back slash). "
  return attemptError(errorMessage:format(PATH_RAW))
end

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
  thread:start(PATH)
  channel:performAtomic(function()
    channel:clear()
    channel:push(thread)
  end)
end

if isMintMousseThread then
  mintmousse._threadID = "MintMousse"
elseif not love.isThread then
  mintmousse._threadID = "main"
else
  local id = require(PATH .. "util.id")
  mintmousse._threadID = id.getNewThreadID()
end

local util = require(PATH .. "util")
mintmousse.cleanupTraceback = util.cleanupTraceback

local codec = require(PATH .. "codec") -- init buffers
if codec.decode(codec.encode("mintmousse")) ~= "mintmousse" then
  logger:error("Codec didn't initialise correctly.")
end

local logging = require(PATH .. "logging")
mintmousse.flushLogs = logging.flushLogs
mintmousse.newLogger = logging.newLogger
mintmousse.addLogSink = logging.addLogSink
mintmousse.addGlobalLogSink = logging.addGlobalLogSink
mintmousse.logUncaughtError = logging.logUncaughtError

local threadCommand = require(PATH .. "threadCommand")
mintmousse.batchStart = threadCommand.batchStart
mintmousse.batchEnd = threadCommand.batchEnd

mintmousse.flushLogs()
if isMintMousseThread then
  mintmousse.pop = threadCommand.pop
  mintmousse.pushEvent = threadCommand.pushEvent

  return mintmousse
end

local threadController = require(PATH .. "threadController")
if not love.isThread then -- is Main thread
  mintmousse.start = threadController.start
  mintmousse.stop = threadController.stop
  mintmousse.wait = threadController.wait
end

mintmousse.setIcon = threadController.setIcon
mintmousse.setIconRaw = threadController.setIconRaw
mintmousse.setIconRFG = threadController.setIconRFG

mintmousse.setTitle = threadController.setTitle

mintmousse.notify = threadController.notify

mintmousse.addToWhitelist = threadController.addToWhitelist
mintmousse.removeFromWhitelist = threadController.removeFromWhitelist
mintmousse.clearWhitelist = threadController.clearWhitelist

if not love.isThread then -- is Main thread
  local eventManager = require(PATH .. "eventManager")
  mintmousse.addCallback = eventManager.addCallback
  mintmousse.removeCallback = eventManager.removeCallback
end

local proxy = require(PATH .. "proxy")
mintmousse.newTab = proxy.newTab
mintmousse.get = proxy.get
mintmousse.removeComponent = proxy.removeComponent

local pages = require(PATH .. "pages")
mintmousse.buildPage = pages.buildPage

mintmousse.flushLogs()

local contract = require(PATH .. "contract")
contract.waitForComponents()

mintmousse.flushLogs()

return mintmousse