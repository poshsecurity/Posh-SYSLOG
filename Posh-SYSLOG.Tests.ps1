Import-Module $PSScriptRoot\Posh-SYSLOG.psm1 -Force
Stop-Job -Name SYSLOGUDPTest -ErrorAction SilentlyContinue
Remove-Job -Name SYSLOGUDPTest -Force -ErrorAction SilentlyContinue
Stop-Job -Name SYSLOGTCPTest -ErrorAction SilentlyContinue
Remove-Job -Name SYSLOGTCPTest -Force -ErrorAction SilentlyContinue

Describe 'Send-SyslogMessage' {
    Mock -ModuleName Posh-SYSLOG Get-Date { return (New-Object datetime(2000,1,1)) }
    
    Mock -ModuleName Posh-SYSLOG Get-WmiObject { return @{partofdomain = $false} }

    $ENV:Computername = 'TestHostname'
    
    
    $ExpectedTimeStamp = (New-Object datetime(2000,1,1)).ToString('yyyy-MM-ddTHH:mm:ss.ffffffzzz')
    
    Function Test-UdpMessage ($SendSyslogMessage)
    {
        $GetSyslogPacket = {
            $endpoint = New-Object System.Net.IPEndPoint ([IPAddress]::Any,514)
            $udpclient= New-Object System.Net.Sockets.UdpClient 514
            $content=$udpclient.Receive([ref]$endpoint)
            [Text.Encoding]::ASCII.GetString($content)
        }

        $null = start-job -Name SYSLOGUDPTest -ScriptBlock $GetSyslogPacket
        Start-Sleep 2
        Invoke-Expression $SendSyslogMessage
        do
        {
            Start-Sleep 1
        }          
        until ((Get-Job -Name SYSLOGUDPTest | Select-Object -ExpandProperty State) -eq 'Completed')
        $UDPResult = Receive-Job SYSLOGUDPTest
        Remove-Job SYSLOGUDPTest
        return $UDPResult
    }

    Function Test-TcpMessage ($SendSyslogMessage)
    {
        $GetSyslogTcpMsg = {
            $endpoint = New-Object System.Net.IPEndPoint ([IPAddress]::Any,514)
            $tcplistener= New-Object System.Net.Sockets.TcpListener $endpoint
            $tcplistener.start()
            $client = $tcplistener.AcceptTcpClient() # will block here until connection
            $stream = $client.GetStream()
            $reader = New-Object System.IO.StreamReader $stream   
            $content = $reader.ReadToEnd()
            $content
            $reader.Dispose()
            $stream.Dispose()
            $client.Dispose()
            $tcplistener.stop()
        }

        $null = start-job -Name SYSLOGTCPTest -ScriptBlock $GetSyslogTcpMsg
        Start-Sleep 2
        Invoke-Expression $SendSyslogMessage
        do
        {
            Start-Sleep 1
        }          
        until ((Get-Job -Name SYSLOGTCPTest | Select-Object -ExpandProperty State) -eq 'Completed')
        $TcpResult = Receive-Job SYSLOGTCPTest
        Remove-Job SYSLOGTCPTest
        return $TcpResult
    }

    Context 'Get-SyslogHostname = Tests' {

    }

    Context 'Connect-UDPClient = Tests' {

    }

    Context 'Connect-TCPClient = Tests' {

    }

    Context 'Get-TCPWriter = Tests' {

    }

    Context 'Disconnect-UDPClient = Tests' {

    }

    Context 'Disconnect-TCPWriter = Tests' {

    }

    Context 'Send-SyslogMessage = Parameter Validation' {
        It 'Should not accept a null value for the server' {
            {Send-SyslogMessage -Server $null -Message 'Test Syslog Message' -Severity 'Alert' -Facility 'auth'} | Should Throw 'The argument is null or empty'
        }

        It 'Should not accept an empty string for the server' {
            {Send-SyslogMessage -Server '' -Message 'Test Syslog Message' -Severity 'Alert' -Facility 'auth'} | Should Throw 'The argument is null or empty'
        }

        It 'Should not accept a null value for the message' {
            {Send-SyslogMessage -Server '127.0.0.1' -Message $null -Severity 'Alert' -Facility 'auth'} | Should Throw 'The argument is null or empty'
        }

        It 'Should not accept an empty string for the message' {
            {Send-SyslogMessage -Server '127.0.0.1' -Message '' -Severity 'Alert' -Facility 'auth'} | Should Throw 'The argument is null or empty'
        }

        It 'Should not accept a null value for the severity' {
            {Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity $null -Facility 'auth'} | Should Throw 'Cannot convert null to type "Syslog_Severity"'
        }

        It 'Should not accept an empty string for the severity' {
            {Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity '' -Facility 'auth'} | Should Throw 'Cannot process argument transformation on parameter'
        }

        It 'Should not accept a null value for the facility' {
            {Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility $null} | Should Throw 'Cannot convert null to type "Syslog_Facility"'
        }

        It 'Should not accept an empty string for the facility' {
            {Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility ''} | Should Throw 'Cannot process argument transformation on parameter'
        }

        It 'Should not accept a null value for the hostname' {
            {Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility 'auth' -Hostname $null} | Should Throw 'The argument is null or empty'
        }

        It 'Should not accept an empty string for the hostname' {
            {Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility 'auth' -Hostname ''} | Should Throw 'The argument is null or empty'
        }

        It 'Should not accept a null value for the application name' {
            {Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility 'auth' -ApplicationName $null} | Should Throw 'The argument is null or empty'
        }

        It 'Should not accept an empty string for the application name' {
            {Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility 'auth' -ApplicationName ''} | Should Throw 'The argument is null or empty'
        }

        It 'Should not accept a null value for the ProcessID' {
            {Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility 'auth' -ProcessID $null} | Should Throw 'The argument is null or empty'
        }

        It 'Should not accept an empty string for the ProcessID' {
            {Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility 'auth' -ProcessID ''} | Should Throw 'The argument is null or empty'
        }

        It 'Should not accept a null value for the MessageID' {
            {Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility 'auth' -MessageID $null} | Should Throw 'The argument is null or empty'
        }

        It 'Should not accept an empty string for the MessageID' {
            {Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility 'auth' -MessageID ''} | Should Throw 'The argument is null or empty'
        }

        It 'Should not accept a null value for the StructuredData' {
            {Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility 'auth' -StructuredData $null} | Should Throw 'The argument is null or empty'
        }

        It 'Should not accept an empty string for the StructuredData' {
            {Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility 'auth' -StructuredData ''} | Should Throw 'The argument is null or empty'
        }

        It 'Should not accept a null value for the timestamp' {
            {Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility 'auth' -Timestamp $null} | Should Throw 'Cannot convert null to type "System.DateTime"'
        }

        It 'Should not accept a null value for the port' {
            {Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility 'auth' -Port $null} | Should Throw 'Cannot validate argument on parameter'
        }

        It 'Should not accept an invalid value for the port' {
            {Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility 'auth' -Port 456789789789} | Should Throw 'Error: "Value was either too large or too small for a UInt16.'
        }

        It 'Should not accept a null value for the UDP port' {
            {Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility 'auth' -UDPPort $null} | Should Throw 'Cannot validate argument on parameter'
        }

        It 'Should not accept an invalid value for the UDP port' {
            {Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility 'auth' -UDPPort 456789789789} | Should Throw 'Error: "Value was either too large or too small for a UInt16.'
        }

        It 'Should not accept a null value for the TCP port' {
            {Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility 'auth' -TCPPort $null} | Should Throw 'Cannot validate argument on parameter'
        }

        It 'Should not accept an invalid value for the TCP port' {
            {Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility 'auth' -TCPPort 456789789789} | Should Throw 'Error: "Value was either too large or too small for a UInt16.'
        }

        It 'Should Accept UDP as a Transport' {
            {Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility 'auth' -Transport UDP} | Should Not Throw 'Cannot validate argument on parameter'
        }

        It 'Should Accept TCP as a Transport' {
            {Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility 'auth' -Transport TCP} | Should Not Throw 'Cannot validate argument on parameter'
        }

        It 'Should not accept a null value for Transport' {
            {Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility 'auth' -Transport $null} | Should Throw 'Cannot validate argument on parameter'
        }

        It 'Should not accept an invalid value for Transport' {
            {Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility 'auth' -Transport 'bob'} | Should Throw 'Cannot validate argument on parameter'
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

    Context 'Send-SyslogMessage = Pipeline input' {

    }

    Context 'Send-SyslogMessage = Severity Level Calculations' {
        It 'Calculates the correct priority of 0 if Facility is Kern and Severity is Emergency' {
            $TestCase = "Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Emergency' -Facility 'kern'"
            $ExpectedResult = '<0>1 {0} TestHostname PowerShell {1} - - Test Syslog Message' -f $ExpectedTimeStamp, $PID
            $TestResult = Test-UdpMessage $TestCase
            $TestResult | Should Be $ExpectedResult
        }

        It 'Calculates the correct priority of 7 if Facility is Kern and Severity is Debug' {
            $TestCase = "Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Debug' -Facility 'kern'"
            $ExpectedResult = '<7>1 {0} TestHostname PowerShell {1} - - Test Syslog Message' -f $ExpectedTimeStamp, $PID
            $TestResult = Test-UdpMessage $TestCase
            $TestResult | Should Be $ExpectedResult
        }   

        It 'Calculates the correct priority of 24 if Facility is daemon and Severity is Emergency' {
            $TestCase = "Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Emergency' -Facility 'daemon'"
            $ExpectedResult = '<24>1 {0} TestHostname PowerShell {1} - - Test Syslog Message' -f $ExpectedTimeStamp, $PID
            $TestResult = Test-UdpMessage $TestCase
            $TestResult | Should Be $ExpectedResult
        }

        It 'Calculates the correct priority of 31 if Facility is daemon and Severity is Debug' {
            $TestCase = "Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Debug' -Facility 'daemon'"
            $ExpectedResult = '<31>1 {0} TestHostname PowerShell {1} - - Test Syslog Message' -f $ExpectedTimeStamp, $PID
            $TestResult = Test-UdpMessage $TestCase
            $TestResult | Should Be $ExpectedResult
        }
    }

    Context 'Send-SyslogMessage = RFC 3164 Message Format' {
        It 'Should send RFC5424 formatted message' {
            $TestCase = "Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility 'auth' -RFC3164"
            $ExpectedResult = '<33>Jan 01 00:00:00 TestHostname PowerShell Test Syslog Message'
            $TestResult = Test-UdpMessage $TestCase
            $TestResult | Should Be $ExpectedResult
        }
    }

    Context 'Send-SyslogMessage = RFC 5424 message format' {
        It 'Should send RFC5424 formatted message' {
            $TestCase = "Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility 'auth'"
            $ExpectedResult = '<33>1 {0} TestHostname PowerShell {1} - - Test Syslog Message' -f $ExpectedTimeStamp, $PID
            $TestResult = Test-UdpMessage $TestCase
            $TestResult | Should Be $ExpectedResult
        }
    }

    Context 'Send-SyslogMessage = Hostname determination' {
        It 'Uses any hostname it is given' {
            $TestCase = "Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility 'auth' -Hostname 'SomeRandomHostName'"
            $ExpectedResult = '<33>1 {0} SomeRandomHostName PowerShell {1} - - Test Syslog Message' -f $ExpectedTimeStamp, $PID
            $TestResult = Test-UdpMessage $TestCase
            $TestResult | Should Be $ExpectedResult
        }

        It 'Uses the FQDN if the computer is domain joined' {
            $ENV:userdnsdomain = 'contoso.com'
            Mock -ModuleName Posh-SYSLOG Get-WmiObject { return @{partofdomain = $true; DNSHostname = 'TestHostname'; Domain = 'contoso.com'} }

            $TestCase = "Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility 'auth'"
            $ExpectedResult = '<33>1 {0} TestHostname.contoso.com PowerShell {1} - - Test Syslog Message' -f $ExpectedTimeStamp, $PID
            $TestResult = Test-UdpMessage $TestCase
            $ENV:userdnsdomain = ''
            Mock -ModuleName Posh-SYSLOG Get-WmiObject { return @{partofdomain = $false} }

            $TestResult | Should Be $ExpectedResult
        }

        It 'Uses a Static IP address, on the correct interface that the server is reached on, if no FQDN and not hostname specified' {
            Mock -ModuleName Posh-SYSLOG Get-NetIPAddress {return @{PrefixOrigin = 'Manual'}}

            $TestCase = "Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility 'auth'"
            $ExpectedResult = '<33>1 {0} 127.0.0.1 PowerShell {1} - - Test Syslog Message' -f $ExpectedTimeStamp, $PID
            $TestResult = Test-UdpMessage $TestCase
            $TestResult | Should Be $ExpectedResult
        }

        It 'Uses the Windows computer name, if no static ip or FQDN' {
            Mock -ModuleName Posh-SYSLOG Get-NetIPAddress {return $null} 

            $TestCase = "Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility 'auth'"
            $ExpectedResult = '<33>1 {0} TestHostname PowerShell {1} - - Test Syslog Message' -f $ExpectedTimeStamp, $PID
            $TestResult = Test-UdpMessage $TestCase
            $TestResult | Should Be $ExpectedResult
        }
    }

    Context 'Send-SyslogMessage = Message Length UDP' {
        $LongMsg = 'This is a very long syslog message. 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890'

        It 'truncates RFC 5424 messages to 2k' {
            $TestCase = "Send-SyslogMessage -Server '127.0.0.1' -Message '$LongMsg' -Severity 'Alert' -Facility 'auth' -Hostname TestHostname"
            $ExpectedResult = ('<33>1 {0} TestHostname PowerShell {1} - - {2}' -f $ExpectedTimeStamp, $PID, $LongMsg).Substring(0,2048)
            $TestResult = Test-UdpMessage $TestCase
            $TestResult | Should Be $ExpectedResult
        }
        It 'truncates RFC 3164 messages to 1k' {
            $TestCase = "Send-SyslogMessage -Server '127.0.0.1' -Message '$LongMsg' -Severity 'Alert' -Facility 'auth' -RFC3164 -Hostname TestHostname"
            $ExpectedResult = ('<33>Jan 01 00:00:00 TestHostname PowerShell {1}' -f $ExpectedTimeStamp, $LongMsg).Substring(0,1024)
            $TestResult = Test-UdpMessage $TestCase
            $TestResult | Should Be $ExpectedResult
        }
    }

    Context 'Send-SyslogMessage = Message Length TCP' {

    }

    Context 'Send-SyslogMessage = TCP Specific Tests' {
        It 'sends using TCP transport' {
            $TestCase = "Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility 'auth' -Hostname TestHostname -Transport TCP"
            $ExpectedResult = '61 <33>1 {0} TestHostname PowerShell {1} - - Test Syslog Message' -f $ExpectedTimeStamp, $PID
            $TestResult = Test-TcpMessage $TestCase
            $TestResult | Should Be $ExpectedResult
        }

        It 'sends using TCP transport with Octet-Counting as the framing' {
            $TestCase = "Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility 'auth' -Hostname TestHostname -Transport TCP -FramingMethod Octet-Counting"
            $ExpectedResult = '61 <33>1 {0} TestHostname PowerShell {1} - - Test Syslog Message' -f $ExpectedTimeStamp, $PID
            $TestResult = Test-TcpMessage $TestCase
            $TestResult | Should Be $ExpectedResult
        }
        It 'sends using TCP transport with Non-Transparent-Framing as the framing' {
            $TestCase = "Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility 'auth' -Hostname TestHostname -Transport TCP -FramingMethod Non-Transparent-Framing"
            $ExpectedResult = '<33>1 {0} TestHostname PowerShell {1} - - Test Syslog Message`n' -f $ExpectedTimeStamp, $PID
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
    #TODO: what about if we cannot connect to the TCP port? Need to test that!

    Context 'Send-SyslogMessage = Generic Tests' {
        It 'does not return any values' {
            $TestCase = Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility 'auth'
            $TestCase | Should be $null
        }
    }

    Context 'Scrypt Analyzer' {
        It 'Does not have any issues with the Script Analyser' {
            Invoke-ScriptAnalyzer .\Functions\*.ps1 | Should be $null
        }
    }

    Stop-Job -Name SYSLOGUDPTest -ErrorAction SilentlyContinue
    Remove-Job -Name SYSLOGUDPTest -Force -ErrorAction SilentlyContinue
    Stop-Job -Name SYSLOGTCPTest -ErrorAction SilentlyContinue
    Remove-Job -Name SYSLOGTCPTest -Force -ErrorAction SilentlyContinue

}