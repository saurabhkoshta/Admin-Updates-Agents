<#
.SYNOPSIS
Validates routing evaluation CSV structure, paired expectations and coverage without calling the agent.
#>
[CmdletBinding()]
param(
    [string]$TestSetPath = (Join-Path $PSScriptRoot 'routing-test-set.csv'),
    [string]$ExpectationsPath = (Join-Path $PSScriptRoot 'routing-expectations.csv')
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Assert-That([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw $Message }
}

function Read-Cases([string]$Path, [string[]]$Columns) {
    $lines = @([IO.File]::ReadAllLines((Resolve-Path -LiteralPath $Path).Path))
    $header = '"' + ($Columns -join '","') + '"'
    Assert-That ($lines.Count -gt 1 -and $lines[0] -ceq $header) "Unexpected CSV header: '$Path'."
    $field = '"(?:[^"]|"")*"'
    $pattern = '^' + ((@($field) * $Columns.Count) -join ',') + '$'
    for ($index = 1; $index -lt $lines.Count; $index++) {
        Assert-That ($lines[$index] -cmatch $pattern) "Invalid quoted CSV record at line $($index + 1): '$Path'."
    }
    return @(Import-Csv -LiteralPath $Path)
}

function Read-Sources([string]$Value, [string]$Context) {
    if ($Value -ceq 'None') { return @() }
    $sources = @($Value -split ';')
    Assert-That (@($sources | Where-Object { $_ -cnotin @('Enterprise', 'Release', 'Learn') }).Count -eq 0) "Unknown source in $Context."
    Assert-That (@($sources | Sort-Object -Unique).Count -eq $sources.Count) "Duplicate source in $Context."
    return $sources
}

$cases = @(Read-Cases $TestSetPath @('question', 'expectedResponse'))
$expectations = @(Read-Cases $ExpectationsPath @('caseId', 'question', 'requiredSources', 'conditionalSources', 'forbiddenSources', 'condition', 'capabilityChecks'))
Assert-That ($cases.Count -ge 1 -and $cases.Count -le 100) 'Import requires 1 to 100 questions.'
Assert-That ($cases.Count -eq 25 -and $expectations.Count -eq $cases.Count) 'Expected exactly 25 paired routing cases.'
Assert-That (@($cases.question | Sort-Object -Unique).Count -eq $cases.Count) 'Duplicate evaluation questions.'
Assert-That (@($expectations.caseId | Sort-Object -Unique).Count -eq $expectations.Count) 'Duplicate routing case IDs.'

$coverage = @{}
$conditionalCount = 0
for ($index = 0; $index -lt $cases.Count; $index++) {
    $case = $cases[$index]
    $route = $expectations[$index]
    $id = 'R{0:00}' -f ($index + 1)
    Assert-That ($route.caseId -ceq $id -and $case.question -ceq $route.question) "Question or row-order mismatch at $id."
    Assert-That (-not [string]::IsNullOrWhiteSpace($case.question) -and $case.question.Length -le 1000) "Question must contain 1 to 1000 characters: $id."
    Assert-That ($case.question -notmatch '(?i)\bMCP\b|MCP-Server|Release Communication|Microsoft Learn Docs|InvokeServer|microsoft_graph_|get_recent_|microsoft_docs_') "Question names a server or tool: $id."
    Assert-That (-not [string]::IsNullOrWhiteSpace($case.expectedResponse)) "Missing response rubric: $id."
    Assert-That (-not [string]::IsNullOrWhiteSpace($route.capabilityChecks)) "Missing capability checks: $id."

    $required = @(Read-Sources $route.requiredSources "$id requiredSources")
    $conditional = @(Read-Sources $route.conditionalSources "$id conditionalSources")
    $forbidden = @(Read-Sources $route.forbiddenSources "$id forbiddenSources")
    if ($required.Count -gt 0) {
        Assert-That ($case.expectedResponse.Contains('without asking the user to select or name a server')) "Missing intent-based routing rubric: $id."
        Assert-That ($case.expectedResponse.Contains('If access is denied, authentication fails or a source is unavailable')) "Missing access-limitation rubric: $id."
        Assert-That ($case.expectedResponse.Contains('never fabricate findings')) "Missing grounding rubric: $id."
    }
    Assert-That (@($required | Where-Object { $_ -cin $conditional -or $_ -cin $forbidden }).Count -eq 0) "Overlapping required source sets: $id."
    Assert-That (@($conditional | Where-Object { $_ -cin $forbidden }).Count -eq 0) "Overlapping conditional and forbidden source sets: $id."
    Assert-That (($required.Count + $conditional.Count + $forbidden.Count) -eq 3) "Every source needs a routing expectation: $id."
    if ($conditional.Count -gt 0) {
        Assert-That ($route.condition -ceq 'PastDatedRoadmap' -and 'Release' -cin $required) "Invalid conditional routing rule: $id."
        Assert-That ($forbidden.Count -eq 0) "Past-dated roadmap checks must allow all three sources: $id."
        $conditionalCount++
    } else {
        Assert-That ($route.condition -ceq 'None') "Unexpected routing condition: $id."
    }
    $key = if ($required.Count -eq 0) { 'None' } else { ($required | Sort-Object) -join ';' }
    if (-not $coverage.ContainsKey($key)) { $coverage[$key] = 0 }
    $coverage[$key]++
}

$expectedCoverage = @{
    'Enterprise' = 5
    'Release' = 4
    'Learn' = 4
    'Enterprise;Release' = 3
    'Enterprise;Learn' = 2
    'Enterprise;Learn;Release' = 4
    'None' = 3
}
Assert-That ($coverage.Count -eq $expectedCoverage.Count) 'Unexpected routing coverage categories.'
foreach ($key in $expectedCoverage.Keys) {
    Assert-That ($coverage.ContainsKey($key) -and $coverage[$key] -eq $expectedCoverage[$key]) "Unexpected coverage for '$key'."
}
Assert-That ($conditionalCount -eq 5) 'Expected five past-dated-roadmap conditional cases.'
Write-Output 'PASS: 25 unique natural-language questions; exact two-column import format; quoted records; prompt limits; paired capability expectations; seven routing categories; five conditional cases.'
Write-Output ('PASS: import row limit; maximum question length {0}/1000 characters; all 22 research rubrics require intent-based routing, explicit access limitations and no fabricated findings.' -f (($cases.question | ForEach-Object { $_.Length } | Measure-Object -Maximum).Maximum))
Write-Output 'This validates test data only. Run the agent and inspect capability traces to verify routing behavior.'
