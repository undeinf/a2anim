param (
    [Parameter(Mandatory=$true)]
    [ValidateSet("enable", "disable")]
    [string]$Mode
)

$programCs = "Program.cs"
$assetsController = "AssetsController.cs"
$baseController = "BaseController.cs"
$configController = "ConfigController.cs"
$searchController = "SearchController.cs"

if ($Mode -eq "enable") {
    Write-Host "Applying Local Development Changes..." -ForegroundColor Green

    # 1. Update Program.cs with tagged CORS block
    if (Test-Path $programCs) {
        $content = Get-Content $programCs -Raw
        
        if ($content -notlike "*AllowReactApp*") {
            $corsService = @"
// #LOCAL_DEV_START
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowReactApp", policy =>
    {
        policy.WithOrigins("http://localhost:3000")
              .AllowAnyHeader()
              .AllowAnyMethod()
              .AllowCredentials();
    });
});
// #LOCAL_DEV_END
builder.Services.AddControllers()
"@
            $content = $content -replace 'builder\.Services\.AddControllers\(\)', $corsService
            $content = $content -replace 'app\.UseSwagger\(\);', "// #LOCAL_DEV_START`r`napp.UseCors(""AllowReactApp"");`r`n// #LOCAL_DEV_END`r`napp.UseSwagger();"
            
            Set-Content $programCs $content
            Write-Host "Updated Program.cs" -ForegroundColor Gray
        }
    }

    # 2. Comment [Authorize] in controllers
    foreach ($file in @($assetsController, $configController, $searchController)) {
        if (Test-Path $file) {
            (Get-Content $file) -replace '^\s*(\[Authorize\])', '// $1' | Set-Content $file
            Write-Host "Commented [Authorize] in $file" -ForegroundColor Gray
        }
    }

    # 3. Uncomment UserID in BaseController.cs
    if (Test-Path $baseController) {
        (Get-Content $baseController) -replace '//\s*(return this\.spoOptions\.Value\.UserID;)', '$1' | Set-Content $baseController
        Write-Host "Uncommented UserID line in $baseController" -ForegroundColor Gray
    }

    Write-Host "`nAll local development changes applied!" -ForegroundColor Cyan
}

elseif ($Mode -eq "disable") {
    Write-Host "Reverting Changes for Production / Server..." -ForegroundColor Yellow

    # 1. Revert Program.cs (Precisely strip everything between tags)
    if (Test-Path $programCs) {
        $content = Get-Content $programCs -Raw
        
        # Remove everything between // #LOCAL_DEV_START and // #LOCAL_DEV_END
        $content = $content -replace '(?s)// #LOCAL_DEV_START.*?// #LOCAL_DEV_END\r?\n?', ''
        
        Set-Content $programCs $content
        Write-Host "Reverted Program.cs" -ForegroundColor Gray
    }

    # 2. Uncomment [Authorize] in controllers
    foreach ($file in @($assetsController, $configController, $searchController)) {
        if (Test-Path $file) {
            (Get-Content $file) -replace '//\s*(\[Authorize\])', '$1' | Set-Content $file
            Write-Host "Restored [Authorize] in $file" -ForegroundColor Gray
        }
    }

    # 3. Re-comment UserID in BaseController.cs
    if (Test-Path $baseController) {
        (Get-Content $baseController) -replace '^\s*(return this\.spoOptions\.Value\.UserID;)', '// $1' | Set-Content $baseController
        Write-Host "Re-commented UserID line in $baseController" -ForegroundColor Gray
    }

    Write-Host "`nAll changes reverted successfully!" -ForegroundColor Cyan
}
