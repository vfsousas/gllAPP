<?php

session_start();
include "../db/connect.php";
date_default_timezone_set("Brazil/East");
$query = "SELECT * FROM information_schema.TABLES WHERE TABLE_SCHEMA = 'gll_automation' AND TABLE_NAME LIKE '%".$_GET['ticket']."%' ORDER BY TABLE_NAME DESC";
$result = mysqli_query($GLOBALS['con'], $query);
if(!$result){
	die('"ERROR: Not possible retrieve the tickets list<br> Mysql output="'.mysqli_error($GLOBALS['con']));
}
$table = mysqli_fetch_array($result);


$query = "DROP TABLE IF EXISTS gll_automation.".$table['TABLE_NAME'];
$result = mysqli_query($GLOBALS['con'], $query);
if(!$result){
	die("ERROR: Not possible drop the table  ".$table['TABLE_NAME']." <br> Mysql output=".mysqli_error($GLOBALS['con']));
}

?>