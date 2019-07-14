Function Get-SyslogHostname
{
    <#
        .SYNOPSIS
        Returns the valid hostname to send to the SYSLOG server according to RFC 5424. The CMDLet will take a socket (either connected to a TCP or UDP client) and return the appropriate response.

        .DESCRIPTION
        Internal Function.

        The purpose of this function is to determine the correct hostname to be sent by the client to the SYSLOG server according to RFC 5424, Section 6.2.4.

        The hostname to be send should be one of these 5, in order of priority:
            1.  FQDN  - Network Adapter and then Global
            2.  Static IP address
            3.  Hostname - Windows always has one of these, so this is our last resort
            4.  Dynamic IP address - We shouldn't get to this one (maybe on a weird Linux configuration?)
            5.  the NILVALUE - Can't see us ever getting here, but its handled.

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
        [System.Net.Sockets.Socket]
        $Socket
    )

    # Ask the specified client what the local endpoint address is
    $LocalEndPoint = $Socket.LocalEndpoint.Address.IPAddressToString

    # Get the Global IP Properties
    $GlobalIPProperties = Get-GlobalIPProperty

    # Get the hostname
    $Hostname = $GlobalIPProperties.HostName

    # Get the DnsSuffix for the Network Interface used
    $NetworkAdapterDnsSuffix = Get-NetworkAdapterDnsSuffix -IPAddress $LocalEndPoint

    # Get the network IP address information
    $NetworkAdapterIPAddress = Get-NetworkIPAddress -IPAddress $LocalEndPoint

    # If that Interface has a DNS Suffix, we will use that
    if ($null -ne $NetworkAdapterDnsSuffix -and '' -ne $NetworkAdapterDnsSuffix)
    {
        $SyslogHostname = '{0}.{1}' -f $Hostname, $NetworkAdapterDnsSuffix
        Write-Verbose -Message ('DNS Suffix is specified on the network adapter used for the connection, using FQDN {0}' -f $SyslogHostname)
        return $SyslogHostname
    }

    # Do we have a Global DNS Suffix (AD join or specified in System Properties etc), we will use that
    if ($null -ne $GlobalIPProperties.DomainName)
    {
        if ('' -ne $GlobalIPProperties.DomainName)
        {
            $SyslogHostname = '{0}.{1}' -f $Hostname, $GlobalIPProperties.DomainName
            Write-Verbose -Message ('The machine is joined to an Active Directory domain, or DNS suffix specified at host level, using FQDN: {0}' -f $SyslogHostname)
            return $SyslogHostname
        }
    }

    # If the Interface is using a Static IP address, we use that
        If ($NetworkAdapterIPAddress.PrefixOrigin -eq 'Manual')
    {
        $SyslogHostname = $LocalEndPoint
        Write-Verbose -Message ('A statically assigned IP was detected as the source for the route to {0}, so the static IP ({1}) will be used as the HOSTNAME value.' -f $LocalEndPoint, $SyslogHostname)
        return $SyslogHostname
    }

    # If there is a hostname, we use that
    if ($null -ne $Hostname)
    {
        $SyslogHostname = $Hostname
        Write-Verbose -Message ('The hostname ({0}) will be used as the HOSTNAME value.' -f $Hostname)
        return $SyslogHostname
    }

    # Finally, Use the Dynamically assigned IP Address
    If ($NetworkAdapterIPAddress.PrefixOrigin -eq 'Dhcp')
    {
        $SyslogHostname = $LocalEndPoint
        Write-Verbose -Message ('A dynamically assigned IP was detected as the source for the route to {0}, so the static IP ({1}) will be used as the HOSTNAME value.' -f $LocalEndPoint, $SyslogHostname)
        return $SyslogHostname
    }

    Write-Verbose -Message 'could not determine the hostname, returning null'
    return $null
}