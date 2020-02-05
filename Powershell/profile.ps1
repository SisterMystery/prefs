
Set-PSReadLineOption -EditMode Vi
Set-PSReadlineKeyHandler -Chord "j" -ScriptBlock { 
    $key = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").Character 
    if ($key -eq "k") { 
        [Microsoft.PowerShell.PSConsoleReadLine]::ViCommandMode() 
    } else {      
   [Microsoft.PowerShell.PSConsoleReadLine]::Insert('j')     
    [Microsoft.PowerShell.PSConsoleReadLine]::Insert($key)   
  }
 }
Set-PSReadLineOption -HistorySearchCursorMovesToEnd
Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward

$GLOBAL:dirHistory = @{};
$GLOBAL:lastDir = "";

function Get-NestLevel {
    $currentPid = $pid;
    $nestLevel = 0;
    $processes = Get-CimInstance -Class Win32_Process -Filter "Name = 'powershell.exe'"  
    $currentProcess = $processes | ? { $_.ProcessId -match $currentPid }
    while($processes.ProcessId.Contains($currentProcess.ParentProcessId)){
        $nestLevel ++;
        $currentProcess = $processes | ? { $_.ProcessId -match $currentProcess.ParentProcessId }
    }
    return $nestLevel
}

function Get-SoftRandomString {
Param([int]$length)
return -Join ((65..90) + (97..122) + (48..57) | Get-Random -Count $length | % {[char]$_})
}

$GLOBAL:lastTime = get-date;
function foxy_history_prompt {

    $here = $(Get-Location).Path;
    If($here -ne $GLOBAL:lastDir){
        If($GLOBAL:dirHistory[$here] -eq $null){
            $GLOBAL:dirHistory[$here] = 1;
        } Else {
            $GLOBAL:dirHistory[$here] ++;
        }
    }
    $GLOBAL:lastDir = $here;
    
    "$(get-date -Format "HH:mm:ss") $(Get-Location) <$('3' * ($nestedPromptLevel + 1)) ";
}
set-item Function:\prompt -Value foxy_history_prompt -Force

function cb {
    [CmdletBinding()]
    Param($oldDir)
    process {
        cd $oldDir
    }
}

Register-ArgumentCompleter -ParameterName oldDir -ScriptBlock {
            param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

            $GLOBAL:dirHistory.Keys |
            Where-Object { $l =  $_.Split('\'); return $l[$l.Count -1] -like "$wordToComplete*" } |
            Sort-Object -Property @{Expression={$GLOBAL:dirHistory[$_.Path]}}| 
            ForEach-Object {
                [System.Management.Automation.CompletionResult]::new($_, $_, 'Text', $_) 
            }
}

function tn { 
    Set-PSReadlineKeyHandler -Key Tab -Function TabCompleteNext
}

function Write-Function {
    param($in)
    Add-Content $PROFILE "`nfunction $((Get-Command $in).name) {" -NoNewLine
    Add-Content $PROFILE (Get-Command $in).Definition -NoNewLine
    Add-Content $PROFILE "}`n" -NoNewLine
}

function Write-Profile {
  param($in)
  Add-Content $PROFILE "`n$in" -NoNewLine
}

function clean-transcript {
param($path)
(Get-Content $path) | ? {$_ -match "^PS>(.+$)" }| %{$matches[1]}
}

function touch {
param($file)
echo $null >> $file
}
