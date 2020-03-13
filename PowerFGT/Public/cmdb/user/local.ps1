#
# Copyright 2019, Alexis La Goutte <alexis dot lagoutte at gmail dot com>
# Copyright 2019, Benjamin Perrier <ben dot perrier at outlook dot com>
#
# SPDX-License-Identifier: Apache-2.0
#

function Add-FGTUserLocal {

    <#
        .SYNOPSIS
        Add a FortiGate Address

        .DESCRIPTION
        Add a FortiGate Address (ipmask, fqdn, widlcard...)

        .EXAMPLE
        Add-FGTFirewallAddress -type ipmask -Name FGT -ip 192.2.0.0 -mask 255.255.255.0

        Add Address objet type ipmask with name FGT and value 192.2.0.0/24

        .EXAMPLE
        Add-FGTFirewallAddress -type ipmask -Name FGT -ip 192.2.0.0 -mask 255.255.255.0 -interface port2

        Add Address objet type ipmask with name FGT, value 192.2.0.0/24 and associated to interface port2

        .EXAMPLE
        Add-FGTFirewallAddress -type ipmask -Name FGT -ip 192.2.0.0 -mask 255.255.255.0 -comment "My FGT Address"

        Add Address objet type ipmask with name FGT, value 192.2.0.0/24 and a comment

        .EXAMPLE
        Add-FGTFirewallAddress -type ipmask -Name FGT -ip 192.2.0.0 -mask 255.255.255.0 -visibility:$false

        Add Address objet type ipmask with name FGT, value 192.2.0.0/24 and disabled visibility

    #>

    Param(
        [Parameter (Mandatory = $true)]
        [ValidateLength(1, 64)]
        [string]$name,
        [Parameter (Mandatory = $false)]
        [switch]$status,
        [Parameter (Mandatory = $false)]
        [string]$passwd,
        [Parameter (Mandatory = $false)]
        [ValidateSet("password", "radius", "tacacs+", "ldap")]
        [string]$type = "password",
        [Parameter (Mandatory = $false)]
        [ValidateLength(1, 63)]
        [string]$emailto,
        [Parameter (Mandatory = $false)]
        [ValidateSet("disable", "fortitoken", "email", "sms", "fortitoken-cloud")]
        [string]$twofactor = "password",
        [Parameter(Mandatory = $false)]
        [String[]]$vdom,
        [Parameter(Mandatory = $false)]
        [psobject]$connection = $DefaultFGTConnection
    )

    Begin {
    }

    Process {

        $invokeParams = @{ }
        if ( $PsBoundParameters.ContainsKey('vdom') ) {
            $invokeParams.add( 'vdom', $vdom )
        }

        if ( Get-FGTUserLocal @invokeParams -name $name -connection $connection) {
            Throw "Already an user using the same name"
        }

        $uri = "api/v2/cmdb/user/local"

        $_user = new-Object -TypeName PSObject

        $_user | add-member -name "name" -membertype NoteProperty -Value $name

        $_user | add-member -name "type" -membertype NoteProperty -Value $type

        if ( $PsBoundParameters.ContainsKey('status') ) {
            if ( $status ) {
                $_user | add-member -name "status" -membertype NoteProperty -Value "enable"
            }
            else {
                $_user | add-member -name "status" -membertype NoteProperty -Value "disable"
            }
        }

        if ( $PsBoundParameters.ContainsKey('passwd') ) {
            $_user | add-member -name "passwd" -membertype NoteProperty -Value $passwd
        }

        Invoke-FGTRestMethod -method "POST" -body $_user -uri $uri -connection $connection @invokeParams | out-Null

        Get-FGTUserLocal -connection $connection @invokeParams -name $name
    }

    End {
    }
}

function Get-FGTUserLocal {

    <#
        .SYNOPSIS
        Get list of all "local users"

        .DESCRIPTION
        Get list of all "local users" (name, type, status... )

        .EXAMPLE
        Get-FGTUserLocal

        Display all local users

        .EXAMPLE
        Get-FGTUserLocal -id 23

        Get local user with id 23

        .EXAMPLE
        Get-FGTUserLocal -name FGT -filter_type contains

        Get local user contains with *FGT*

        .EXAMPLE
        Get-FGTUserLocal -skip

        Display all local users (but only relevant attributes)

        .EXAMPLE
        Get-FGTUserLocal -vdom vdomX

        Display all local users on vdomX
    #>

    [CmdletBinding(DefaultParameterSetName = "default")]
    Param(
        [Parameter (Mandatory = $false, Position = 1, ParameterSetName = "name")]
        [string]$name,
        [Parameter (Mandatory = $false, ParameterSetName = "id")]
        [string]$id,
        [Parameter (Mandatory = $false)]
        [Parameter (ParameterSetName = "filter")]
        [string]$filter_attribute,
        [Parameter (Mandatory = $false)]
        [Parameter (ParameterSetName = "name")]
        [Parameter (ParameterSetName = "id")]
        [Parameter (ParameterSetName = "filter")]
        [ValidateSet('equal', 'contains')]
        [string]$filter_type = "equal",
        [Parameter (Mandatory = $false)]
        [Parameter (ParameterSetName = "filter")]
        [psobject]$filter_value,
        [Parameter(Mandatory = $false)]
        [switch]$skip,
        [Parameter(Mandatory = $false)]
        [String[]]$vdom,
        [Parameter(Mandatory = $false)]
        [psobject]$connection = $DefaultFGTConnection
    )

    Begin {
    }

    Process {

        $invokeParams = @{ }
        if ( $PsBoundParameters.ContainsKey('skip') ) {
            $invokeParams.add( 'skip', $skip )
        }
        if ( $PsBoundParameters.ContainsKey('vdom') ) {
            $invokeParams.add( 'vdom', $vdom )
        }

        #Filtering
        switch ( $PSCmdlet.ParameterSetName ) {
            "name" {
                $filter_value = $name
                $filter_attribute = "name"
            }
            "id" {
                $filter_value = $id
                $filter_attribute = "id"
            }
            default { }
        }

        #if filter value and filter_attribute, add filter (by default filter_type is equal)
        if ( $filter_value -and $filter_attribute ) {
            $invokeParams.add( 'filter_value', $filter_value )
            $invokeParams.add( 'filter_attribute', $filter_attribute )
            $invokeParams.add( 'filter_type', $filter_type )
        }

        $reponse = Invoke-FGTRestMethod -uri 'api/v2/cmdb/user/local' -method 'GET' -connection $connection @invokeParams
        $reponse.results
    }

    End {
    }
}