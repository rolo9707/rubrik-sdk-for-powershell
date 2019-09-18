#requires -Version 3
function Get-RubrikUser
{
  <#  
      .SYNOPSIS
      Gets settings of a local Rubrik user

      .DESCRIPTION
      The Get-RubrikUser cmdlet is used to query the Rubrik cluster to retrieve a list of settings around a local Rubrik user account.

      .NOTES
      Written by Mike Preston for community usage
      Twitter: @mwpreston
      GitHub: mwpreston

      .LINK
      http://rubrikinc.github.io/rubrik-sdk-for-powershell/reference/Get-RubrikUser.html

      .EXAMPLE
      Get-RubrikUser
      This will return settings of all of the user accounts configured within the Rubrik cluster.

      .EXAMPLE
      Get-RubrikUser -local
      This will return settings of all of the local user accounts configured within the Rubrik cluster.

      .EXAMPLE
      Get-RubrikUser -username 'john.doe'
      This will return settings for the user account with the username of john.doe configured within the Rubrik cluster.
  
      .EXAMPLE
      Get-RubrikUser -authDomainId '1111-222-333'
      This will return settings of all of the user accounts belonging to the specified authoriation domain.
  #>

  [CmdletBinding()]
  Param(
    # Username to filter on
    [Parameter(ParameterSetName='Query')] 
    [String] $Username,
    # AuthDomainId to filter on
    [Parameter(ParameterSetName='Query')]
    [Alias('auth_domain_id')] 
    [String]$authDomainId ,
    # Filter only by local users
    [Parameter(ParameterSetName='Query')]
    [Switch]$local,
    # User ID
    [Parameter(ParameterSetName='ID',Mandatory = $true)] 
    [String]$id,
    # Rubrik server IP or FQDN
    [Parameter(ParameterSetName='Query')]
    [Parameter(ParameterSetName='ID')]
    [String]$Server = $global:RubrikConnection.server,
    # API version
    [Parameter(ParameterSetName='Query')]
    [Parameter(ParameterSetName='ID')]
    [String]$api = $global:RubrikConnection.api
  )

  Begin {

    # The Begin section is used to perform one-time loads of data necessary to carry out the function's purpose
    # If a command needs to be run with each iteration or pipeline input, place it in the Process section
    
    # Check to ensure that a session to the Rubrik cluster exists and load the needed header data for authentication
    Test-RubrikConnection
    
    # API data references the name of the function
    # For convenience, that name is saved here to $function
    $function = $MyInvocation.MyCommand.Name
    
    # Retrieve all of the URI, method, body, query, result, filter, and success details for the API endpoint
    Write-Verbose -Message "Gather API Data for $function"
    $resources = Get-RubrikAPIData -endpoint $function
    Write-Verbose -Message "Load API data for $($resources.Function)"
    Write-Verbose -Message "Description: $($resources.Description)"
  
  }

  Process {
    if ($local) {
      $authDomainId = (Get-RubrikLDAP | Where {$_.domainType -eq 'LOCAL'}).id
    }
    $uri = New-URIString -server $Server -endpoint ($resources.URI)
    $uri = Test-QueryParam -querykeys ($resources.Query.Keys) -parameters ((Get-Command $function).Parameters.Values) -uri $uri
    $body = New-BodyString -bodykeys ($resources.Body.Keys) -parameters ((Get-Command $function).Parameters.Values)
    $result = Submit-Request -uri $uri -header $Header -method $($resources.Method) -body $body
    $result = Test-ReturnFormat -api $api -result $result -location $resources.Result
    $result = Test-FilterObject -filter ($resources.Filter) -result $result

    return $result
  } # End of process
} # End of function