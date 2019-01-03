# SecureAuth Configuration Integrity Check
# by John Morgan 1/3/2019 Kelsey-Seybold Clinic
#
# This script expects to sit on the root of the D: drive.
# The script is also expecting Secureauth to be installed
# in d:\secureauth.  If you've installed SecureAuth
# elsewhere, or don't have a useable D: drive, modify the
# script to match your system.
#
# The best way to use this script is as a scheduled task.
# Resource use is not high, but I would suggest running
# daily or hourly as opposed to every minute.

# Get the perevious results.
$oldFiles = Import-csv 'd:\result.csv'

# Get the hashes of all the web.config files in each realm.
$newFiles = get-FileHash "D:\SecureAuth\SecureAuth*\web.config" -Algorithm MD5

# Iterate through each file and see if the hashes match the pervious run.
# If any of the hashes do not match, the files have been altered.
$newFiles | %{

    # Break out the path and hash of the current file.
    $currentPath = $_.Path
    $currentHash = $_.Hash

    # Get the record from the last run coresponding to the path
    # of the file we are currently testing.
    $oldFile = $oldFiles | Where-Object {$_.Path -eq $currentPath}

    # Copy the hash into its own variable.
    $oldHash = $oldFile.Hash
    
    # Compare the hash of the current file to the last time we saw it.
    if($oldHash -eq $currentHash){
        $match = "MATCH"
    }else{
        $match = " MODIFIED! "
        # If the configuration has been modified write to the event log.
        # Powershell was griping about using a custom name, so I used
        # The SecureAuth Backup Tool as the source, becasue the log source
        # can be guaranteed to be valid on any system running SecureAuth
        Write-EventLog -LogName "Application" -Source "SecureAuth Backup Tool" -EventId 666 -EntryType Warning -Message "$($currentPath), $($match),$($oldHash),$($currentHash)"
    }
    # If we need a line by line comparison for script testing we can
    # enable the line below.
    #Write-Output "$($currentPath),$($currentHash),$($oldHash),$($match)"
}

# Write the current hashes out to a file so we can reference them on the
# next run of the script.
$newFiles | Export-Csv -Path 'D:\result.csv'