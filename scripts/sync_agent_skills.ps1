[CmdletBinding()]
param(
    [ValidateSet('All', 'Claude', 'Codex')]
    [string]$Target = 'All',

    [switch]$Overwrite
)

$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $ScriptDir
$CanonicalRoot = Join-Path $RepoRoot '.agent-skills'

if (-not (Test-Path -LiteralPath $CanonicalRoot)) {
    throw "No existe la carpeta canonica de skills: $CanonicalRoot"
}

function Sync-SkillSet {
    param(
        [Parameter(Mandatory = $true)]
        [string]$DestinationRoot,

        [Parameter(Mandatory = $true)]
        [string]$Label
    )

    New-Item -ItemType Directory -Path $DestinationRoot -Force | Out-Null

    Get-ChildItem -Path $CanonicalRoot -Directory | ForEach-Object {
        $SourceSkillDir = $_.FullName
        $SkillName = $_.Name
        $SourceSkill = Join-Path $SourceSkillDir 'SKILL.md'
        $DestinationSkillDir = Join-Path $DestinationRoot $SkillName
        $DestinationSkill = Join-Path $DestinationSkillDir 'SKILL.md'

        if (-not (Test-Path -LiteralPath $SourceSkill)) {
            throw "La skill $SkillName no tiene SKILL.md"
        }

        New-Item -ItemType Directory -Path $DestinationSkillDir -Force | Out-Null

        if ((Test-Path -LiteralPath $DestinationSkill) -and -not $Overwrite) {
            $SourceText = Get-Content -Path $SourceSkill -Raw
            $DestinationText = Get-Content -Path $DestinationSkill -Raw
            if ($SourceText -ne $DestinationText) {
                throw "La skill $SkillName ya existe en $Label y difiere. Reejecuta con -Overwrite para sincronizar."
            }
        }

        Copy-Item -Path $SourceSkill -Destination $DestinationSkill -Force
        Write-Host "Sincronizada $SkillName -> $Label"
    }
}

if ($Target -in @('All', 'Claude')) {
    Sync-SkillSet -DestinationRoot (Join-Path $RepoRoot '.claude\skills') -Label 'Claude Code'
}

if ($Target -in @('All', 'Codex')) {
    $CodexSkills = Join-Path $env:USERPROFILE '.codex\skills'
    Sync-SkillSet -DestinationRoot $CodexSkills -Label 'Codex'
}
