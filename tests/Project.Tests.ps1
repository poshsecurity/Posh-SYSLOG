if (-not(Get-Module -ListAvailable -Name "PSScriptAnalyzer")) {
    Write-Warning "Installing latest version of PSScriptAnalyzer"
    # Install PSScriptAnalyzer
    Install-Module PSScriptAnalyzer -Force -Scope CurrentUser
}

$script:ModuleName = 'Posh-SYSLOG'

$ModuleBase = Split-Path -Parent $MyInvocation.MyCommand.Path

# Get the list of Pester Tests we are going to skip
$PesterTestExceptions = Get-Content -Path "$ModuleBase\Project.Exceptions.txt"

# For tests in .\Tests subdirectory
if ((Split-Path $ModuleBase -Leaf) -eq 'Tests') {
    $ModuleBase = Split-Path $ModuleBase -Parent
}

Describe "PSScriptAnalyzer rule-sets" -Tag Build , ScriptAnalyzer {

    $Rules = Get-ScriptAnalyzerRule
    $scripts = Get-ChildItem $ModuleBase -Include *.ps1, *.psm1, *.psd1 -Recurse | Where-Object fullname -notmatch 'classes'

    foreach ( $Script in $scripts )
    {
        Context "Script '$($script.FullName)'" {

            foreach ( $rule in $rules )
            {
                # Skip all rules that are on the exclusions list
                if ($PesterTestExceptions -contains $rule.RuleName) { continue }
                It "Rule [$rule]" {

                    (Invoke-ScriptAnalyzer -Path $script.FullName -IncludeRule $rule.RuleName ).Count | Should Be 0
                }
            }
        }
    }
}


Describe "General project validation: $moduleName" -Tags Build {
    BeforeAll {
        Get-Module $ModuleName | Remove-Module
    }
    It "Module '$moduleName' can import cleanly" {
        {Import-Module $ModuleBase\$ModuleName.psd1 -force } | Should Not Throw
    }
}
