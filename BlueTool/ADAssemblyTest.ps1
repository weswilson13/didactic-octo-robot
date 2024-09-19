Add-Type -AssemblyName System.DirectoryServices.AccountManagement

$objPrincipal = [System.DirectoryServices.AccountManagement.Principal]::FindByIdentity([System.DirectoryServices.AccountManagement.ContextType]::Domain,'svc_mssqlserver')
$objPrincipal
