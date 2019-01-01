# Posh-SYSLOG

[![Codacy Badge](https://api.codacy.com/project/badge/Grade/108fce1968bc40e689ef8053bc3d1e78)](https://app.codacy.com/app/kjacobsen/Posh-SYSLOG?utm_source=github.com&utm_medium=referral&utm_content=poshsecurity/Posh-SYSLOG&utm_campaign=Badge_Grade_Dashboard)

![Build Status](https://build.status.url.here)

## Description

A module for sending SYSLOG messages from PowerShell.

The module supports RFC5424 and RFC3164, and can send messages via TCP and UDP.

Authored by Kieran Jacobsen

## Installing

The easiest way to get Posh-SYSLOG is using the [PowerShell Gallery](https://powershellgallery.com/packages/Posh-SYSLOG/)!

### Inspecting the module

Best practice is that you inspect modules prior to installing them. You can do this by saving the module to a local path:

``` PowerShell
PS> Save-Module -Name Posh-SYSLOG -Path <path>
```

### Installing the module

Once you trust a module, you can install it using:

``` PowerShell
PS> Install-Module -Name Posh-SYSLOG
```

### Updating Posh-SYSLOG

Once installed from the PowerShell Gallery, you can update it using:

``` PowerShell
PS> Update-Module -Name Posh-SYSLOG
```

### Uninstalling Posh-SYSLOG

To remove Posh-SYSLOG:

``` PowerShell
PS> Uninstall-Module -Name Posh-SYSLOG
```

## Contributing to Posh-SYSLOG

Interested in contributing? Read how you can [Contribute](contributing.md) to Posh-SYSLOG

This project maintains a [Code of Conduct](code-of-conduct.md) that establishes how the project is governed and how everyone involved is expected to behave. You can report unacceptable behavior to [Developer@PowerShellis.Cool](mailto:Developer@PowerShellis.Cool).

## Release History

A detailed release history is contained in the [Change Log](CHANGELOG.md).

## License

Posh-SYSLOG is provided under the [MIT license](LICENSE.md).
