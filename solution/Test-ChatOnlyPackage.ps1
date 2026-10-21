<#
.SYNOPSIS
Validates the sanitized chat-only solution without importing it or installing dependencies.
.EXAMPLE
powershell -NoProfile -File .\solution\Test-ChatOnlyPackage.ps1
#>
[CmdletBinding()]
param(
    [string]$PackagePath,
    [string]$ChecksumPath
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
Add-Type -AssemblyName System.IO.Compression.FileSystem
$scriptDirectory = Split-Path $MyInvocation.MyCommand.Path -Parent
$root = Split-Path $scriptDirectory -Parent
if (-not $PackagePath) { $PackagePath = Join-Path $scriptDirectory 'AdminUpdatesAgents_1_2_0_0.zip' }
if (-not $ChecksumPath) { $ChecksumPath = Join-Path $scriptDirectory 'SHA256SUMS.txt' }

function Assert-That([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw $Message }
}

function Normalize([string]$Text) {
    return $Text.Replace("`r`n", "`n").TrimEnd()
}

function Without-Metadata([string]$Text) {
    return Normalize ([regex]::Replace((Normalize $Text), '(?m)^mcs\.metadata:\n(?:[ \t]+[^\n]*(?:\n|$))*', ''))
}

function Read-Source([string]$RelativePath) {
    return [IO.File]::ReadAllText((Join-Path $root $RelativePath))
}

function Scalar([string]$Text, [string]$Name) {
    $match = [regex]::Match((Normalize $Text), '(?m)^[ \t]*(?:- )?' + [regex]::Escape($Name) + ': ([^\r\n]+)$')
    Assert-That $match.Success "Missing scalar '$Name'."
    return $match.Groups[1].Value
}

function Read-Xml([string]$Text) {
    $document = [Xml.XmlDocument]::new()
    $document.XmlResolver = $null
    Assert-That ($Text -notmatch '<!DOCTYPE') 'DTD declarations are not allowed.'
    $document.LoadXml($Text)
    return ,$document
}

$tools = @(
    'MCP-Server-for-Enterprise_PPB',
    'MicrosoftLearnDocsMCP-MicrosoftLearnDocsMCPServer_mZQ',
    'ReleaseCommunicationMCP_6bY'
)
$skill = 'sample_adminupdatesagent.skill.cross-source-investigation'
$feedback = 'Default_FeedbackCollectionBotSettings_wMTLOY'
$components = @($feedback, $skill) + @($tools | ForEach-Object { "sample_adminupdatesagent.tool.$_" })
$connectors = @(
    'sample_5Fmcp-2Dserver-2Dfor-2Denterprise',
    'sample_5Frelease-20communication-20mcp'
)
$expectedEntries = @('customizations.xml', 'solution.xml', '[Content_Types].xml',
    'Assets/botcomponent_connectionreferenceset.xml',
    'bots/sample_adminupdatesagent/bot.xml', 'bots/sample_adminupdatesagent/configuration.json')
foreach ($name in $components) {
    $expectedEntries += "botcomponents/$name/botcomponent.xml", "botcomponents/$name/data"
}
foreach ($name in $connectors) {
    foreach ($suffix in 'connectionparameters.json', 'iconblob.Png', 'openapidefinition.json', 'policytemplateinstances.json') {
        $expectedEntries += "Connector/${name}_$suffix"
    }
}
$expectedEntries += "Connector/$($connectors[0])_connectionparametersets.json"
$zip = [IO.Compression.ZipFile]::OpenRead((Resolve-Path $PackagePath).Path)
try {
    $entries = @($zip.Entries | ForEach-Object { $_.FullName })
    Assert-That ($entries.Count -eq 25) 'Expected exactly 25 package files.'
    Assert-That ((($entries | Sort-Object) -join "`n") -ceq (($expectedEntries | Sort-Object) -join "`n")) 'Unexpected, missing, or duplicate package files.'
    $texts = @{}
    foreach ($entry in $zip.Entries) {
        if ($entry.FullName -match '\.Png$') { continue }
        $reader = [IO.StreamReader]::new($entry.Open())
        try { $texts[$entry.FullName] = $reader.ReadToEnd() } finally { $reader.Dispose() }
        if ($entry.FullName -match '\.xml$') { [void](Read-Xml $texts[$entry.FullName]) }
        if ($entry.FullName -match '\.json$') { [void]($texts[$entry.FullName] | ConvertFrom-Json) }
        Assert-That ($texts[$entry.FullName] -notmatch '(?i)sample_admindigestsubscription|manage-admin-digest-subscription|weekly-admin-digest|Daily-MC-Trigger|Admin Digest (Processor|Subscriber)|sample_(AllowedRecipientDomains|SharedDigest\w+)|shared_(commondataserviceforapps|office365|teams|agentnode)|sample_sharedagentnode|Addanewrowtoselectedenvironment|Listrowsfromselectedenvironment|Updatearowinselectedenvironment|101e7790-4aba-f111-aaae-000d3a367f85|fe1d7790-4aba-f111-aaae-000d3a367f85|72db0b11-874d-21ab-c86f-ff64254dedb1') "Removed feature reference in '$($entry.FullName)'."
        Assert-That ($texts[$entry.FullName] -notmatch '(?i)\.onmicrosoft\.com|\.crm\d*\.dynamics\.com|[?&](sig|access_token|client_secret|refresh_token)=') "Environment-bound URL or credential in '$($entry.FullName)'."
    }

    [xml]$manifest = Read-Xml $texts['solution.xml']
    $solution = $manifest.ImportExportXml.SolutionManifest
    Assert-That ($solution.UniqueName -ceq 'AdminUpdatesAgents' -and $solution.Version -ceq '1.2.0.0' -and $solution.Managed -eq '0') 'Solution identity, version, or unmanaged format changed.'
    Assert-That ($solution.SelectNodes('MissingDependencies/*').Count -eq 0) 'Unexpected missing dependencies.'
    $roots = @($solution.RootComponents.RootComponent)
    Assert-That ($roots.Count -eq 3) 'Expected bot and two connector roots.'
    Assert-That (@($roots | Where-Object { $_.type -eq '10000' -and $_.schemaName -ceq 'sample_adminupdatesagent' -and $_.behavior -eq '0' }).Count -eq 1) 'Missing bot root component.'

    [xml]$customizations = Read-Xml $texts['customizations.xml']
    foreach ($name in 'Entities', 'Roles', 'Workflows', 'EntityRelationships', 'EntityMaps', 'FieldSecurityProfiles', 'Templates', 'OrganizationSettings', 'optionsets', 'CustomControls', 'EntityDataProviders') {
        $node = $customizations.SelectSingleNode("/ImportExportXml/$name")
        Assert-That ($null -ne $node -and $node.ChildNodes.Count -eq 0) "Unexpected $name assets."
    }
    Assert-That ($customizations.SelectNodes('//environmentvariabledefinition|//environmentvariablevalue').Count -eq 0) 'Unexpected environment variables.'
    $packagedConnectors = @($customizations.ImportExportXml.Connectors.Connector)
    Assert-That ($packagedConnectors.Count -eq 2) 'Expected exactly two custom connectors.'
    foreach ($connector in $packagedConnectors) {
        Assert-That ($connector.name -cin $connectors) 'Unexpected custom connector.'
        $connectorRoots = @($roots | Where-Object { $_.type -eq '372' -and $_.schemaName -ceq $connector.name -and $_.id.Trim('{}') -ieq $connector.connectorid })
        Assert-That ($connectorRoots.Count -eq 1) "Unresolved connector root '$($connector.name)'."
        foreach ($property in 'openapidefinition', 'connectionparameters', 'connectionparametersets', 'policytemplateinstances', 'iconblob') {
            $node = $connector.SelectSingleNode($property)
            if ($null -ne $node) { Assert-That ($node.InnerText.TrimStart('/') -cin $entries) "Dangling connector file '$property'." }
        }
        $sourceDirectories = @(Get-ChildItem (Join-Path $root 'connectors') -Directory | Where-Object { $_.Name.StartsWith($connector.name + '-') })
        Assert-That ($sourceDirectories.Count -eq 1) "Missing connector source '$($connector.name)'."
        foreach ($file in Get-ChildItem $sourceDirectories[0].FullName -Filter '*.json') {
            $source = Get-Content $file.FullName -Raw | ConvertFrom-Json | ConvertTo-Json -Depth 100 -Compress
            $packaged = $texts["Connector/$($connector.name)_$($file.Name)"] | ConvertFrom-Json | ConvertTo-Json -Depth 100 -Compress
            Assert-That ($source -ceq $packaged) "Connector JSON differs from sanitized source: '$($file.Name)'."
        }
        $iconEntry = $zip.GetEntry("Connector/$($connector.name)_iconblob.Png")
        $iconStream = $iconEntry.Open()
        $sha256 = [Security.Cryptography.SHA256]::Create()
        try { $iconHash = [BitConverter]::ToString($sha256.ComputeHash($iconStream)).Replace('-', '') } finally { $iconStream.Dispose(); $sha256.Dispose() }
        Assert-That ($iconHash -ceq (Get-FileHash (Join-Path $sourceDirectories[0].FullName 'iconblob.png') -Algorithm SHA256).Hash) 'Connector icon differs from sanitized source.'
        $openapi = $texts["Connector/$($connector.name)_openapidefinition.json"] | ConvertFrom-Json
        Assert-That ($openapi.swagger -eq '2.0' -and @($openapi.paths.PSObject.Properties).Count -gt 0) 'Invalid connector OpenAPI shape.'
    }
    $enterpriseAuth = $texts["Connector/$($connectors[0])_connectionparametersets.json"] | ConvertFrom-Json
    Assert-That ($enterpriseAuth.values.Count -eq 2) 'Enterprise authentication choices changed.'
    foreach ($choice in $enterpriseAuth.values) {
        Assert-That ($choice.parameters.token.oAuthSettings.customParameters.TenantId.value -ceq '00000000-0000-0000-0000-000000000000') 'Enterprise authentication contains a tenant binding.'
    }

    $references = @($customizations.ImportExportXml.connectionreferences.connectionreference)
    Assert-That ($references.Count -eq 3) 'Expected exactly three connection references.'
    $sourceConnections = @(Get-ChildItem (Join-Path $root 'infrastructure\connections') -File)
    Assert-That ($sourceConnections.Count -eq 3) 'Expected exactly three source connection mappings.'
    $sourceTools = @(Get-ChildItem (Join-Path $root 'capabilities\tools') -File)
    Assert-That ($sourceTools.Count -eq 3) 'Expected exactly three source tools.'
    Assert-That (@(Get-ChildItem (Join-Path $root 'behaviors') -Recurse -File).Count -eq 2) 'Expected only the investigation skill and its payload.'
    [xml]$assets = Read-Xml $texts['Assets/botcomponent_connectionreferenceset.xml']
    $links = @($assets.DocumentElement.ChildNodes)
    Assert-That ($links.Count -eq 3) 'Expected exactly three botcomponent connection links.'
    foreach ($tool in $tools) {
        $source = Read-Source "capabilities\tools\$tool.mcs.yml"
        $componentName = "sample_adminupdatesagent.tool.$tool"
        Assert-That ((Without-Metadata $source) -ceq (Without-Metadata $texts["botcomponents/$componentName/data"])) "Tool payload mismatch: '$tool'."
        Assert-That ((Scalar $source 'kind') -ceq 'McpTool' -and (Scalar $source 'authMode') -ceq 'Maker') 'Tools must use centrally managed agent-author MCP authentication.'
        $logicalName = Scalar $source 'connectionReference'
        $connectorId = Scalar $source 'connectorId'
        $matchingReferences = @($references | Where-Object { $_.connectionreferencelogicalname -ceq $logicalName -and $_.connectorid -ceq $connectorId })
        Assert-That ($matchingReferences.Count -eq 1) "Unresolved connection reference for '$tool'."
        $customConnectorId = $matchingReferences[0].SelectSingleNode('customconnectorid/connectorid')
        if ($null -ne $customConnectorId) {
            Assert-That (@($packagedConnectors | Where-Object { $_.connectorid -ieq $customConnectorId.InnerText }).Count -eq 1) "Dangling custom connector for '$tool'."
        }
        Assert-That (@($links | Where-Object { $_.GetAttribute('botcomponentid.schemaname') -ceq $componentName -and $_.GetAttribute('connectionreferenceid.connectionreferencelogicalname') -ceq $logicalName }).Count -eq 1) "Unresolved component link for '$tool'."
        $mapping = Read-Source "infrastructure\connections\$logicalName.sync.yaml"
        Assert-That ((Scalar $mapping 'connectionReferenceLogicalName') -ceq $logicalName -and (Scalar $mapping 'connectorId') -ceq $connectorId) "Source connection mismatch for '$tool'."
        [xml]$component = Read-Xml $texts["botcomponents/$componentName/botcomponent.xml"]
        Assert-That ($component.botcomponent.name -ceq (Scalar $source 'componentName') -and $component.botcomponent.description -ceq (Scalar $source 'description')) "Tool metadata mismatch: '$tool'."
    }
    foreach ($name in $components) {
        [xml]$component = Read-Xml $texts["botcomponents/$name/botcomponent.xml"]
        $expectedType = if ($name -eq $feedback) { '18' } else { '9' }
        Assert-That ($component.botcomponent.schemaname -ceq $name -and $component.botcomponent.componenttype -eq $expectedType -and $component.botcomponent.parentbotid.schemaname -ceq 'sample_adminupdatesagent') "Invalid component identity or parent: '$name'."
    }
    $skillData = Without-Metadata $texts["botcomponents/$skill/data"]
    $skillMatch = [regex]::Match($skillData, '\Akind: InlineAgentSkill\ncontent: \|-\n(?<payload>.*?)\nauthoringSource: Blank\z', [Text.RegularExpressions.RegexOptions]::Singleline)
    Assert-That $skillMatch.Success 'Invalid skill payload wrapper.'
    $payload = ($skillMatch.Groups['payload'].Value -split "`n" | ForEach-Object { if ($_.StartsWith('  ')) { $_.Substring(2) } else { $_ } }) -join "`n"
    Assert-That ((Normalize $payload) -ceq (Normalize (Read-Source 'behaviors\cross-source-investigation\SKILL.md'))) 'Investigation content differs from source.'
    $skillSource = Read-Source 'behaviors\cross-source-investigation\skill.mcs.yml'
    Assert-That ((Without-Metadata $skillSource) -ceq "kind: InlineAgentSkill`nauthoringSource: Blank") 'Investigation definition changed.'
    [xml]$skillComponent = Read-Xml $texts["botcomponents/$skill/botcomponent.xml"]
    Assert-That ($skillComponent.botcomponent.name -ceq (Scalar $skillSource 'componentName') -and $skillComponent.botcomponent.description -ceq (Scalar $skillSource 'description') -and $skill -ceq (Scalar $skillSource 'schemaName')) 'Investigation metadata differs from source.'
    Assert-That ((Normalize $texts["botcomponents/$feedback/data"]) -ceq (Normalize (Read-Source "settings\$feedback.mcs.yml"))) 'Default feedback settings differ from source.'

    [xml]$bot = Read-Xml $texts['bots/sample_adminupdatesagent/bot.xml']
    Assert-That ($bot.bot.schemaname -ceq 'sample_adminupdatesagent' -and $bot.bot.authenticationmode -eq '2' -and $bot.bot.authenticationtrigger -eq '1' -and $bot.bot.template -ceq 'cliagent-1.0.0' -and $bot.bot.language -eq '1033') 'Bot identity, authentication, or template changed.'
    $settings = Normalize (Read-Source 'settings.mcs.yml')
    Assert-That ((Scalar $settings 'schemaName') -ceq $bot.bot.schemaname -and (Scalar $settings 'displayName') -ceq $bot.bot.name) 'Source and packaged bot identities differ.'
    Assert-That ((Scalar $settings 'accessControlPolicy') -ceq 'GroupMembership' -and (Scalar $settings 'authenticationMode') -ceq 'Integrated' -and (Scalar $settings 'authenticationTrigger') -ceq 'Always') 'Source access or authentication changed.'
    $match = [regex]::Match($settings, '(?ms)^          value: \|\n(?<instructions>.*?)(?=^    web:)')
    Assert-That $match.Success 'Missing static agent instruction segment.'
    $instructions = ($match.Groups['instructions'].Value -split "`n" | ForEach-Object { if ($_.StartsWith('            ')) { $_.Substring(12) } else { $_ } }) -join "`n"
    $configuration = $texts['bots/sample_adminupdatesagent/configuration.json'] | ConvertFrom-Json
    Assert-That ($configuration.'$kind' -ceq 'BotConfiguration' -and $configuration.recognizer.'$kind' -ceq 'CLICopilotRecognizer' -and $configuration.agentSettings.instructions.segments.Count -eq 1 -and $configuration.agentSettings.instructions.segments[0].'$kind' -ceq 'StaticSegment') 'Invalid bot configuration shape.'
    Assert-That ((Normalize $configuration.agentSettings.instructions.segments[0].value) -ceq (Normalize $instructions)) 'Packaged instructions differ from source.'
    Assert-That ($configuration.agentSettings.model.series -ceq (Scalar $settings 'series') -and -not $configuration.agentSettings.web.enableWebSearch) 'Model or web grounding configuration changed.'
    foreach ($required in 'Chat-only scope:', 'specific Microsoft products or all products', 'on-demand briefing', 'not stored as a persistent preference', 'Do not schedule delivery, send email, post to Teams, save subscriptions', 'background', 'Current date: {Text(Today(),DateTimeFormat.LongDate)}', 'Search both MCP-Server-for-Enterprise and Microsoft Learn Docs MCP Server', 'Treat Microsoft Learn as authoritative', 'Treat enterprise access as read-only') {
        Assert-That ($instructions.Contains($required)) "Missing required instruction: '$required'."
    }

    [xml]$contentTypes = Read-Xml $texts['[Content_Types].xml']
    $overrides = @($contentTypes.DocumentElement.ChildNodes | Where-Object LocalName -eq 'Override')
    Assert-That ($overrides.Count -eq 5) 'Expected exactly five botcomponent content-type overrides.'
    foreach ($override in $overrides) {
        Assert-That ($override.PartName.TrimStart('/') -cin $entries) 'Dangling content-type override.'
    }
    $expectedParts = @($components | ForEach-Object { "/botcomponents/$_/data" })
    Assert-That ((($overrides.PartName | Sort-Object) -join "`n") -ceq (($expectedParts | Sort-Object) -join "`n")) 'Incorrect content-type coverage.'
    $checksum = [IO.File]::ReadAllText((Resolve-Path $ChecksumPath).Path).Trim()
    $hash = (Get-FileHash -LiteralPath $PackagePath -Algorithm SHA256).Hash.ToLowerInvariant()
    Assert-That ($checksum -ceq "$hash  AdminUpdatesAgents_1_2_0_0.zip") 'SHA256SUMS does not exactly match the package.'
    Write-Output 'PASS: 25 files; 1 bot; 3 MCP tools; 1 investigation skill; 1 feedback setting; 2 custom connectors; 3 connection references and links.'
    Write-Output 'PASS: XML/JSON, exact inventory, roots, dependencies, references, source parity, chat-only instructions, authentication, sanitized auth, and checksum.'
    Write-Output "Solution: AdminUpdatesAgents 1.2.0.0 (unmanaged); SHA256: $hash"
} finally {
    $zip.Dispose()
}
