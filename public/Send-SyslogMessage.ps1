Add-Type -TypeDefinition @"
public enum Syslog_Facility
{
    kern,
    user,
    mail,
    daemon,
    auth,
    syslog,
    lpr,
    news,
    uucp,
    clock,
    authpriv,
    ftp,
    ntp,
    logaudit,
    logalert,
    cron,
    local0,
    local1,
    local2,
    local3,
    local4,
    local5,
    local6,
    local7,
}
"@

Add-Type -TypeDefinition @"
public enum Syslog_Severity
{
    Emergency,
    Alert,
    Critical,
    Error,
    Warning,
    Notice,
    Informational,
    Debug
}
"@

Add-Type -TypeDefinition @"
public enum Syslog_Protocol
{
    UDP,
    TCP,
    TCPwithTLS
}
"@

Function Send-SyslogMessage
{
    <#
            .SYNOPSIS
            Sends a SYSLOG message to a server running the SYSLOG daemon

            .DESCRIPTION
            Sends a message to a SYSLOG server as defined in RFC 5424 and RFC 3164. It can use UDP, TCP or TCP with TLS/SSL.

            .OUTPUTS
            Nothing is output

            .EXAMPLE
            Send-SyslogMessage -Server mySyslogserver -Message 'The server is down!' -Severity Emergency -Facility Mail
            Sends a syslog message to mysyslogserver, saying "server is down", severity emergency and facility is mail

            .EXAMPLE
            Send-SyslogMessage -Server mySyslogserver -Message 'The server is up' -Severity Informational -Facility Mail -Transport TCP
            Sends a syslog message to mysyslogserver, using TCP, saying "server is up", severity informational and facility is mail

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
        [Parameter(Mandatory                        = $true,
                   ValueFromPipelineByPropertyName  = $false,
                   HelpMessage                      = 'Server to send message to')]
        [ValidateNotNullOrEmpty()]
        [String]
        $Server,

        #Our message or content that we want to send to the server. This is option in RFC 5424, the CMDLet still has this as a madatory parameter, to send no message, simply specifiy '-' (as per RFC).
        [Parameter(Mandatory                        = $true,
                   ValueFromPipelineByPropertyName  = $true,
                   HelpMessage                      = 'Message to send')]
        [ValidateNotNullOrEmpty()]
        [String]
        $Message,

        #Severity level as defined in SYSLOG specification, must be of ENUM type Syslog_Severity
        [Parameter(Mandatory                        = $true,
                   ValueFromPipelineByPropertyName  = $true,
                   HelpMessage                      = 'Messsage severity level')]
        [ValidateNotNullOrEmpty()]
        [Syslog_Severity]
        $Severity,

        #Facility of message as defined in SYSLOG specification, must be of ENUM type Syslog_Facility
        [Parameter(Mandatory                        = $true,
                   ValueFromPipelineByPropertyName  = $true,
                   HelpMessage                      = 'Facility sending message')]
        [ValidateNotNullOrEmpty()]
        [Syslog_Facility]
        $Facility,

        #Hostname of machine the message is about, if not specified, RFC 5425 selection rules will be followed.
        [Parameter(Mandatory                        = $false,
                   ValueFromPipelineByPropertyName  = $false)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Hostname,

        #Specify the name of the application or script that is sending the mesage. If not specified, will select the ScriptName, or if empty, powershell.exe will be sent. To send Null, specify '-' to meet RFC 5424.
        [Parameter(Mandatory                        = $false,
                   ValueFromPipelineByPropertyName  = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $ApplicationName,

        #Time and date of the message, must be of type DateTime. Correct format will be selected depending on RFC requested. If not specified, will call get-date to get appropriate date time.
        [Parameter(Mandatory                        = $false,
                   ValueFromPipelineByPropertyName  = $true)]
        [ValidateNotNullOrEmpty()]
        [DateTime]
        $Timestamp = (Get-Date),

        #SYSLOG UDP (or TCP) port to which to send the message. Defaults to 514, if not specified.
        [Parameter(Mandatory                        = $false,
                   ValueFromPipelineByPropertyName  = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidateRange(1, 65535)]
        [Alias('UDPPort','TCPPort')]
        [UInt16]
        $Port = 514,

        # Transport protocol (TCP or UDP or TCP with TLS) over which the message will be sent. Default is UDP.
        [Parameter(Mandatory                        = $false,
                   ValueFromPipelineByPropertyName  = $true)]
        [ValidateNotNullOrEmpty()]
        #[ValidateSet('UDP','TCP', 'TCPwithTLS')]
        #[String]
        [Syslog_Protocol]
        $Transport = 'UDP',

        #ProcessID or PID of generator of message. Will automatically use $PID global variable. If you want to override this and send null, specify '-' to meet RFC 5424 rquirements.
        [Parameter(Mandatory                        = $false,
                   ValueFromPipelineByPropertyName  = $true,
                   ParameterSetName                 = 'RFC5424')]
        [ValidateNotNullOrEmpty()]
        [String]
        $ProcessID = $PID,

        #Error message or troubleshooting number associated with the message being sent. If you want to override this and send null, specify '-' to meet RFC 5424 rquirements.
        [Parameter(Mandatory                        = $false,
                   ValueFromPipelineByPropertyName  = $true,
                   ParameterSetName                 = 'RFC5424')]
        [ValidateNotNullOrEmpty()]
        [String]
        $MessageID = '-',

        #Key Pairs of structured data as a string as defined in RFC5424. Default will be '-' which means null.
        [Parameter(Mandatory                        = $false,
                   ValueFromPipelineByPropertyName  = $true,
                   ParameterSetName                 = 'RFC5424')]
        [ValidateNotNullOrEmpty()]
        [String]
        $StructuredData = '-',

        # Framing method used for the message, default is 'Octet-Counting' (see RFC6587 section 3.4). This only applies when TCP is used for transport (no effect on UDP messages).
        [Parameter(Mandatory                        = $false,
                   ValueFromPipelineByPropertyName  = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('Octet-Counting','Non-Transparent-Framing','None')]
        [String]
        $FramingMethod = 'Octet-Counting',

        # SSL/TLS Protocols to be used when connecting to server. Default is TLS1.2.
        [Parameter(Mandatory                        = $false,
                   ValueFromPipelineByPropertyName  = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Security.Authentication.SslProtocols]
        $SslProtocols = [System.Security.Authentication.SslProtocols]::Tls12,

        # Do not validate the SSL/TLS certificate presented by the server.
        [Parameter(Mandatory                        = $false,
                   ValueFromPipelineByPropertyName  = $true)]
        [switch]
        $DoNotValidateTLSCertificate,

        #Send an RFC3164 fomatted message instead of RFC5424.
        [Parameter(Mandatory                        = $true,
                   ValueFromPipelineByPropertyName  = $true,
                   ParameterSetName                 = 'RFC3164')]
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
                Write-Verbose -Message 'Selected Transport is UDP'
                try
                {
                    $NetworkClient = Connect-UDPClient -Server $Server -Port $Port
                }
                catch
                {
                    throw $_
                }
            }

            'TCP'
            {
                Write-Verbose -Message 'Selected Transport is TCP'
                try
                {
                    $NetworkClient = Connect-TCPClient -Server $Server -Port $Port
                    $TcpWriter = Get-TCPWriter -TcpClient $NetworkClient
                }
                catch
                {
                    throw $_
                }
            }

            'TCPwithTLS'
            {
                Write-Verbose -Message 'Selected Transport is TCP with TLS'
                try
                {
                    $NetworkClient = Connect-TCPClient -Server $Server -Port $Port

                    $GetTCPWriterParams = @{
                        TcpClient                   = $NetworkClient
                        UseTLS                      = $true
                        ServerHostname              = $Server
                        SslProtocols                = $SslProtocols
                        DoNotValidateTLSCertificate = $DoNotValidateTLSCertificate
                    }

                    $TcpWriter = Get-TCPWriter @GetTCPWriterParams
                }
                catch
                {
                    throw $_
                }
            }
        }

        # If the hostname parameter is not specified, then we need to determine the correct value to be sent.
        if (-not $PSBoundParameters.ContainsKey('Hostname'))
        {
            Write-Verbose -Message 'No Hostname value provided, Detecting correct HOSTNAME value...'
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
        $Severity_Number =$Severity.value__
        Write-Verbose -Message ('Syslog Facility value is {0}, Severity value is {1}' -f $Facility_Number, $Severity_Number)

        # Calculate the PRI
        $Priority = ($Facility_Number * 8) + $Severity_Number
        Write-Verbose -Message ('Priority (PRI) is {0}' -f $Priority)

        # Set the APP-NAME
        if (-not $PSBoundParameters.ContainsKey('ApplicationName'))
        {
            $ApplicationName = $Caller
            Write-Verbose -Message ('No APP-NAME value was provided by caller, using previously detected value: {0}'-f $ApplicationName)
        }

        Switch ($PSCmdlet.ParameterSetName)
        {
            'RFC3164'
            {
                Write-Verbose -Message 'Using RFC 3164 message format. Maxmimum length of 1024 bytes (section 4.1)'

                #Get the timestamp
                <#
                    The TIMESTAMP field is the local time and is in the format of "Mmm dd hh:mm:ss" (without the quote marks) where:
                    ...
                    dd is the day of the month. If the day of the month is less
                    than 10, then it MUST be represented as a space and then the
                    number. For example, the 7th day of August would be
                    represented as "Aug  7", with two spaces between the "g" and
                    the "7".
                #>

                if ($Timestamp.Day.tostring().length -eq 1) {
                    $FormattedTimestamp = (Get-Culture).TextInfo.ToTitleCase($Timestamp.ToString('MMM  d HH:mm:ss'))
                }
                else
                {
                    $FormattedTimestamp = (Get-Culture).TextInfo.ToTitleCase($Timestamp.ToString('MMM dd HH:mm:ss'))
                }

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

        Write-Verbose -Message ('Message attempting to send is: {0}' -f $FullSyslogMessage)

        # Ensure that the message is not too long. We could just compare the strings length, however using the encoding is the more appropriate way of confirming the length in bytes.
        if ($Encoding.GetByteCount($FullSyslogMessage) -gt $MaxLength)
        {
            $FullSyslogMessage = $FullSyslogMessage.Substring(0,$MaxLength)
            Write-Verbose -Message ('Message was too long and was shortened to {0} characters' -f $MaxLength)
            Write-Verbose -Message ('Shortened message is: {0}' -f $FullSyslogMessage)
        }

        Switch -Wildcard ($Transport)
        {
            'UDP'
            {
                # Convert into byte array representation
                $ByteSyslogMessage = $Encoding.GetBytes($FullSyslogMessage)

                # Send the Message
                Try
                {
                    $null = Send-UDPMessage -UdpClient $NetworkClient -Datagram $ByteSyslogMessage
                }
                Catch
                {
                    If ($null -ne $NetworkClient.client)
                    {
                        Write-Verbose -Message 'Cleaning up the UDP client object'
                        $null = Disconnect-UDPClient -UdpClient $NetworkClient
                    }
                    throw $_
                }
            }

            'TCP*'
            {
                Write-Verbose -Message ('Framing method is: {0}' -f $FramingMethod)
                Switch ($FramingMethod)
                {
                    'Octet-Counting'
                    {
                        $OctetCount = ($Encoding.GetBytes($FullSyslogMessage)).Length
                        $FramedSyslogMessage = '{0} {1}' -f $OctetCount, $FullSyslogMessage
                        Write-Verbose -Message ('Octet-Counting - Framed message is: {0}' -f $FullSyslogMessage)
                    }

                    'Non-Transparent-Framing'
                    {
                        $FramedSyslogMessage = '{0}{1}' -f $FullSyslogMessage, "`n"
                        Write-Verbose -Message ('Non-Transparent-Framing - Framed message is: {0}' -f $FullSyslogMessage)
                    }

                    'None'
                    {
                        $FramedSyslogMessage = $FullSyslogMessage
                        Write-Verbose -Message "No change to the message for framing type 'none'"
                    }
                }

                # Convert into byte array representation
                $ByteSyslogMessage = $Encoding.GetBytes($FramedSyslogMessage)

                # Send the Message
                Try
                {
                    $null = Send-TCPMessage -TCPWriter $TcpWriter -Datagram $ByteSyslogMessage
                }
                Catch
                {
                    # If there is an error, we need to clean up any open connections.
                    If ($null -ne $TcpStream)
                    {
                        Write-Verbose -Message 'Cleaning up the TCP writer object'
                        $null = Disconnect-TCPWriter -TCPWriter $TcpWriter
                    }

                    If ($null -ne $NetworkClient.client)
                    {
                        Write-Verbose -Message 'Cleaning up the TCP client object'
                        $null = Disconnect-TCPClient -TcpClient $NetworkClient
                    }

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
        Switch -Wildcard ($Transport)
        {
            'UDP'
            {
                If ($null -ne $NetworkClient.client)
                {
                    Write-Verbose -Message 'Cleaning up the UDP client object'
                    $null = Disconnect-UDPClient -UdpClient $NetworkClient
                }
            }

            'TCP*'
            {
                If ($null -ne $TcpWriter)
                {
                    Write-Verbose -Message 'Cleaning up the TCP writer object'
                    $null = Disconnect-TCPWriter -TCPWriter $TcpWriter
                }

                If ($null -ne $NetworkClient.client)
                {
                    Write-Verbose -Message 'Cleaning up the TCP client object'
                    $null = Disconnect-TCPClient -TcpClient $NetworkClient
                }
            }
        }
        Write-Debug -Message 'Finished the END block'
    }
}
