# ModulePath

This module can be used to get and set the new PSModulePath setting in PowerShell 7, which allows you to set your PSModulePath default directory. This is useful for targeting modules outside of OneDrive.

Please note that `PSGet/PSResourceGet` do not have native support for this new directory, and you will need to use Save-Module instead of Install-Module. As an alternative, consider [ModuleFast](https://github.com/justingrote/modulefast) which has native support and detection for powershell.config.json.

## Quick Start

```powershell
#Returns nothing if your powershell.config.json has not been configured yet
Get-PSModulePathConfig 

#Preview setting the module path to this, optionally creating it if it doesn't exist. 
Set-PSModulePathConfig -Path '%LOCALAPPDATA%\powershell\Modules' -Whatif 

#Apply the setting. Optionally specify -AllUsers to specify it at the PowerShell level (usually requires admin rights unless powershell is locally installed into your users directory)
Set-PSModulePathConfig -Path '%LOCALAPPDATA%\powershell\Modules' # Sets the module path for the user

#Gets your current active primary PSModulePath. Note that a restart of PowerShell is required for the above to take effect.
Get-PSModulePath
Get-PSModulePath -AllUsers
```
