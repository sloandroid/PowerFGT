
#
# Copyright 2018, Alexis La Goutte <alexis dot lagoutte at gmail dot com>
#
# SPDX-License-Identifier: Apache-2.0
#

function ConvertTo-netmask2cidr {

    param (
            [String]$netmask
    )
    switch ($netmask)
    {
        "255.0.0.0" {"8"}
        "255.128.0.0" {"9"}
        "255.192.0.0" {"10"}
        "255.224.0.0" {"11"}
        "255.240.0.0" {"12"}
        "255.248.0.0" {"13"}
        "255.252.0.0" {"14"}
        "255.254.0.0" {"15"}
        "255.255.0.0" {"16"}
        "255.255.128.0" {"17"}
        "255.255.192.0" {"18"}
        "255.255.224.0" {"19"}
        "255.255.240.0" {"20"}
        "255.255.248.0" {"21"}
        "255.255.252.0" {"22"}
        "255.255.254.0" {"23"}
        "255.255.255.0" {"24"}
        "255.255.255.128" {"25"}
        "255.255.255.192" {"26"}
        "255.255.255.224" {"27"}
        "255.255.255.240" {"28"}
        "255.255.255.248" {"29"}
        "255.255.255.252" {"30"}
        "255.255.255.254" {"31"}
        "255.255.255.255" {"32"}
        default {"0"}
    }
}


if (Get-Module -Name PowerFGT){

} elseif (Get-Module -ListAvailable -Name PowerFGT) {
#Check the availability of PowerFGT module (and load !)
    Import-Module PowerFGT
    Clear-Host

} else {
    Write-Error "Need to install PowerFGT Module (Install-Module PowerFGT)"
    exit
}

if (Get-Module -Name PowerNSX){

} elseif (Get-Module -ListAvailable -Name PowerNSX) {
#Check the availability of PowerFGT module (and load !)
    Import-Module PowerNSX
    Clear-Host

} else {
    Write-Error "Need to install PowerNSX Module (Install-Module PowerNSX)"
    exit
}

if($null -eq $DefaultFGTConnection){
    Write-Error "Need to connect to your Firewall (Connect-FGT....)"
    exit
}

if($null -eq $DefaultNSXConnection){
    Write-Error "Need to connect to your NSX (Connect-NSXServer -vCenter....)"
    exit
}


$objects = Get-FGTAddress


write-host "There is" $objects.count "objects on the Firewall"
$objet_ipmask = $objects | Where-Object {$_.type -eq "ipmask"}
write-host "There is" $objet_ipmask.count "objects ip mask on the Firewall"
$i = 0;

foreach ($object in $objet_ipmask) {

    $name  = $object.name
    $desc = $object.comment
    $ip = $object."start-ip"
    $mask =  $object."end-ip"
    $ipmask = $ip + "/ " + $mask

    $cidr = ConvertTo-netmask2cidr $mask
    if($cidr -ne '0' ) {
        $ipcidr = $ip + "/" + $cidr
        new-NsxIPSet -name $name -Description $desc -ip $ipcidr | Out-Null
        write-host "Convert" $object.name "(" $ipmask ") to NSX..."
        $i++
    } else {
        write-warning "Impossible to convert $name ( $ipmask ) => wrong mask"
    }
}
write-host "There is" $i "object(s) converted"