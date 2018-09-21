<?php

session_start();
include "../db/connect.php";
date_default_timezone_set("Brazil/East");
$query = "SELECT * FROM information_schema.TABLES WHERE TABLE_SCHEMA = 'gll_automation' AND TABLE_NAME LIKE '%_errors_results' ORDER BY TABLE_NAME DESC";
$result = mysqli_query($GLOBALS['con'], $query);
if(!$result){
	die('Updating ID - fatal error'.mysqli_error($GLOBALS['con']));
}
echo "<table border='1' style='width:100%'>";
while($table = mysqli_fetch_array($result)) { 
	echo "<tr>";
	$arr = explode("_", $table['TABLE_NAME']);
	$name = $arr[0];
	echo "<td>$name</td>";
	
	$ticket_name = str_replace($name."_", "", $table['TABLE_NAME']);
	$ticket_name = str_replace("_errors_results", "", $ticket_name);
	$datetimeFormat = 'Y-m-d H:i:s';
	$date = new DateTime();
	$date->setTimestamp($ticket_name/1000);
	echo "<td>".$date->format($datetimeFormat)."</td>";
	echo "<td align='center'>".$ticket_name."</td>";  
	echo "<td align='center'> view</td>";
	echo "<td align='center'><a href='#' onClick='downlodCSV(".$ticket_name.")'> CSV Download </a></td>";
	echo "<td align='center' ><a href='#' onClick='downlodXLS(".$ticket_name.")'> XLS Download </a> </td>";
	echo "<tr>";
}
echo "</table>";

?>