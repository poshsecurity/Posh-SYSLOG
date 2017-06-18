Function Send-TCPMessage
{
    <#
        .SYNOPSIS
        Sends a datagram using the specified TCP writer

        .DESCRIPTION
        Internal function.

        This function will send a datagram using the specified TCP writer.

        .EXAMPLE
        Send-TCPMessage -TcpWriter $Writer -Datagram $Message
        Sends the datagram, or byte array, $Message using the specified TCP writer $writer.

        .OUTPUTS
        None
    #>

    [CmdletBinding()]
    [OutputType($null)]
    param
    (
        # TCPWriter object, that is already connected to the TCP server.
        [Parameter(Mandatory   = $true,
                   HelpMessage = 'TCPWriter object, that is already connected to the TCP server')]
        [ValidateNotNullOrEmpty()]
        [System.IO.StreamWriter]
        $TcpWriter,

        # Byte array containing the datagram to be sent.
        [Parameter(Mandatory   = $true,
                   HelpMessage = 'Byte array containing the datagram to be sent')]
        [ValidateNotNullOrEmpty()]
        [byte[]]
        $Datagram
    )

    Write-Verbose -Message ([Text.Encoding]::ASCII.GetString($Datagram)) -Verbose

    $null = $TcpWriter.Write($Datagram, 0, $Datagram.Length)
}