# Read-only queries for the extension's local control page. Never evaluate command text.
. (Join-Path $PSScriptRoot 'GlobalBank-Data.ps1')
$script:ControlEncoding = New-Object System.Text.UTF8Encoding($false, $true)

function Read-ControlJson([string]$dataDirectory, [string]$name) {
    $path = Join-Path $dataDirectory $name
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        if ($name -eq 'GlobalBank.json') { throw 'No character data yet. Start the Global Bank helper and log in to your characters.' }
        throw 'No auction cache yet. Run an auction search in game and let the Global Bank helper collect it.'
    }
    $info = Get-Item -LiteralPath $path
    if ($info.Length -gt 67108864) { throw 'This local data file is too large to open here (limit 64 MiB).' }
    return [System.IO.File]::ReadAllText($path, $script:ControlEncoding) | ConvertFrom-Json
}
function ConvertTo-ControlCharacters($database) {
    if ($null -eq $database.characters) { throw 'The character data file has an unsupported format.' }
    $characters = foreach ($c in @($database.characters)) {
        if (-not $c) { continue }
        $bags = @(foreach ($item in @($c.bag)) {
            if ($item) { [pscustomobject]@{ Id=[string]$item.id; Name=[string]$item.name; Count=[int64]$item.count; Where='bag' } }
        })
        $bank = @(foreach ($item in @($c.bank)) {
            if ($item) { [pscustomobject]@{ Id=[string]$item.id; Name=[string]$item.name; Count=[int64]$item.count; Where='bank' } }
        })
        $classes = @($c.classes | Where-Object { $_ -and $_.name } | ForEach-Object { [pscustomobject]@{Name=[string]$_.name;Level=[int]$_.level} })
        if (-not $classes.Count -and $c.class) { $classes = @([pscustomobject]@{Name=[string]$c.class;Level=[int]$c.level}) }
        [pscustomobject]@{ Name=[string]$c.name; Class=[string]$c.class; Classes=$classes; Level=[int]$c.level; Gold=[int64]$c.gold;
            Note=[string]$c.note; Saved=[string]$c.saved; Bag=$bags; Bank=$bank; Items=($bags.Count + $bank.Count) }
    }
    return ,@($characters)
}
function Format-ControlClasses($c) {
    return (@($c.Classes | ForEach-Object { "$($_.Name)($($_.Level))" }) -join ', ')
}
function Limit-ControlLines($lines) {
    $maxLines = 200
    $items = @($lines)
    $out = New-Object 'System.Collections.Generic.List[string]'
    foreach ($line in @($items | Select-Object -First $maxLines)) {
        $text = [string]$line
        if ($text.Length -gt 500) { $text = $text.Substring(0, 500) + '…' }
        $out.Add($text)
    }
    if ($items.Count -gt $maxLines) { $out.Add('More results were omitted. Narrow your search to see them.') }
    return ($out -join "`n")
}
function Get-ControlBankQuery([string]$dataDirectory, [string]$command) {
    if (-not $command -or $command.Length -gt 256 -or $command -match '[\x00-\x1f]') { throw 'Enter a bank command of at most 256 characters.' }
    $text = $command.Trim().TrimStart('/').Trim()
    $parts = @($text -split '\s+')
    $name = $parts[0].ToLowerInvariant()
    $rest = (@($parts | Select-Object -Skip 1)) -join ' '
    if ($name -eq 'get' -and $parts.Count -gt 1) {
        $name = $parts[1].ToLowerInvariant()
        $rest = (@($parts | Select-Object -Skip 2)) -join ' '
    }
    if (@('help','?','commands') -contains $name) {
        return "Read-only bank commands:`n  list [gold|level|items|name|note|saved] [text]`n  list note bank alt (find text in notes)`n  search <item or note>`n  search warrior > 60 (level 60 or higher)`n  show <character>`n  gold [character]`n  goldtotal`n`nThe / and the word get are optional. To update data, use the Global Bank helper window."
    }
    $supported = @('list','chars','characters','search','find','item','items','show','char','character','view','bank','bag','gold','goldtotal','totalgold','total')
    if ($supported -notcontains $name) { throw 'This page only accepts the read-only bank commands shown by help.' }
    $chars = ConvertTo-ControlCharacters (Read-ControlJson $dataDirectory 'GlobalBank.json')
    $lines = New-Object 'System.Collections.Generic.List[string]'
    if (@('goldtotal','totalgold','total') -contains $name -or ($name -eq 'gold' -and (-not $rest -or $rest -ieq 'total'))) {
        $lines.Add("$(Format-GBGold (Get-GBGoldTotal $chars)) gold on $($chars.Count) character(s).")
    } elseif ($name -eq 'gold' -or @('show','char','character','view','bank','bag') -contains $name) {
        if (-not $rest) { throw 'Enter a character name, for example: show Cherry' }
        $matches = Find-GBCharacter $chars $rest
        if ($matches.Count -ne 1) { throw 'No unique character matched. Use list to find the full name.' }
        $c = $matches[0]
        $lines.Add("$($c.Name) - $(Format-ControlClasses $c); $(Format-GBGold $c.Gold) gold; saved $($c.Saved)")
        if ($name -ne 'gold') {
            if ($c.Note) { $lines.Add("Note: $($c.Note)") }
            foreach ($group in @(@{ label='Bag'; items=$c.Bag }, @{ label='Bank'; items=$c.Bank })) {
                $lines.Add("$($group.label):")
                $items = Group-GBItems $group.items
                if (-not $items.Count) { $lines.Add('  No saved items.') }
                foreach ($item in $items) { $lines.Add("  $($item.Name): $($item.Count)") }
            }
        }
    } elseif (@('search','find','item','items') -contains $name) {
        if (-not $rest) { throw 'Enter an item name or note, for example: search mana' }
        if ($rest -match '^(.+?)\s*(>=|>|<=|<|=)\s*(\d+)\s*$') {
            $className=$Matches[1].Trim(); $operator=$Matches[2]; $level=[int64]$Matches[3]
            foreach ($c in $chars) {
                $matching = @($c.Classes | Where-Object {
                    $classLevel=$_.Level
                    $_.Name -ieq $className -and $(switch ($operator) {
                        '>' { $classLevel -ge $level }; '>=' { $classLevel -ge $level }
                        '<' { $classLevel -lt $level }; '<=' { $classLevel -le $level }; '=' { $classLevel -eq $level }
                    })
                })
                if ($matching.Count) { $lines.Add("$($c.Name): $(Format-ControlClasses $c)") }
            }
            if (-not $lines.Count) { $lines.Add('No matching saved classes. Log in with the updated addon to save class levels.') }
            return Limit-ControlLines $lines
        }
        foreach ($c in $chars) { if ($c.Note -and $c.Note.IndexOf($rest, [StringComparison]::OrdinalIgnoreCase) -ge 0) { $lines.Add("Note - $($c.Name): $($c.Note)") } }
        $items = Search-GBItems $chars $rest
        foreach ($item in $items) {
            $lines.Add("$($item.Name): $($item.Total) total")
            foreach ($holder in $item.Holders) { $lines.Add("  $($holder.Name): bag $($holder.Bag), bank $($holder.Bank)") }
        }
        if (-not $lines.Count) { $lines.Add("No item names or notes contain: $rest") }
    } else {
        $words = @($rest -split '\s+' | Where-Object { $_ })
        $sort = 'name'
        if ($words.Count -and @('gold','level','items','name','note','saved') -contains $words[0].ToLowerInvariant()) {
            $sort = $words[0].ToLowerInvariant(); $words = @($words | Select-Object -Skip 1)
        }
        $filter = $words -join ' '
        $list = @($chars | Where-Object { -not $filter -or $_.Note.IndexOf($filter, [StringComparison]::OrdinalIgnoreCase) -ge 0 -or ($sort -ne "note" -and $_.Name.IndexOf($filter, [StringComparison]::OrdinalIgnoreCase) -ge 0) })
        if (@('gold','level','items','saved') -contains $sort) { $list = @($list | Sort-Object @{ Expression=$sort; Descending=$true }, Name) }
        else { $list = @($list | Sort-Object $sort, Name) }
        foreach ($c in $list) { $lines.Add("$($c.Name) | $(Format-ControlClasses $c) | $(Format-GBGold $c.Gold) gold | $($c.Items) item slots | $($c.Saved)$(if ($c.Note) { ' | ' + $c.Note })") }
        if (-not $list.Count) { $lines.Add('No matching characters.') }
        else { $lines.Add("$($list.Count) character(s), $(Format-GBGold (Get-GBGoldTotal $list)) gold.") }
    }
    return Limit-ControlLines $lines
}
function Get-ControlAuctionQuery([string]$dataDirectory, [string]$search, [string]$realmFilter) {
    if (-not $search -or $search.Length -gt 128 -or $search -match '[\x00-\x1f]') { throw 'Enter an item name or ID of at most 128 characters.' }
    if ($realmFilter.Length -gt 120 -or $realmFilter -match '[\x00-\x1f]') { throw 'The realm name is too long or contains an invalid character.' }
    $data = Read-ControlJson $dataDirectory 'AAHBroadCache.json'
    if ($data.schemaVersion -ne 1 -or $null -eq $data.realms) { throw 'The auction cache has an unsupported format.' }
    $lines = New-Object 'System.Collections.Generic.List[string]'
    $lines.Add('Saved auction observations; prices and availability may have changed.')
    $now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
    $matches = 0
    foreach ($realm in $data.realms.PSObject.Properties) {
        if ($realmFilter -and $realm.Name.IndexOf($realmFilter, [StringComparison]::OrdinalIgnoreCase) -lt 0) { continue }
        foreach ($entry in @($realm.Value.entries)) {
            if (-not $entry -or -not $entry.data) { continue }
            $item = $entry.data
            if (([string]$item.name).IndexOf($search, [StringComparison]::OrdinalIgnoreCase) -lt 0 -and ([string]$item.itemid).IndexOf($search, [StringComparison]::OrdinalIgnoreCase) -lt 0) { continue }
            $matches++
            if ($matches -gt 150) { continue }
            $seen = [double]$entry.lastSeenTrustedUTC
            $age = if ($seen -gt 0 -and $seen -le $now) { '{0} min ago' -f [math]::Floor(($now - $seen) / 60) } else { 'time unknown' }
            $price = if ($null -eq $item.buyoutPrice -or [double]$item.buyoutPrice -le 0) { 'no buyout' } else { "buyout $($item.buyoutPrice) $($item.moneyMode)" }
            $lines.Add("$($item.name) (ID $($item.itemid), stack $($item.count)) | $($realm.Name) | last seen $age | $price | seller $($item.seller)")
        }
    }
    if (-not $matches) { $lines.Add('No matching cached auctions. Try another item or realm, or search in game first.') }
    elseif ($matches -gt 150) { $lines.Add("Showing 150 of $matches matches. Narrow your search to see more.") }
    return Limit-ControlLines $lines
}
