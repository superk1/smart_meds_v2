# Set the base directory
$baseDir = "D:\proyectos\smart_meds_V2"
$outputFile = "$baseDir\extracted_code_part3.txt"

# List of files to extract
$files = @(
    "lib/features/inventory/domain/entities/inventory_item.dart",
    "lib/features/inventory/data/models/inventory_item_model.dart",
    "lib/features/inventory/data/fakes/fake_inventory_repository.dart",
    "lib/features/catalog/domain/entities/catalog_medication.dart",
    "lib/features/catalog/data/models/catalog_medication_model.dart",
    "lib/features/catalog/data/fakes/fake_catalog_repository.dart",
    "lib/features/admin_review/domain/entities/pending_medication_submission.dart",
    "lib/features/admin_review/data/models/pending_medication_submission_model.dart",
    "lib/features/admin_review/data/fakes/fake_pending_submission_repository.dart",
    "test/features/inventory/inventory_repository_test.dart",
    "test/features/inventory/inventory_item_model_test.dart",
	"AGENTS.MD"

    )

# Create or overwrite the output file
New-Item -Path $outputFile -ItemType File -Force | Out-Null

# Process each file
foreach ($file in $files) {
    $fullPath = Join-Path $baseDir $file
    
    # Add file header
    "=" * 80 | Out-File -FilePath $outputFile -Append -Encoding UTF8
    "FILE: $file" | Out-File -FilePath $outputFile -Append -Encoding UTF8
    "=" * 80 | Out-File -FilePath $outputFile -Append -Encoding UTF8
    "" | Out-File -FilePath $outputFile -Append -Encoding UTF8
    
    # Check if file exists and add content
    if (Test-Path $fullPath) {
        Get-Content $fullPath -Raw -Encoding UTF8 | Out-File -FilePath $outputFile -Append -Encoding UTF8
    } else {
        "ERROR: File not found - $fullPath" | Out-File -FilePath $outputFile -Append -Encoding UTF8
    }
    
    "" | Out-File -FilePath $outputFile -Append -Encoding UTF8
    "" | Out-File -FilePath $outputFile -Append -Encoding UTF8
}

Write-Host "Extraction completed. Output file: $outputFile"d:
d:
