param (
    [String]$Hostname = "localhost",
    [String]$Port = "8080",
    [String]$Path = "/"
)

Import-Module $PSScriptRoot\Modules\Processor.psm1

$Listener = New-Object System.Net.HttpListener
$Listener.Prefixes.Add("http://" + $Hostname + ":" + $Port + $Path)

try {
    
    $Listener.Start()

    while ($Listener.IsListening) {
    
        $ContextTask = $Listener.GetContextAsync()

        while (-not $ContextTask.AsyncWaitHandle.WaitOne(500)) { }

        Resolve-Endpoint($ContextTask.Result)
    
    }
}
finally {
    $Listener.Close()
    Remove-Module Processor
}