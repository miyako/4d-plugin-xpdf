//%attributes = {}
$path:=System folder:C487(Desktop:K41:16)+"test.pdf"

$status:=XPDF Get images ($path)

C_PICTURE:C286($image)

For each ($image;$status.images)
	SET PICTURE TO PASTEBOARD:C521($image)
End for each 

$params:=New object:C1471("gray";True:C214)

$status:=XPDF Get images ($path;$params)

For each ($image;$status.images)
	SET PICTURE TO PASTEBOARD:C521($image)
End for each 

$params:=New object:C1471("mono";True:C214)

$status:=XPDF Get images ($path;$params)

For each ($image;$status.images)
	SET PICTURE TO PASTEBOARD:C521($image)
End for each 