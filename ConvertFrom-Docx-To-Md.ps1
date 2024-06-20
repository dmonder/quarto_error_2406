function Convert-Docx {
    param (
        [string]$std_fldr,
        [string]$input_file,
        [string]$output_file,
        [string]$dst_path
    )

    Write-Host "Processing $input_file : $std_fldr"
    
    # Path to the docx file for the standard
    $std_docx_path = "$std_fldr/$input_file.docx" -replace "\\", "/"

    # Path to the resultant markdown file and images path for the standard
    $std_md_path = "$dst_path/$output_file.qmd" -replace "\\", "/"

    Write-Host "...converting $std_docx_path to $std_md_path"
    # Call pandoc to convert the docx file to markdown
    # Must include multi-line tables and remove grid tables to ensure proper conversion of tables and to 
    #     allow custom-styles within tables 
    $cmd = "pandoc '$std_docx_path' -o '$std_md_path' --from 'docx+styles' --to 'markdown+multiline_tables-grid_tables'"
    Write-Host $cmd
    Invoke-Expression $cmd
}

# Make sure all the main destination folders exist
$folders = "./requirements", "./documents" 

foreach ($folder in $folders) {
    if ($folder -and !(Test-Path $folder)) {
        [void](New-Item -ItemType Directory -Force -Path $folder)
    }
}

Convert-Docx -input_file "Standard 05.4" -std_fldr "./report/Standard 05.4" -output_file "Standard 05.4" -dst_path "./requirements"
Convert-Docx -input_file "index" -std_fldr "./report" -dst_path "." -output_file "index"
Convert-Docx -input_file "Requirements" -std_fldr "./report" -dst_path "." -output_file "Requirements"
