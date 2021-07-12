Import-Module .\Modules\Router.psm1
function Resolve-Endpoint {
    
    param (
        [Parameter(Mandatory)][System.Net.HttpListenerContext]$Context
    )

    BEGIN {

        # Declare variables
        $Request = $Context.Request
        $Response = $Context.Response
        $Route = $Request.Url.LocalPath
        
        # Determine Endpoint
        $Endpoint = $Endpoints.Where({$_.Route -eq $Route -and $_.Method -eq $Request.HttpMethod})
    }

    PROCESS {

        # Endpoint validation
        if ($Endpoint.Count -le 0) {
            Write-Error ("Endpoint not found " + $Route)
            $Response.StatusCode = 404
            $Response.Close()
            return
        }
        elseif ($Endpoint.Count -ge 2) {
            Write-Error("Unexpected Endpoint response. Validate Router configuration")
            $Response.StatusCode = 500
            $Response.Close()
            return
        }
       
        Invoke-Endpoint -Context $Context -Endpoint $Endpoint

        return

    }
    
}

function Invoke-Endpoint {
    
    param (
        [Parameter(Mandatory)][System.Object]$Context,
        [Parameter(Mandatory)][System.Object]$Endpoint
    )

    BEGIN {
 
        # Declare variables
        $Request = $Context.Request
        $Response = $Context.Response
        
        # Read request body from client
        $RequestBody = (New-Object System.IO.StreamReader @($Request.InputStream, [System.Text.Encoding]::UTF8)).ReadToEnd()
    }
    
    PROCESS {

        # Validate Input
        try {
            Invoke-Deserialization -Data $RequestBody | Out-Null
        }
        catch {
            # If JSON invalid send HTTP 400
            Write-Error "Invalid JSON in Request Body"
            $Response.StatusCode = 400
            $Response.Close()
            return
        }


        # Return to client
        try {
            # Filter argument based on HTTP method
            if ($Request.HttpMethod -eq "GET") {
                $Data = $Endpoint.Action.Invoke((Resolve-QueryString -URL $Request.RawUrl))
            }
            elseif ($RequestBody.Length -ge 1) {
                $Data = $Endpoint.Action.Invoke((Invoke-Deserialization -Data $RequestBody))
            }
            else {
                Write-Error "Request provided values that were unexpected"
                $Response.StatusCode = 400
                $Response.Close()
                return
            }
            
            Send-Response -Data $Data -Response $Response
        }
        catch { 
            #Write-Error "Unable to execute Endpoint"
            Write-Output $_
            $Response.StatusCode = 500
            $Response.Close()
        }

        return
       
    }

}

function Send-Response {
    
    param (
        [Parameter(Mandatory)]$Data,
        [Parameter(Mandatory)][System.Object]$Response
    )

    PROCESS {
        # Convert endpoint response to Bytes for StreamWriter
        $Response.ContentEncoding = [System.Text.Encoding]::UTF8
        try {
            $Data = Invoke-Serialization -Data $Data
            $Buffer = [System.Text.Encoding]::UTF8.GetBytes($Data)
            $Response.OutputStream.Write($Buffer, 0, $Data.Length)
            $Response.Close()
        }
        catch {
            Write-Error "Unable to send response"
            $Response.StatusCode = 500
        }
        
        # Close response to send reply back to client
        $Response.Close()

    }

}

function Resolve-QueryString {

    param (
        [Parameter(Mandatory)][String]$URL
    )

    PROCESS {

        $ht = @{}

        $Buffer = $URL.IndexOf('?')
        $Buffer = $URL.Substring($Buffer + 1, $URL.Length - $Buffer - 1)
        $Buffer = $Buffer.Split('&').Split('=')

        # return if no query strings found
        if (($Buffer.Length % 2) -ne 0 -or -not($URL.Contains('?'))) {
            return
        }
        $i = 0
        1..($Buffer.Length / 2) | ForEach-Object {
            $ht.Add($Buffer[$i++],$Buffer[$i++])
        }

        return $ht

    }

}

function Invoke-Serialization {
    
    param (
        [Parameter(Mandatory)]$Data
    )

    PROCESS {
        return (ConvertTo-Json @($Data) -Compress)
    }

}

function Invoke-Deserialization {

    param (
        [Parameter(Mandatory)]$Data
    )

    PROCESS {
        return ($Data | ConvertFrom-Json)
    }

}

Export-ModuleMember -Function Resolve-Endpoint
