# ConvertTo-Jpeg

> A PowerShell script that converts RAW (and other) image files to the widely-supported JPEG format

## Overview

Many cameras - and many phones - save photos in a custom file format.
Known as [RAW images](https://en.wikipedia.org/wiki/Raw_image_format), these files contain richer information than the widely-supported [JPEG format](https://en.wikipedia.org/wiki/JPEG) allows, but they are not as widely supported by tools.
To easily view, edit, or share pictures, it can be handy to convert RAW images to the JPEG format.

`ConvertTo-Jpeg.ps1` is a [PowerShell](https://en.wikipedia.org/wiki/PowerShell) script that uses the [Windows.Graphics.Imaging API](https://docs.microsoft.com/en-us/uwp/api/windows.graphics.imaging) to create a JPEG-encoded copy of each image that is passed to it.
(The original file is not modified.)

## Examples

Passing parameters:

```PowerShell
PS C:\T> .\ConvertTo-Jpeg.ps1 C:\T\Pictures\IMG_1234.HEIC C:\T\Pictures\IMG_5678.HEIC
C:\T\Pictures\IMG_1234.HEIC -> IMG_1234.HEIC.jpg
C:\T\Pictures\IMG_5678.HEIC -> IMG_5678.HEIC.jpg
```

Pipeline via `dir`:

```PowerShell
PS C:\T> dir C:\T\Pictures | .\ConvertTo-Jpeg.ps1
C:\T\Pictures\IMG_1234.HEIC -> IMG_1234.HEIC.jpg
C:\T\Pictures\IMG_5678.HEIC -> IMG_5678.HEIC.jpg
C:\T\Pictures\Kitten.jpg [Already JPEG]
C:\T\Pictures\Notes.txt [Unsupported]
```

Pipeline via `Get-ChildItem`:

```PowerShell
PS C:\T> Get-ChildItem C:\T\Pictures -Filter *.HEIC | .\ConvertTo-Jpeg.ps1
C:\T\Pictures\IMG_1234.HEIC -> IMG_1234.HEIC.jpg
C:\T\Pictures\IMG_5678.HEIC -> IMG_5678.HEIC.jpg
```

## Formats

| Decoder                      | Extensions |
| ---------------------------- | ---------- |
| BMP Decoder                  | .BMP .DIB .RLE |
| DDS Decoder                  | .DDS |
| DNG Decoder                  | .DNG |
| GIF Decoder                  | .GIF |
| ICO Decoder                  | .ICO .ICON |
| JPEG Decoder                 | .EXIF .JFIF .JPE .JPEG .JPG |
| Microsoft Camera Raw Decoder | .ARW .HEIC .CRW .DNG .ERF .KDC .MRW .NEF .NRW .ORF .PEF .RAF .RAW .RW2 .RWL .SR2 .SRW |
| *Microsoft HEIF Decoder*     | .AVCS .HEIC .HEICS .HEIF .HEIFS |
| PNG Decoder                  | .PNG |
| TIFF Decoder                 | .TIF .TIFF |
| WMPhoto Decoder              | .JXR .WDP |

## HEIC/HEIF

Windows 10's April 2018 Update (version 1803) added support for [HEIC/HEIF images](https://en.wikipedia.org/wiki/High_Efficiency_Image_File_Format) to the Windows.Graphics.Imaging API.
`ConvertTo-Jpeg.ps1` uses the new decoder automatically if it's available.
To enable the decoder, install the Microsoft [HEIF and HEVC Media Extensions](https://www.microsoft.com/store/productId/9NTLD6MSD8BM) bundle (or else both of [HEVC Video Extensions](https://www.microsoft.com/store/productId/9NMZLZ57R3T7) and [HEIF Image Extensions](https://www.microsoft.com/store/productId/9PMMSR1CGPWG)).
Once done, the built-in Photos app (and other programs that use the Windows.Graphics.Imaging API) will be able to open HEIC/HEIF images.
