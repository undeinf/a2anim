param (
    [Parameter(Mandatory=$true)]
    [ValidateSet("enable", "disable")]
    [string]$Mode
)

$programCs = "Program.cs"
$assetsController = "Controllers/AssetsController.cs"  # Adjust path if needed
$baseController = "Controllers/BaseController.cs"      # Adjust path if needed
$configController = "Controllers/ConfigController.cs"  # Adjust path if needed
$searchController = "Controllers/SearchController.cs"  # Adjust path if needed

if ($Mode -eq "enable") {
    Write-Host "Applying Local Development Changes..." -ForegroundColor Green

    # 1. Update Program.cs
    if (Test-Path $programCs) {
        $content = Get-Content $programCs -Raw
        
        # Add Cors Service if not present
        if ($content -notlike "*AllowReactApp*") {
            $corsService = @"
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
builder.Services.AddControllers()
"@
            $content = $content -replace "builder\.Services\.AddControllers\(\)", $corsService
            $content = $content -replace "app\.UseSwagger\(\);", "app.UseCors(""AllowReactApp"");`napp.UseSwagger();"
            Set-Content $programCs $content
        }
    }

    # 2. Comment [Authorize] in AssetsController, ConfigController, SearchController
    foreach ($file in @($assetsController, $configController, $searchController)) {
        if (Test-Path $file) {
            (Get-Content $file) -replace '(\[Authorize\])', '// $1' | Set-Content $file
        }
    }

    # 3. Uncomment UserID in BaseController.cs
    if (Test-Path $baseController) {
        (Get-Content $baseController) -replace '//\s*(return this\.spoOptions\.Value\.UserID;)', '$1' | Set-Content $baseController
    }

    Write-Host "Local changes applied successfully!" -ForegroundColor Cyan
}
elseif ($Mode -eq "disable") {
    Write-Host "Reverting Changes for Production / Server..." -ForegroundColor Yellow

    # Use Git to revert all modified files cleanly if using Git
    if (Get-Command git -ErrorAction SilentlyContinue) {
        git checkout -- $programCs $assetsController $baseController $configController $searchController
        Write-Host "Reverted via Git successfully!" -ForegroundColor Cyan
    }
    else {
        # Fallback manual regex revert
        foreach ($file in @($assetsController, $configController, $searchController)) {
            if (Test-Path $file) {
                (Get-Content $file) -replace '//\s*(\[Authorize\])', '$1' | Set-Content $file
            }
        }
        if (Test-Path $baseController) {
            (Get-Content $baseController) -replace '^\s*(return this\.spoOptions\.Value\.UserID;)', '// $1' | Set-Content $baseController
        }
        Write-Host "Reverted manually!" -ForegroundColor Cyan
    }
}
