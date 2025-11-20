--- Retrieves the major version number of the Windows operating system using Lua FFI.
-- This method uses the low-level, more reliable RtlGetVersion function from NTDLL.dll,
-- Note: For Windows 11 (Build >= 22000), this function forces the return value to 11
-- instead of the kernel-reported 10 for clarity.
--
-- @returns number: The major version number (e.g., 10 for Windows 10/11) on success.
-- @returns number: -1 if the operating system is not Windows or the FFI call fails.

local success, ffi = pcall(require, "ffi")

if not success or not ffi or ffi.os ~= "Windows" then
  return -1
end

ffi.cdef[[
// ---- Required Windows Type definitions ----
typedef unsigned long DWORD;
typedef long LONG;
typedef char CHAR;
typedef unsigned short WORD;
typedef unsigned char BYTE;
// ----                                   ----

typedef struct {
  DWORD dwOSVersionInfoSize; // Mandatory field: Must be set to the size of the structure before calling the funcition
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
]]

local ntdll = ffi.load("ntdll")
local OSVERSIONINFOEXW = ffi.typeof("OSVERSIONINFOEXW")

local versionInfoExW = OSVERSIONINFOEXW()
versionInfoExW.dwOSVersionInfoSize = ffi.sizeof(versionInfoExW)

if ntdll.RtlGetVersion(versionInfoExW) == 0 then -- returns 0 on success
  local major = versionInfoExW.dwMajorVersion
  local build = versionInfoExW.dwBuildNumber

  --- Windows 11 detection logic:
  -- If the reported major version is 10 AND the build number is 22000 or greater, 
  -- we return 11 since windows doesn't like telling us it's actually 11
  if major == 10 and build >= 22000 then
    return 11
  end

  -- Otherwise, return the kernel-reported major version
  return major
end

return -1