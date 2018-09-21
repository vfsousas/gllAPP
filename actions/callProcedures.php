<?php

session_start();
require_once '../excel/PHPExcel/PHPExcel.php';
include "../db/connect.php";
$path = "../server/php/files/" . session_id();
chmod($path, 0777);
	
	$start_time = date('mm/dd/YYYY h:i:s', time());
	foreach (new DirectoryIterator($path) as $file) {
		if ($file->isFile()) {
			$fileName = strtolower($file->getFilename());
			if(strpos($fileName, ".xls")){
				$xlsfile = $fileName;
			}
		}
	}
				
	$xlsfile = str_replace(".xls", "", $xlsfile);
	$xlsfile = $_SESSION['username']."_".$_GET['nowtime']."_xls_".$xlsfile;
	
	$event_create = "CREATE 
	EVENT gll_automation.".$xlsfile	."
	ON SCHEDULE AT CURRENT_TIMESTAMP + INTERVAL 30 SECOND
	 DO BEGIN
	 
	 SELECT now() into @starttime;\n
	";
	
	$query = "";
	$gll_files_pool = "";
	$total_rows = 0;
	$total_rows_errors = 0;
	$results = $_SESSION['username']."_".$_GET['nowtime']."_errors_results";
	
	
	$tmstmp = $_GET['nowtime'];
	
	foreach (new DirectoryIterator($path) as $file) {
		if ($file->isFile()) {
			$fileName = strtolower($file->getFilename());
			if(strpos($fileName, ".inp")){
				//gll_table, xls_table, result_table
				$gllfile = strtolower($_SESSION['username']."_".$_GET['nowtime']."_".$fileName);
				$gllfile_new = str_replace(".inp", "", $gllfile);
				$gll_files_pool =$gll_files_pool.";".$gllfile_new;
				
				$result = mysqli_query($GLOBALS['con'], "select count(*) FROM gll_automation.$gllfile_new");
				if (!$result) {
					printf("ERROR: Not possible count values from table $gllfile_new <br> Mysql output=", mysqli_error($GLOBALS['con']));
					exit();
				}
				$row = mysqli_fetch_array($result);
				$total_rows = $total_rows + $row[0];
				
				$query = "\n ". strtolower("call populate('$gllfile_new', '$xlsfile', '$results', '$tmstmp');");
				$query = $query ."\n ".strtolower("DROP TABLE IF EXISTS gll_automation.$gllfile_new;");
				$event_create .= " " . $query;
			}			
		}
			$query = "select count(*) FROM gll_automation.$results";
			$result = mysqli_query($GLOBALS['con'],$query);
			if (!$result) {
					printf("ERROR: Not possible count values from table $results <br> Mysql output=<br>", mysqli_error($GLOBALS['con']));
					exit();
				}
		}	
		$row = mysqli_fetch_array($result);
			$total_rows_errors = $total_rows_errors + $row[0];
			//$event_create =  $event_create.' DROP EVENT IF EXISTS '.$GLOBALS['xlstable'].';';
			$event_create .= "\n ".strtolower("DROP TABLE IF EXISTS ".$xlsfile.";");
			$event_create .= "SET @end_time = now();";
			$event_create .= "INSERT INTO `audit` (`id`, `owner`, `files`, `start_time`, `end_time`, `rows_count`, `defects_found`) VALUES (NULL, '".$_SESSION['username']."', '$gll_files_pool', @starttime, now(), '$total_rows', (select count(*) FROM $results));";
			$event_create = $event_create ."END";
			if(!mysqli_query($GLOBALS['con'], $event_create)){
						echo "<BR>$event_create<br>";
						die('ERROR: Not possible insert values in audit table <br> Mysql output=<br>'.mysqli_error($GLOBALS['con']));
			}
			
			sleep(5);
			echo "Done";
?>