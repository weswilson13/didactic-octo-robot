[CmdletBinding()]
param (
    [string]$SwitchName,

    [ValidateSet('C9300-24T', 'C9300-48T')]
    [string]$Model,

    [validatescript( { $_.PSObject.Properties.Name -match 'DefaultGateway|SubnetMask|IPAddress' } )]
    [psobject]$NetworkSettings
)

function ConfigurationBuilder ($configPath) {

    Add-Type -AssemblyName System.Configuration

    # # Set this to the full path of your App.config
    # $configPath = "$PSScriptRoot\App.config"

    [System.AppDomain]::CurrentDomain.SetData("APP_CONFIG_FILE", $configPath)
    [Configuration.ConfigurationManager].GetField("s_initState", "NonPublic, Static").SetValue($null, 0)
    [Configuration.ConfigurationManager].GetField("s_configSystem", "NonPublic, Static").SetValue($null, $null)
    ([Configuration.ConfigurationManager].Assembly.GetTypes() | 
        Where-Object {$_.FullName -eq "System.Configuration.ClientConfigPaths"})[0].GetField("s_current", "NonPublic, Static").SetValue($null, $null)

    return @{ 
        AppSettings=[System.Configuration.ConfigurationManager]::AppSettings
        ConnectionStrings=[System.Configuration.ConfigurationManager]::ConnectionStrings
    }
}

# load common parameters
$config = ConfigurationBuilder "$PSScriptRoot\Switches.config"

$configOutput = $config.AppSettings['OutputPath']
$templatePath = $config.AppSettings['TemplatePath']

$switch = @{Name = $SwitchName; Model = $Model}

$network = switch ($SwitchName) {
    { $_.StartsWith('NNPTC') } { 'NNPP'; break }
    { $_.StartsWith('PTCL') } { 'NNTP'; break }
    Default { Write-Error "Switch name must start with 'NNPTC' or 'PTCL'." }
}

$_switchName = $SwitchName
if($network -eq 'NNTP') { $_switchName = "$($SwitchName).nntp.gov"}

# check if NetworkSettings was provided and contains an IPAddress
if ($NetworkSettings.PSObject.Properties.Name -contains 'IPAddress') { # use the provided IP address
    if (!($dnsEntry = [System.Net.Dns]::GetHostEntry($NetworkSettings.IPAddress))) {
        Throw "DNS entry for $($NetworkSettings.IPAddress) not found. Verify the IP Address and/or check DNS, and try again."
    }
}
else { # resolve the switch name to an IP address using DNS
    if (!($dnsEntry = [System.Net.Dns]::GetHostEntry($_switchName))) {
        Throw "DNS entry for $SwitchName not found. Verify the switch name and/or check DNS, and try again."
    }
}

$ipAddress = $dnsEntry.AddressList.IPAddressToString

# check if NetworkSettings was provided and contains a DefaultGateway
if ($NetworkSettings.PSObject.Properties.Name -contains 'DefaultGateway') { # use the provided DefaultGateway
    $defaultGateway = $NetworkSettings.DefaultGateway
}
else { # determine the DefaultGateway based on the IP address and config settings
    $subnet = $ipAddress.Split('.')[2]
    if ($config.AppSettings["${network}_Gateway_$subnet"]) {
        $defaultGateway = $config.AppSettings["${network}_Gateway_$subnet"]
    }
    elseif ($config.AppSettings["DefaultGatewayIP"]) { # use the default gateway in the switches subnet
        $defaultGateway = $ipAddress -replace '(.*)\.(.*)$', ('$1.' + $config.AppSettings["DefaultGatewayIP"])
    }
    else { # default to .251 if nothing else is configured
        $defaultGateway = $ipAddress -replace '(.*)\.(.*)$', ('$1.251') 
    }
}

# check if NetworkSettings was provided and contains a SubnetMask
if ($NetworkSettings.PSObject.Properties.Name -contains 'SubnetMask') { # use the provided SubnetMask
    $subnetMask = $NetworkSettings.SubnetMask
}
elseif ($config.AppSettings["SubnetMask"]) { # use the default SubnetMask from config
    $subnetMask = $config.AppSettings["SubnetMask"]
}
else { # default to
    $subnetMask = '255.255.255.0'
}

$switch.Add('FQDN', $dnsEntry.HostName)
$switch.Add('IPAddress', $ipAddress)
$switch.Add('DefaultGateway', $defaultGateway)
$switch.Add('SubnetMask', $subnetMask)

$template = "{0}\_{1}.conf" -f $templatePath, $Model

$switchConfig = Get-Content $template -Raw
$switchConfig = $switchConfig -replace '<SWITCHNAME>', $switch.Name
$switchConfig = $switchConfig -replace '<IPADDRESS>', $switch.IPAddress
$switchConfig = $switchConfig -replace '<SUBNETMASK>', $switch.SubnetMask
$switchConfig = $switchConfig -replace '<DEFAULTGATEWAY>', $switch.DefaultGateway

Set-Content -Path "$($switch.Name).txt" -Value $switchConfig
Write-Output "Configuration file '$($switch.Name).txt' created successfully."