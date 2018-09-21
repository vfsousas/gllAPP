<?php
session_start();
require_once '../excel/PHPExcel/PHPExcel.php';
include "../db/connect.php";
$path = "../server/php/files/" . session_id();
chmod($path, 0777);


$query = "CREATE TABLE gll_dump.".$_SESSION['username']."_".$_GET['nowtime']."_errors_results (
				ID int(11) NOT NULL,
				filename varchar(300) NOT NULL,
				row varchar(30) NOT NULL,
				issue varchar(300) NOT NULL,
				other varchar(100) NOT NULL)";
	if(!mysqli_query($GLOBALS['con'], $query)){
  				die("ERROR: Not possible create the table to sabe dump results<br> Mysql output=".mysqli_error($GLOBALS['con']));
	}
	
	$query = "ALTER TABLE gll_dump.".$_SESSION['username']."_".$_GET['nowtime']."_errors_results ADD PRIMARY KEY (ID)";
	if(!mysqli_query($GLOBALS['con'], $query)){
  				die("ERROR: Not possible create the table to sabe dump results<br> Mysql output=".mysqli_error($GLOBALS['con']));
	}
	
	$query = "ALTER TABLE gll_dump.".$_SESSION['username']."_".$_GET['nowtime']."_errors_results MODIFY ID int(11) NOT NULL AUTO_INCREMENT";
	if(!mysqli_query($GLOBALS['con'], $query)){
  				die("ERROR: Not possible modify the table erros results to insert ID column<br> Mysql output=".mysqli_error($GLOBALS['con']));
	}
	?>