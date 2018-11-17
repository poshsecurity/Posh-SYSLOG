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
        It 'Does not accept null IP Address' {
            {Get-NetworkAdapter -IPAddress $null} | Should Throw
        }

        It 'Does not accept empty string for an IP Address' {
            {Get-NetworkAdapter -IPAddress ''} | Should Throw
        }

        It 'Does not accept invalid IP Addresses (1)' {
            {Get-NetworkAdapter -IPAddress 'cat'} | Should Throw
        }

        It 'Does not accept invalid IP Addresses (2)' {
            {Get-NetworkAdapter -IPAddress '321.321.321.321'} | Should Throw
        }

        It 'Does not accept invalid IP Addresses (3)' {
            {Get-NetworkAdapter -IPAddress '321.123.123.123'} | Should Throw
        }

        It 'Does not accept invalid IP Addresses (4)' {
            {Get-NetworkAdapter -IPAddress '123.321.123.123'} | Should Throw
        }

        It 'Does not accept invalid IP Addresses (5)' {
            {Get-NetworkAdapter -IPAddress '123.123.321.123'} | Should Throw
        }

        It 'Does not accept invalid IP Addresses (6)' {
            {Get-NetworkAdapter -IPAddress '123.123.123.321'} | Should Throw
        }

        It 'Does not accept invalid IP Addresses (7)' {
            {Get-NetworkAdapter -IPAddress '123'} | Should Throw
        }

        It 'Does not accept invalid IP Addresses (8)' {
            {Get-NetworkAdapter -IPAddress '123.123'} | Should Throw
        }

        It 'Does not accept invalid IP Addresses (9)' {
            {Get-NetworkAdapter -IPAddress '123.123.123'} | Should Throw
        }

        It 'Does not accept invalid IP Addresses (10)' {
            {Get-NetworkAdapter -IPAddress '123.123.123.123.123'} | Should Throw
        }

        It 'Throws an error if it cannot find the IP address' {
            {Get-NetworkAdapter -IPAddress '1.1.1.1'} | Should Throw
        }

        It 'Does accept a valid ip address' {
            {Get-NetworkAdapter -IPAddress '127.0.0.1'} | Should Not Throw
        }
    }

}
