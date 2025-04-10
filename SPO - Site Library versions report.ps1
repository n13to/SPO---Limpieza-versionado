#Import SharePoint Online module
Import-Module Microsoft.Online.SharePoint.Powershell
  
Function Generate-VersionHistoryReport()
{
  param
    (
        [Parameter(Mandatory=$true)] [string] $SiteURL,
        [Parameter(Mandatory=$true)] [string] $ReportOutput
    )
    Try {
        #Setup the context
        $Ctx = New-Object Microsoft.SharePoint.Client.ClientContext($SiteURL)
        $Ctx.Credentials = $Credentials
          
        #Get all subsites and Lists from the site
        $Web = $Ctx.Web
        $Ctx.Load($Web)
        $Ctx.Load($Web.Webs)
        $Lists = $Web.Lists
        $Ctx.Load($Lists)
        $Ctx.ExecuteQuery()
         
        Write-host -f Yellow "Processing Site: "$SiteURL
        #Exclude system lists
        $ExcludedLists = @("Access Requests","App Packages","appdata","appfiles","Apps in Testing","Cache Profiles","Composed Looks","Content and Structure Reports","Content type publishing error log","Converted Forms",
            "Device Channels","Form Templates","fpdatasources","Get started with Apps for Office and SharePoint","List Template Gallery", "Long Running Operation Status","Maintenance Log Library", ,"Master Docs","Master Page Gallery"
               "MicroFeed","NintexFormXml","Quick Deploy Items","Relationships List","Reusable Content","Reporting Metadata", "Reporting Templates", "Search Config List","Site Assets", "Site Pages", "Solution Gallery",
                    "Style Library","Suggested Content Browser Locations","Theme Gallery", "TaxonomyHiddenList","User Information List","Web Part Gallery","wfpub","wfsvc","Workflow History","Workflow Tasks")
      
        #Iterate through each list in a site and get versioning configuration
        ForEach($List in $Lists)
        {            
            if(($ExcludedLists -NotContains $List.Title) -and ($List.EnableVersioning) -and ($List.BaseType -eq "DocumentLibrary"))
            {
                Write-Host "`tProcessing Library:"$List.Title
                #Query to Batch process Items from the document library
                $Query =  New-Object Microsoft.SharePoint.Client.CamlQuery
                $Query.ViewXml = "<View Scope='RecursiveAll'><Query><OrderBy><FieldRef Name='ID' /></OrderBy></Query><RowLimit>2000</RowLimit></View>"
                 
                $VersionHistoryData = @()
                Do {
                    $ListItems=$List.GetItems($Query)
                    $Ctx.Load($ListItems)
                    $Ctx.ExecuteQuery()
                    $Query.ListItemCollectionPosition = $ListItems.ListItemCollectionPosition
 
                    #Iterate throgh each version of file
                    $VersionHistoryData = @()
                    #Iterate throgh each file - Excluding Folder Objects
                    Foreach ($Item in $ListItems | Where { $_.FileSystemObjectType -eq "File"})
                    {
                        $File = $web.GetFileByServerRelativeUrl($Item["FileRef"])
                        $Ctx.Load($File)
                        $Ctx.Load($File.Versions)
                        $Ctx.ExecuteQuery()
  
                        If($File.Versions.Count -ge 1)
                        {
                            $VersionSize=0 
                            #Calculate Version Size
                            Foreach ($Version in $File.Versions)
                            {
                                $VersionSize = $VersionSize + $Version.Size
                            }
  
                            #Send Data to object array
                            $VersionHistoryData += New-Object PSObject -Property @{
                            'Site' = $SiteURL
                            'Library' = $List.Title
                            'File Name' = $File.Name
                            'Version Count' = $File.Versions.count
                            'Version Size-KB' = ($VersionSize/1024)
                            'URL' = $SiteURL+$File.ServerRelativeUrl
                            }
                        }
                    }
                } While ($Query.ListItemCollectionPosition -ne $null)
 
                #Export the data to CSV
                $VersionHistoryData | Export-Csv $ReportOutput -Append -NoTypeInformation
            }
        }
  
        #Iterate through each subsite in the current web
        Foreach ($Subweb in $Web.Webs)
        {
            #Call the function recursively to process all subsites underneaththe current web
            Generate-VersionHistoryReport -SiteURL $Subweb.URL -ReportOutput $ReportOutput
        }
     }
    Catch {
        write-host -f Red "Error Generating version History Report!" $_.Exception.Message
    } 
}
  
#Set parameter values
$SiteURL="https://Crescent.sharepoint.com/sites/marketing"
$ReportOutput="C:\Temp\VersionHistoryRpt.csv"
  
#Get Credentials to connect
$Cred= Get-Credential
$Credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($Cred.Username, $Cred.Password)
  
#Delete the Output report file if exists
If (Test-Path $ReportOutput) { Remove-Item $ReportOutput }
  
#Call the function to generate version History Report
Generate-VersionHistoryReport -SiteURL $SiteURL -ReportOutput $ReportOutput