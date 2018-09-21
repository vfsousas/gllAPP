<html>
<style>
.table tr {
    transition: background 0.2s ease-in;
}

.table tr:nth-child(odd) {
    background: silver;
}

.table tr:hover {
    background: silver;
    cursor: pointer;
}
</style>
<?php

session_start();
include "../db/connect.php";
date_default_timezone_set("Brazil/East");
$query = "SELECT * FROM information_schema.TABLES WHERE TABLE_SCHEMA = 'gll_automation' AND TABLE_NAME LIKE '%".$_SESSION['username']."%_errors_results' ORDER BY TABLE_NAME DESC";
$result = mysqli_query($GLOBALS['con'], $query);
if(!$result){
	die('Updating ID - fatal error'.mysqli_error($GLOBALS['con']));
}

echo "<table border='1' style='width:100% ' class='panel panel-default' >";
echo "<tr class='panel-title' align='center' bgcolor='#f5f5f5'>";
echo "<h4><th>Execution Date</th><th>Ticket Number</th><th style='width:30%' colspan='2'>Execution Status</th><th style='width:30%'>Actions</th></h4>";
echo "</tr>";
while($table = mysqli_fetch_array($result)) { 
	echo "<tr align='center'>";
	$sessionname = strtolower($_SESSION['username']);
	$table_name = strtolower($table['TABLE_NAME']);
	$ticket_name = str_replace($sessionname."_", "", $table_name);
	$ticket_name = str_replace("_errors_results", "", $ticket_name);

	$datetimeFormat = 'Y-m-d H:i:s';
	$date = new DateTime();
	$date->setTimestamp($ticket_name/1000);
	echo "<td>".$date->format($datetimeFormat)."</td>";
	echo "<td align='center'>".$ticket_name."</td>";  
	
	$query_count ="Select COUNT(*)  as count from information_schema.events where event_name like '%".$_SESSION['username']."_$ticket_name%'";
	$result_status = mysqli_query($GLOBALS['con'], $query_count);
	if(!$result_status){
		die('Updating ID - fatal error'.mysqli_error($GLOBALS['con']));
	}
	$table_status = mysqli_fetch_array($result_status);
	if($table_status['count']=="1"){
			echo "<td align='center'> <button type='button' class='btn btn-success' > <i class='glyphicon glyphicon-dashboard'></i> Running </button></td>";
			echo "<td></td>";
	}else{
			$query_count ="Select COUNT(*)  as count from information_schema.tables where table_schema = 'gll_dump' AND table_name like '%".strtolower($_SESSION['username'])."_$ticket_name%'";
			$result_status = mysqli_query($GLOBALS['con'], $query_count);
			$table_count = mysqli_fetch_array($result_status);

			if(!$result_status){
				die('Listing your ticktes - fatal error'.mysqli_error($GLOBALS['con']));
			}
			if($table_count['count']=='0'){
				echo "<td align='center'> <button type='button' class='btn btn-primary start' onClick='viewTicket(".$ticket_name.")'> <i class='glyphicon glyphicon glyphicon-eye-open'></i> Completed </button></td><td>&nbsp;</td>";
				echo "<td align='center' ><button type='button' class='btn btn-info active'  onClick='downlodCSV(".$ticket_name.")'> <i class='glyphicon glyphicon-cloud-download'></i> CSV </button>  <button type='button' class='btn btn-info active' onClick='downlodXLS(".$ticket_name.")'> <i class='glyphicon glyphicon-cloud-download'></i> XLS </button>  <button type='button' class='btn btn-danger destroy' onClick='deleteExecution(".$ticket_name.")'> <i class='glyphicon glyphicon-trash'></i> Delete </button> </td>";
			}else{
				echo "<td align='center'> <button type='button' class='btn btn-primary start' onClick='viewTicket(".$ticket_name.")'> <i class='glyphicon glyphicon glyphicon-eye-open'></i> Completed </button></td><td><button type='button' class='btn btn-primary start' onClick='viewTicketDUMP(".$ticket_name.")'>  <i class='glyphicon glyphicon glyphicon-eye-open'></i> DUMP </button></td>";
				echo "<td align='center' ><button type='button' class='btn btn-info active'  onClick='downlodCSV(".$ticket_name.")'> <i class='glyphicon glyphicon-cloud-download'></i> CSV </button>  <button type='button' class='btn btn-info active' onClick='downlodXLS(".$ticket_name.")'> <i class='glyphicon glyphicon-cloud-download'></i> XLS </button>  <button type='button' class='btn btn-danger destroy' onClick='deleteExecution(".$ticket_name.")'> <i class='glyphicon glyphicon-trash'></i> Delete </button> </td>";
			}
			
			

	}
	
	echo "<tr>";
}
echo "</table>";


?>
</html>