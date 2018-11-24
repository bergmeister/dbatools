#ValidationTags#Messaging,FlowControl,Pipeline,CodeStyle#
function Get-DbaAgAgentJob {
    <#
    .SYNOPSIS
        Gets Agent Jobs associated Availability Groups databases

    .DESCRIPTION
        Gets Agent Jobs associated Availability Groups databases

   .PARAMETER SqlInstance
        The target SQL Server instance or instances. Server version must be SQL Server version 2012 or higher.

    .PARAMETER SqlCredential
        Login to the SqlInstance instance using alternative credentials. Windows and SQL Authentication supported. Accepts credential objects (Get-Credential)

    .PARAMETER Database
        The target database or databases.

    .PARAMETER AvailabilityGroup
        The target availability group.

    .PARAMETER InputObject
        Enables piping from Get-DbaAgDatabase

    .PARAMETER WhatIf
        Shows what would happen if the command were to run. No actions are actually performed.

    .PARAMETER Confirm
        Prompts you for confirmation before executing any changing operations within the command.

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .NOTES
        Tags: AvailabilityGroup, HA, AG
        Author: Chrissy LeMaire (@cl), netnerds.net
        Website: https://dbatools.io
        Copyright: (c) 2018 by dbatools, licensed under MIT
        License: MIT https://opensource.org/licenses/MIT

    .LINK
        https://dbatools.io/Get-DbaAgAgentJob

    .EXAMPLE
        PS C:\> Get-DbaAgAgentJob -SqlInstance sql2017a

        Gets all Agent Jobs associated all Availability Groups on sql2017a
    
    .EXAMPLE
        PS C:\> Get-DbaAgAgentJob -SqlInstance sql2017a -AvailabilityGroup ag1 -Database db1, db2

        Gets Agent Jobs associated with db1 and db2 from ag1 on sql2017a.

    #>
    [CmdletBinding()]
    param (
        [DbaInstanceParameter[]]$SqlInstance,
        [PSCredential]$SqlCredential,
        [string]$AvailabilityGroup,
        [string[]]$Database,
        [string[]]$Category,
        [parameter(ValueFromPipeline)]
        [Microsoft.SqlServer.Management.Smo.AvailabilityDatabase[]]$InputObject,
        [switch]$EnableException
    )
    begin {
        $servers = @()
        $dbs = @()
    }
    process {
        foreach ($instance in $SqlInstance) {
            $InputObject += Get-DbaAgDatabase -SqlInstance $instance -SqlCredential $SqlCredential -Database $Database
        }
        
        foreach ($agdb in $InputObject) {
            if ($agdb.Parent.Parent.Name -notin $servers.Name) {
                $servers += $agdb.Parent.Parent
            }
            if ($agdb.Name -notin $dbs) {
                $dbs += $agdb.Name
            }
        }
        
        $allags = Get-DbaAgentJob -SqlInstance $agdb.Parent.Parent -Category $Category
        $agdbs = $allags | Where-Object {
            $_.JobSteps.DatabaseName -in $Database
        }
        $allags += $agdbs | Where-Object {
            $_.JobSteps.DatabaseName -in $Database -and $_.Name -notin $agdbs.Name
        }
    }
}