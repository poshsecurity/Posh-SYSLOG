Function Disconnect-TCPWriter
{
    <#
        .SYNOPSIS
        Disconnects/Closes a TCPWriter Object

        .DESCRIPTION
        Internal function.

        Disconnects/closes an open TCPWriter.

        .EXAMPLE
        Disconnect-TCPWriter -TCPWriter $Writer
        Closes the writer $Writer.

        .OUTPUTS
        None
    #>

    [CmdletBinding()]
    param
    (
        # TcpWriter object
        [Parameter(Mandatory   = $true,
                   HelpMessage = 'TcpWriter object')]
        [ValidateNotNullOrEmpty()]
        [System.IO.StreamWriter]
        $TcpWriter
    )

    Try
    {
        $TcpStream = $TcpWriter.BaseStream

        If ($null -ne $TcpWriter)
        {
            Write-Verbose -Message 'Cleaning up the TCP writer object'
            $TcpWriter.Close()
            Write-Debug -message ('Writer Closed')
        }

        If ($null -ne $TcpStream)
        {
            Write-Verbose -Message 'Cleaning up the TCP stream object'
            $TcpStream.Dispose()
            Write-Debug -message ('Stream Closed')
        }
    }
    Catch
    {
        Throw $_
    }
}