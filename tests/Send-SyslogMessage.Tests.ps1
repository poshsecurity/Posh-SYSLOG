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
        Mock -ModuleName Posh-SYSLOG Get-Date { return (New-Object datetime(2000,1,1)) }

        Mock -ModuleName Posh-SYSLOG Get-CimInstance { return @{partofdomain = $false; DNSHostname = 'TestHostname'} }

        Mock -ModuleName Posh-SYSLOG Connect-TCPClient {
            return @{Client = New-Object -TypeName System.Net.Sockets.Socket -ArgumentList @([System.Net.Sockets.SocketType]::Stream, [System.Net.Sockets.ProtocolType]::Tcp)}
        }
        Mock -ModuleName Posh-SYSLOG Connect-UDPClient {
            return @{Client = New-Object -TypeName System.Net.Sockets.Socket -ArgumentList @([System.Net.Sockets.SocketType]::Dgram, [System.Net.Sockets.ProtocolType]::Udp)}
        }
        Mock -ModuleName Posh-SYSLOG Disconnect-TCPClient { }
        Mock -ModuleName Posh-SYSLOG Disconnect-UDPClient { }
        Mock -ModuleName Posh-SYSLOG Disconnect-TCPWriter { }
        Mock -ModuleName Posh-SYSLOG Get-TCPWriter {
            return (New-Object -TypeName System.IO.StreamWriter -ArgumentList  @([System.IO.Stream]::Null))
        }
        Mock -ModuleName Posh-SYSLOG Get-NetworkAdapter { return $null }
        Mock -ModuleName Posh-SYSLOG Get-SyslogHostname { return 'TestHostname' }
        Mock -CommandName Send-TCPMessage -ModuleName Posh-SYSLOG { $Global:TestResult = $Datagram; return $null }
        Mock -CommandName Send-UDPMessage -ModuleName Posh-SYSLOG { $Global:TestResult = $Datagram; return $null }

        $ExpectedTimeStamp = (New-Object datetime(2000,1,1)).ToString('yyyy-MM-ddTHH:mm:ss.ffffffzzz')

        # Create an ASCII Encoding object
        $Encoding = [Text.Encoding]::ASCII

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
                {Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity $null -Facility 'auth'} | Should Throw #'Cannot validate argument on parameter 'Severity'. The argument "" does not belong to the set "Emergency,Alert,Critical,Error,Warning,Notice,Informational,Debug" specified by the ValidateSet attribute. Supply an argument that is in the set and then try the command again.'
            }

            It 'Should not accept an empty string for the severity' {
                {Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity '' -Facility 'auth'} | Should Throw #'Cannot validate argument on parameter 'Severity'. The argument "" does not belong to the set "Emergency,Alert,Critical,Error,Warning,Notice,Informational,Debug" specified by the ValidateSet attribute. Supply an argument that is in the set and then try the command again.'
            }

            foreach ($value in [Syslog_Severity].GetEnumNames()){
                It "Should accept $value for Syslog_Severity" {
                    {Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity $value -Facility 'auth'} | Should not Throw
                }
            }

            It 'Should not accept a null value for the facility' {
                {Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility $null} | Should Throw #'Cannot validate argument on parameter 'Facility'. The argument "" does not belong to the set "kern,user,mail,daemon,auth,syslog,lpr,news,uucp,clock,authpriv,ftp,ntp,logaudit,logalert,cron,local0,local1,local2,local3,local4,local5,local6,local7" specified by the ValidateSet attribute. Supply an argument that is in the set and then try the command again.'
            }

            It 'Should not accept an empty string for the facility' {
                {Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility ''} | Should Throw #'Cannot validate argument on parameter 'Facility'. The argument "" does not belong to the set "kern,user,mail,daemon,auth,syslog,lpr,news,uucp,clock,authpriv,ftp,ntp,logaudit,logalert,cron,local0,local1,local2,local3,local4,local5,local6,local7" specified by the ValidateSet attribute. Supply an argument that is in the set and then try the command again.'
            }

            foreach ($value in [Syslog_Facility].GetEnumNames()){
                It "Should accept $value for Syslog_Facility" {
                    {Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility $value} | Should not Throw
                }
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

            It 'Should accept an valid string for the application name' {
                {Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility 'auth' -ApplicationName 'ApplicationName'} | Should Not Throw
            }

            It 'Should not accept a null value for the ProcessID' {
                {Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility 'auth' -ProcessID $null} | Should Throw 'The argument is null or empty'
            }

            It 'Should not accept an empty string for the ProcessID' {
                {Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility 'auth' -ProcessID ''} | Should Throw 'The argument is null or empty'
            }

             It 'Should accept an valid string for the ProcessID' {
                {Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility 'auth' -ProcessID '3214893'} | Should Not Throw
            }

            It 'Should not accept a null value for the MessageID' {
                {Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility 'auth' -MessageID $null} | Should Throw 'The argument is null or empty'
            }

            It 'Should not accept an empty string for the MessageID' {
                {Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility 'auth' -MessageID ''} | Should Throw 'The argument is null or empty'
            }

            It 'Should accept an valid string for the MessageID' {
                {Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility 'auth' -MessageID 'messageid'} | Should Not Throw
            }

            It 'Should not accept a null value for the StructuredData' {
                {Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility 'auth' -StructuredData $null} | Should Throw 'The argument is null or empty'
            }

            It 'Should not accept an empty string for the StructuredData' {
                {Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility 'auth' -StructuredData ''} | Should Throw 'The argument is null or empty'
            }

            It 'Should accept an valid string for the StructuredData' {
                {Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility 'auth' -StructuredData 'structureddata'} | Should Not Throw
            }

            It 'Should not accept a null value for the timestamp' {
                {Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility 'auth' -Timestamp $null} | Should Throw 'Cannot convert null to type "System.DateTime"'
            }

            It 'Should accept a valid value for the timestamp' {
                {Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility 'auth' -Timestamp $ExpectedTimeStamp} | Should Not Throw
            }

            It 'Should not accept a null value for the port' {
                {Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility 'auth' -Port $null} | Should Throw 'Cannot validate argument on parameter'
            }

            It 'Should not accept an invalid value for the port' {
                {Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility 'auth' -Port 456789789789} | Should Throw 'Error: "Value was either too large or too small for a UInt16.'
            }

            It 'Should accept an valid value for the port' {
                {Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility 'auth' -Port 445} | Should Not Throw
            }

            It 'Should not accept a null value for the UDP port' {
                {Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility 'auth' -UDPPort $null} | Should Throw 'Cannot validate argument on parameter'
            }

            It 'Should not accept an invalid value for the UDP port' {
                {Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility 'auth' -UDPPort 456789789789} | Should Throw 'Error: "Value was either too large or too small for a UInt16.'
            }

            It 'Should accept an valid value for the UDP port' {
                {Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility 'auth' -UDPPort 445} | Should Not Throw
            }

            It 'Should not accept a null value for the TCP port' {
                {Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility 'auth' -TCPPort $null} | Should Throw 'Cannot validate argument on parameter'
            }

            It 'Should not accept an invalid value for the TCP port' {
                {Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility 'auth' -TCPPort 456789789789} | Should Throw 'Error: "Value was either too large or too small for a UInt16.'
            }

            It 'Should accept an valid value for the TCP port' {
                {Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility 'auth' -TCPPort 445} | Should Not Throw
            }

            It 'Should Accept UDP as a Transport' {
                {Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility 'auth' -Transport 'UDP'} | Should Not Throw 'Cannot validate argument on parameter'
            }

            It 'Should Accept TCP as a Transport' {
                {Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility 'auth' -Transport 'TCP'} | Should Not Throw 'Cannot validate argument on parameter'
            }

            It 'Should Accept TCPwith TLS as a Transport' {
                {Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility 'auth' -Transport 'TCPwithTLS'} | Should Not Throw 'Cannot validate argument on parameter'
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

            It 'Should not accept null for SslProtocols' {
                {Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility 'auth' -Transport 'TCPwithTLS' -SslProtocols $null} | Should Throw
            }

            It 'Should not accept a empty string for SslProtocols' {
                {Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility 'auth' -Transport 'TCPwithTLS' -SslProtocols ''} | Should Throw
            }

            It 'Should not accept an invalid value for SslProtocols' {
                {Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility 'auth' -Transport 'TCPwithTLS' -SslProtocols 'bob'} | Should Throw
            }

            foreach ($value in [System.Security.Authentication.SslProtocols].GetEnumNames()){
                It "Should accept $value for SslProtocls" {
                    {Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility 'auth' -Transport 'TCPwithTLS' -SslProtocols $value} | Should Not Throw
                }
            }

        }

        Context 'Send-SyslogMessage = Pipeline input' {
            Mock -CommandName Send-UDPMessage -ModuleName Posh-SYSLOG { $Global:TestResult = $Datagram; return $null }

            It 'Should accept valid input from the pipeline for RFC5424' {
                $PipelineInput = [PSCustomObject]@{
                    Message         = 'Test Syslog Message'
                    Severity        = 'Emergency'
                    Facility        = 'Kern'
                    ApplicationName = 'RandomAppName'
                    ProcessID       = 12345678
                    MessageID       = 'messageid'
                    StructuredData  = 'structuredata'
                    Timestamp       = $ExpectedTimeStamp
                }
                $ExpectedResult = '<0>1 {0} TestHostname RandomAppName 12345678 messageid structuredata Test Syslog Message' -f $ExpectedTimeStamp
                $null =  $PipelineInput | Send-SyslogMessage -Server 'localhost'
                $Encoding.GetString($Global:TestResult) | should be $ExpectedResult
            }

            It 'Should accept valid input from the pipeline for RFC3164' {
                $PipelineInput = [PSCustomObject]@{
                    Message         = 'Test Syslog Message'
                    Severity        = 'Emergency'
                    Facility        = 'Kern'
                    ApplicationName = 'RandomAppName'
                    Timestamp       = $ExpectedTimeStamp
                    RFC3164         = $true
                }
                $ExpectedResult = '<0>Jan  1 00:00:00 TestHostname RandomAppName Test Syslog Message'
                $null =  $PipelineInput | Send-SyslogMessage -Server 'localhost' -RFC3164
                $Encoding.GetString($Global:TestResult) | should be $ExpectedResult
            }
        }

        Context 'Send-SyslogMessage = Severity Level Calculations' {
            Mock -CommandName Send-UDPMessage -ModuleName Posh-SYSLOG { $Global:TestResult = $Datagram; return $null }

            It 'Calculates the correct priority of 0 if Facility is Kern and Severity is Emergency' {
                $ExpectedResult = '<0>1 {0} TestHostname Send-SyslogMessage.Tests.ps1 {1} - - Test Syslog Message' -f $ExpectedTimeStamp, $PID
                $null =  Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Emergency' -Facility 'kern'
                $Encoding.GetString($Global:TestResult) | should be $ExpectedResult
            }

            It 'Calculates the correct priority of 7 if Facility is Kern and Severity is Debug' {
                $ExpectedResult = '<7>1 {0} TestHostname Send-SyslogMessage.Tests.ps1 {1} - - Test Syslog Message' -f $ExpectedTimeStamp, $PID
                $null = Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Debug' -Facility 'kern'
                $Encoding.GetString($Global:TestResult) | should be $ExpectedResult
            }

            It 'Calculates the correct priority of 24 if Facility is daemon and Severity is Emergency' {
                $ExpectedResult = '<24>1 {0} TestHostname Send-SyslogMessage.Tests.ps1 {1} - - Test Syslog Message' -f $ExpectedTimeStamp, $PID
                $null = Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Emergency' -Facility 'daemon'
                $Encoding.GetString($Global:TestResult) | should be $ExpectedResult
            }

            It 'Calculates the correct priority of 31 if Facility is daemon and Severity is Debug' {
                $ExpectedResult = '<31>1 {0} TestHostname Send-SyslogMessage.Tests.ps1 {1} - - Test Syslog Message' -f $ExpectedTimeStamp, $PID
                $null = Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Debug' -Facility 'daemon'
                $Encoding.GetString($Global:TestResult) | should be $ExpectedResult
            }
        }

        Context 'Send-SyslogMessage = RFC 3164 Message Format' {
            Mock -CommandName Send-UDPMessage -ModuleName Posh-SYSLOG { $Global:TestResult = $Datagram; return $null }

            It 'Should send RFC5424 formatted message with correct date format (10 to 31)' {
                Mock -ModuleName Posh-SYSLOG Get-Date { return (New-Object datetime(2000,1,10)) }

                $ExpectedResult = '<33>Jan 10 00:00:00 TestHostname Send-SyslogMessage.Tests.ps1 Test Syslog Message'
                $null = Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility 'auth' -RFC3164
                $Encoding.GetString($Global:TestResult) | should be $ExpectedResult
            }

            It 'Should send RFC5424 formatted message with correct date format (1 to 9)' {
                Mock -ModuleName Posh-SYSLOG Get-Date { return (New-Object datetime(2000,1,1)) }

                $ExpectedResult = '<33>Jan  1 00:00:00 TestHostname Send-SyslogMessage.Tests.ps1 Test Syslog Message'
                $null = Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility 'auth' -RFC3164
                $Encoding.GetString($Global:TestResult) | should be $ExpectedResult
            }
        }

        Context 'Send-SyslogMessage = RFC 5424 message format' {
            Mock -CommandName Send-UDPMessage -ModuleName Posh-SYSLOG { $Global:TestResult = $Datagram; return $null }

            It 'Should send RFC5424 formatted message' {
                $ExpectedResult = '<33>1 {0} TestHostname Send-SyslogMessage.Tests.ps1 {1} - - Test Syslog Message' -f $ExpectedTimeStamp, $PID
                $null = Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility 'auth'
                $Encoding.GetString($Global:TestResult) | should be $ExpectedResult
            }
        }

        Context 'Send-SyslogMessage = Message Length UDP' {
            Mock -CommandName Send-UDPMessage -ModuleName Posh-SYSLOG { $Global:TestResult = $Datagram; return $null }

            $LongMsg = 'This is a very long syslog message. 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890'

            It 'truncates RFC 5424 messages to 2k' {
                $ExpectedResult = ('<33>1 {0} TestHostname Send-SyslogMessage.Tests.ps1 {1} - - {2}' -f $ExpectedTimeStamp, $PID, $LongMsg).Substring(0,2048)
                $null = Send-SyslogMessage -Server '127.0.0.1' -Message $LongMsg -Severity 'Alert' -Facility 'auth'
                $Encoding.GetString($Global:TestResult) | should be $ExpectedResult
            }
            It 'truncates RFC 3164 messages to 1k' {
                $ExpectedResult = ('<33>Jan  1 00:00:00 TestHostname Send-SyslogMessage.Tests.ps1 {1}' -f $ExpectedTimeStamp, $LongMsg).Substring(0,1024)
                $null = Send-SyslogMessage -Server '127.0.0.1' -Message $LongMsg -Severity 'Alert' -Facility 'auth' -RFC3164
                $Encoding.GetString($Global:TestResult) | should be $ExpectedResult
            }
        }

        Context 'Send-SyslogMessage = Message Length TCP' {

            $LongMsg = 'This is a very long syslog message. 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890'

            It 'truncates RFC 5424 messages to 2k' {
                $ExpectedResult = ('<33>1 {0} TestHostname Send-SyslogMessage.Tests.ps1 {1} - - {2}' -f $ExpectedTimeStamp, $PID, $LongMsg).Substring(0,2048)
                $FramedResult = '2048 {0}' -f $ExpectedResult

                $null = Send-SyslogMessage -Server '127.0.0.1' -Message $LongMsg -Severity 'Alert' -Facility 'auth' -Transport TCP
                $Encoding.GetString($Global:TestResult) | should be $FramedResult
            }
            It 'truncates RFC 3164 messages to 1k' {
                $ExpectedResult = ('<33>Jan  1 00:00:00 TestHostname Send-SyslogMessage.Tests.ps1 {1}' -f $ExpectedTimeStamp, $LongMsg).Substring(0,1024)
                $FramedResult = '1024 {0}' -f $ExpectedResult

                $null = Send-SyslogMessage -Server '127.0.0.1' -Message $LongMsg -Severity 'Alert' -Facility 'auth' -RFC3164 -Transport TCP
                $Encoding.GetString($Global:TestResult) | should be $FramedResult
            }
        }

        Context 'Send-SyslogMessage = TCP Specific Tests' {
            #Mock -CommandName Send-TCPMessage -ModuleName Posh-SYSLOG { $Global:TestResult = $Datagram; return $null }

            It 'sends using TCP transport' {
                $ExpectedResult = '<33>1 {0} TestHostname Send-SyslogMessage.Tests.ps1 {1} - - Test Syslog Message' -f $ExpectedTimeStamp, $PID
                $FramedResult = '{0} {1}' -f $ExpectedResult.Length, $ExpectedResult

                $null = Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility 'auth' -Hostname TestHostname -Transport TCP
                $Encoding.GetString($Global:TestResult) | should be $FramedResult
            }

            It 'sends using TCP transport with Octet-Counting as the framing' {
                $ExpectedResult = '<33>1 {0} TestHostname Send-SyslogMessage.Tests.ps1 {1} - - Test Syslog Message' -f $ExpectedTimeStamp, $PID
                $FramedResult = '{0} {1}' -f $ExpectedResult.Length, $ExpectedResult

                $null = Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility 'auth' -Hostname TestHostname -Transport TCP -FramingMethod Octet-Counting
                $Encoding.GetString($Global:TestResult) | should be $FramedResult
            }
            It 'sends using TCP transport with Non-Transparent-Framing as the framing' {
                $ExpectedResult = '<33>1 {0} TestHostname Send-SyslogMessage.Tests.ps1 {1} - - Test Syslog Message{2}' -f $ExpectedTimeStamp, $PID, "`n"
                $null = Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility 'auth' -Hostname TestHostname -Transport TCP -FramingMethod Non-Transparent-Framing
                $Encoding.GetString($Global:TestResult) | should be $ExpectedResult
            }

            It 'sends using TCP transport with no framing' {
                $ExpectedResult = '<33>1 {0} TestHostname Send-SyslogMessage.Tests.ps1 {1} - - Test Syslog Message' -f $ExpectedTimeStamp, $PID
                $null = Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility 'auth' -Hostname TestHostname -Transport TCP -FramingMethod None
                $Encoding.GetString($Global:TestResult) | should be $ExpectedResult
            }

        }

        Context 'Send-SyslogMessage = Application Name Selection' {
            #Mock -CommandName Send-UDPMessage -ModuleName Posh-SYSLOG { $Global:TestResult = $Datagram; return $null }

            It 'Takes an Application Name as specified' {
                $ExpectedResult = '<33>1 {0} TestHostname SomeRandomName {1} - - Test Syslog Message' -f $ExpectedTimeStamp, $PID
                $null = Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility 'auth' -ApplicationName 'SomeRandomName'
                $Encoding.GetString($Global:TestResult) | should be $ExpectedResult
            }

            It 'uses myInvocation.ScriptName if one is available' {
                $ExpectedResult = '<33>1 {0} TestHostname Send-SyslogMessage.Tests.ps1 {1} - - Test Syslog Message' -f $ExpectedTimeStamp, $PID
                $null = Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility 'auth'
                $Encoding.GetString($Global:TestResult) | should be $ExpectedResult
            }
        }

        Context 'Send-SyslogMessage = Generic Tests' {
            #Mock -CommandName Send-UDPMessage -ModuleName Posh-SYSLOG { $Global:TestResult = $Datagram; return $null }

            It 'does not return any values' {
                $TestCase = Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility 'auth'
                $TestCase | Should be $null
            }
        }
    }

}
