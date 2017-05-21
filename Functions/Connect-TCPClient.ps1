Function Connect-TCPClient
{
    <#
        .SYNOPSIS
        Describe purpose of "Connect-TCPClient" in 1-2 sentences.

        .DESCRIPTION
        Add a more complete description of what the function does.

        .PARAMETER Server
        Describe parameter -Server.

        .PARAMETER Port
        Describe parameter -Port.

        .EXAMPLE
        Connect-TCPClient -Server Value -Port Value
        Describe what this call does

        .NOTES
        Place additional notes here.

        .LINK
        URLs to related sites
        The first link is opened by Get-Help -Online Connect-TCPClient

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
        [String]
        $Server,

        # Parameter help description
        [Parameter(Mandatory = $true,HelpMessage='Add help message for user')]
        [ValidateNotNullOrEmpty()]
        [ValidateRange(1, 65535)]
        [UInt16]
        $Port
    )

    # Create a TCP client Object
    Try 
    {
        $TcpClient = New-Object -TypeName System.Net.Sockets.TcpClient
        $TcpClient.Connect($Server, $Port)
    }
    Catch 
    {
        Throw $_
    }

    $TcpClient
}