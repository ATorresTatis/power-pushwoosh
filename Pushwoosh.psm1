$Script:PushwooshEndPoint = 'https://cp.pushwoosh.com/json/1.3/'

<#
.SYNOPSIS
Creates a new push notification and sends it to a device.

.DESCRIPTION
Creates a new push notification. The total size of the POST request must not exceed 10Mb. When a request contains less than 10 device tokens to Pushwoosh API, the server returns the “CODE_NOT_AVAILABLE” value for “Messages”. See http://docs.pushwoosh.com/docs/createmessage

.EXAMPLE
New-PushwooshSession -ApiAccessToken 'YOUR_API_ACCESS_TOKEN' -ApplicationCode 'YOUR_APP_CODE' | Send-PushMessage -Message 'Hello World' -PushTokenDevice 'YOUR_PUSH_TOKEN_DEVICE'
Send a push message to a single device.

.EXAMPLE
New-PushwooshSession -ApiAccessToken 'YOUR_API_ACCESS_TOKEN' -ApplicationCode 'YOUR_APP_CODE' | Send-PushMessage -Message 'Hello World' -PushTokenDevice 'YOUR_PUSH_TOKEN_DEVICE_1','YOUR_PUSH_TOKEN_DEVICE_2'
Send a push message to a set of devices.

.PARAMETER InputObject
Object returned by New-PushwooshSession cmdlet.

.PARAMETER Message
Text push message.

.PARAMETER PushTokenDevice
Device push token to receive the message. See: http://docs.pushwoosh.com/docs/registerdevice

.INPUTS
You can pipe the object returned by New-PushwooshSession cmdlet.

.OUTPUTS
PSCustomObject with status properties which describe operation results.

.LINK
New-PushwooshSession
#>
function Send-PushwooshMessage
{
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    Param
    (
        [Parameter(Mandatory,ValueFromPipeline)]
        [ValidateNotNull()]
        [PSCustomObject]
        $InputObject,        

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Message,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $PushTokenDevice
    )

    Process
    {
        # See: http://docs.pushwoosh.com/docs/createmessage => Request section
        $Body = [PSCustomObject]@{request= @{
            application=$InputObject.ApplicationCode;
            auth=$InputObject.ApiAccessToken;
            notifications=@(@{
				send_date='now';
				ignore_user_timezone=$true;
				content=$Message;
				devices=@($PushTokenDevice)}
			)}
		}

        $CreateMessageUri = New-Object -TypeName System.Uri -ArgumentList ($Script:PushwooshEndPoint + 'createMessage')
        $WebClient = New-Object -TypeName System.Net.WebClient

        if (-not [string]::IsNullOrEmpty($InputObject.ProxyServer))
        {        
            Write-Verbose -Message "Setting proxy $($InputObject.ProxyServer)"
            $WebClient.Proxy = New-Object -TypeName System.Net.WebProxy -ArgumentList $InputObject.ProxyServer
        }
        
        $WebClient.Encoding = [System.Text.Encoding]::UTF8
        $WebClient.Headers.Add([System.Net.HttpRequestHeader]::ContentType, "application/json")
        $RawBody = ($Body | ConvertTo-Json -Depth 5 -Compress)

        Write-Verbose -Message $CreateMessageUri.AbsoluteUri
        Write-Verbose -Message $RawBody

        $Response = $WebClient.UploadString($CreateMessageUri, $RawBody)
        ($Response | ConvertFrom-Json) | Write-Output
    }
}


<#
.SYNOPSIS
Sets the information required to initialize a Pushwoosh session.

.DESCRIPTION
Create a PSCustomObject to set the information required to initialize a Pushwoosh session.

.PARAMETER ApiAccessToken
The API Access Token provided by Pushwoosh. See https://cp.pushwoosh.com/v2/api_access

.PARAMETER ApplicationCode
The Application code provided by Pushwoosh. See https://cp.pushwoosh.com/v2/applications

.PARAMETER ProxyServer
The proxy server Url to connect to Internet (if any).

.EXAMPLE
New-PushwooshSession -ApiAccessToken 'YOUR_API_ACCESS_TOKEN' -ApplicationCode 'YOUR_APP_CODE'

.EXAMPLE
New-PushwooshSession -ApiAccessToken 'YOUR_API_ACCESS_TOKEN' -ApplicationCode 'YOUR_APP_CODE' -ProxyServer 'http://192.168.0.1:123'

.INPUTS
None.

.OUTPUTS
PSCustomObject with ApiAccessToken, ApplicationCode and ProxyServer properties initialised.

.LINK
Send-PushwooshMessage
#>
function New-PushwooshSession
{
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    Param
    (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ApiAccessToken,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ApplicationCode,

        [Parameter()]
        [string]
        $ProxyServer=([System.Net.WebProxy]::GetDefaultProxy().Address.AbsoluteUri)
    )
   
    if (-not [string]::IsNullOrEmpty($ProxyServer))
    {
        if ($ProxyServer.EndsWith('/'))
        {
            $ProxyServer = $ProxyServer.Substring(0,$ProxyServer.Length -1)
        }
    }

    $SessionInfo = [PSCustomObject]@{
		ApiAccessToken=$ApiAccessToken; 
		ApplicationCode=$ApplicationCode; 
		ProxyServer=$ProxyServer}
		
	Write-Verbose -Message ($SessionInfo | Format-List | Out-String)
	Write-Output -InputObject $SessionInfo
}
