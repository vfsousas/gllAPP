<?php

session_start();
require_once '../excel/PHPExcel/PHPExcel.php';
include "../db/connect.php";
$path = "../server/php/files/" . session_id();
chmod($path, 0777);
	
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
	
	$results = $_SESSION['username']."_".$_GET['nowtime']."_errors_results";
	
	$tmstmp = $_GET['nowtime'];
	
	
foreach (new DirectoryIterator($path) as $file) {
		if ($file->isFile()) {
			$fileName = strtolower($file->getFilename());
			if(strpos($fileName, ".inp")){
				//gll_table, xls_table, result_table
				$gllfile = strtolower($_SESSION['username']."_".$_GET['nowtime']."_".$fileName);
				$gllfile_new = str_replace(".inp", "", $gllfile);
								
					
				$query = "\n ". strtolower("call gll_automation.populate('$gllfile_new', '$xlsfile', '$results', '$tmstmp');");
				while(mysqli_more_results($GLOBALS['con']) && mysqli_next_result($GLOBALS['con']));
				if(!mysqli_query($GLOBALS['con'], $query)){
					die("ERROR: Not possible call the procedure POPULATE <br> Mysql output=".mysqli_error($GLOBALS['con']));
				}
				while(mysqli_more_results($GLOBALS['con']) && mysqli_next_result($GLOBALS['con']));
			}			
		}
}	
		
			
?>