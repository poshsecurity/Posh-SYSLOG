Function Get-TCPWriter
{
    <#
        .SYNOPSIS
        Describe purpose of "Get-TCPWriter" in 1-2 sentences.

        .DESCRIPTION
        Add a more complete description of what the function does.

        .PARAMETER TcpClient
        Describe parameter -TcpClient.

        .EXAMPLE
        Get-TCPWriter -TcpClient Value
        Describe what this call does

        .NOTES
        Place additional notes here.

        .LINK
        URLs to related sites
        The first link is opened by Get-Help -Online Get-TCPWriter

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
        [Net.Sockets.TcpClient]
        $TcpClient
    )

    Try 
    {
        $TcpStream = $TcpClient.GetStream()
        $TcpWriter = New-Object -TypeName System.IO.StreamWriter -ArgumentList $TcpStream
        $TcpWriter.AutoFlush = $true
    }
    Catch 
    {
        Throw $_
    }
    $TcpWriter
}
