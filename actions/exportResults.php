<?php

session_start();
include "../db/connect.php";


$query = "SELECT * FROM information_schema.TABLES WHERE TABLE_SCHEMA = 'gll_automation' AND TABLE_NAME LIKE '%".$_GET['ticket']."%_errors_results' ORDER BY TABLE_NAME DESC";
$result = mysqli_query($GLOBALS['con'], $query);
if(!$result){
	die("ERROR: Not possible select all values in the error_results <br> Mysql output=".mysqli_error($GLOBALS['con']));
}

while($table = mysqli_fetch_array($result)) { 
	$table_name = $table['TABLE_NAME'];
}



$query = "SELECT * FROM gll_automation.$table_name";
$result = mysqli_query($GLOBALS['con'], $query);
if (!$result) die("ERROR: Not possible select all values in the table $table_name<br> Mysql output=".mysqli_error($GLOBALS['con']));

$headers = $result->fetch_fields();

foreach($headers as $header) {
    $head[] = $header->name;
}

$fp = fopen('php://output', 'w');

if ($fp && $result) {
    
	if($_GET['type']=="csv"){
		header('Content-Type: text/csv');
		header('Content-Disposition: attachment; filename="'.$table_name.'.csv"');
	}else{
		header("Content-type: application/vnd.ms-excel; name='excel'");
		header('Content-Disposition: attachment; filename="'.$table_name.'.xls"');
	}
    header('Pragma: no-cache');
    header('Expires: 0');
    fputcsv($fp, array_values($head)); 
    while ($row = $result->fetch_array(MYSQLI_NUM)) {
        fputcsv($fp, array_values($row));
    }
    die;
}

?>