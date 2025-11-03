<#
#####
Ticket Project Automation Script
#####
.SYNOPSIS
    This script automates the creation of project folder structures for new tickets.

.DESCRIPTION
    When a new ticket is created, this script generates a standardized folder structure
    to help organize files related to the ticket.

.PARAMETER TicketType
    The type of ticket request being created (e.g., "Audit", "CarrierImplementation").

.PARAMETER AccountName
    The name of the account or company requesting the ticket.

.PARAMETER IncludeSourceFiles
    Switch to enable moving source files from the Staging folder into the Ticket folder.

.EXAMPLE
    .\NewTicket.ps1 -TicketType Audit -AccountName "HOSC"
    
.EXAMPLE
    .\NewTicket.ps1 -TicketType Audit -AccountName "HOSC" -IncludeSourceFiles

#>

# parameters
param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("Audit", "CarrierImplementation")]
    [string]$TicketType,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$AccountName,

    [Parameter(Mandatory=$false)]
    [switch]$IncludeSourceFiles  
)


# init variables
[string]$configFilePath = Join-Path -path $PSScriptRoot -ChildPath "config.json"        # Path to configuration file using script root
[string]$YearMonthDay = Get-Date -Format "yyyyMMdd"                                    # Current date in YYYYMMDD format
[string]$Year = $YearMonthDay.Substring(0, 4)                                          # Current year in YYYY format

# try reading config file
try {
    $configFile = Get-Content -Path $configFilePath -Raw -ErrorAction Stop | ConvertFrom-Json
}
catch {
    Write-Host "Error: Unable to read configuration file at path: $configFilePath." -ForegroundColor Red
    exit 1
}


# Get folder path of downloads relevant to the ticket request from config file
$projectBasePath = switch ($TicketType) {
    "Audit" { $configFile.basePathAudit }
    "CarrierImplementation" { $configFile.basePathCarrierImplementation }
    default { 
        Write-Host "Invalid TicketType ($TicketType) specified. Valid types: Audit, CarrierImplementation" -ForegroundColor Red
        exit 1
    }
}

# Ensure base path exists -- terminate otherwise
if (-not (Test-Path $projectBasePath)){
    Write-Host "Error: The base path for $TicketType tickets does not exist: $projectBasePath" -ForegroundColor Red
    exit 1
}


# Get folder path of target projects directory from config file
[string]$projectBasePathYear = Join-Path -Path $projectBasePath -ChildPath $Year

# Root Ticket Folder (YYYYMM_Account)
[string]$projectFolderName = $configFile.folderNameFormat -replace "{YearMonthDay}", $YearMonthDay -replace "{Account}", $AccountName
[string]$projectFullPath = Join-Path -Path $projectBasePathYear -ChildPath $projectFolderName

try {

    # Create new folder structure for the ticket
    Write-Host "📁 Creating folder and subfolders..." -ForegroundColor Cyan
    New-Item -Path $projectFullPath -ItemType Directory -Force -ErrorAction Stop | Out-Null

}
catch {
    Write-Host "Error: An error occurred while creating main project folder: $_" -ForegroundColor Red
    exit 1
}

# Subfolders: (01_Source, 02_Working, 03_Final) -- non-terminating errors
foreach ($subFolder in $configFile.subFolders){

    [string]$subFolderPath = Join-Path -Path $projectFullPath -ChildPath $subFolder.name
    New-Item -Path $subFolderPath -ItemType Directory -Force | Out-Null

    # Create any nested subfolders (e.g. _ census, _invoice, _merge)
    foreach ($nestedSubFolder in $subFolder.subFolders){
        [string]$nestedSubFolderPath = Join-Path -Path $subFolderPath -ChildPath $nestedSubFolder
        New-Item -Path $nestedSubFolderPath -ItemType Directory -Force | Out-Null
    }
}

# Optionally copy source files from Staging folder to Ticket folder
if ($IncludeSourceFiles) {
    [string]$stagingFolderPath = $configFile.stagingFolder
    [string]$sourceDestinationPath = Join-Path -Path $projectFullPath -ChildPath "01_Source"

    # Ensure staging folder exists
    if (-not (Test-Path $stagingFolderPath)){
        Write-Host "Warning: Staging folder does not exist at path: $stagingFolderPath. Skipping file transfer." -ForegroundColor Yellow
    }
    elseif (-not (Get-ChildItem -Path $stagingFolderPath -ErrorAction SilentlyContinue)){
        Write-Host "Warning: Staging folder is empty at path: $stagingFolderPath. Skipping file transfer." -ForegroundColor Yellow
    }
    else {
        Write-Host "📂 Moving source files from Staging to Ticket folder..." -ForegroundColor Cyan
        Move-Item -Path (Join-Path -Path $stagingFolderPath -ChildPath "*") -Destination $sourceDestinationPath -Recurse -Force
        Write-Host "   ✅ File transfer completed" -ForegroundColor Green
    }
}
else {
    Write-Host "💡 Tip: Use -IncludeSourceFiles to auto-move files from staging folder" -ForegroundColor Gray
}

# prompt user of completion
Write-Host "✅ Project folder structure created at: $projectFullPath" -ForegroundColor Green
Write-Host "   (Check above for any subfolder creation errors)" -ForegroundColor Gray