$htmlCatalog = Invoke-WebRequest -Uri "https://boards.4chan.org/wg/catalog"

If (Test-Path -Path "index.html" -PathType leaf) {
    Remove-Item -Path "./index.html"
}

If (-not (Get-Module -ErrorAction Ignore -ListAvailable ThreadJob )) {
    Install-Module -Name ThreadJob -Scope CurrentUser
}

New-Item .\index.html -ItemType "file" | out-null
Set-Content .\index.html -Value $htmlCatalog

$htmlParsed = ConvertFrom-Html -Path $pwd/index.html
$aLink = $htmlParsed.SelectNodes("//script")   

$positionSlashA = $aLink[4].InnerText.IndexOf("var catalog = {")
$result1 = $aLink[4].InnerText.Substring($positionSlashA + 14)
$positionfirstspace = $result1.IndexOf("};")
$text = $result1.Substring(0, $positionfirstspace) + "}"
$json = ConvertFrom-Json $text

$val = $json.threads -replace "[^0-9\s]"
$val2 = $val.Split(" ")

ForEach ($siteItem in $val2) {
    If (Test-Path -Path "index.html" -PathType leaf) {
        Remove-Item -Path "./index.html"
    }

    $newSiteUrl = "https://boards.4chan.org/wg/thread/" + $siteItem
    $html = Invoke-WebRequest -Uri $newSiteUrl

    If (-not (Get-Module -ErrorAction Ignore -ListAvailable PowerHTML)) {
        Write-Verbose "Installing PowerHTML module for the current user..."
        Install-Module PowerHTML -ErrorAction Stop
    }

    Import-Module -ErrorAction Stop PowerHTML  

    New-Item .\index.html -ItemType "file" | out-null
    Set-Content .\index.html -Value $html

    $htmlParsed = ConvertFrom-Html -Path $pwd/index.html
    $aLink = $htmlParsed.SelectNodes("//a[contains(@class, 'fileThumb')]")
    
    $aLink  | Foreach-Object -ThrottleLimit 50 -Parallel {
        $counter = Get-Random

        $dataAtual = Get-Date -Format "yyyy-MM-dd"
        $folderName = "./4chan_images/" + $dataAtual + "/" + $using:siteItem
    
        If (-Not(Test-Path $folderName)) {
            New-Item $folderName -ItemType Directory
        }
        
        $filePath = $folderName + "/image_" + $counter.ToString() + ".jpg"
        $hrefValue = $_.GetAttributeValue("href", "")
        
        $newUrl = $hrefValue.replace("//", "https://")
        
        Invoke-WebRequest $newUrl -OutFile $filePath
        Write-Host "File saved with success in " $filePath
    }    
}

Write-Host "All done ✅"

