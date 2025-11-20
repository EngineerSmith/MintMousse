local success, ffi = pcall(require, "ffi")

if not success or not ffi or ffi.os ~= "Windows" then
  return nil
end

ffi.cdef[[
// --- Shared Windows Type definitions ---
typedef unsigned long DWORD;
typedef long LONG;
typedef char CHAR;
typedef unsigned short WORD;
typedef unsigned char BYTE;
typedef long long intptr_t;
typedef intptr_t HANDLE;
typedef int BOOL;
typedef DWORD* LPDWORD;
// ---------------------------------------

// --- OS Version Structures and Functions ---
typedef struct {
  DWORD dwOSVersionInfoSize; // Mandatory field: Must be set to the size of the structure before calling the function
  DWORD dwMajorVersion;      // The output field containing the major version (e.g. 10)
  DWORD dwMinorVersion;
  DWORD dwBuildNumber;       // The output field used to distinguish between Win 10 and Win 11 (22000+)
  DWORD dwPlatformId;
  CHAR szCSDVersion[128];
  WORD wServicePackMajor;
  WORD wServicePackMinor;
  WORD wSuitMask;
  BYTE wProductType;
  BYTE wReserved;
} OSVERSIONINFOEXW;

LONG RtlGetVersion(OSVERSIONINFOEXW *lpVersionInformation);
// -------------------------------------------

// --- Console Structures and Functions ---
static const int STD_OUTPUT_HANDLE = -11;
static const int INVALID_HANDLE_VALUE = -1;
static const int ENABLE_VIRTUAL_TERMINAL_PROCESSING = 0X0004;

HANDLE GetStdHandle(int nStdHandle);
BOOL GetConsoleMode(HANDLE hConsoleHandle, LPDWORD lpMode);
BOOL SetConsoleMode(HANDLE hConsoleHandle, DWORD dwMode);
// ----------------------------------------
]]

local ntdll = ffi.load("ntdll")
local kernel32 = ffi.load("kernel32")
local C = ffi.C
local bit = require("bit")

local windowsAPI = { }

windowsAPI.getMajorVersion = function()
  local versionInfoExW = ffi.new("OSVERSIONINFOEXW")
  versionInfoExW.dwOSVersionInfoSize = ffi.sizeof(versionInfoExW)

  if ntdll.RtlGetVersion(versionInfoExW) == 0 then
    local major = versionInfoExW.dwMajorVersion
    local build = versionInfoExW.dwBuildNumber
    if major == 10 and build >= 22000 then
      return 11
    end
    return major
  end
  return nil
end

windowsAPI.enableVirtualTerminal = function()
  local handle = kernel32.GetStdHandle(C.STD_OUTPUT_HANDLE)
  if handle == C.INVALID_HANDLE_VALUE or handle == 0 then
    return false -- Not a console/error
  end

  local mode_ptr = ffi.new("LPDWORD")
  if kernel32.GetConsoleMode(handle, mode_ptr) == 0 then
    return false -- Not a console
  end

  local currentMode = mode_ptr[0]
  local VT_flag = C.ENABLE_VIRTUAL_TERMINAL_PROCESSING

  if bit.band(currentMode, VT_flag) ~= 0 then
    return true -- Already enabled
  end

  local newMode = bit.bor(currentMode, VT_flag)
  if kernel32.SetConsoleMode(handle, newMode) ~= 0 then
    return true -- Successfully enabled
  end
  return false -- Failed to set mode
end

windowsAPI.setupANSIConsole = function()
  local windowsVersion = windowsAPI.getMajorVersion()
  if type(windowsVersion) ~= "number" or windowsVersion < 1 then
    return false
  end

  local success = windowsAPI.enableVirtualTerminal()
  if not success then
    return false
  end

  return true
end

return windowsAPI