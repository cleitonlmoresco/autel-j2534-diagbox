#Requires -Version 5.1
<#
.SYNOPSIS
    Testa PassThruOpen/ReadVersion/Close direto na DLL J2534 (bancada, sem software de diagnostico).

.DESCRIPTION
    Carrega a DLL J2534 via P/Invoke e tenta abrir o dispositivo. Serve para separar
    problema de DLL/firmware de problema de configuracao do software (CLIP, DiagBox etc.).

    IMPORTANTE: execute com o PowerShell de 32 bits, pois as DLLs J2534 sao x86:
      C:\Windows\SysWOW64\WindowsPowerShell\v1.0\powershell.exe

.PARAMETER DllPath
    Caminho da DLL J2534. Padrao: C:\Windows\SysWOW64\VCIV200432.dll

.EXAMPLE
    & "C:\Windows\SysWOW64\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy Bypass -File .\test_j2534.ps1

.EXAMPLE
    & "C:\Windows\SysWOW64\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy Bypass -File .\test_j2534.ps1 -DllPath "C:\Windows\SysWOW64\VCMI432.DLL"
#>
[CmdletBinding()]
param(
    [string]$DllPath = 'C:\Windows\SysWOW64\VCIV200432.dll'
)

$code = @"
using System;
using System.Runtime.InteropServices;
using System.Text;

public class J2534Test
{
    [DllImport("kernel32.dll", CharSet = CharSet.Ansi)]
    public static extern IntPtr LoadLibrary(string lpFileName);

    [DllImport("kernel32.dll", CharSet = CharSet.Ansi)]
    public static extern IntPtr GetProcAddress(IntPtr hModule, string lpProcName);

    [DllImport("kernel32.dll")]
    public static extern bool FreeLibrary(IntPtr hModule);

    public delegate int PassThruOpenDel(IntPtr pName, out uint pDeviceID);
    public delegate int PassThruCloseDel(uint deviceID);
    public delegate int PassThruReadVersionDel(uint deviceID, byte[] firmwareVersion, byte[] dllVersion, byte[] apiVersion);
    public delegate int PassThruGetLastErrorDel(byte[] errorDescription);

    public static string Run(string dllPath)
    {
        StringBuilder sb = new StringBuilder();
        IntPtr hLib = LoadLibrary(dllPath);
        if (hLib == IntPtr.Zero)
        {
            return "ERRO: nao foi possivel carregar " + dllPath +
                   " (use o PowerShell de 32 bits: C:\\Windows\\SysWOW64\\WindowsPowerShell\\v1.0\\powershell.exe)";
        }
        sb.AppendLine("DLL carregada: " + dllPath);

        IntPtr pOpen = GetProcAddress(hLib, "PassThruOpen");
        IntPtr pClose = GetProcAddress(hLib, "PassThruClose");
        IntPtr pReadVer = GetProcAddress(hLib, "PassThruReadVersion");
        IntPtr pGetLastError = GetProcAddress(hLib, "PassThruGetLastError");

        if (pOpen == IntPtr.Zero)
        {
            FreeLibrary(hLib);
            return sb.ToString() + "ERRO: DLL nao expoe PassThruOpen";
        }

        PassThruOpenDel open = (PassThruOpenDel)Marshal.GetDelegateForFunctionPointer(pOpen, typeof(PassThruOpenDel));
        PassThruCloseDel close = (PassThruCloseDel)Marshal.GetDelegateForFunctionPointer(pClose, typeof(PassThruCloseDel));
        PassThruGetLastErrorDel getLastError = null;
        if (pGetLastError != IntPtr.Zero)
            getLastError = (PassThruGetLastErrorDel)Marshal.GetDelegateForFunctionPointer(pGetLastError, typeof(PassThruGetLastErrorDel));

        uint deviceId = 0;
        int ret = open(IntPtr.Zero, out deviceId);
        sb.AppendLine("PassThruOpen retorno: 0x" + ret.ToString("X2") + " (" + ret + ")");

        if (ret != 0)
        {
            if (getLastError != null)
            {
                byte[] err = new byte[256];
                getLastError(err);
                sb.AppendLine("GetLastError: " + Encoding.ASCII.GetString(err).TrimEnd('\0'));
            }
            FreeLibrary(hLib);
            return sb.ToString();
        }

        sb.AppendLine("DeviceID: 0x" + deviceId.ToString("X8"));
        sb.AppendLine("*** DEVICE ABERTO COM SUCESSO ***");

        if (pReadVer != IntPtr.Zero)
        {
            PassThruReadVersionDel readVer = (PassThruReadVersionDel)Marshal.GetDelegateForFunctionPointer(pReadVer, typeof(PassThruReadVersionDel));
            byte[] fw = new byte[256];
            byte[] dllv = new byte[256];
            byte[] api = new byte[256];
            int vRet = readVer(deviceId, fw, dllv, api);
            sb.AppendLine("PassThruReadVersion retorno: 0x" + vRet.ToString("X2"));
            if (vRet == 0)
            {
                sb.AppendLine("  Firmware: " + Encoding.ASCII.GetString(fw).TrimEnd('\0'));
                sb.AppendLine("  DLL: " + Encoding.ASCII.GetString(dllv).TrimEnd('\0'));
                sb.AppendLine("  API: " + Encoding.ASCII.GetString(api).TrimEnd('\0'));
            }
        }

        int cRet = close(deviceId);
        sb.AppendLine("PassThruClose retorno: 0x" + cRet.ToString("X2"));
        FreeLibrary(hLib);
        return sb.ToString();
    }
}
"@

Add-Type -TypeDefinition $code -Language CSharp -ErrorAction Stop
Write-Host "=== TESTE J2534 (32 bits): $DllPath ==="
[J2534Test]::Run($DllPath) | Write-Host
