# Create Functions
function Invoke-FolderHashSummary {
    Param(
        [parameter(mandatory=$true)]
        $Path
        )
    # Gather files
    $myFiles = Get-ChildItem -Path($path) -File -Recurse
    # Format the file size to something more human friendly
    foreach($file in $myFiles){
        if(($file.length/1GB) -ge 1){
            $fileSize = [math]::Round($file.length/1GB,2)
            Add-member -InputObject $file -NotePropertyName ‘Size’ -NotePropertyValue “$fileSize GB”
        }
        elseif(($file.length/1MB) -ge 1){
            $fileSize = [math]::Round($file.length/1MB,2)
            Add-member -InputObject $file -NotePropertyName ‘Size’ -NotePropertyValue “$fileSize MB”
        }
        else{
            $fileSize = [math]::Round($file.length/1KB,2)
            Add-member -InputObject $file -NotePropertyName ‘Size’ -NotePropertyValue “$fileSize KB”
        }
    }
    $myFiles | Select-Object Name, Size, CreationTime | Out-File -FilePath($path + "\filesummary.txt")
    # Generate Hashfile
    Get-FileHash ($path + "\filesummary.txt") | Out-File -FilePath($path + "\filehash.csv")
}

function Invoke-FolderBrowserDialog {
    # "$script:" will allow us to access this variable from outside the function to retrieve selected path
    $script:folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    $defaultPath = "C:\Users\$env:USERNAME"
    $folderBrowser.SelectedPath = $defaultPath
    $folderBrowser.ShowNewFolderButton = $false
    $folderBrowser.Description = "Select folder"
    $folderBrowser.RootFolder = [System.Environment+SpecialFolder]::MyComputer
    $folderResponse = $folderBrowser.ShowDialog()

    #Verify selection was made
    if($folderResponse -eq 'Cancel'){
        # User made no selection!
        EXIT
    }
    else{
        # User made a selection! | NOTE "$folderBrowser variable was created in the Invoke-FolderBrowserDialog function
        $selectedPath = $folderBrowser.SelectedPath
    }
    # Return just the folder path
    return $selectedPath
}

# Add Forms Assembly
[void][Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
[System.Windows.Forms.Application]::EnableVisualStyles()

# Ask user if they need to compare hash summary
$message = "Are you comparing your files folder hash?`nSelect no if you are creating a new hash summary."
$title = "Select Option Below"
$buttons = [System.Windows.Forms.MessageBoxButtons]::YesNoCancel
$icons = [System.Windows.Forms.MessageBoxIcon]::Question
$userResponse = [System.Windows.Forms.MessageBox]::Show($message, $title, $buttons, $icons)

# Handle Response
if($userResponse -eq 'Cancel'){
    # The user clicked cancel or the exit button | Exit the script
    EXIT
}
elseif($userResponse -eq 'Yes'){
    # The user is attempting to verify the copied folder
    # Get Path
    $selectedPath = Invoke-FolderBrowserDialog

    # Hash Method
    $oldFileHashHash = Get-FileHash -Path "$selectedPath\filehash.csv"
    Remove-Item "$selectedpath\filesummary.txt"
    Remove-Item "$selectedpath\filehash.csv"

    Invoke-FolderHashSummary -Path $selectedPath

    $newFileHashHash = Get-FileHash -Path "$selectedPath\filehash.csv"

    $title = "File Check Result"
    $buttons = [System.Windows.Forms.MessageBoxButtons]::OK

    if($newFileHashHash -eq $oldFileHashHash){
        # Hashes Match
        $message = "Copied contents match original contents."
        $icons = [System.Windows.Forms.MessageBoxIcon]::Information
        [System.Windows.Forms.MessageBox]::Show($message, $title, $buttons, $icons)
        EXIT
    }
    else{
        $message = "Copied contents do not match original contents!"
        $icons = [System.Windows.Forms.MessageBoxIcon]::Warning
        [System.Windows.Forms.MessageBox]::Show($message, $title, $buttons, $icons)
        EXIT
    }
}
else{
    # The user selected no and is creating a new summary and hash
    $selectedPath = Invoke-FolderBrowserDialog

    Invoke-FolderHashSummary -Path $selectedPath
}
