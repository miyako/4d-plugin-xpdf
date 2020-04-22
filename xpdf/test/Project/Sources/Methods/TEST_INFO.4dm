//%attributes = {}
$path:=System folder:C487(Desktop:K41:16)+"test.pdf"

$params:=New object:C1471("rawDates";True:C214)

$status:=XPDF Get info ($path;$params)
