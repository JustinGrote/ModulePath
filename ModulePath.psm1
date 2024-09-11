#requires -Version 7.2
$ErrorActionPreference = 'Stop'

function Get-ModulePathConfig {
	<#
	.SYNOPSIS
	Gets the current PSModulePath configuration from powershell.config.json. Returns null if no path detected
	.LINK
	https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_powershell_config?view=powershell-7.4
	#>

	$allUsersBasePath = $PSHOME
	$currentUserBasePath = (Split-Path $profile.CurrentUserAllHosts)

	$configPaths = @{}
	foreach ($directory in $allUsersBasePath, $currentUserBasePath) {
		$configPath = Join-Path $directory 'powershell.config.json'
		if (Test-Path $configPath) {
			$config = Get-Content $configPath | ConvertFrom-Json -AsHashtable
			if ($config.PSModulePath) {
				$configPaths.$configPath = $config.PSModulePath
			}
		}
	}

	return [pscustomobject]$configPaths
}

function Set-ModulePathConfig {
	<#
	.SYNOPSIS
	Set the PSModulePath for the current user or all users in powershell.config.json
	.LINK
	https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_powershell_config?view=powershell-7.4
	#>
	[CmdletBinding(SupportsShouldProcess)]
	param(
		#Specify the path that you wish to become the primary PSModulePath
		[Parameter(Mandatory = $true)]
		[string]$Path,
		#Specify if you wish to set the PSModulePath at the PowerShell directory for all users, rather than for your user
		[Switch]$AllUsers,
		#If specified, we will not try to create the folder if it does not exist. You will need to create it yourself separately or PowerShell may not behave properly.
		[Switch]$NoCreate
	)

	$ConfigBasePath = $AllUsers ? $PSHOME : (Split-Path $profile.CurrentUserAllHosts)
	$ConfigPath = Join-Path $ConfigBasePath 'powershell.config.json'

	$Config = if (Test-Path $ConfigPath) {
		Get-Content $ConfigPath | ConvertFrom-Json -AsHashtable
	} else {
		$createConfig = $true
	}

	$Config ??= @{}
	$Config.PSModulePath = $Path

	# Resolve environment variables in the provided path
	$ResolvedPath = [Environment]::ExpandEnvironmentVariables($Path)

	if (-not (Test-Path $ResolvedPath) -and -not $NoCreate) {
		if ($PSCmdlet.ShouldProcess($ResolvedPath, "Create Directory")) {
			New-Item $ResolvedPath -ItemType Directory -Force | Out-Null
		}
	}

	if (-not $PSCmdlet.ShouldProcess($ConfigPath, "Set PSModulePath to $Path")) {
		return
	}

	if ($createConfig) {
		#Will create any directories required along the path too in the event they don't exist
		New-Item $ConfigPath -ItemType File -Force | Out-Null
	}

	$Config
	| ConvertTo-Json -Depth 10
	| Out-File -Encoding UTF8 -LiteralPath $ConfigPath -Force
}


function Get-ModulePath ([Switch]$AllUsers) {
	<#
	.SYNOPSIS
	Get the PSModulePath for the current user or all users, taking powershell.config.json into account.

	.NOTES
	This uses a private API to get the PSModulePath for the current user or all users. This will hopefully be replaced with a public API in the future: https://github.com/PowerShell/PowerShell/issues/24274
	#>
	$scopeType = [Management.Automation.Configuration.ConfigScope]
	$pscType = $scopeType.
	Assembly.
	GetType('System.Management.Automation.Configuration.PowerShellConfig')

	$pscInstance = $pscType.
	GetField('Instance', [Reflection.BindingFlags]'Static,NonPublic').
	GetValue($null)

	$getModulePathMethod = $pscType.GetMethod('GetModulePath', [Reflection.BindingFlags]'Instance,NonPublic')

	if ($AllUsers) {
		$getModulePathMethod.Invoke($pscInstance, $scopeType::AllUsers) ?? [Management.Automation.ModuleIntrinsics]::GetPSModulePath('BuiltIn')
	} else {
		$getModulePathMethod.Invoke($pscInstance, $scopeType::CurrentUser) ?? [Management.Automation.ModuleIntrinsics]::GetPSModulePath('User')
	}
}