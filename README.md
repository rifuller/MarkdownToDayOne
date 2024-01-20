# MarkdownToDayOne
A tool for importing markdown files to Day One journal, including attachments and tags from Obsidian.

## Pre-requisites
- Day One Journal app installed from the MacOS App Store
- Day One CLI
- [Powershell Core](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-macos?view=powershell-7.4#install-the-latest-stable-release-of-powershell)

This will install the latter two:

```bash
sudo bash /Applications/Day\ One.app/Contents/Resources/install_cli.sh
brew install powershell/tap/powershell

```

## Usage

I recommend importing in batches so that, if an error occurs, it’s easy to delete the batch in DayOne and rerun it. If that’s not possible, consider moving/deleting files after they’re imported to avoid creating duplicate entries.

For Obsidan users, this must be run from the root folder of the vault to import attachments succesfully.

```ps1
./markdown-to-dayone.ps1 -file "2023-11-01.md"
```

or


```ps1
Get-ChildItem -Recurse -Filter "2023*.md" 2023-11 | Sort-Object |  ./markdown-to-dayone.ps1
```

## Troubleshooting

```
Error: Invalid value(s) for option -a, --attachments; -p, --photos: path/to/attachment.jpg
```

The attachment could not be found. Check the path in the md file is correct, relative to the current working directory.