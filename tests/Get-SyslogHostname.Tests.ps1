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

# InModuleScope runs the test in module scope.
# It creates all variables and functions in module scope.
# As a result, test has access to all functions, variables and aliases
# in the module even if they're not exported.
InModuleScope $script:ModuleName {
    Describe "Basic function unit tests" -Tags Build , Unit{
        # Open TCP 514 so we can test TCP connections (without hitting the network)
        $TCPEndpoint = New-Object System.Net.IPEndPoint ([IPAddress]::Loopback,514)
        $TCPListener = New-Object System.Net.Sockets.TcpListener $TCPEndpoint
        $TCPListener.start()

        Context 'UDP Client Tests' {
            $UDPCLient = New-Object -TypeName System.Net.Sockets.UdpClient
            $UDPCLient.Connect('127.0.0.1', '514')

            It 'Uses the FQDN if the computer is domain joined' {
                Mock -ModuleName Posh-SYSLOG Get-CimInstance { return @{partofdomain = $true; DNSHostname = 'TestHostname'; Domain = 'contoso.com'} }
                $TestResult = Get-SyslogHostname -Socket $UDPCLient.Client
                Mock -ModuleName Posh-SYSLOG Get-CimInstance { return @{partofdomain = $false; DNSHostname = 'TestHostname'} }
                $TestResult | Should Be 'TestHostname.contoso.com'
            }

            It 'Uses a Static IP address, on the correct interface that the server is reached on, if no FQDN and not hostname specified' {
                Mock -ModuleName Posh-SYSLOG Get-NetworkAdapter {return @{PrefixOrigin = 'Manual'}}
                $TestResult = Get-SyslogHostname -Socket $UDPCLient.Client
                $TestResult | Should Be '127.0.0.1'
            }

            It 'Uses the Windows computer name, if no static ip or FQDN' {
                Mock -ModuleName Posh-SYSLOG Get-NetworkAdapter {return $null}
                $TestResult = Get-SyslogHostname -Socket $UDPCLient.Client
                $TestResult | Should Be 'TestHostname'
            }
        }

        Context 'TCP Client Tests' {
            $TCPCLient = New-Object -TypeName System.Net.Sockets.TcpClient
            $TCPCLient.Connect('127.0.0.1', '514')

            It 'Uses the FQDN if the computer is domain joined' {
                Mock -ModuleName Posh-SYSLOG Get-CimInstance { return @{partofdomain = $true; DNSHostname = 'TestHostname'; Domain = 'contoso.com'} }
                $TestResult = Get-SyslogHostname -Socket $TCPCLient.Client
                Mock -ModuleName Posh-SYSLOG Get-CimInstance { return @{partofdomain = $false; DNSHostname = 'TestHostname'} }
                $TestResult | Should Be 'TestHostname.contoso.com'
            }

            It 'Uses a Static IP address, on the correct interface that the server is reached on, if no FQDN and not hostname specified' {
                Mock -ModuleName Posh-SYSLOG Get-NetworkAdapter {return @{PrefixOrigin = 'Manual'}}
                $TestResult = Get-SyslogHostname -Socket $TCPCLient.Client
                $TestResult | Should Be '127.0.0.1'
            }

            It 'Uses the Windows computer name, if no static ip or FQDN' {
                Mock -ModuleName Posh-SYSLOG Get-NetworkAdapter {return $null}
                $TestResult = Get-SyslogHostname -Socket $TCPCLient.Client
                $TestResult | Should Be 'TestHostname'
            }
        }

        $TCPListener.stop()
    }

}
