Import-Module $PSScriptRoot\PowerShellSyslog.psm1 -Force

Describe 'Send-SyslogMessage' {
    Mock Get-Date { return New-Object datetime(2000,1,1) }
    $TestHostname = 'TestRig'

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

        It 'Should not accept a null value for the facility' {
            {Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility 'auth'} | Should Throw ''
        }

    }

    Context 'Output' {
        It 'Should not return any value' {
            Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility 'auth' | Should be $null
        }
    }

    Context 'Verbose Information - Not RFC Specific' {
        It 'verbosely should print the correct priority of 0 if Facility is Kern and Severity is Emergency' {
            (Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Emergency' -Facility 'kern' -Verbose 4>&1)[1] | Should Match 'Priority is 0'
        }

        It 'verbosely should print the correct priority of 7 if Facility is Kern and Severity is Debug' {
            (Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'debug' -Facility 'kern' -Verbose 4>&1)[1] | Should Match 'Priority is 7'
        }

        It 'verbosely should print the correct priority of 24 if Facility is daemon and Severity is Emergency' {
            (Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Emergency' -Facility 'daemon' -Verbose 4>&1)[1] | Should Match 'Priority is 24'
        }

        It 'verbosely should print the correct priority of 31 if Facility is daemon and Severity is Debug' {
            (Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'debug' -Facility 'daemon' -Verbose 4>&1)[1] | Should Match 'Priority is 31'
        }
    }

    Context 'Verbose Information - RFC 3164' {
        It 'Should send RFC 3164 formatted message (checked via verbose output)' {
            Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility 'auth' -Timestamp (Get-Date) -Hostname $TestHostname -Verbose | Should be $null
        }
    }

    Context 'Verbose Information - RFC 5424' {
    
    }
}