$script:ModuleName = 'Posh-SYSLOG'

# Removes all versions of the module from the session before importing
Get-Module $ModuleName | Remove-Module

$ModuleBase = Split-Path -Parent $MyInvocation.MyCommand.Path

# For tests in .\Tests subdirectory
if ((Split-Path $ModuleBase -Leaf) -eq 'Tests') {
    $ModuleBase = Split-Path $ModuleBase -Parent
}

## This variable is for the VSTS tasks and is to be used for referencing any mock artifacts
$Env:ModuleBase = $ModuleBase

Import-Module $ModuleBase\$ModuleName.psd1 -PassThru -ErrorAction Stop | Out-Null

Write-Warning -Message ('These tests require access to google.com (TCP 80 and 443)')

# InModuleScope runs the test in module scope.
# It creates all variables and functions in module scope.
# As a result, test has access to all functions, variables and aliases
# in the module even if they're not exported.
InModuleScope $script:ModuleName {
    Describe "Basic function unit tests" -Tags Build , Unit{

        It 'Connects to a known port and does not throw' {
            $TCPClient = Connect-TCPClient -Server 'google.com' -port 80
            {
                $TCPWriter = Get-TCPWriter -TcpClient $TCPClient
                Disconnect-TCPWriter -TcpWriter $TCPWriter
            } | should not throw
        }

        It 'Connects to a known port and returns a TCP writer' {
            $TCPClient = Connect-TCPClient -Server 'google.com' -port 80
            $TCPWriter = Get-TCPWriter -TcpClient $TCPClient
            $TCPWriter | Should -BeOfType System.IO.StreamWriter
            Disconnect-TCPWriter -TcpWriter $TCPWriter
        }

        It 'Connects to a known port over TLS and returns a TCP writer' {
            $TCPClient = Connect-TCPClient -Server 'google.com' -port 443
            {
                $TCPWriter = Get-TCPWriter -TcpClient $TCPClient -UseTLS -ServerHostname 'google.com'
                Disconnect-TCPWriter -TcpWriter $TCPWriter
            } | should not throw
        }

        It 'Throws an error if connecting and the certificate does not match' {
            $TCPClient = Connect-TCPClient -Server 'google.com' -port 443
            $TCPWriter = Get-TCPWriter -TcpClient $TCPClient -UseTLS -ServerHostname 'google.com'
            $TCPWriter | Should -BeOfType System.IO.StreamWriter
            Disconnect-TCPWriter -TcpWriter $TCPWriter
        }

        It 'Does not throw an error if connecting and the certificate does not match and -DoNotValidateTLSCertificate is used and returns a TCP writer' {
            $TCPClient = Connect-TCPClient -Server 'google.com' -port 443
            $TCPWriter = Get-TCPWriter -TcpClient $TCPClient -UseTLS -ServerHostname 'notgoogle.com' -DoNotValidateTLSCertificate
            $TCPWriter | Should -BeOfType System.IO.StreamWriter
            Disconnect-TCPWriter -TcpWriter $TCPWriter
        }
    }

}
