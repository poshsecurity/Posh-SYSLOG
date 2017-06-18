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
    [OutputType($null)]
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
    }
    Catch 
    {
        Throw $_
    }
}