﻿Import-Module $PSScriptRoot\Posh-SYSLOG.psm1 -Force
Stop-Job -Name SyslogTest1 -ErrorAction SilentlyContinue
Remove-Job -Name SyslogTest1 -Force -ErrorAction SilentlyContinue

Describe 'Send-SyslogMessage' {
    Mock -ModuleName Posh-SYSLOG Get-Date { return (New-Object datetime(2000,1,1)) }

    Mock -ModuleName Posh-SYSLOG Get-NetIPAddress {return $null}

    Mock -ModuleName Posh-SYSLOG Test-NetConnection {
        $Connection = New-Object PSCustomObject
        $Connection | Add-Member -MemberType NoteProperty -Name 'SourceAddress' -Value (New-Object PSCustomObject) -Force
        $Connection.SourceAddress | Add-Member -MemberType NoteProperty -Name 'IPAddress' -Value ('123.123.123.123') -Force
        $Connection.SourceAddress | Add-Member -MemberType NoteProperty -Name 'PrefixOrigin' -Value ('Manual') -Force
        return $Connection
    }

    $ENV:Computername = 'TestHostname'
    $ENV:userdnsdomain = $null
    
    $ExpectedTimeStamp = (New-Object datetime(2000,1,1)).ToString('yyyy-MM-ddTHH:mm:ss.ffffffzzz')
    function Test-Message ($SendSyslogMessage)
    {
        $GetSyslogPacket = {
            $endpoint = New-Object System.Net.IPEndPoint ([IPAddress]::Any,514)
            $udpclient= New-Object System.Net.Sockets.UdpClient 514
            $content=$udpclient.Receive([ref]$endpoint)
            [Text.Encoding]::ASCII.GetString($content)
        }

        $null = start-job -Name SyslogTest1 -ScriptBlock $GetSyslogPacket
        Start-Sleep 2
        Invoke-Expression $SendSyslogMessage
        do
        {
            Start-Sleep 2
        }          
        until ((Get-Job -Name SyslogTest1 | Select-Object -ExpandProperty State) -eq 'Completed')
        $UDPResult = Receive-Job SyslogTest1
        Remove-Job SyslogTest1
        return $UDPResult
    }


    function Test-TcpMessage ($SendSyslogMessage)
    {
        $GetSyslogTcpMsg = {
            $endpoint = New-Object System.Net.IPEndPoint ([IPAddress]::Any,514)
            $tcplistener= New-Object System.Net.Sockets.TcpListener $endpoint
            $tcplistener.start()

            $client = $tcplistener.AcceptTcpClient() # will block here until connection
            $stream = $client.GetStream();
            
            $reader = New-Object System.IO.StreamReader $stream   
            $content = $reader.ReadToEnd()
            $content
               
            $reader.Dispose()
            $stream.Dispose()
            $client.Dispose()
            $tcplistener.stop()
        }

        $null = start-job -Name SyslogTest2 -ScriptBlock $GetSyslogTcpMsg
        Start-Sleep 2
        Invoke-Expression $SendSyslogMessage
        do
        {
            Start-Sleep 2
        }          
        until ((Get-Job -Name SyslogTest2 | Select-Object -ExpandProperty State) -eq 'Completed')
        $TcpResult = Receive-Job SyslogTest2
        Remove-Job SyslogTest2
        return $TcpResult
    }


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

        It 'Should reject ProcessID parameter if -RFC3164 is specified' {
            {Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility 'auth' -RFC3164 -ProcessID 1} | Should Throw 'Parameter set cannot be resolved using the specified named parameters'
        }

        It 'Should reject MessageID parameter if -RFC3164 is specified' {
            {Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility 'auth' -RFC3164 -MessageID 1} | Should Throw 'Parameter set cannot be resolved using the specified named parameters'
        }

        It 'Should reject StructuredData parameter if -RFC3164 is specified' {
            {Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility 'auth' -RFC3164 -StructuredData 1} | Should Throw 'Parameter set cannot be resolved using the specified named parameters'
        }
    }

    Context 'Severity Level Calculations' {
        It 'Calculates the correct priority of 0 if Facility is Kern and Severity is Emergency' {
            $TestCase = "Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Emergency' -Facility 'kern' -Hostname TestHostname"
            $ExpectedResult = '<0>1 {0} TestHostname PowerShell {1} - - Test Syslog Message' -f $ExpectedTimeStamp, $PID
            $TestResult = Test-Message $TestCase
            $TestResult | Should Be $ExpectedResult
        }

        It 'Calculates the correct priority of 7 if Facility is Kern and Severity is Debug' {
            $TestCase = "Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Debug' -Facility 'kern' -Hostname TestHostname"
            $ExpectedResult = '<7>1 {0} TestHostname PowerShell {1} - - Test Syslog Message' -f $ExpectedTimeStamp, $PID
            $TestResult = Test-Message $TestCase
            $TestResult | Should Be $ExpectedResult
        }   

        It 'Calculates the correct priority of 24 if Facility is daemon and Severity is Emergency' {
            $TestCase = "Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Emergency' -Facility 'daemon' -Hostname TestHostname"
            $ExpectedResult = '<24>1 {0} TestHostname PowerShell {1} - - Test Syslog Message' -f $ExpectedTimeStamp, $PID
            $TestResult = Test-Message $TestCase
            $TestResult | Should Be $ExpectedResult
        }

        It 'Calculates the correct priority of 31 if Facility is daemon and Severity is Debug' {
            $TestCase = "Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Debug' -Facility 'daemon' -Hostname TestHostname"
            $ExpectedResult = '<31>1 {0} TestHostname PowerShell {1} - - Test Syslog Message' -f $ExpectedTimeStamp, $PID
            $TestResult = Test-Message $TestCase
            $TestResult | Should Be $ExpectedResult
        }
    }

    Context 'RFC 3164 Message Format' {
        It 'Should send RFC5424 formatted message' {
            $TestCase = "Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility 'auth' -RFC3164 -Hostname TestHostname"
            $ExpectedResult = '<33>Jan 01 00:00:00 TestHostname PowerShell Test Syslog Message'
            $TestResult = Test-Message $TestCase
            $TestResult | Should Be $ExpectedResult
        }
    }

    Context 'RFC 5424 message format' {
        It 'Should send RFC5424 formatted message' {
            $TestCase = "Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility 'auth' -Hostname TestHostname"
            $ExpectedResult = '<33>1 {0} TestHostname PowerShell {1} - - Test Syslog Message' -f $ExpectedTimeStamp, $PID
            $TestResult = Test-Message $TestCase
            $TestResult | Should Be $ExpectedResult
        }
    }

    Context 'Hostname determination' {              
        It 'Uses any hostname it is given' {
            $TestCase = "Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility 'auth' -Hostname 'SomeRandomHostNameDude.example.invalid'"
            $ExpectedResult = '<33>1 {0} SomeRandomHostNameDude.example.invalid PowerShell {1} - - Test Syslog Message' -f $ExpectedTimeStamp, $PID
            $TestResult = Test-Message $TestCase
            $TestResult | Should Be $ExpectedResult
        }

        <# #These tests will not work with the new FQDN and static IP detection:

        It 'Uses the FQDN if the computer is domain joined' {
            #$ENV:userdnsdomain = 'contoso.com'
            $TestCase = "Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility 'auth'"
            $ExpectedResult = '<33>1 {0} {1} PowerShell {2} - - Test Syslog Message' -f $ExpectedTimeStamp, $FQDN, $PID
            $TestResult = Test-Message $TestCase
            #$ENV:userdnsdomain = ''
            $TestResult | Should Be $ExpectedResult
        }

        It 'Uses a Static IP address, on the correct interface that the server is reached on, if no FQDN and not hostname specified' {
            Mock -ModuleName Posh-SYSLOG Get-NetIPAddress {return 'value'}          

            $TestCase = "Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility 'auth'"
            $ExpectedResult = '<33>1 {0} 123.123.123.123 PowerShell {1} - - Test Syslog Message' -f $ExpectedTimeStamp, $PID
            $TestResult = Test-Message $TestCase
            $TestResult | Should Be $ExpectedResult
        }

        It 'Uses the Windows computer name, if no static ip or FQDN' {
            Mock -ModuleName Posh-SYSLOG Get-NetIPAddress {return $null} 

            $TestCase = "Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility 'auth'"
            $ExpectedResult = '<33>1 {0} TestHostname PowerShell {1} - - Test Syslog Message' -f $ExpectedTimeStamp, $PID
            $TestResult = Test-Message $TestCase
            $TestResult | Should Be $ExpectedResult
        }
        #>
    }

    Context 'Log Message tests' {
        $LongMsg = 'This is a very long syslog message. 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890'

        It 'truncates RFC 5424 messages to 2k' {
            $TestCase = "Send-SyslogMessage -Server '127.0.0.1' -Message '$LongMsg' -Severity 'Alert' -Facility 'auth' -Hostname TestHostname"
            $ExpectedResult = ('<33>1 {0} TestHostname PowerShell {1} - - {2}' -f $ExpectedTimeStamp, $PID, $LongMsg).Substring(0,2048)
            $TestResult = Test-Message $TestCase
            $TestResult | Should Be $ExpectedResult
        }
        It 'truncates RFC 3164 messages to 1k' {
            $TestCase = "Send-SyslogMessage -Server '127.0.0.1' -Message '$LongMsg' -Severity 'Alert' -Facility 'auth' -RFC3164 -Hostname TestHostname"
            $ExpectedResult = ('<33>Jan 01 00:00:00 TestHostname PowerShell {1}' -f $ExpectedTimeStamp, $LongMsg).Substring(0,1024)
            $TestResult = Test-Message $TestCase
            $TestResult | Should Be $ExpectedResult
        }
        It 'sends using TCP transport' {
            $TestCase = "Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility 'auth' -Hostname TestHostname -Transport TCP -FramingMethod Non-Transparent-Framing"
            $ExpectedResult = '<33>1 {0} TestHostname PowerShell {1} - - Test Syslog Message' -f $ExpectedTimeStamp, $PID
            $TestResult = Test-TcpMessage $TestCase
            $TestResult | Should Be $ExpectedResult
        }
    }




    Context 'TCP Message tests' {
        It 'sends using TCP transport with Octet-Counting as the framing' {
            $TestCase = "Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility 'auth' -Hostname TestHostname -Transport TCP -FramingMethod Octet-Counting"
            $ExpectedResult = '61 <33>1 {0} TestHostname PowerShell {1} - - Test Syslog Message' -f $ExpectedTimeStamp, $PID
            $TestResult = Test-TcpMessage $TestCase
            $TestResult | Should Be $ExpectedResult
        }
        It 'sends using TCP transport with Non-Transparent-Framing as the framing' {
            $TestCase = "Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility 'auth' -Hostname TestHostname -Transport TCP -FramingMethod Non-Transparent-Framing"
            $ExpectedResult = '<33>1 {0} TestHostname PowerShell {1} - - Test Syslog Message\n' -f $ExpectedTimeStamp, $PID
            $TestResult = Test-TcpMessage $TestCase
            $TestResult | Should Be $ExpectedResult
        }

        It 'sends using TCP transport with no framing' {
            $TestCase = "Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility 'auth' -Hostname TestHostname -Transport TCP -FramingMethod None"
            $ExpectedResult = '<33>1 {0} TestHostname PowerShell {1} - - Test Syslog Message' -f $ExpectedTimeStamp, $PID
            $TestResult = Test-TcpMessage $TestCase
            $TestResult | Should Be $ExpectedResult
        }

    }

    Context 'Function tests' {
        It 'does not return any values' {
            $TestCase = Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility 'auth'
            $TestCase | Should be $null
        }
    }

    Context 'Scrypt Analyzer' {
        It 'Does not have any issues with the Script Analyser' {
            Invoke-ScriptAnalyzer .\Functions\Send-SyslogMessage.ps1 | Should be $null
        }
    }

}