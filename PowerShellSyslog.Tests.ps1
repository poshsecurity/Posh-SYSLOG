Import-Module $PSScriptRoot\PowerShellSyslog.psm1 -Force

Describe 'Send-SyslogMessage' {
    Mock -ModuleName PowerShellSyslog Get-Date { return (New-Object datetime(2000,1,1)) }

    Mock -ModuleName PowerShellSyslog Get-NetIPAddress {return $null}

    Mock -ModuleName PowerShellSyslog Test-NetConnection {return 'DHCP'}

    $ENV:Computername = 'TestHostname'
    $ENV:userdnsdomain = $null

    Context 'Parameter Validation' {
        It 'Should not accept a null value for the server' {
            {Send-SyslogMessage -Server $null -Message 'Test Syslog Message' -Severity 'Alert' -Facility 'auth'} | Should Throw 'The argument is null or empty'
        }
        It 'Should not accept a null value for the message' {
            {Send-SyslogMessage -Server '127.0.0.1' -Message $null -Severity 'Alert' -Facility 'auth'} | Should Throw 'The argument is null or empty'
        }

        It 'Should not accept a null value for the severity' {
            {Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity $null -Facility 'auth'} | Should Throw 'Cannot convert null to type "Syslog_Severity"'
        }

        It 'Should not accept a null value for the facility' {
            {Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility $null} | Should Throw 'Cannot convert null to type "Syslog_Facility"'
        }

        It 'Should not accept a null value for the hostname' {
            {Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility 'auth' -Hostname $null} | Should Throw 'The argument is null or empty'
        }

        It 'Should not accept a null value for the application name' {
            {Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility 'auth' -ApplicationName $null} | Should Throw 'The argument is null or empty'
        }

        It 'Should not accept a null value for the timestamp' {
            {Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility 'auth' -Timestamp $null} | Should Throw 'Cannot convert null to type "System.DateTime"'
        }

        It 'Should not accept a null value for the UDP port' {
            {Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility 'auth' -UDPPort $null} | Should Throw 'Cannot validate argument on parameter'
        }

        It 'Should not accept an invalid value for the UDP port' {
            {Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility 'auth' -UDPPort 456789789789} | Should Throw 'Error: "Value was either too large or too small for a UInt16.'
        }

        It 'If the -RFC3164 is specified, reject ProcessID parameter' {
        
        }

        It 'If the -RFC3164 is specified, reject MessageID parameter' {
        
        }

        It 'If the -RFC3164 is specified, reject StructuredData parameter' {
        
        }

        <#

        .PARAMETER RFC3164
            Send an RFC3164 fomatted message instead of RFC5424.

	        $ProcessID = $PID,
                $MessageID = '-',
                $StructuredData = '-',

        #>
    }

    Context 'Output' {
        It 'Should not return any value' {
            Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility 'auth' | Should be $null
        }
    }

    Context 'Verbose Information - Not RFC Specific' {
        It 'verbosely should print the correct priority of 0 if Facility is Kern and Severity is Emergency' {
            (Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Emergency' -Facility 'kern' -Verbose 4>&1)[1] | Should be 'Priority is 0'
        }

        It 'verbosely should print the correct priority of 7 if Facility is Kern and Severity is Debug' {
            (Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'debug' -Facility 'kern' -Verbose 4>&1)[1] | Should be 'Priority is 7'
        }

        It 'verbosely should print the correct priority of 24 if Facility is daemon and Severity is Emergency' {
            (Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Emergency' -Facility 'daemon' -Verbose 4>&1)[1] | Should be 'Priority is 24'
        }

        It 'verbosely should print the correct priority of 31 if Facility is daemon and Severity is Debug' {
            (Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'debug' -Facility 'daemon' -Verbose 4>&1)[1] | Should be 'Priority is 31'
        }
    }

    Context 'Verbose Information - RFC 3164' {
        $TestCase = Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility 'auth' -RFC3164 -Verbose 4>&1
        $Expected = 'Message to send will be <33>Jan 01 00:00:00 TestHostname PowerShellSyslog.Tests.ps1 Test Syslog Message'

        It 'Should contain RFC3164 formatted message' {
            $TestCase[3] | Should Be $Expected
        }
    }

    Context 'Verbose Information - RFC 5424' {
        $TestCase = Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility 'auth' -Verbose 4>&1
        $ExpectedTimeStamp = (New-Object datetime(2000,1,1)).ToString('yyyy-MM-ddTHH:mm:ss.ffffffzzz')
        $Expected = 'Message to send will be <33>1 {0} TestHostname PowerShellSyslog.Tests.ps1 {1} - - Test Syslog Message' -f $ExpectedTimeStamp, $PID

        It 'Should contain RFC5424 formatted message' {
            $TestCase[3] | Should Be $Expected
        }
    }

    Context 'Determine hostname correctly' {
    
    }
}


# Mock Get-NetIPAddress and Test-NetConnection