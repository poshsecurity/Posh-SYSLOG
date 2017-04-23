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

function Send-SyslogMessage
{
    <#
            .SYNOPSIS
            Sends a SYSLOG message to a server running the SYSLOG daemon

            .DESCRIPTION
            Sends a message to a SYSLOG server as defined in RFC 5424 and RFC 3164. 

            .INPUTS
            Nothing can be piped directly into this function

            .OUTPUTS
            Nothing is output

            .EXAMPLE
            Send-SyslogMessage mySyslogserver "The server is down!" Emergency Mail
            Sends a syslog message to mysyslogserver, saying "server is down", severity emergency and facility is mail

            .NOTES
            NAME: Send-SyslogMessage
            AUTHOR: Kieran Jacobsen
                    Jared Poeppelman

            .LINK
            https://github.com/poshsecurity/Posh-Syslog

            .LINK
            https://poshsecurity.com

    #>
    [CMDLetBinding(DefaultParameterSetName = 'RFC5424')]
    Param
    (
        #Destination SYSLOG server that message is to be sent to.
        [Parameter(Mandatory = $true,
                    ValueFromPipeline = $false,
                    HelpMessage = 'Server to send message to')]
        [ValidateNotNullOrEmpty()]
        [String] 
        $Server,
	
        #Our message or content that we want to send to the server. This is option in RFC 5424, the CMDLet still has this as a madatory parameter, to send no message, simply specifiy '-' (as per RFC).
        [Parameter(Mandatory = $true,
                    ValueFromPipeline = $true,
                    HelpMessage = 'Message to send')]
        [ValidateNotNullOrEmpty()]
        [String]
        $Message,
	
        #Severity level as defined in SYSLOG specification, must be of ENUM type Syslog_Severity
        [Parameter(Mandatory = $true,
                    ValueFromPipeline = $true,
                    HelpMessage = 'Messsage severity level')]
        [ValidateNotNullOrEmpty()]
        [Syslog_Severity]
        $Severity,
	
        #Facility of message as defined in SYSLOG specification, must be of ENUM type Syslog_Facility
        [Parameter(Mandatory = $true,
                    ValueFromPipeline = $true,
                    HelpMessage = 'Facility sending message')]
        [ValidateNotNullOrEmpty()]
        [Syslog_Facility] 
        $Facility,
	
        #Hostname of machine the message is about, if not specified, RFC 5425 selection rules will be followed.
        [Parameter(Mandatory = $false,
                    ValueFromPipeline = $false)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Hostname = '',
	
        #Specify the name of the application or script that is sending the mesage. If not specified, will select the ScriptName, or if empty, powershell.exe will be sent. To send Null, specify '-' to meet RFC 5424. 
        [Parameter(Mandatory = $false,
                    ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $ApplicationName = '',
	
        #ProcessID or PID of generator of message. Will automatically use $PID global variable. If you want to override this and send null, specify '-' to meet RFC 5424 rquirements. This is only sent for RFC 5424 messages.
        [Parameter(Mandatory = $false,
                    ValueFromPipeline = $true,
                    ParameterSetName = 'RFC5424')]
        [ValidateNotNullOrEmpty()]
        [String]
        $ProcessID = $PID,
	
        #Error message or troubleshooting number associated with the message being sent. If you want to override this and send null, specify '-' to meet RFC 5424 rquirements. This is only sent for RFC 5424 messages.
        [Parameter(Mandatory = $false,
                    ValueFromPipeline = $true,
                    ParameterSetName = 'RFC5424')]
        [ValidateNotNullOrEmpty()]
        [String]
        $MessageID = '-',
	
        #Key Pairs of structured data as a string as defined in RFC5424. Default will be '-' which means null. This is only sent for RFC 5424 messages.
        [Parameter(Mandatory = $false,
                    ValueFromPipeline = $true,
                    ParameterSetName = 'RFC5424')]
        [ValidateNotNullOrEmpty()]
        [String]
        $StructuredData = '-',
	
        #Time and date of the message, must be of type DateTime. Correct format will be selected depending on RFC requested. If not specified, will call get-date to get appropriate date time.
        [Parameter(Mandatory = $false,
                    ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [DateTime] 
        $Timestamp = (Get-Date),
	
        #SYSLOG UDP (or TCP) port to which to send the message. Defaults to 514, if not specified.
        [Parameter(Mandatory = $false,
                    ValueFromPipeline = $false)]
        [ValidateNotNullOrEmpty()]
        [ValidateRange(1,65535)]
        [Alias('UDPPort','TCPPort')]
        [UInt16]
        $Port = 514,

        # Transport protocol (TCP or UDP) over which the message will be sent. Default is UDP.
        [Parameter(Mandatory = $false,
                    ValueFromPipeline = $false)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('UDP','TCP')]
        [String]
        $Transport = 'UDP',

        # Framing method used for the message, default is 'Octet-Counting' (see RFC6587 section 3.4). This only applies when TCP is used for transport (no effect on UDP messages).
        [Parameter(Mandatory = $false,
                    ValueFromPipeline = $false)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('Octet-Counting','Non-Transparent-Framing','None')]
        [String]
        $FramingMethod='Octet-Counting',
	
        #Send an RFC3164 fomatted message instead of RFC5424.
        [Parameter(Mandatory = $True,
                    ValueFromPipeline = $true,
                    ParameterSetName = 'RFC3164')]
        [switch]
        $RFC3164,

        #Enable static source IP detection for strict adherence to RFC 5424 (section 6.2.4), if FQDN is not available. Using this might reduce performance in high-volume scenarios.
        [Parameter(Mandatory = $false,
                    ValueFromPipeline = $false)]
        [switch]
        $DetectSourceIP
    )
    Begin 
    {
        Write-Verbose "Starting the BEGIN block..."

        # Create an ASCII Encoding object
        $Encoding = [System.Text.Encoding]::ASCII

        if ($Hostname -eq '')
        {            
            Write-Verbose "No HOSTNAME value was provided, so automatic selection will now be attempted..."
            <#
            According to RFC 5424 (section 6.2.4), we need to send our HOSTNAME field as one of these 5 (in order of priority)
            1.  FQDN
            2.  Static IP address
            3.  Hostname - Windows always has one of these, so this is our last resort
            4.  Dynamic IP address - We will never get to this one
            5.  the NILVALUE - or this one

            Windows should always, in the worst case, have a result at 3, the hostname or computer name from which this command is run.
            #>        
            
            # Get the IP global proprties of the local machine, to determine if an FQDN is available
            #$ComputerName = [System.Net.Dns]::GetHostByName($Env:COMPUTERNAME).HostName
            #([System.Net.NetworkInformation.IPGlobalProperties]::GetIPGlobalProperties().Hostname) + '.' + ([System.Net.NetworkInformation.IPGlobalProperties]::GetIPGlobalProperties().DomainName)
            $IpGlobalProps = [System.Net.NetworkInformation.IPGlobalProperties]::GetIPGlobalProperties()


            if ($IpGlobalProps.DomainName) # If a domain name (and therefore an FQDN) is available...
            {          
                Write-Verbose "Attempting FQDN detection for HOSTNAME value..."
                $Hostname = ($IpGlobalProps.Hostname +'.'+ $IpGlobalProps.DomainName) # Use HOSTNAME Option 1 (FQDN), per RFC 5424 (section 6.2.4)
                Write-Verbose "A domain suffix was detected in the global IP properties, so the FQDN ($Hostname) will be used as the HOSTNAME value."
            }
            else
            {                              
                Write-Verbose "A domain suffix was not detected in the global IP properties, so FQDN will not be used as the HOSTNAME value."
                $StaticSourceIP = $null
                if ($DetectSourceIP) 
                {
                    Write-Verbose "Attempting static source IP detection for HOSTNAME value..."
                    # Get the static source IPv4 address that will be used to send the message, if there is one
                    $RouteInfo = Test-NetConnection -ComputerName $Server -DiagnoseRouting -ErrorAction SilentlyContinue -InformationLevel Quiet

                    # If it is a static address, use it as the HOSTNAME
                    if ((Get-NetIPAddress -IPAddress $RouteInfo.SelectedSourceAddress.IPAddress).PrefixOrigin -eq 'Manual')
                    {
                        $StaticSourceIP = $RouteInfo.SelectedSourceAddress.IPAddress  # Use HOSTNAME Option 2, (static IP address), per RFC 5424 (section 6.2.4), but only if -DetectSourceIP used and source IP successfully detected
                        $Hostname = $StaticSourceIP
                        Write-Verbose "A statically assigned IP was detected as the source for the route to $Server, so the static IP ($Hostname) will be used as the HOSTNAME value."
                    }
                    else
                    {
                        Write-Verbose "A statically assigned IP was not detected as the source for the route to $Server, so an IP will not be used as the HOSTNAME value."         
                    }
                }
                if ($null -eq $StaticSourceIP) # If static detection was not used or it did not detect a static IP...
                {
                    Write-Verbose "Falling back to hostname for HOSTNAME value..."
                    $Hostname = $Env:COMPUTERNAME # Use HOSTNAME Option 3 (hostname), per RFC 5424 (section 6.2.4)
                    Write-Verbose "The hostname ($Hostname) will be used as the HOSTNAME value."
                }
            }
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

        # Initiate the required network objects
        Switch ($Transport)
        {        
            'UDP' 
            {
                Write-Verbose 'Attempting to create the UDP client object'
                # Create a UDP client Object
                Try {
                    $UDPCLient = New-Object -TypeName System.Net.Sockets.UdpClient
                    $UDPCLient.Connect($Server, $Port)
                }
                Catch {
                    Write-Error $_ -ErrorAction Stop
                }
                Write-Verbose 'Successfully created the UDP client object'
            }          
            'TCP'
            {
                Write-Verbose 'Attempting to create the TCP client, stream, and writer objects'
                # Create TCP client, stream, and writer
                Try {
                    $TcpClient = New-Object System.Net.Sockets.TcpClient $Server, $Port
                    $TcpStream = $TcpClient.GetStream()
                    $TcpWriter = New-Object System.IO.StreamWriter $TcpStream
                }
                Catch {
                    Write-Error $_ -ErrorAction Stop
                }
                Write-Verbose 'Successfully created the TCP client, stream, and writer objects'               
            }
        }  
        Write-Verbose "Finished the BEGIN block"     
    }
    Process 
    {
        Write-Verbose "Starting the PROCESS block..."

        # Evaluate the facility and severity based on the enum types
        $Facility_Number = $Facility.value__
        $Severity_Number = $Severity.value__
        Write-Verbose "Syslog Facility is $Facility_Number, Severity is $Severity_Number"

        # Calculate the PRI
        $Priority = ($Facility_Number * 8) + $Severity_Number
        Write-Verbose "Priority (PRI) is $Priority"

        # Set the APP-NAME
        if ($ApplicationName -eq '')
        {
            Write-Verbose "No APP-NAME value was provided, so it will be detected..."
            $ApplicationName = $Caller
            Write-Verbose "$ApplicationName will be used as the APP-NAME value."
            
        }

        if ($PSCmdlet.ParameterSetName -eq 'RFC3164')
        {
            Write-Verbose 'Using RFC 3164 message format'

            #Get the timestamp
            $FormattedTimestamp = (Get-Culture).TextInfo.ToTitleCase($Timestamp.ToString('MMM dd HH:mm:ss'))
            
            # Assemble the full syslog formatted Message
            $FullSyslogMessage = '<{0}>{1} {2} {3} {4}' -f $Priority, $FormattedTimestamp, $Hostname, $ApplicationName, $Message
            
            # Set the max message length per RFC 3164 section 4.1
            Write-Verbose 'Using RFC 3164 (section 4.1) max length of 1024 bytes'
            [int]$MaxLength = 1024
        }
        else
        {
            Write-Verbose 'Using RFC 5424 message format'
            
            #Get the timestamp
            $FormattedTimestamp = $Timestamp.ToString('yyyy-MM-ddTHH:mm:ss.ffffffzzz')
            
            # Assemble the full syslog formatted Message
            $FullSyslogMessage = '<{0}>1 {1} {2} {3} {4} {5} {6} {7}' -f $Priority, $FormattedTimestamp, $Hostname, $ApplicationName, $ProcessID, $MessageID, $StructuredData, $Message
            
            # Set the max message length per RFC 5424 section 6.1
            Write-Verbose 'Using RFC 5424 (section 6.1) max length of 2048 bytes'
            [int]$MaxLength = 2048
        }

        Write-Verbose "Message being attempted is: $FullSyslogMessage"
        
        # If the message is too long, shorten it
        if ($FullSyslogMessage.Length -gt $MaxLength)
        {
            $FullSyslogMessage = $FullSyslogMessage.Substring(0,$MaxLength)
            Write-Verbose "Message was too long and was shortened to $MaxLength characters"
            Write-Verbose "Shortened message is: $FullSyslogMessage"
        }


        Switch ($Transport)
        {
            'UDP' 
            {
                # Convert into byte array representation
                $ByteSyslogMessage = $Encoding.GetBytes($FullSyslogMessage)
                Write-Verbose "Message raw bytes: $ByteSyslogMessage"
                Write-Verbose ('Message raw bytes length: '+($ByteSyslogMessage.Count))

                # Send the Message
                Try {
                    $null = $UDPCLient.Send($ByteSyslogMessage, $ByteSyslogMessage.Length)
                }
                Catch {
                    Write-Error $_ -ErrorAction Stop
                }
            }            
            'TCP'
            {
                Write-Verbose "Framing method is: $FramingMethod"
                Switch ($FramingMethod) 
                {  
                    'Octet-Counting' 
                    { 
                        $OctetCount = ($Encoding.GetBytes($FullSyslogMessage)).Length
                        $FramedSyslogMessage = '{0} {1}' -f $OctetCount, $FullSyslogMessage
                        Write-Verbose "Framed message is: $FullSyslogMessage"
                    }
                    'Non-Transparent-Framing' 
                    {
                        $FramedSyslogMessage = '{0}{1}' -f $FullSyslogMessage, "`n"
                        Write-Verbose "Framed message is: $FullSyslogMessage"
                    }
                    'None' 
                    {
                        $FramedSyslogMessage = $FullSyslogMessage
                        Write-Verbose "No change to the message for framing type 'none'"  
                    }
                }
                
                # Convert into byte array representation
                $ByteSyslogMessage = $Encoding.GetBytes($FramedSyslogMessage)
                Write-Verbose "Message raw bytes: $ByteSyslogMessage"
                Write-Verbose ('Message raw bytes length: '+($ByteSyslogMessage.Count))


                # Send the Message
                Try {
                    $null = $TcpWriter.Write($ByteSyslogMessage, 0, $ByteSyslogMessage.Length)
                }
                Catch {
                    Write-Error $_ -ErrorAction Stop
                }
            }
        }
        Write-Verbose "Finished the PROCESS block" 
    }
    End 
    {
        Write-Verbose "Starting the END block..."
        
        # Clean up our network objects
        Switch ($Transport)
        {
            'UDP' 
            {
                If ($UDPCLient)
                {
                    Write-Verbose 'Cleaning up the UDP client object'
                    $UDPCLient.Close()
                }
            }          
            'TCP'
            {
                If ($TcpWriter)
                {
                    Write-Verbose 'Cleaning up the TCP writer object'
                    $TcpWriter.Close()
                }

                If ($TcpStream)
                {
                    Write-Verbose 'Cleaning up the TCP stream object'
                    $TcpStream.Dispose()
                }

                If ($TcpClient)
                {
                    Write-Verbose 'Cleaning up the TCP client object'
                    $TcpClient.Close()
                }
            }
        }
        Write-Verbose "Finished the END block" 
    }
}