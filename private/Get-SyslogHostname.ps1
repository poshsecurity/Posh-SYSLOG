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
            4.  Dynamic IP address - We shouldn't get to this one (maybe on a weird Linux configuration?)
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
        [System.Net.Sockets.Socket]
        $Socket
    )

    # Ask the appropriate client what the local endpoint address is
    $LocalEndPoint = $Socket.LocalEndpoint.Address.IPAddressToString

    # Get the Global IP Properties
    $GlobalIPProperties = [System.Net.NetworkInformation.IPGlobalProperties]::GetIPGlobalProperties()

    # Get the hostname
    $Hostname = $GlobalIPProperties.HostName

    # Get the list of all network interfaces
    $Interfaces = [System.Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces()

    # Get the Network Interface being used
    $Interface = $Interfaces.Where({$_.GetIPProperties().UnicastAddresses.Address.IPAddressToString -contains $LocalEndPoint})

    # If that Interface has a DNS Suffix, we will use that
    if ($null -ne $Interface.GetIPProperties().DNSsuffix)
    {
        if ('' -ne $Interface.GetIPProperties().DNSsuffix)
        {
            $SyslogHostname = '{0}.{1}' -f $Hostname, $Interface.GetIPProperties().DNSsuffix
            Write-Verbose -Message 'Interface DNS Suffix'
            return $SyslogHostname
        }
    }

    # Do we have a Global DNS Suffix (AD join or specified in System Properties etc), we will use that
    if ($null -ne $GlobalIPProperties.DomainName)
    {
        if ('' -ne $GlobalIPProperties.DomainName)
        {
            $SyslogHostname = '{0}.{1}' -f $Hostname, $GlobalIPProperties.DomainName
            Write-Verbose -Message 'Global DNS Suffix'
            return $SyslogHostname
        }
    }

    # If the Interface is using a Static IP address, we use that
    $UnicastAddress = $Interface.GetIPProperties().UnicastAddresses.Where{$_.PrefixOrigin -eq 'Manual'}
    If ($UnicastAddress.count -ge 1)
    {
        $SyslogHostname = $UnicastAddress.Address.IPAddressToString
        Write-Verbose -Message 'Static'
        return $SyslogHostname
    }

    # If there is a hostname, we use that
    if ($null -ne $Hostname)
    {
        $SyslogHostname = $Hostname
        Write-Verbose -Message 'Hostname'
        return $SyslogHostname
    }

    # Finally, Use the Dynamically assigned IP Address
    $UnicastAddress = $Interface.GetIPProperties().UnicastAddresses.Where{$_.PrefixOrigin -eq 'Dhcp'}
    If ($UnicastAddress.count -ge 1)
    {
        $SyslogHostname = $UnicastAddress.Address.IPAddressToString
        Write-Verbose -Message 'DHCP'
        return $SyslogHostname
    }

    throw 'Could not determine IP address'
}