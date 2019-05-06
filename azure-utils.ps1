<#
.SYNOPSIS
Login to Azure as specific tenant.
.PARAMETER tenantId
The Tenant ID (Directory ID), which can be found in the properties of Active Directory.
#>
function Login($tenantId)
{
	Connect-AzAccount -Tenant $tenantId
}

<#
.SYNOPSIS
Set application settings of an app.
.PARAMETER resourceGroupName
The name of the app's resource group.
.PARAMETER appName
The name of the app.
.PARAMETER hash
A hash table containing all application settings to be set for the app. Use Get-AppSettings and update its values to be sure to not unintentionally lose any settings.
#>
function Set-AppSettings($resourceGroupName, $appName, $hash)
{
	Set-AzWebApp -ResourceGroupName $resourceGroupName -Name $appName -AppSettings $hash
}

<#
.SYNOPSIS
Get all application settings of an app.
.PARAMETER resourceGroupName
The name of the app's resource group.
.PARAMETER appName
The name of the app.
.LINK
https://blogs.msdn.microsoft.com/tfssetup/2016/05/20/accessingupdating-azure-web-app-settings-from-vsts-using-azure-powershell/
#>
function Get-AppSettings($resourceGroupName, $appName)
{
	$webappAdmin = Get-AzResource -ResourceGroupName $resourceGroupName -ResourceName $appName
	$appSettingList = $webApp.SiteConfig.AppSettings
	$hash = @{}
	ForEach ($kvp in $appSettingList) {
		$hash[$kvp.Name] = $kvp.Value
	}
	return $hash
}

<#
.SYNOPSIS
Create a SQL user with password for an existing database.
.PARAMETER connectionString
The connection string of the database for which the user should be created.
.PARAMETER dbUsername
The name of the user to be created.
.PARAMETER dbPassword
The password of the user to be created.
.PARAMETER role
The role which the user should be assigned to, e.g. db_owner, db_datareader, db_datawriter.
.LINK
https://blog.kloud.com.au/2016/04/12/creating-accounts-on-azure-sql-database-through-powershell-automation/
#>
function Create-DbUser($connectionString, $dbUsername, $dbPassword, $role)
{
	$connection = New-Object -TypeName System.Data.SqlClient.SqlConnection($connectionString)
	
	$queryCreateUser = "EXECUTE('CREATE USER [' + @username + '] WITH PASSWORD = ''' + @password + '''')"
	$commandCreateUser = New-Object -TypeName System.Data.SqlClient.SqlCommand($queryCreateUser, $connection)
	$username = New-Object -TypeName System.Data.SqlClient.SqlParameter("@username", $dbUsername)
	$commandCreateUser.Parameters.Add($username)
	$password = New-Object -TypeName System.Data.SqlClient.SqlParameter("@password", $dbPassword)
	$commandCreateUser.Parameters.Add($password)
	
	$queryAddRole = "EXECUTE('EXEC sp_addrolemember ''' + @role + ''', ''' + @username + '''')"
	$commandAddRole = New-Object -TypeName System.Data.SqlClient.SqlCommand($queryAddRole, $connection)
	$paramUsername = New-Object -TypeName System.Data.SqlClient.SqlParameter("@username", $dbUsername)
	$commandAddRole.Parameters.Add($paramUsername)
	$paramRole = New-Object -TypeName System.Data.SqlClient.SqlParameter("@role", $role)
	$commandAddRole.Parameters.Add($paramRole)
	
	$connection.Open()
	$commandCreateUser.ExecuteNonQuery()
	$commandAddRole.ExecuteNonQuery()
	$connection.Close()
}
