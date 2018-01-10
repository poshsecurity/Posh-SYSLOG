Function Get-SyslogHostname
{
    <#
        .SYNOPSIS
        Returns the valid hostname to send to the SYSLOG server according to RFC 5424. The CMDLet will take a socket (either connected to a TCP or UDP client) and return the appropriate response.

        .DESCRIPTION
        Internal Function.

        The purpose of this function is to determine the correct hostname to be sent by the client to the SYSLOG server according to RFC 5424, Section 6.2.4.

        The hostname to be send should be one of these 5, in order of priority:
            1.  FQDN
            2.  Static IP address
            3.  Hostname - Windows always has one of these, so this is our last resort
            4.  Dynamic IP address - We will never get to this one
            5.  the NILVALUE - or this one

        Windows should always, in the worst case, have a result at 3, the hostname or computer name from which this command is run.

        .EXAMPLE
        Get-SyslogHostname -Socket $Socket
        Returns the correct hostname to be sent.

        .OUTPUTS
        List of output types produced by this function.
    #>

    [CmdletBinding()]
    [OutputType([String])]
    Param
    (
        # Socket of the Client
        [Parameter(Mandatory   = $true,
                   HelpMessage = 'Add help message for user')]
        [ValidateNotNullOrEmpty()]
        [Net.Sockets.Socket]
        $Socket
    )

    # Get the Win32_ComputerSystem object
    $Win32_ComputerSystem =  Get-CimInstance -ClassName win32_computersystem

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
        $NetworkAdapter = Get-NetworkAdapter -IPAddress $LocalEndPoint

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
            $Hostname = $Win32_ComputerSystem.dnshostname

            Write-Verbose -Message ('The hostname ({0}) will be used as the HOSTNAME value.' -f $Hostname)
        }
    }

    Write-Debug -Message ('Get-SyslogHostname is returning value {0}' -f $Hostname)

    $Hostname
}