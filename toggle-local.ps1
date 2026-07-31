param (
    [Parameter(Mandatory=$true)]
    [ValidateSet("enable", "disable")]
    [string]$Mode
)

# Relative file paths (adjust subfolder paths if your controllers live elsewhere, e.g., "Controllers/AssetsController.cs")
$programCs = "Program.cs"
$assetsController = "AssetsController.cs"
$baseController = "BaseController.cs"
$configController = "ConfigController.cs"
$searchController = "SearchController.cs"

if ($Mode -eq "enable") {
    Write-Host "Applying Local Development Changes..." -ForegroundColor Green

    # 1. Update Program.cs (Add CORS service and middleware)
    if (Test-Path $programCs) {
        $content = Get-Content $programCs -Raw
        
        if ($content -notlike "*AllowReactApp*") {
            # Insert CORS service before AddControllers()
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
            $content = $content -replace 'builder\.Services\.AddControllers\(\)', $corsService
            
            # Insert CORS middleware before UseSwagger()
            $content = $content -replace 'app\.UseSwagger\(\);', "app.UseCors(""AllowReactApp"");`r`napp.UseSwagger();"
            
            Set-Content $programCs $content
            Write-Host "Updated Program.cs" -ForegroundColor Gray
        }
    }

    # 2. Comment out [Authorize] attributes
    foreach ($file in @($assetsController, $configController, $searchController)) {
        if (Test-Path $file) {
            (Get-Content $file) -replace '^\s*(\[Authorize\])', '// $1' | Set-Content $file
            Write-Host "Commented [Authorize] in $file" -ForegroundColor Gray
        }
    }

    # 3. Uncomment UserID return line in BaseController.cs
    if (Test-Path $baseController) {
        (Get-Content $baseController) -replace '//\s*(return this\.spoOptions\.Value\.UserID;)', '$1' | Set-Content $baseController
        Write-Host "Uncommented UserID line in $baseController" -ForegroundColor Gray
    }

    Write-Host "`nAll local development changes applied!" -ForegroundColor Cyan
}

elseif ($Mode -eq "disable") {
    Write-Host "Reverting Changes for Production / Server..." -ForegroundColor Yellow

    # 1. Revert Program.cs (Remove CORS configuration)
    if (Test-Path $programCs) {
        $content = Get-Content $programCs -Raw
        
        # Remove CORS Service block
        $corsBlockRegex = '(?s)builder\.Services\.AddCors\(options =>.*?\n\}\);\r?\n'
        $content = $content -replace $corsBlockRegex, ''
        
        # Remove app.UseCors call
        $content = $content -replace 'app\.UseCors\("AllowReactApp"\);\r?\n', ''
        
        Set-Content $programCs $content
        Write-Host "Reverted Program.cs" -ForegroundColor Gray
    }

    # 2. Uncomment [Authorize] attributes
    foreach ($file in @($assetsController, $configController, $searchController)) {
        if (Test-Path $file) {
            (Get-Content $file) -replace '//\s*(\[Authorize\])', '$1' | Set-Content $file
            Write-Host "Restored [Authorize] in $file" -ForegroundColor Gray
        }
    }

    # 3. Re-comment UserID line in BaseController.cs
    if (Test-Path $baseController) {
        (Get-Content $baseController) -replace '^\s*(return this\.spoOptions\.Value\.UserID;)', '// $1' | Set-Content $baseController
        Write-Host "Re-commented UserID line in $baseController" -ForegroundColor Gray
    }

    Write-Host "`nAll changes reverted successfully!" -ForegroundColor Cyan
}
