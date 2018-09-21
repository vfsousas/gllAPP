<?php

session_start();
include "../db/connect.php";
date_default_timezone_set("Brazil/East");

$query = "use gll_dump";
$result = mysqli_query($GLOBALS['con'], $query);


$query = "SHOW tables like '%".$_GET['ticket']."%' ";
$result = mysqli_query($GLOBALS['con'], $query);
if(!$result){
	die('Select tables - fatal error '.mysqli_error($GLOBALS['con']));
}

$table = mysqli_fetch_array($result);
$table_name = $table[0];


$error_results_table_name = $_SESSION['username']."_".$_GET['ticket']."_errors_results";

$query = "SELECT filename, COUNT(issue) as countIssue FROM gll_dump.$error_results_table_name GROUP BY filename";
$result = mysqli_query($GLOBALS['con'], $query);
if(!$result){
	die('Updating ID - fatal error'.mysqli_error($GLOBALS['con']));
}

echo "<table border='1' style='width:100% ' class='panel panel-default' >";
echo "<tr class='panel-title' align='center' bgcolor='#f5f5f5'>";
echo "<h4><td>File Name</td><td>Number Defects Found</td></h4>";
echo "</tr>";
while($table = mysqli_fetch_array($result)) { 
	echo "<tr class'panel-heading' align='center'>";
	$fileName = str_ireplace($_SESSION['username']."_".$_GET['ticket']."_", "",  $table['filename']);
	echo "<td>$fileName</td>";
	echo "<td>".$table['countIssue']."</td>";
	echo "<tr>";
}
echo "</table>";



$query = "SELECT start_time, end_time, timediff(end_time, start_time) as difftime, FORMAT(rows_count,2) as rowscount, FORMAT(defects_found,2) as defectsfound FROM gll_automation.audit WHERE files like '%".$_GET['ticket']."%'";
$result = mysqli_query($GLOBALS['con'], $query);
if(!$result){
	die('Error retriveing data from Audit Table - fatal error'.mysqli_error($GLOBALS['con']));
}

echo "<table border='1' style='width:100% ' class='panel panel-default' >";
echo "<tr class='panel-title' align='center' bgcolor='#f5f5f5'>";
echo "<h4><td>Start Time Execution</td><td>End Time Execution</td><td>Total Time Execution</td><td>Rows Processed</td> <td>Total Defects Found</td></h4>";
echo "</tr>";
while($table = mysqli_fetch_array($result)) { 
	echo "<tr class'panel-heading' align='center'>";
	echo "<td>".$table['start_time']."</td>";
	echo "<td>".$table['end_time']."</td>";
	echo "<td>".$table['difftime']."</td>";
	echo "<td>".$table['rowscount']."</td>";
	echo "<td>".$table['defectsfound']."</td>";
	echo "<tr>";
}
echo "</table>";


$query = "SELECT * FROM gll_dump.$table_name LIMIT 100";
$result = mysqli_query($GLOBALS['con'], $query);
if(!$result){
	die('Updating ID - fatal error'.mysqli_error($GLOBALS['con']));
}

echo "<style>tr:nth-of-type(odd) {background-color:#ccc;    }</style>";
echo "<table border='1' style='width:100% ' class='panel panel-default' >";
echo "<tr class='panel-title' align='center' bgcolor='#f5f5f5'>";
echo "<h4><td>File Name</td><td>Row Number</td><td>Issue</td></h4>";
echo "</tr>";
while($table = mysqli_fetch_array($result)) { 
	echo "<tr class'panel-heading' align='center'>";
	$fileName = str_ireplace($_SESSION['username']."_".$_GET['ticket']."_", "",  $table['filename']);
	echo "<td>$fileName</td>";
	echo "<td>".$table['row']."</td>";
	echo "<td>".$table['issue']."</td>";
	echo "<tr>";
}
echo "</table>";


?>