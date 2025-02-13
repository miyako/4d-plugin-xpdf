//%attributes = {}
$path:=System folder:C487(Desktop:K41:16)+"test.pdf"

$params:=New object:C1471
$params.layout:="line"
$params.fixedPitch:=5
$params.fixedLineSpacing:=10

$status:=XPDF Get text($path; $params)