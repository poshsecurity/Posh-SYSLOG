#requires -Version 2 -Modules NetTCPIP
enum Syslog_Facility
{
    kern
    user
    mail
    daemon
    auth
    syslog
    lpr
    news
    uucp
    clock
    authpriv
    ftp
    ntp
    logaudit
    logalert
    cron
    local0
    local1
    local2
    local3
    local4
    local5
    local6
    local7
}

enum Syslog_Severity
{
    Emergency
    Alert
    Critical
    Error
    Warning
    Notice
    Informational
    Debug
}

Function Get-SyslogHostname
{
    <#
        .SYNOPSIS
        Describe purpose of "Get-SyslogHostname" in 1-2 sentences.

        .DESCRIPTION
        Add a more complete description of what the function does.

        .PARAMETER Socket
        Describe parameter -Socket.

        .EXAMPLE
        Get-SyslogHostname -Socket Value
        Describe what this call does

        .NOTES
        Place additional notes here.

        .LINK
        URLs to related sites
        The first link is opened by Get-Help -Online Get-SyslogHostname

        .INPUTS
        List of input types that are accepted by this function.

        .OUTPUTS
        List of output types produced by this function.
    #>

    Param
    (
        # Socket of the Client
        [Parameter(Mandatory = $true,HelpMessage='Add help message for user')]
        [Net.Sockets.Socket]
        $Socket
    )

    <#
            According to RFC 5424 (section 6.2.4), we need to send our HOSTNAME field as one of these 5 (in order of priority)
            1.  FQDN
            2.  Static IP address
            3.  Hostname - Windows always has one of these, so this is our last resort
            4.  Dynamic IP address - We will never get to this one
            5.  the NILVALUE - or this one

            Windows should always, in the worst case, have a result at 3, the hostname or computer name from which this command is run.
    #>        
    
    # Get the Win32_ComputerSystem object
    $Win32_ComputerSystem = Get-WmiObject -Class win32_computersystem

    if ($Win32_ComputerSystem.partofdomain) # If domain joined
    {
        # Use HOSTNAME Option 1 (FQDN), per RFC 5424 (section 6.2.4)
        $Hostname = '{0}.{1}' -f $Win32_ComputerSystem.DNSHostname, $Win32_ComputerSystem.Domain
        
        Write-Verbose -Message ('The machine is joined to an Active Directory domain, hostname value will be FQDN: {0}' -f $Hostname)
    }
    else
    {
        # Ask the appropriate client what the local endpoint address is
        $LocalEndPoint = $Socket.LocalEndpoint.Address.IPAddressToString

        # Get the adapter that the endpoint is assigned to
        $NetworkAdapter = Get-NetIPAddress -IPAddress $LocalEndPoint

        # Is that local endpoint a statically assigned ip address?
        if ($NetworkAdapter.PrefixOrigin -eq 'Manual')
        {
            # Use HOSTNAME Option 2 (Static IP address), per RFC 5424 (section 6.2.4)
            $Hostname = $LocalEndPoint

            Write-Verbose -Message ('A statically assigned IP was detected as the source for the route to {0}, so the static IP ({1}) will be used as the HOSTNAME value.' -f $Socket.RemoteEndPoint.Address.IPAddressToString, $Hostname)
        }
        else
        {
            # Use HOSTNAME Option 3 (hostname), per RFC 5424 (section 6.2.4)
            $Hostname = $Env:COMPUTERNAME

            Write-Verbose -Message ('The hostname ({0}) will be used as the HOSTNAME value.' -f $Hostname)
        }
    }

    Write-Debug -Message ('Get-SyslogHostname is returning value {0}' -f $Hostname)

    $Hostname
}

Function Connect-UDPClient
{
    <#
        .SYNOPSIS
        Describe purpose of "Connect-UDPClient" in 1-2 sentences.

        .DESCRIPTION
        Add a more complete description of what the function does.

        .PARAMETER Server
        Describe parameter -Server.

        .PARAMETER Port
        Describe parameter -Port.

        .EXAMPLE
        Connect-UDPClient -Server Value -Port Value
        Describe what this call does

        .NOTES
        Place additional notes here.

        .LINK
        URLs to related sites
        The first link is opened by Get-Help -Online Connect-UDPClient

        .INPUTS
        List of input types that are accepted by this function.

        .OUTPUTS
        List of output types produced by this function.
    #>

    param
    (
        # Parameter help description
        [Parameter(Mandatory = $true,HelpMessage='Add help message for user')]
        [ValidateNotNullOrEmpty()]
        [String]
        $Server,

        # Parameter help description
        [Parameter(Mandatory = $true,HelpMessage='Add help message for user')]
        [ValidateNotNullOrEmpty()]
        [ValidateRange(1, 65535)]
        [UInt16]
        $Port
    )

    # Create a UDP client Object
    Try 
    {
        $UDPCLient = New-Object -TypeName System.Net.Sockets.UdpClient
        $UDPCLient.Connect($Server, $Port)
    }
    Catch 
    {
        Throw $_
    }

    $UDPCLient
}

Function Connect-TCPClient
{
    <#
        .SYNOPSIS
        Describe purpose of "Connect-TCPClient" in 1-2 sentences.

        .DESCRIPTION
        Add a more complete description of what the function does.

        .PARAMETER Server
        Describe parameter -Server.

        .PARAMETER Port
        Describe parameter -Port.

        .EXAMPLE
        Connect-TCPClient -Server Value -Port Value
        Describe what this call does

        .NOTES
        Place additional notes here.

        .LINK
        URLs to related sites
        The first link is opened by Get-Help -Online Connect-TCPClient

        .INPUTS
        List of input types that are accepted by this function.

        .OUTPUTS
        List of output types produced by this function.
    #>

    param
    (
        # Parameter help description
        [Parameter(Mandatory = $true,HelpMessage='Add help message for user')]
        [ValidateNotNullOrEmpty()]
        [String]
        $Server,

        # Parameter help description
        [Parameter(Mandatory = $true,HelpMessage='Add help message for user')]
        [ValidateNotNullOrEmpty()]
        [ValidateRange(1, 65535)]
        [UInt16]
        $Port
    )

    # Create a TCP client Object
    Try 
    {
        $TcpClient = New-Object -TypeName System.Net.Sockets.TcpClient
        $TcpClient.Connect($Server, $Port)
    }
    Catch 
    {
        Throw $_
    }

    $TcpClient
}

Function Get-TCPWriter
{
    <#
        .SYNOPSIS
        Describe purpose of "Get-TCPWriter" in 1-2 sentences.

        .DESCRIPTION
        Add a more complete description of what the function does.

        .PARAMETER TcpClient
        Describe parameter -TcpClient.

        .EXAMPLE
        Get-TCPWriter -TcpClient Value
        Describe what this call does

        .NOTES
        Place additional notes here.

        .LINK
        URLs to related sites
        The first link is opened by Get-Help -Online Get-TCPWriter

        .INPUTS
        List of input types that are accepted by this function.

        .OUTPUTS
        List of output types produced by this function.
    #>

    param
    (
        # Parameter help description
        [Parameter(Mandatory = $true,HelpMessage='Add help message for user')]
        [ValidateNotNullOrEmpty()]
        [Net.Sockets.TcpClient]
        $TcpClient
    )

    # Create TCP client, stream, and writer
    Try 
    {
        $TcpStream = $TcpClient.GetStream()
        $TcpWriter = New-Object -TypeName System.IO.StreamWriter -ArgumentList $TcpStream
    }
    Catch 
    {
        Throw $_
    }
    $TcpWriter
}

Function Send-UDPMessage
{
    <#
        .SYNOPSIS
        Describe purpose of "Disconnect-UDPClient" in 1-2 sentences.

        .DESCRIPTION
        Add a more complete description of what the function does.

        .EXAMPLE
        Disconnect-UDPClient
        Describe what this call does

        .NOTES
        Place additional notes here.

        .LINK
        URLs to related sites
        The first link is opened by Get-Help -Online Disconnect-UDPClient

        .INPUTS
        List of input types that are accepted by this function.

        .OUTPUTS
        List of output types produced by this function.
    #>
    
    param
    (
        # Parameter help description
        [Parameter(Mandatory = $true,HelpMessage='Add help message for user')]
        [ValidateNotNullOrEmpty()]
        [Net.Sockets.UdpClient]
        $UdpClient,

        # Parameter help description
        [Parameter(Mandatory = $true)]
        [byte[]]
        $Datagram
    )
    
    $null = $UdpClient.Send($Datagram, $Datagram.Length)
}

Function Send-TCPMessage
{
    <#
        .SYNOPSIS
        Describe purpose of "Disconnect-UDPClient" in 1-2 sentences.

        .DESCRIPTION
        Add a more complete description of what the function does.

        .EXAMPLE
        Disconnect-UDPClient
        Describe what this call does

        .NOTES
        Place additional notes here.

        .LINK
        URLs to related sites
        The first link is opened by Get-Help -Online Disconnect-UDPClient

        .INPUTS
        List of input types that are accepted by this function.

        .OUTPUTS
        List of output types produced by this function.
    #>

}

Function Disconnect-UDPClient
{
    <#
        .SYNOPSIS
        Describe purpose of "Disconnect-UDPClient" in 1-2 sentences.

        .DESCRIPTION
        Add a more complete description of what the function does.

        .EXAMPLE
        Disconnect-UDPClient
        Describe what this call does

        .NOTES
        Place additional notes here.

        .LINK
        URLs to related sites
        The first link is opened by Get-Help -Online Disconnect-UDPClient

        .INPUTS
        List of input types that are accepted by this function.

        .OUTPUTS
        List of output types produced by this function.
    #>

}

Function Disconnect-TCPWriter
{
    <#
        .SYNOPSIS
        Describe purpose of "Disconnect-TCPWriter" in 1-2 sentences.

        .DESCRIPTION
        Add a more complete description of what the function does.

        .EXAMPLE
        Disconnect-TCPWriter
        Describe what this call does

        .NOTES
        Place additional notes here.

        .LINK
        URLs to related sites
        The first link is opened by Get-Help -Online Disconnect-TCPWriter

        .INPUTS
        List of input types that are accepted by this function.

        .OUTPUTS
        List of output types produced by this function.
    #>

}

Function Disconnect-TCPClient
{
    <#
        .SYNOPSIS
        Describe purpose of "Disconnect-TCPWriter" in 1-2 sentences.

        .DESCRIPTION
        Add a more complete description of what the function does.

        .EXAMPLE
        Disconnect-TCPWriter
        Describe what this call does

        .NOTES
        Place additional notes here.

        .LINK
        URLs to related sites
        The first link is opened by Get-Help -Online Disconnect-TCPWriter

        .INPUTS
        List of input types that are accepted by this function.

        .OUTPUTS
        List of output types produced by this function.
    #>

}

Function Send-SyslogMessage
{
    <#
            .SYNOPSIS
            Sends a SYSLOG message to a server running the SYSLOG daemon

            .DESCRIPTION
            Sends a message to a SYSLOG server as defined in RFC 5424 and RFC 3164. 

            .INPUTS
            TODO: Need to update this

            .OUTPUTS
            Nothing is output

            .EXAMPLE
            Send-SyslogMessage mySyslogserver "The server is down!" Emergency Mail
            Sends a syslog message to mysyslogserver, saying "server is down", severity emergency and facility is mail

            .EXAMPLE
            TODO: We need additional examples here

            .NOTES
            NAME: Send-SyslogMessage
            AUTHOR: Kieran Jacobsen    (kjacobsen)
                    Jared Poeppelman   (powershellshock)
                    Ronald Rink        (dfch)
                    Xtrahost
                    Fredruk Furtenbach (flic)

            .LINK
            https://github.com/poshsecurity/Posh-Syslog

            .LINK
            https://poshsecurity.com

    #>
    [CMDLetBinding(DefaultParameterSetName = 'RFC5424')]
    Param
    (
        #Destination SYSLOG server that message is to be sent to.
        [Parameter( Mandatory = $true,
                    ValueFromPipeline = $false,
                    HelpMessage = 'Server to send message to')]
        [ValidateNotNullOrEmpty()]
        [String] 
        $Server,
	
        #Our message or content that we want to send to the server. This is option in RFC 5424, the CMDLet still has this as a madatory parameter, to send no message, simply specifiy '-' (as per RFC).
        [Parameter( Mandatory = $true,
                    ValueFromPipeline = $true,
                    HelpMessage = 'Message to send')]
        [ValidateNotNullOrEmpty()]
        [String]
        $Message,
	
        #Severity level as defined in SYSLOG specification, must be of ENUM type Syslog_Severity
        [Parameter( Mandatory = $true,
                    ValueFromPipeline = $true,
                    HelpMessage = 'Messsage severity level')]
        [ValidateNotNullOrEmpty()]
        [Syslog_Severity]
        $Severity,
	
        #Facility of message as defined in SYSLOG specification, must be of ENUM type Syslog_Facility
        [Parameter( Mandatory = $true,
                    ValueFromPipeline = $true,
                    HelpMessage = 'Facility sending message')]
        [ValidateNotNullOrEmpty()]
        [Syslog_Facility] 
        $Facility,
	
        #Hostname of machine the message is about, if not specified, RFC 5425 selection rules will be followed.
        [Parameter( Mandatory = $false,
                    ValueFromPipeline = $false)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Hostname,
	
        #Specify the name of the application or script that is sending the mesage. If not specified, will select the ScriptName, or if empty, powershell.exe will be sent. To send Null, specify '-' to meet RFC 5424. 
        [Parameter( Mandatory = $false,
                    ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $ApplicationName,
	
        #ProcessID or PID of generator of message. Will automatically use $PID global variable. If you want to override this and send null, specify '-' to meet RFC 5424 rquirements. This is only sent for RFC 5424 messages.
        [Parameter( Mandatory = $false,
                    ValueFromPipeline = $true,
                    ParameterSetName = 'RFC5424')]
        [ValidateNotNullOrEmpty()]
        [String]
        $ProcessID = $PID,
	
        #Error message or troubleshooting number associated with the message being sent. If you want to override this and send null, specify '-' to meet RFC 5424 rquirements. This is only sent for RFC 5424 messages.
        [Parameter( Mandatory = $false,
                    ValueFromPipeline = $true,
                    ParameterSetName = 'RFC5424')]
        [ValidateNotNullOrEmpty()]
        [String]
        $MessageID = '-',
	
        #Key Pairs of structured data as a string as defined in RFC5424. Default will be '-' which means null. This is only sent for RFC 5424 messages.
        [Parameter( Mandatory = $false,
                    ValueFromPipeline = $true,
                    ParameterSetName = 'RFC5424')]
        [ValidateNotNullOrEmpty()]
        [String]
        $StructuredData = '-',
	
        #Time and date of the message, must be of type DateTime. Correct format will be selected depending on RFC requested. If not specified, will call get-date to get appropriate date time.
        [Parameter( Mandatory = $false,
                    ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [DateTime] 
        $Timestamp = (Get-Date),
	
        #SYSLOG UDP (or TCP) port to which to send the message. Defaults to 514, if not specified.
        [Parameter( Mandatory = $false,
                    ValueFromPipeline = $false)]
        [ValidateNotNullOrEmpty()]
        [ValidateRange(1, 65535)]
        [Alias('UDPPort','TCPPort')]
        [UInt16]
        $Port = 514,

        # Transport protocol (TCP or UDP) over which the message will be sent. Default is UDP.
        [Parameter( Mandatory = $false,
                    ValueFromPipeline = $false)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('UDP','TCP')]
        [String]
        $Transport = 'UDP',

        # Framing method used for the message, default is 'Octet-Counting' (see RFC6587 section 3.4). This only applies when TCP is used for transport (no effect on UDP messages).
        [Parameter( Mandatory = $false,
                    ValueFromPipeline = $false)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('Octet-Counting','Non-Transparent-Framing','None')]
        [String]
        $FramingMethod = 'Octet-Counting',
	
        #Send an RFC3164 fomatted message instead of RFC5424.
        [Parameter( Mandatory = $false,
                    ValueFromPipeline = $true,
                    ParameterSetName = 'RFC3164')]
        [switch]
        $RFC3164
    )
    
    Begin 
    {
        Write-Debug -Message 'Starting the BEGIN block...'

        # Create an ASCII Encoding object
        $Encoding = [Text.Encoding]::ASCII

        # Initiate the required network objects
        Switch ($Transport)
        {        
            'UDP' 
            {
                $NetworkClient = Connect-UDPClient -Server $Server -Port $Port
            }

            'TCP'
            {
                $NetworkClient = Connect-TCPClient -Server $Server -Port $Port
                $TcpWriter = Get-TCPWriter -TcpClient $NetworkClient
            }
        }
        
        # If the hostname parameter is not specified, then we need to determine the correct value to be sent.
        if (-not $PSBoundParameters.ContainsKey('Hostname'))
        {
            Write-Verbose -Message 'Detecting correct HOSTNAME value (value not provided)...'
            $Hostname = Get-SyslogHostname -Socket $NetworkClient.Client
        }

        # Get the calling script name, if there is one
        if (($null -ne $myInvocation.ScriptName) -and ($myInvocation.ScriptName -ne ''))
        {
            $Caller = Split-Path -Leaf -Path $myInvocation.ScriptName
        }
        else
        {
            $Caller = 'PowerShell'
        }
        
        Write-Debug -Message 'Finished the BEGIN block'     
    }
    
    Process 
    {
        Write-Debug -Message 'Starting the PROCESS block...'

        # Evaluate the facility and severity based on the enum types
        $Facility_Number = $Facility.value__
        $Severity_Number = $Severity.value__
        Write-Verbose -Message ('Syslog Facility value is {0}, Severity value is {1}' -f $Facility_Number, $Severity_Number)

        # Calculate the PRI
        $Priority = ($Facility_Number * 8) + $Severity_Number
        Write-Verbose -Message ('Priority (PRI) is {0}' -f $Priority)

        # Set the APP-NAME
        if (-not $PSBoundParameters.ContainsKey('ApplicationName'))
        {
            Write-Verbose -Message ('No APP-NAME value was provided by caller, using previously detected value: {0}'-f $ApplicationName)
            $ApplicationName = $Caller
        }

        Switch ($PSCmdlet.ParameterSetName)
        {
            'RFC3164' 
            {
                Write-Verbose -Message 'Using RFC 3164 message format. Maxmimum length of 1024 bytes (section 4.1)'

                #Get the timestamp
                $FormattedTimestamp = (Get-Culture).TextInfo.ToTitleCase($Timestamp.ToString('MMM dd HH:mm:ss'))
                
                # Assemble the full syslog formatted Message
                $FullSyslogMessage = '<{0}>{1} {2} {3} {4}' -f $Priority, $FormattedTimestamp, $Hostname, $ApplicationName, $Message
                
                # Set the max message length per RFC 3164 section 4.1            
                $MaxLength = 1024
            }

            'RFC5424'
            {
                Write-Verbose -Message 'Using RFC 5424 message format. Maxmimum length of 2048 bytes.'
            
                #Get the timestamp
                $FormattedTimestamp = $Timestamp.ToString('yyyy-MM-ddTHH:mm:ss.ffffffzzz')
                
                # Assemble the full syslog formatted Message
                $FullSyslogMessage = '<{0}>1 {1} {2} {3} {4} {5} {6} {7}' -f $Priority, $FormattedTimestamp, $Hostname, $ApplicationName, $ProcessID, $MessageID, $StructuredData, $Message
                
                # Set the max message length per RFC 5424 section 6.1
                $MaxLength = 2048
            }
        }
        
        Write-Verbose -Message ('Message being attempted is: {0}' -f $FullSyslogMessage)
        
        # Ensure that the message is not too long. We could just compare the strings length, however using the encoding is the more appropriate way of confirming the length in bytes.
        if ($Encoding.GetByteCount($FullSyslogMessage) -gt $MaxLength)
        {
            $FullSyslogMessage = $FullSyslogMessage.Substring(0,$MaxLength)
            Write-Verbose -Message ('Message was too long and was shortened to {0} characters' -f $MaxLength)
            Write-Verbose -Message ('Shortened message is: {0}' -f $FullSyslogMessage)
        }

        Switch ($Transport)
        {
            'UDP' 
            {
                # Convert into byte array representation
                $ByteSyslogMessage = $Encoding.GetBytes($FullSyslogMessage)
                Write-Verbose -Message ('Message raw bytes: {0}' -f $ByteSyslogMessage)
                Write-Verbose -Message ('Message raw bytes length: '+($ByteSyslogMessage.Count))

                # Send the Message
                Try 
                {
                    Send-UDPMessage -UdpClient $NetworkClient -Datagram $ByteSyslogMessage
                }
                Catch 
                {
                    #TODO: Cleanup connections
                    throw $_
                }
            }

            'TCP'
            {
                Write-Verbose -Message ('Framing method is: {0}' -f $FramingMethod)
                Switch ($FramingMethod) 
                {  
                    'Octet-Counting' 
                    { 
                        $OctetCount = ($Encoding.GetBytes($FullSyslogMessage)).Length
                        $FramedSyslogMessage = '{0} {1}' -f $OctetCount, $FullSyslogMessage
                        Write-Verbose -Message ('Framed message is: {0}' -f $FullSyslogMessage)
                    }
                    'Non-Transparent-Framing' 
                    {
                        $FramedSyslogMessage = '{0}{1}' -f $FullSyslogMessage, "`n"
                        Write-Verbose -Message ('Framed message is: {0}' -f $FullSyslogMessage)
                    }
                    'None' 
                    {
                        $FramedSyslogMessage = $FullSyslogMessage
                        Write-Verbose -Message "No change to the message for framing type 'none'"  
                    }
                }
                
                # Convert into byte array representation
                $ByteSyslogMessage = $Encoding.GetBytes($FramedSyslogMessage)
                Write-Verbose -Message ('Message raw bytes: {0}' -f $ByteSyslogMessage)
                Write-Verbose -Message ('Message raw bytes length: '+($ByteSyslogMessage.Count))

                # Send the Message
                Try 
                {
                    $null = $TcpWriter.Write($ByteSyslogMessage, 0, $ByteSyslogMessage.Length)
                }
                Catch 
                {
                    #TODO: Cleanup connections
                    throw $_
                }
            }
        }

        Write-Debug -Message 'Finished the PROCESS block' 
    }
    
    End 
    {
        Write-Debug -Message 'Starting the END block...'
        
        # Clean up our network objects
        #TODO: Move this to a separate internal function
        Switch ($Transport)
        {
            'UDP' 
            {
                If ($NetworkClient)
                {
                    Write-Verbose -Message 'Cleaning up the UDP client object'
                    $NetworkClient.Close()
                }
            }          
            'TCP'
            {
                $TcpStream = $TcpWriter.BaseStream
                
                If ($TcpWriter)
                {
                    Write-Verbose -Message 'Cleaning up the TCP writer object'
                    $TcpWriter.Close()
                }

                If ($TcpStream)
                {
                    Write-Verbose -Message 'Cleaning up the TCP stream object'
                    $TcpStream.Dispose()
                }

                If ($NetworkClient)
                {
                    Write-Verbose -Message 'Cleaning up the TCP client object'
                    $NetworkClient.Close()
                }
            }
        }
        Write-Debug -Message 'Finished the END block' 
    }
}
