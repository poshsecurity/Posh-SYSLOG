Function Get-TCPWriter
{
    <#
        .SYNOPSIS
        Returns a TCPWriter object for a given TcpClient.

        .DESCRIPTION
        Creates a TcpWriter, given the TcpClient (and TcpStream), and returns it.

        .EXAMPLE
        Get-TCPWriter -TcpClient $Client
        Returns a TCPWriter connected to the stream associated with the TCPClient.

        .OUTPUTS
        System.IO.StreamWriter
    #>

    [CmdletBinding(DefaultParameterSetName = 'TLSDisabled')]
    [OutputType([System.IO.StreamWriter])]
    param
    (
        # TCP Client that is connected to an endpoint
        [Parameter(Mandatory   = $true,
                   HelpMessage = 'TCP Client that is connected to an endpoint')]
        [ValidateNotNullOrEmpty()]
        [Net.Sockets.TcpClient]
        $TcpClient,

        # Enables support for TLS
        [Parameter(Mandatory        = $true,
                   ParameterSetName = 'UseTLS')]
        [switch]
        $UseTLS,

        # Server Hostname to validate against the certificate presented during TLS validation
        [Parameter(Mandatory        = $true,
                   ParameterSetName = 'UseTLS')]
        [string]
        $ServerHostname,

        # SSL Protocols accepted
        [Parameter(Mandatory        = $false,
                   ParameterSetName = 'UseTLS')]
        [System.Security.Authentication.SslProtocols]
        $SslProtocols = [System.Security.Authentication.SslProtocols]::Tls12,

        # Do not validate TLS Certificate
        [Parameter(Mandatory        = $false,
                   ParameterSetName = 'UseTLS')]
        [switch]
        $DoNotValidateTLSCertificate
    )

    Try
    {
        if ($UseTLS)
        {
            Write-Debug -Message 'Using TCP connection with TLS/SSL'
            if ($DoNotValidateTLSCertificate)
            {
                # See https://docs.microsoft.com/en-us/dotnet/api/system.net.security.sslstream.-ctor?view=netframework-4.7.2 and
                #     https://stackoverflow.com/questions/19252963/powershell-ssl-socket-client
                Write-Warning -Message 'Ignoring SSL/TLS certificate validation issues'
                $TCPStream = New-Object -TypeName System.Net.Security.SslStream -ArgumentList ($TCPClient.GetStream(), $false, {$True})
            }
            else
            {
                $TCPStream = New-Object -TypeName System.Net.Security.SslStream -ArgumentList ($TCPClient.GetStream(), $false)
            }

            $TCPStream.AuthenticateAsClient($ServerHostname, $null, $SslProtocols, $false)
        }
        else
        {
            $TcpStream = $TcpClient.GetStream()
        }

        $TcpWriter = New-Object -TypeName System.IO.StreamWriter -ArgumentList $TcpStream

        # We want to set autoflush to true so that we send whatever is in the stream/writer when a newline is entered
        $TcpWriter.AutoFlush = $true
    }
    Catch
    {
        Throw $_
    }

    $TcpWriter
}
