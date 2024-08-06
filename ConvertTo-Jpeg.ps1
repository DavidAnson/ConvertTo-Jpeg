# ConvertTo-Jpeg - Converts RAW (and other) image files to the widely-supported JPEG format
# https://github.com/DavidAnson/ConvertTo-Jpeg

Param (
    [Parameter(
        Mandatory = $false,
        Position = 1,
        ValueFromPipeline = $true,
        ValueFromPipelineByPropertyName = $true,
        ValueFromRemainingArguments = $true,
        HelpMessage = "Array of image file names to convert to JPEG")]
    [Alias("FullName")]
    [String[]]
    $Files,

    [Parameter(
        HelpMessage = "Output folder for converted files")]
    [String]
    [Alias("o")]
    $OutputFolderPath,

    [Parameter(
        HelpMessage = "Fix extension of JPEG files without the .jpg extension")]
    [Switch]
    [Alias("f")]
    $FixExtensionIfJpeg,

    [Parameter(
        HelpMessage = "Opens dialogs for input files and output folder if not supplied")]
    [Switch]
    [Alias("t")]
    $InteractiveMode,

    [Parameter(
        HelpMessage = "Also copy unconverted image files to the output folder path")]
    [Switch]
    [Alias("u")]
    $OutputUnconverted,

    [Parameter(
        HelpMessage = "Do not fail on conversion error, only write exception")]
    [Switch]
    $NoFailOnConvert,

    [Parameter(
        HelpMessage = "Remove existing extension of non-JPEG files before adding .jpg")]
    [Switch]
    [Alias("r")]
    $RemoveOriginalExtension
)

Begin
{
    # Technique for await-ing WinRT APIs: https://fleexlab.blogspot.com/2018/02/using-winrts-iasyncoperation-in.html
    Add-Type -AssemblyName System.Runtime.WindowsRuntime
    $runtimeMethods = [System.WindowsRuntimeSystemExtensions].GetMethods()
    $asTaskGeneric = ($runtimeMethods | ? { $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1' })[0]
    Function AwaitOperation ($WinRtTask, $ResultType)
    {
        $asTaskSpecific = $asTaskGeneric.MakeGenericMethod($ResultType)
        $netTask = $asTaskSpecific.Invoke($null, @($WinRtTask))
        $netTask.Wait() | Out-Null
        $netTask.Result
    }
    $asTask = ($runtimeMethods | ? { $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncAction' })[0]
    Function AwaitAction ($WinRtTask)
    {
        $netTask = $asTask.Invoke($null, @($WinRtTask))
        $netTask.Wait() | Out-Null
    }

    # Reference WinRT assemblies
    [Windows.Storage.StorageFile, Windows.Storage, ContentType=WindowsRuntime] | Out-Null
    [Windows.Graphics.Imaging.BitmapDecoder, Windows.Graphics, ContentType=WindowsRuntime] | Out-Null
}

Process
{
    # If no files were passed and interactive mode, open a file dialog to select them
    if (!$Files -and $InteractiveMode)
    {
        Add-Type -AssemblyName System.Windows.Forms
        $FileBrowser = New-Object System.Windows.Forms.OpenFileDialog -Property @{
            InitialDirectory = [Environment]::GetFolderPath('Desktop') 
            Title            = "Select Files to Convert"
            Multiselect      = $true
            # filter selection to supported filetypes
            Filter           = "Image Files (*.*)|*.BMP;*.DIB;*.RLE;*.CUR;*.DDS;*.DNG;*.GIF;*.ICO;*.ICON;*.EXIF;*.JFIF;*.JPE;*.JPEG;*.JPG;*.ARW;*.CR2;*.CRW;*.DNG;*.ERF;*.KDC;*.MRW;*.NEF;*.NRW;*.ORF;*.PEF;*.RAF;*.RAW;*.RW2;*.RWL;*.SR2;*.SRW;*.AVCI;*.AVCS;*.HEIC;*.HEICS;*.HEIF;*.HEIFS;*.WEBP;*.PNG;*.TIF;*.TIFF;*.JXR;*.WDP|All files (*.*)|*.*"
        }
        $null = $FileBrowser.ShowDialog()
        $Files = $FileBrowser.FileNames
        $FileBrowser.Dispose()
    }

    # If no output folder selected and interactive mode, select a folder with dialog
    if (!$OutputFolderPath -and $InteractiveMode)
    {
        Add-Type -AssemblyName System.Windows.Forms
        $OutputFolderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog -Property @{
            Description = "Select Folder to Place Converted Files"
        }
        $null = $OutputFolderBrowser.ShowDialog()
        $OutputFolderPath = $OutputFolderBrowser.SelectedPath
        $OutputFolderBrowser.Dispose()

        # If no OutputFolderPath was selected, Throw Error
        if (!$OutputFolderPath)
        {
            Throw "Output Folder Not Selected."
        }
    }

    # Files that failed to be converted
    $FailedFiles = New-Object -TypeName "System.Collections.ArrayList"

    # Summary of imaging APIs: https://docs.microsoft.com/en-us/windows/uwp/audio-video-camera/imaging
    foreach ($file in $Files)
    {
        Write-Host $file -NoNewline
        try
        {
            try
            {
                # Get SoftwareBitmap from input file, determine output path
                $file = Resolve-Path -LiteralPath $file
                $inputFile = AwaitOperation ([Windows.Storage.StorageFile]::GetFileFromPathAsync($file)) ([Windows.Storage.StorageFile])
                $inputFolder = AwaitOperation ($inputFile.GetParentAsync()) ([Windows.Storage.StorageFolder])
                $inputExtension = $inputFile.FileType
                $outputFolder = $inputFolder
                # Determine output file name
                # Get name of original file, including extension
                $fileName = $inputFile.Name
                if ($RemoveOriginalExtension)
                {
                    # If removing original extension, get the original file name without the extension
                    $fileName = $inputFile.DisplayName 
                }
                # Add .jpg to the file name
                $outputFileName = $fileName + ".jpg"

                if ($OutputFolderPath)
                {
                    $outputFolder = AwaitOperation ([Windows.Storage.StorageFolder]::GetFolderFromPathAsync($OutputFolderPath)) ([Windows.Storage.StorageFolder])
                }
                $inputStream = AwaitOperation ($inputFile.OpenReadAsync()) ([Windows.Storage.Streams.IRandomAccessStreamWithContentType])
                $decoder = AwaitOperation ([Windows.Graphics.Imaging.BitmapDecoder]::CreateAsync($inputStream)) ([Windows.Graphics.Imaging.BitmapDecoder])
            }
            catch
            {
                # Ignore non-image files
                Write-Host " [Unsupported]"
                continue
            }
            # Check if image is already a jpg
            if ($decoder.DecoderInformation.CodecId -eq [Windows.Graphics.Imaging.BitmapDecoder]::JpegDecoderId)
            {
                # Check if jpg files should have their extensions fixed
                $ExtensionRequiresFix = $FixExtensionIfJpeg -and ($inputExtension -ne ".jpg") -and ($inputExtension -ne ".jpeg")
                if ($ExtensionRequiresFix)
                {
                    $outputFileName = $inputFile.DisplayName + ".jpg"
                }
                else
                {
                    $outputFileName = $inputFile.Name
                }

                # If OutputUnconverted and there is an OutputFolderPath
                # Copy the existing file to the output folder
                if ($OutputUnconverted -and $OutputFolderPath)
                {
                    # Copy input file to output folder
                    Copy-Item -path $inputFile.Path -Destination $(Join-Path $outputFolder.Path $outputFileName)
                    Write-Host " => $(Join-Path $outputFolder.Path $outputFileName)"
                    continue
                }
                else
                {
                    if ($ExtensionRequiresFix)
                    {
                        # Rename JPEG-encoded files to have ".jpg" extension
                        AwaitAction ($inputFile.RenameAsync($outputFileName))
                        Write-Host " => $(Join-Path $inputFolder.Path $outputFileName)"
                    }
                    else
                    {
                        # Skip JPEG-encoded files
                        Write-Host " [Already JPEG]"
                    }
                    continue
                }
            }
            $bitmap = AwaitOperation ($decoder.GetSoftwareBitmapAsync()) ([Windows.Graphics.Imaging.SoftwareBitmap])

            # Write SoftwareBitmap to output file
            $outputFile = AwaitOperation ($outputFolder.CreateFileAsync($outputFileName, [Windows.Storage.CreationCollisionOption]::ReplaceExisting)) ([Windows.Storage.StorageFile])
            $outputStream = AwaitOperation ($outputFile.OpenAsync([Windows.Storage.FileAccessMode]::ReadWrite)) ([Windows.Storage.Streams.IRandomAccessStream])
            $encoder = AwaitOperation ([Windows.Graphics.Imaging.BitmapEncoder]::CreateAsync([Windows.Graphics.Imaging.BitmapEncoder]::JpegEncoderId, $outputStream)) ([Windows.Graphics.Imaging.BitmapEncoder])
            $encoder.SetSoftwareBitmap($bitmap)
            $encoder.IsThumbnailGenerated = $true

            # Do it
            AwaitAction ($encoder.FlushAsync())
            Write-Host " -> $(Join-Path $outputFolder.Path $outputFileName)"
        }
        catch
        {
            if ($NoFailOnConvert)
            {
                # Report full details and add file to list
                Write-Error $_.Exception
                $FailedFiles.Add($file)
            }
            else
            {
                # Report full details
                throw $_.Exception.ToString()
            }
        }
        finally
        {
            # Clean-up
            if ($inputStream -ne $null) { [System.IDisposable]$inputStream.Dispose() }
            if ($outputStream -ne $null) { [System.IDisposable]$outputStream.Dispose() }
        }
    }

    if ($FailedFiles.Count -gt 0)
    {
        Write-Host "The following files failed to convert."
        Write-Host "You may lack the required extensions or the files may be corrupt."
        foreach ($file in $FailedFiles)
        {
            Write-Host $file
        }
    }
}
