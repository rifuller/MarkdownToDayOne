<#

.SYNOPSIS

.md to DayOne journal entry converter.

.DESCRIPTION

Converts markdown files (from say Obsidian) to DayOne journal entries.

.PARAMETER fiwle

The markdown file to convert.

.EXAMPLE

markdown-to-dayone.ps1 -file "2023-11-01.md"

.EXAMPLE

Get-ChildItem -Recurse -Filter "2023*.md" 2023-11 | ~/markdown-to-dayone.ps1

#>

param(
    [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
    [System.IO.FileSystemInfo]$file,

    [Parameter(Mandatory = $false, Position = 1)]
    [switch]$WhatIf = $false
)

Begin {
    $ErrorActionPreference = "Stop"
    Set-StrictMode -Version Latest

    # My markdown files optionally have a title after the date in the filename.
    function GetTitle($file) {
        $filename = $file.Name.Substring(0, $file.Name.length - 3)

        $i = $filename.IndexOf(" ")
        if ($i -ne -1) {
            $title = $filename.Substring($i + 1)
        }
        else {
            $title = ""
        }

        return $title
    }

    # Get the time the file was created and split it into datetime and the timezone ("eg. ±00:00")
    function GetDateAndTz($file) {
        $isoDate = $file.CreationTime.ToString("o") 
        $tz = "GMT" + $isoDate.SubString($isoDate.Length - 6) 
        return ($file.CreationTime.ToString("yyyy-MM-dd hh:mm:ss tt"), $tz)
    }

    function GetTagsAndStrip($contents) {
        $tags = [System.Collections.ArrayList]@()

        if ($null -ne $contents `
                -and $contents.Length -gt 3 `
                -and $contents[0] -eq '---' `
                -and $contents[1] -eq 'tags:') {

            for ($i = 2; $i -lt $contents.Length; $i++) {
                $line = $contents[$i]
                if ($line -eq '---') {
                    # Return the contents sans the tags section.
                    return @($contents[($i + 1)..($contents.Length - 1)], $tags)
                }

                if ($line.StartsWith("  -")) {
                    $tag = $line.Substring(4)
                    Write-Host "Found tag: $tag"
                    $discard = $tags.Add($tag)
                }
            }

            throw "End of the tags section not found."
        }

        return ($contents, $tags)
    }    
}

Process {
    Write-Host $file.FullName
    $title = GetTitle $file
    $date, $tz = GetDateAndTz $file
    
    $contents = (get-content $file.FullName)

    # Search for all inline attachments and replace them with Day One's placeholder.
    $attachments = [System.Collections.ArrayList]@()
    $contents = $contents | % { $_ -Replace "!\[\[(?<attachment>.+)\]\]", { $i = $attachments.Add($_); "[{attachment}]" } }

    $contents, $tags = GetTagsAndStrip -contents $contents
 
    Write-Host "Date=$date; TZ=$tz; Title=$title; Attachments=$($attachments.Count)"
    if (-not $WhatIf) {
        $dayoneargs = @("--date", "`"$date`"", "-z", $tz)
        
        # Add atachments. Note that the Obsidian uses attachments paths relative
        # to the root folder of their vault so for now this script needs 
        # to be run in the root folder of the vault.
        if ($attachments.Count -gt 0) {
            $dayoneargs += "-a"
            $dayoneargs += $attachments | % { "`"$($_.Groups["attachment"].Value)`"" }
            # $dayoneargs += "--"
        }

        if ($tags.Count -gt 0) {
            $dayoneargs += "-t"
            $dayoneargs += $tags | % { "$($_.Replace(' ', '\ '))" }
        }

        # The dayone2 CLI is very sensitive about the ordering of arguments. It has difficulty recognising 
        # where one parameter ends and the next starts because it doesn't use standard delimeters. If "new"
        # is at the beginning, it will hang waiting for more input. Other times, it interprets the body as 
        # part of the title. 
        $dayoneargs += ("--", "new", "`"$title `n " + [String]::Join("`n", $contents) + "`"")
        $p = Start-Process -PassThru -Wait -ArgumentList $dayoneargs "dayone2"

        if ($p.ExitCode -ne 0) {
            throw "dayone2 exited with code $($p.ExitCode)"
        }
    }
}
