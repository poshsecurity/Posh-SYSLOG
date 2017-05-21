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
    param
    (
        # Parameter help description
        [Parameter(Mandatory = $true,HelpMessage='Add help message for user')]
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