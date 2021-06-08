class Endpoint {
    [String]$Route
    [String]$Method
    [ScriptBlock]$Action
}

$Endpoints = @(

    [Endpoint]@{
        Route = "/sample/get"
        Method = "GET"
        Action = {
            $ht = $args[0]
            
            if ($ht -eq $null) {
                Write-Output "Sample Text"
            }
            else {
                Write-Output $ht
            }
        }
    }
   
    [Endpoint]@{
        Route = "/sample/post"
        Method = "POST"
        Action = {
            $obj = $args[0]

            Write-Output ("First Name: " + $obj.First + " Last Name: " + $obj.Last)
        }
    }
)

Export-ModuleMember -Variable Endpoints