//%attributes = {}
$path:=System folder:C487(Desktop:K41:16)+"公開講演予定表0415.pdf"

$params:=New object:C1471("gray";True:C214)

$status:=XPDF Get images ($path;$params)

C_PICTURE:C286($image)

For each ($image;$status.images)
	SET PICTURE TO PASTEBOARD:C521($image)
End for each 

$params:=New object:C1471("mono";True:C214)

$status:=XPDF Get images ($path;$params)

C_PICTURE:C286($image)

For each ($image;$status.images)
	SET PICTURE TO PASTEBOARD:C521($image)
End for each 

$status:=XPDF Get images ($path)

C_PICTURE:C286($image)

For each ($image;$status.images)
	SET PICTURE TO PASTEBOARD:C521($image)
End for each 