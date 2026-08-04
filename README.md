![version](https://img.shields.io/badge/version-17%2B-3E8B93)
![platform](https://img.shields.io/static/v1?label=platform&message=mac-intel%20|%20mac-arm%20|%20win-64&color=blue)
![downloads](https://img.shields.io/github/downloads/miyako/4d-plugin-xpdf/total)

### Dependencies and Licensing

* the source code of this plugin developed using the [4D Plug-in SDK](https://github.com/4d/4D-Plugin-SDK) is licensed under the MIT license.
* see [Xpdf](https://www.xpdfreader.com/opensource.html) for the licensing of **Xpdf** (shared library).
* the licensing of the binary product of this plugin is subject to the licensing of all its dependencies.
 
# 4d-plugin-xpdf
Extract text from PDF, images from PDF.

The `xpdf` plugin extracts content from PDF files using the [xpdf](https://www.xpdfreader.com/) engine: plain text, rendered page images, and document metadata. Text extraction respects the PDF's own layout/reading-order model (or one of xpdf's alternate layout modes); image extraction rasterizes pages to `Picture` values (PNG-encoded); metadata extraction reads the PDF's Info dictionary and, where present, its XMP metadata block. All three commands take a file path and an options `Object`, and all three return a single result `Object`.

| Command | Returns | Purpose |
|---|---|---|
| [`XPDF Get text`](#xpdf-get-text) | Object | Extract a PDF's text content, with control over layout/reading order and margins |
| [`XPDF Get images`](#xpdf-get-images) | Object | Rasterize PDF pages to PNG `Picture` values |
| [`XPDF Get info`](#xpdf-get-info) | Object | Read document metadata, permissions, page sizes/boxes, and per-page rendering info |

**Platforms:** macOS, Windows

---

## Requirements & platform notes

- All three commands take the same first two parameters: `path` (Text, **mandatory**) and `options` (Object, **optional** — pass nothing, or `Null`, to use all defaults).
- **Failure is reported in the result object, not as a 4D error.** Every command always returns an `Object` with a `success` Boolean. On failure you'll also get `error` (a numeric xpdf error code) and/or `errorMessage` (Text). Check `success` before trusting any other field.
- **A document's own permission flags can cause failure even with a correct password.** `XPDF Get text` and `XPDF Get images` both check the PDF's copy-permission flag (`okToCopy`) and fail with `errorMessage: "copy is not allowed"` if the document forbids content extraction — this is independent of whether you supplied the right `userPassword`/`ownerPassword`.
- **`hdpi`/`vdpi` in `XPDF Get images` are clamped to a 1–2400 range.** Values outside that range (including non-numeric/`NaN`/`Infinity` input) are clamped or ignored rather than passed straight through, to avoid attempting to rasterize an unreasonably large bitmap.
- On startup, the plugin points [fontconfig](https://www.freedesktop.org/wiki/Software/fontconfig/) at a `fonts.conf`/font set bundled inside the plugin's own resources (on macOS, resolved from the plugin bundle; on Windows, resolved relative to the plugin `.4dx`'s own folder). This affects font substitution quality in `XPDF Get images`; you don't configure it yourself.
- The plugin's commands are marked thread-safe in its manifest, but internally share state tied to a single PDF-processing session; expect calls made concurrently from different 4D processes to execute one at a time rather than in parallel. Don't rely on concurrent calls to these three commands for a throughput win.
- The remainder of this reference (result-object shapes for error/errorMessage, and `XPDF Get info`'s failure branch) reflects the plugin's current, fixed source. If you're on an older build of the plugin, `errorMessage`/`error` may not be populated on failure for `XPDF Get text`/`XPDF Get images`, and `XPDF Get info` may return only `success: false` with no further explanation on failure.

---

## XPDF Get text

**`XPDF Get text ( path : Text ; options : Object ) → Object`**

### Syntax

```
XPDF Get text ( path : Text ; options : Object ) → status : Object
```

| Parameter | Type | Description |
|---|---|---|
| `path` | Text | Path to the PDF file to read. Mandatory. |
| `options` | Object | Extraction options (see below). Optional — omit for all defaults. |
| Result | Object | Status object: `success`, `text` on success, `error`/`errorMessage` on failure. |

**`options` properties** (all optional):

| Property | Type | Description |
|---|---|---|
| `start` | Number | First page to extract (1-based). Values ≤ 0 are ignored (default: page 1). |
| `end` | Number | Last page to extract. Omitted, ≤ 0, or beyond the document's page count defaults to the document's last page. |
| `layout` | Text | One of `"table"`, `"physical"`, `"simple"`, `"line"`, `"raw"`. Any other value (or omitting `layout`) uses xpdf's default reading-order layout. |
| `noPageBreaks` | Boolean | When `true`, suppresses page-break markers in the extracted text. Default `false`. |
| `ownerPassword` | Text | Owner password, if the PDF is encrypted. |
| `userPassword` | Text | User password, if the PDF is encrypted. |
| `marginLeft`, `marginRight`, `marginTop`, `marginBottom` | Number | Margins (in points) excluded from extraction on each side. Default `0`. |
| `fixedPitch` | Number | Fixed character pitch, used by the `"table"`, `"physical"`, and `"line"` layouts. Default `0` (auto). |
| `fixedLineSpacing` | Number | Fixed line spacing, used only by the `"line"` layout. Default `0` (auto). |
| `clipText` | Boolean | When `true`, clips text to the page's crop box. Default `false`. |
| `discardDiagonalText` | Boolean | When `true`, discards non-horizontal text (e.g. rotated watermarks). Default `false`. |

### Description

Text is extracted encoded as UTF-8 and returned as a single Text value in `status.text` (spanning every page in the requested range — there's no per-page breakdown; use `noPageBreaks`/`layout` to control how page boundaries show up in the string). The `layout` option controls how xpdf reconstructs reading order from the PDF's underlying, unordered text-drawing operations:

- `"table"` / `"physical"` — preserve the visual column/row layout, using `fixedPitch` to control character spacing.
- `"simple"` — a simplified column-aware layout.
- `"line"` — one line per physical text line, using `fixedPitch`/`fixedLineSpacing`.
- `"raw"` — text in the order it appears in the PDF's content stream, with no reading-order reconstruction.
- default (no `layout`, or an unrecognized value) — xpdf's standard reading-order heuristic.

Extraction fails (`success: false`) if the file can't be opened as a valid PDF (`errorMessage: "failed to open pdf"`, plus a numeric xpdf `error` code), if the document's permissions forbid copying (`errorMessage: "copy is not allowed"`), or if xpdf's text-output stage itself fails to initialize (`errorMessage: "failed to create output"`).

### Example

From the plugin's own test method (`TEST_TEXT.4dm`):

```4d
$path:=System folder:C487(Desktop:K41:16)+"test.pdf"

$params:=New object:C1471
$params.layout:="line"
$params.fixedPitch:=5
$params.fixedLineSpacing:=10

$status:=XPDF Get text($path; $params)
```

Extracting a specific page range with default layout, and checking the result:

```4d
$params:=New object:C1471("start"; 2; "end"; 5)
$status:=XPDF Get text($path; $params)

If ($status.success)
	ALERT:C41($status.text)
Else 
	ALERT:C41("Extraction failed: "+String:C10($status.error)+" - "+$status.errorMessage)
End if 
```

---

## XPDF Get images

**`XPDF Get images ( path : Text ; options : Object ) → Object`**

### Syntax

```
XPDF Get images ( path : Text ; options : Object ) → status : Object
```

| Parameter | Type | Description |
|---|---|---|
| `path` | Text | Path to the PDF file to read. Mandatory. |
| `options` | Object | Rendering options (see below). Optional — omit for all defaults. |
| Result | Object | Status object: `success`, `images` (Collection of Picture) on success, `error`/`errorMessage` on failure. |

**`options` properties** (all optional):

| Property | Type | Description |
|---|---|---|
| `start` | Number | First page to render (1-based). Values ≤ 0 are ignored (default: page 1). |
| `end` | Number | Last page to render. Omitted, ≤ 0, or beyond the page count defaults to the document's last page. |
| `hdpi` | Number | Horizontal resolution in DPI. Default `150` if omitted (or if the page's own detected resolution is `0`). Clamped to 1–2400. |
| `vdpi` | Number | Vertical resolution in DPI. Default `150` if omitted (or if the page's own detected resolution is `0`). Clamped to 1–2400. |
| `mono` | Boolean | Render as 1-bit black & white. Default `false`. Takes priority over `gray`/`grey`/`alpha` if set. |
| `gray` / `grey` | Boolean | Render as 8-bit grayscale. Either spelling works; both set the same option. Ignored if `mono` is `true`. Default `false`. |
| `alpha` | Boolean | Include an alpha channel in the output PNG. Ignored if `mono` is `true`. Default `false`. |
| `ownerPassword` | Text | Owner password, if the PDF is encrypted. |
| `userPassword` | Text | User password, if the PDF is encrypted. |

### Description

Returns one PNG-encoded `Picture` per page in the requested range, in `status.images`, in page order. Color mode is chosen by `mono`/`gray`/`grey`/`alpha` as above; if none are set, pages render as 24-bit RGB (32-bit RGBA if `alpha` is `true`).

If `hdpi`/`vdpi` aren't supplied, the plugin first asks xpdf for the page's own natural resolution and uses that; only if xpdf reports `0` does it fall back to the `150` DPI default. Supplying `hdpi`/`vdpi` explicitly always overrides this auto-detection.

Failure modes mirror [`XPDF Get text`](#xpdf-get-text): a file that won't open as a valid PDF (`errorMessage: "failed to open pdf"` plus a numeric `error` code), or a document whose permissions forbid copying (`errorMessage: "copy is not allowed"`). If rendering a specific page's PNG fails internally, that page is simply omitted from `images` rather than the whole command failing — check `PA_GetCollectionLength`/the length of `status.images` against your requested page range if you need to detect a partial result.

### Example

From the plugin's own test method (`TEST_IMAGE.4dm`):

```4d
$path:=System folder:C487(Desktop:K41:16)+"original_document.pdf"

$status:=XPDF Get images($path)

C_PICTURE:C286($image)

For each ($image; $status.images)
	WRITE PICTURE FILE:C680(System folder:C487(Desktop:K41:16)+"test.png"; $image)
	SET PICTURE TO PASTEBOARD:C521($image)
End for each 

For each ($image; $status.images)
	SET PICTURE TO PASTEBOARD:C521($image)
End for each 
$params:=New object:C1471("gray"; True:C214)

$status:=XPDF Get images($path; $params)

For each ($image; $status.images)
	SET PICTURE TO PASTEBOARD:C521($image)
End for each 

$params:=New object:C1471("mono"; True:C214)

$status:=XPDF Get images($path; $params)
```

Rendering only the first page at a specific resolution:

```4d
$params:=New object:C1471("start"; 1; "end"; 1; "hdpi"; 300; "vdpi"; 300)
$status:=XPDF Get images($path; $params)

If (($status.success) & ($status.images.length>0))
	C_PICTURE:C286($firstPage)
	$firstPage:=$status.images[0]
End if 
```

---

## XPDF Get info

**`XPDF Get info ( path : Text ; options : Object ) → Object`**

### Syntax

```
XPDF Get info ( path : Text ; options : Object ) → status : Object
```

| Parameter | Type | Description |
|---|---|---|
| `path` | Text | Path to the PDF file to read. Mandatory. |
| `options` | Object | Options (see below). Optional — omit for all defaults. |
| Result | Object | Status object: `success`, `info` (Object, see below) on success, `error`/`errorMessage` on failure. |

**`options` properties** (all optional):

| Property | Type | Description |
|---|---|---|
| `start` | Number | First page to include in `info.pages` (1-based). Values ≤ 0 are ignored (default: page 1). Does not affect document-level metadata. |
| `end` | Number | Last page to include in `info.pages`. Omitted, ≤ 0, or beyond the page count defaults to the last page. |
| `rawDates` | Boolean | When `true`, `CreationDate`/`ModDate` are left in their raw PDF/XMP date-string form. When `false` (default), they're reformatted using the system locale's date/time format. |
| `ownerPassword` | Text | Owner password, if the PDF is encrypted. |
| `userPassword` | Text | User password, if the PDF is encrypted. |

**`status.info` object** (present when `success` is `true`):

| Property | Type | Description |
|---|---|---|
| `Title`, `Subject`, `Keywords`, `Author`, `Creator`, `Producer` | Text | Present only if found in the PDF's Info dictionary or XMP metadata. |
| `CreationDate`, `ModDate` | Text | Present only if found; formatted per locale unless `rawDates` is `true`. |
| `isTagged` | Boolean | Whether the document has a tagged structure tree (accessibility tagging). |
| `form` | Text | One of `"none"`, `"AcroForm"`, `"staticXFA"`, `"dynamicXFA"`. |
| `numPages` | Number | Total page count. |
| `isEncrypted` | Boolean | Whether the document is encrypted. |
| `okToPrint`, `okToCopy`, `okToChange`, `okToAddNotes` | Boolean | Present only when `isEncrypted` is `true`. Document permission flags. |
| `isLinearized` | Boolean | Whether the PDF is linearized ("fast web view"). |
| `version` | Number | PDF version (e.g. `1.7`). |
| `metadata` | Text | Raw XMP metadata block, if present. |
| `pages` | Collection of Object | One entry per page in the `start`/`end` range — see below. |

**Each entry in `pages`:**

| Property | Type | Description |
|---|---|---|
| `hdpi`, `vdpi` | Number | The page's natural rendering resolution as reported by xpdf's image output stage. |
| `width`, `height` | Number | Crop-box width/height, in points. |
| `paper` | Text | `"letter"` or `"A0"`–`"A6"` if the page size matches within tolerance; omitted otherwise. |
| `rotate` | Number | Page rotation, in degrees. |
| `mediaBox`, `cropBox`, `bleedBox`, `trimBox`, `artBox` | Object | Each an object with `x1`, `y1`, `x2`, `y2` (points). Omitted for a page whose internal page-tree entry couldn't be resolved (a rare, malformed-PDF case). |

### Description

`XPDF Get info` reads both the PDF's classic Info dictionary and, where present, its XMP metadata packet — for the overlapping fields (`Title`/`dc:title`, `Author`/`dc:creator`, etc.) XMP takes precedence when both exist and disagree, because it's read second and overwrites the Info-dictionary value. Fields absent from both sources are simply omitted from `info`, not returned as empty strings.

Unlike [`XPDF Get text`](#xpdf-get-text) and [`XPDF Get images`](#xpdf-get-images), this command does not check the document's copy-permission flag — metadata is read regardless of `okToCopy`.

### Example

From the plugin's own test method (`TEST_INFO.4dm`):

```4d
$path:=System folder:C487(Desktop:K41:16)+"test.pdf"

$params:=New object:C1471("rawDates";True:C214)

$status:=XPDF Get info ($path;$params)
```

Reading page count and per-page sizes for a specific range:

```4d
$params:=New object:C1471("start"; 1; "end"; 3)
$status:=XPDF Get info($path; $params)

If ($status.success)
	ALERT:C41("Document has "+String:C10($status.info.numPages)+" pages")
	
	For each ($page; $status.info.pages)
		ALERT:C41("Page size: "+String:C10($page.width)+" x "+String:C10($page.height)+" pt")
	End for each 
End if 
```

---

## Error handling & troubleshooting

- **Always check `success` first.** All three commands return a status `Object` unconditionally; a failed call is not a 4D method error, it's `success: false` with `error`/`errorMessage` fields to inspect.
- **`errorMessage: "copy is not allowed"` means the PDF's own permission flags forbid extraction** (`XPDF Get text`/`XPDF Get images` only) — this happens even with a correct `userPassword`/`ownerPassword`, since it reflects the document's stated permissions, not whether you could unlock it.
- **`errorMessage: "failed to open pdf"` with a numeric `error` code** covers everything from a missing/unreadable file to a corrupt or wrong-password-protected PDF — the numeric code is xpdf's own internal error code, useful for logging but not meant to be pattern-matched against a specific 4D-documented list.
- **A missing page range silently clamps rather than errors.** `start`/`end` values ≤ 0, non-numeric, or beyond the document's actual page count are clamped to the valid range (or ignored) rather than causing a failure — you won't get an error for asking for `"end": 9999` on a 3-page document, you'll just get pages up to the last one.
- **`XPDF Get images` can return fewer pictures than pages requested.** If a single page's PNG encoding fails, that page is dropped from `images` rather than failing the whole call — compare the length of `status.images` to your expected page count if this matters to your workflow.
- **`hdpi`/`vdpi` are capped at 2400.** Requesting a higher resolution won't error, it will silently render at the cap — if you need genuinely higher-resolution output, check your build of the plugin for whether this cap has been adjusted.
- **Font substitution quality in `XPDF Get images` depends on the plugin's bundled fontconfig setup**, resolved automatically at plugin startup; if rendered text looks wrong (missing glyphs, substituted fonts) this is the first thing to check, and it isn't something you configure per-call.

---

## Quick reference

```4d
// Text
$status:=XPDF Get text($path; New object:C1471("layout"; "table"; "start"; 1; "end"; 5))
If ($status.success)
	$text:=$status.text
End if 

// Images
$status:=XPDF Get images($path; New object:C1471("hdpi"; 300; "vdpi"; 300; "gray"; True:C214))
If ($status.success)
	For each ($image; $status.images)
		WRITE PICTURE FILE:C680($folder+String:C10($ii)+".png"; $image)
	End for each 
End if 

// Info
$status:=XPDF Get info($path; New object:C1471("rawDates"; False:C215))
If ($status.success)
	$numPages:=$status.info.numPages
	$title:=$status.info.Title
End if 
```
