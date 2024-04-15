function Get-PSAOAIBanner {
    param (
        
    )
    
    $banner = get-content -Path "$PSScriptRoot\..\images\banner.txt" -Raw
    write-Host $banner

}
