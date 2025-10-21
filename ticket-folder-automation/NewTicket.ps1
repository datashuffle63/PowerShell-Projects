<#
#####
Ticket Project Automation Script
#####
.SYNOPSIS
    This script automates the creation of project folder structures for new tickets.
.DESCRIPTION
    When a new ticket is created, this script generates a standardized folder structure
    to help organize files related to the ticket.
#>

# variables
$configFilePath = "C:\Path\To\ConfigFile.json"  # Path to configuration file

# Prompt user for the year-month effective of the ticket

# Prompt user for the Account name (Company who made the request)

# Get folder path of downloads relevant to the ticket request from config file

# Get folder path of target projects directory from config file

# Create new folder structure for the ticket

# Root Ticket Folder (YYYYMM_Account)

# Subfolders: (01_Source, 02_Working, 03_Final)

# Subfolders: (02_Working) -> (_census, _invoice)

# Subfolders: (03_Final) -> (_merge)
