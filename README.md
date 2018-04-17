# ConvertTo-Jpeg

> A PowerShell script that converts RAW (and other) image files to the widely-supported JPEG format

## Overview

Many cameras save photos in a custom file format.
Known as [RAW images](https://en.wikipedia.org/wiki/Raw_image_format), these files contain richer information than the widely-supported [JPEG format](https://en.wikipedia.org/wiki/JPEG) allows, but they are not as widely supported by tools.
To easily view, edit, or share pictures, it can be handy to convert RAW images to the JPEG format.

`ConvertTo-Jpeg.ps1` is a [PowerShell](https://en.wikipedia.org/wiki/PowerShell) script that uses the [Windows.Graphics.Imaging API](https://docs.microsoft.com/en-us/uwp/api/windows.graphics.imaging) to create a JPEG-encoded copy of each image that is passed to it.
(The original file is not modified.)

## Examples

Passing parameters:

```PowerShell
PS C:\T> .\ConvertTo-Jpeg.ps1 C:\T\Pictures\IMG_1234.CR2 C:\T\Pictures\IMG_5678.CR2
C:\T\Pictures\IMG_1234.CR2 -> IMG_1234.CR2.jpg
C:\T\Pictures\IMG_5678.CR2 -> IMG_5678.CR2.jpg
```

Pipeline via `dir`:

```PowerShell
PS C:\T> dir C:\T\Pictures | .\ConvertTo-Jpeg.ps1
C:\T\Pictures\IMG_1234.CR2 -> IMG_1234.CR2.jpg
C:\T\Pictures\IMG_5678.CR2 -> IMG_5678.CR2.jpg
C:\T\Pictures\Kitten.jpg [Already JPEG]
C:\T\Pictures\Notes.txt [Unsupported]
```

Pipeline via `Get-ChildItem`:

```PowerShell
PS C:\T> Get-ChildItem C:\T\Pictures -Filter *.cr2 | .\ConvertTo-Jpeg.ps1
C:\T\Pictures\IMG_1234.CR2 -> IMG_1234.CR2.jpg
C:\T\Pictures\IMG_5678.CR2 -> IMG_5678.CR2.jpg
```

## Formats

| Decoder         | Extensions |
| --------------- | ---------- |
| BMP Decoder     | .BMP .DIB .RLE |
| GIF Decoder     | .GIF |
| ICO Decoder     | .ICO .ICON |
| JPEG Decoder    | .EXIF .JFIF .JPE .JPEG .JPG |
| PNG Decoder     | .PNG |
| TIFF Decoder    | .TIF .TIFF |
| DNG Decoder     | .DNG |
| WMPhoto Decoder | .JXR .WDP |
| DDS Decoder     | .DDS |
| Microsoft Camera Raw Decoder | .ARW .CR2 .CRW .DNG .ERF .KDC .MRW .NEF .NRW .ORF .PEF .RAF .RAW .RW2 .RWL .SR2 .SRW |
