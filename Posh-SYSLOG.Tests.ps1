#TODO: what about if we cannot connect to the TCP port? Need to test that!
#TODO: hostname resolution issues/errors need to be handled

Import-Module .\Posh-SYSLOG.psm1 -Force

Describe 'Send-SyslogMessage' {
    Mock -ModuleName Posh-SYSLOG Get-Date { return (New-Object datetime(2000,1,1)) }
    
    Mock -ModuleName Posh-SYSLOG Get-CimInstance { return @{partofdomain = $false; DNSHostname = 'TestHostname'} }

    $ExpectedTimeStamp = (New-Object datetime(2000,1,1)).ToString('yyyy-MM-ddTHH:mm:ss.ffffffzzz')

    # Create an ASCII Encoding object
    $Encoding = [Text.Encoding]::ASCII

    # Open TCP 514 so we can test TCP connections (without hitting the network)
    $TCPEndpoint = New-Object System.Net.IPEndPoint ([IPAddress]::Loopback,514)
    $TCPListener = New-Object System.Net.Sockets.TcpListener $TCPEndpoint
    $TCPListener.start()

    Context 'Get-SyslogHostname = UDP Client Tests' {
        $UDPCLient = New-Object -TypeName System.Net.Sockets.UdpClient
        $UDPCLient.Connect('127.0.0.1', '514')

        It 'Uses the FQDN if the computer is domain joined' {
            Mock -ModuleName Posh-SYSLOG Get-CimInstance { return @{partofdomain = $true; DNSHostname = 'TestHostname'; Domain = 'contoso.com'} }
            $TestResult = Get-SyslogHostname -Socket $UDPCLient.Client
            Mock -ModuleName Posh-SYSLOG Get-CimInstance { return @{partofdomain = $false; DNSHostname = 'TestHostname'} }
            $TestResult | Should Be 'TestHostname.contoso.com'
        }

        It 'Uses a Static IP address, on the correct interface that the server is reached on, if no FQDN and not hostname specified' {
            Mock -ModuleName Posh-SYSLOG Get-NetIPAddress {return @{PrefixOrigin = 'Manual'}}
            $TestResult = Get-SyslogHostname -Socket $UDPCLient.Client
            $TestResult | Should Be '127.0.0.1'
        }

        It 'Uses the Windows computer name, if no static ip or FQDN' {
            Mock -ModuleName Posh-SYSLOG Get-NetIPAddress {return $null} 
            $TestResult = Get-SyslogHostname -Socket $UDPCLient.Client
            $TestResult | Should Be 'TestHostname'
        }
    }

    Context 'Get-SyslogHostname = TCP Client Tests' {
        $TCPCLient = New-Object -TypeName System.Net.Sockets.TcpClient
        $TCPCLient.Connect('127.0.0.1', '514')

        It 'Uses the FQDN if the computer is domain joined' {
            Mock -ModuleName Posh-SYSLOG Get-CimInstance { return @{partofdomain = $true; DNSHostname = 'TestHostname'; Domain = 'contoso.com'} }
            $TestResult = Get-SyslogHostname -Socket $TCPCLient.Client
            Mock -ModuleName Posh-SYSLOG Get-CimInstance { return @{partofdomain = $false; DNSHostname = 'TestHostname'} }
            $TestResult | Should Be 'TestHostname.contoso.com'
        }

        It 'Uses a Static IP address, on the correct interface that the server is reached on, if no FQDN and not hostname specified' {
            Mock -ModuleName Posh-SYSLOG Get-NetIPAddress {return @{PrefixOrigin = 'Manual'}}
            $TestResult = Get-SyslogHostname -Socket $TCPCLient.Client
            $TestResult | Should Be '127.0.0.1'
        }

        It 'Uses the Windows computer name, if no static ip or FQDN' {
            Mock -ModuleName Posh-SYSLOG Get-NetIPAddress {return $null} 
            $TestResult = Get-SyslogHostname -Socket $TCPCLient.Client
            $TestResult | Should Be 'TestHostname'
        }
    }

    Context 'Connect-UDPClient = Tests' {
        It 'Should not accept a null value for the server' {
            {Connect-UDPClient -Server $null -Port 514} | Should Throw 'The argument is null or empty'
        }

        It 'Should not accept an empty string for the server' {
            {Connect-UDPClient -Server '' -Port 514} | Should Throw 'The argument is null or empty'
        }

        It 'Should accept an IP address for the server' {
            {Connect-UDPClient -Server '127.0.0.1' -Port 514} | Should not throw
        }

        It 'Should accept an hostname string for the server' {
            {Connect-UDPClient -Server 'localhost' -Port 514} | Should not throw
        }
        
        It 'Should not accept a null value for the port' {
            {Connect-UDPClient -Server '127.0.0.1' -Port $null} | Should Throw 'Cannot validate argument on parameter'
        }

        It 'Should not accept an invalid value for the port' {
            {Connect-UDPClient -Server '127.0.0.1' -Port 456789789789} | Should Throw 'Error: "Value was either too large or too small for a UInt16.'
        }

        It 'Should accept an valid value for the port' {
            {Connect-UDPClient -Server '127.0.0.1' -Port 514} | Should Not Throw
        }
        
        It 'creates a UDP client' {
            {Connect-UDPClient -Server '127.0.0.1' -Port 514} | should not be $null
        }
    }

    Context 'Connect-TCPClient = Tests' {
        It 'Should not accept a null value for the server' {
            {Connect-TCPClient -Server $null -Port 514} | Should Throw 'The argument is null or empty'
        }

        It 'Should not accept an empty string for the server' {
            {Connect-TCPClient -Server '' -Port 514} | Should Throw 'The argument is null or empty'
        }

        It 'Should accept an IP address for the server' {
            {Connect-UDPClient -Server '127.0.0.1' -Port 514} | Should not throw
        }

        It 'Should accept an hostname string for the server' {
            {Connect-UDPClient -Server 'localhost' -Port 514} | Should not throw
        }
        
        It 'Should not accept a null value for the port' {
            {Connect-TCPClient -Server '127.0.0.1' -Port $null} | Should Throw 'Cannot validate argument on parameter'
        }

        It 'Should not accept an invalid value for the port' {
            {Connect-TCPClient -Server '127.0.0.1' -Port 456789789789} | Should Throw 'Error: "Value was either too large or too small for a UInt16.'
        }

        It 'Should accept an valid value for the port' {
            {Connect-TCPClient -Server '127.0.0.1' -Port 514} | Should Not Throw
        }
        
        It 'creates a TCP client' {
            {Connect-TCPClient -Server '127.0.0.1' -Port 514} | should not be $null
        }
    }

    Context 'Get-TCPWriter = Tests' {
        $TCPClient = Connect-TCPClient -Server '127.0.0.1' -port 514

        It 'creates a TCPWriter' {
            {Get-TCPWriter -TcpClient $TCPClient} | should not be $null
        }
    }

    Context 'Disconnect-UDPClient = Tests' {
        $UDPClient = Connect-UDPClient -Server '127.0.0.1' -port 514
        
        It 'disconnects the UDP client' {
            Disconnect-UDPClient $UDPClient
            $UDPClient.Client | should be $null
        }
    }

    Context 'Disconnect-TCPWriter = Tests' {
        $TCPClient = Connect-TCPClient -Server '127.0.0.1' -port 514
        $TCPWriter = Get-TCPWriter -TcpClient $TCPClient

        It 'disconnects the TCP Writer' {
            Disconnect-TCPWriter -TcpWriter $TCPWriter
            $TCPWriter.BaseStream | should be $null
        }
    }

    Context 'Disconnect-TCPClient = Tests' {
        $TCPClient = Connect-TCPClient -Server '127.0.0.1' -port 514

        It 'disconnects the TCP client' {
            Disconnect-TCPClient $TCPClient
            $TCPClient.Client | should be $null
        }
    }

    Context 'Send-SyslogMessage = Parameter Validation' {
        Mock -ModuleName Posh-SYSLOG Send-UDPMessage { return $null }
        Mock -ModuleName Posh-SYSLOG Send-TCPMessage { return $null }

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
            $ExpectedResult = '<0>Jan 01 00:00:00 TestHostname RandomAppName Test Syslog Message'
            $null =  $PipelineInput | Send-SyslogMessage -Server 'localhost' -RFC3164
            $Encoding.GetString($Global:TestResult) | should be $ExpectedResult
        }
    }

    Context 'Send-SyslogMessage = Severity Level Calculations' {
        Mock -CommandName Send-UDPMessage -ModuleName Posh-SYSLOG { $Global:TestResult = $Datagram; return $null }

        It 'Calculates the correct priority of 0 if Facility is Kern and Severity is Emergency' {
            $ExpectedResult = '<0>1 {0} TestHostname Posh-SYSLOG.Tests.ps1 {1} - - Test Syslog Message' -f $ExpectedTimeStamp, $PID
            $null =  Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Emergency' -Facility 'kern'
            $Encoding.GetString($Global:TestResult) | should be $ExpectedResult
        }

        It 'Calculates the correct priority of 7 if Facility is Kern and Severity is Debug' {
            $ExpectedResult = '<7>1 {0} TestHostname Posh-SYSLOG.Tests.ps1 {1} - - Test Syslog Message' -f $ExpectedTimeStamp, $PID
            $null = Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Debug' -Facility 'kern'
            $Encoding.GetString($Global:TestResult) | should be $ExpectedResult
        }   

        It 'Calculates the correct priority of 24 if Facility is daemon and Severity is Emergency' {
            $ExpectedResult = '<24>1 {0} TestHostname Posh-SYSLOG.Tests.ps1 {1} - - Test Syslog Message' -f $ExpectedTimeStamp, $PID
            $null = Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Emergency' -Facility 'daemon'
            $Encoding.GetString($Global:TestResult) | should be $ExpectedResult
        }

        It 'Calculates the correct priority of 31 if Facility is daemon and Severity is Debug' {
            $ExpectedResult = '<31>1 {0} TestHostname Posh-SYSLOG.Tests.ps1 {1} - - Test Syslog Message' -f $ExpectedTimeStamp, $PID
            $null = Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Debug' -Facility 'daemon'
            $Encoding.GetString($Global:TestResult) | should be $ExpectedResult
        }
    }

    Context 'Send-SyslogMessage = RFC 3164 Message Format' {
        Mock -CommandName Send-UDPMessage -ModuleName Posh-SYSLOG { $Global:TestResult = $Datagram; return $null }

        It 'Should send RFC5424 formatted message' {
            $ExpectedResult = '<33>Jan 01 00:00:00 TestHostname Posh-SYSLOG.Tests.ps1 Test Syslog Message'
            $null = Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility 'auth' -RFC3164
            $Encoding.GetString($Global:TestResult) | should be $ExpectedResult
        }
    }

    Context 'Send-SyslogMessage = RFC 5424 message format' {
        Mock -CommandName Send-UDPMessage -ModuleName Posh-SYSLOG { $Global:TestResult = $Datagram; return $null }

        It 'Should send RFC5424 formatted message' {
            $ExpectedResult = '<33>1 {0} TestHostname Posh-SYSLOG.Tests.ps1 {1} - - Test Syslog Message' -f $ExpectedTimeStamp, $PID
            $null = Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility 'auth'
            $Encoding.GetString($Global:TestResult) | should be $ExpectedResult
        }
    }

    Context 'Send-SyslogMessage = Hostname determination' {
        Mock -CommandName Send-UDPMessage -ModuleName Posh-SYSLOG { $Global:TestResult = $Datagram; return $null }

        It 'Uses any hostname it is given' {
            $ExpectedResult = '<33>1 {0} SomeRandomHostName Posh-SYSLOG.Tests.ps1 {1} - - Test Syslog Message' -f $ExpectedTimeStamp, $PID
            $null = Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility 'auth' -Hostname 'SomeRandomHostName'
            $Encoding.GetString($Global:TestResult) | should be $ExpectedResult
        }

        It 'Uses the FQDN if the computer is domain joined' {
            Mock -ModuleName Posh-SYSLOG Get-CimInstance { return @{partofdomain = $true; DNSHostname = 'TestHostname'; Domain = 'contoso.com'} }

            $ExpectedResult = '<33>1 {0} TestHostname.contoso.com Posh-SYSLOG.Tests.ps1 {1} - - Test Syslog Message' -f $ExpectedTimeStamp, $PID
            $null = Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility 'auth'

            Mock -ModuleName Posh-SYSLOG Get-CimInstance { return @{partofdomain = $false; DNSHostname = 'TestHostname'} }

            $Encoding.GetString($Global:TestResult) | should be $ExpectedResult
        }

        It 'Uses a Static IP address, on the correct interface that the server is reached on, if no FQDN and not hostname specified' {
            Mock -ModuleName Posh-SYSLOG Get-NetIPAddress {return @{PrefixOrigin = 'Manual'}}

            $ExpectedResult = '<33>1 {0} 127.0.0.1 Posh-SYSLOG.Tests.ps1 {1} - - Test Syslog Message' -f $ExpectedTimeStamp, $PID
            $null = Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility 'auth'
            $Encoding.GetString($Global:TestResult) | should be $ExpectedResult
        }

        It 'Uses the Windows computer name, if no static ip or FQDN' {
            Mock -ModuleName Posh-SYSLOG Get-NetIPAddress {return $null}

            $ExpectedResult = '<33>1 {0} TestHostname Posh-SYSLOG.Tests.ps1 {1} - - Test Syslog Message' -f $ExpectedTimeStamp, $PID
            $null = Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility 'auth'
            $Encoding.GetString($Global:TestResult) | should be $ExpectedResult
        }
    }

    Context 'Send-SyslogMessage = Message Length UDP' {
        Mock -CommandName Send-UDPMessage -ModuleName Posh-SYSLOG { $Global:TestResult = $Datagram; return $null }

        $LongMsg = 'This is a very long syslog message. 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890'

        It 'truncates RFC 5424 messages to 2k' {
            $ExpectedResult = ('<33>1 {0} TestHostname Posh-SYSLOG.Tests.ps1 {1} - - {2}' -f $ExpectedTimeStamp, $PID, $LongMsg).Substring(0,2048)
            $null = Send-SyslogMessage -Server '127.0.0.1' -Message $LongMsg -Severity 'Alert' -Facility 'auth'
            $Encoding.GetString($Global:TestResult) | should be $ExpectedResult
        }
        It 'truncates RFC 3164 messages to 1k' {
            $ExpectedResult = ('<33>Jan 01 00:00:00 TestHostname Posh-SYSLOG.Tests.ps1 {1}' -f $ExpectedTimeStamp, $LongMsg).Substring(0,1024)
            $null = Send-SyslogMessage -Server '127.0.0.1' -Message $LongMsg -Severity 'Alert' -Facility 'auth' -RFC3164
            $Encoding.GetString($Global:TestResult) | should be $ExpectedResult
        }
    }

    Context 'Send-SyslogMessage = Message Length TCP' {
        Mock -CommandName Send-TCPMessage -ModuleName Posh-SYSLOG { $Global:TestResult = $Datagram; return $null }

        $LongMsg = 'This is a very long syslog message. 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890'

        It 'truncates RFC 5424 messages to 2k' {
            $ExpectedResult = ('<33>1 {0} TestHostname Posh-SYSLOG.Tests.ps1 {1} - - {2}' -f $ExpectedTimeStamp, $PID, $LongMsg).Substring(0,2048)
            $FramedResult = '2048 {0}' -f $ExpectedResult

            $null = Send-SyslogMessage -Server '127.0.0.1' -Message $LongMsg -Severity 'Alert' -Facility 'auth' -Transport TCP
            $Encoding.GetString($Global:TestResult) | should be $FramedResult
        }
        It 'truncates RFC 3164 messages to 1k' {
            $ExpectedResult = ('<33>Jan 01 00:00:00 TestHostname Posh-SYSLOG.Tests.ps1 {1}' -f $ExpectedTimeStamp, $LongMsg).Substring(0,1024)
            $FramedResult = '1024 {0}' -f $ExpectedResult

            $null = Send-SyslogMessage -Server '127.0.0.1' -Message $LongMsg -Severity 'Alert' -Facility 'auth' -RFC3164 -Transport TCP
            $Encoding.GetString($Global:TestResult) | should be $FramedResult
        }
    }

    Context 'Send-SyslogMessage = TCP Specific Tests' {
        Mock -CommandName Send-TCPMessage -ModuleName Posh-SYSLOG { $Global:TestResult = $Datagram; return $null }

        It 'sends using TCP transport' {
            $ExpectedResult = '<33>1 {0} TestHostname Posh-SYSLOG.Tests.ps1 {1} - - Test Syslog Message' -f $ExpectedTimeStamp, $PID
            $FramedResult = '{0} {1}' -f $ExpectedResult.Length, $ExpectedResult

            $null = Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility 'auth' -Hostname TestHostname -Transport TCP
            $Encoding.GetString($Global:TestResult) | should be $FramedResult
        }

        It 'sends using TCP transport with Octet-Counting as the framing' {
            $ExpectedResult = '<33>1 {0} TestHostname Posh-SYSLOG.Tests.ps1 {1} - - Test Syslog Message' -f $ExpectedTimeStamp, $PID
            $FramedResult = '{0} {1}' -f $ExpectedResult.Length, $ExpectedResult
            
            $null = Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility 'auth' -Hostname TestHostname -Transport TCP -FramingMethod Octet-Counting
            $Encoding.GetString($Global:TestResult) | should be $FramedResult
        }
        It 'sends using TCP transport with Non-Transparent-Framing as the framing' {
            $ExpectedResult = '<33>1 {0} TestHostname Posh-SYSLOG.Tests.ps1 {1} - - Test Syslog Message{2}' -f $ExpectedTimeStamp, $PID, "`n"
            $null = Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility 'auth' -Hostname TestHostname -Transport TCP -FramingMethod Non-Transparent-Framing
            $Encoding.GetString($Global:TestResult) | should be $ExpectedResult
        }

        It 'sends using TCP transport with no framing' {
            $ExpectedResult = '<33>1 {0} TestHostname Posh-SYSLOG.Tests.ps1 {1} - - Test Syslog Message' -f $ExpectedTimeStamp, $PID
            $null = Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility 'auth' -Hostname TestHostname -Transport TCP -FramingMethod None
            $Encoding.GetString($Global:TestResult) | should be $ExpectedResult
        }

    }

    Context 'Send-SyslogMessage = Application Name Selection' {
        Mock -CommandName Send-UDPMessage -ModuleName Posh-SYSLOG { $Global:TestResult = $Datagram; return $null }

        It 'Takes an Application Name as specified' {
            $ExpectedResult = '<33>1 {0} TestHostname SomeRandomName {1} - - Test Syslog Message' -f $ExpectedTimeStamp, $PID
            $null = Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility 'auth' -ApplicationName 'SomeRandomName'
            $Encoding.GetString($Global:TestResult) | should be $ExpectedResult
        }

        It 'uses myInvocation.ScriptName if one is available' {
            $ExpectedResult = '<33>1 {0} TestHostname Posh-SYSLOG.Tests.ps1 {1} - - Test Syslog Message' -f $ExpectedTimeStamp, $PID
            $null = Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility 'auth'
            $Encoding.GetString($Global:TestResult) | should be $ExpectedResult
        }
    }

    Context 'Send-SyslogMessage = Generic Tests' {
        Mock -CommandName Send-UDPMessage -ModuleName Posh-SYSLOG { $Global:TestResult = $Datagram; return $null }

        It 'does not return any values' {
            $TestCase = Send-SyslogMessage -Server '127.0.0.1' -Message 'Test Syslog Message' -Severity 'Alert' -Facility 'auth'
            $TestCase | Should be $null
        }
    }

    Context 'Script Analyzer' {
        It 'Does not have any issues with the Script Analyser' {
            Invoke-ScriptAnalyzer .\Functions\*.ps1 | Should be $null
        }
    }

    $TCPListener.stop()
}