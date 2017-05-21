Function Connect-UDPClient
{
    <#
        .SYNOPSIS
        Describe purpose of "Connect-UDPClient" in 1-2 sentences.

        .DESCRIPTION
        Add a more complete description of what the function does.

        .PARAMETER Server
        Describe parameter -Server.

        .PARAMETER Port
        Describe parameter -Port.

        .EXAMPLE
        Connect-UDPClient -Server Value -Port Value
        Describe what this call does

        .NOTES
        Place additional notes here.

        .LINK
        URLs to related sites
        The first link is opened by Get-Help -Online Connect-UDPClient

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

    # Create a UDP client Object
    Try 
    {
        $UDPCLient = New-Object -TypeName System.Net.Sockets.UdpClient
        $UDPCLient.Connect($Server, $Port)
    }
    Catch 
    {
        Throw $_
    }

    $UDPCLient
}