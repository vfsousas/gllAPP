<!DOCTYPE html>
<html lang="en">

  <head>
  
	<link href="/favicon.ico" rel="shortcut icon">
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="description" content="issues found">
    <meta name="author" content="Willian Richard dos Santos">
    <title>Percentage of errors</title>
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.1/css/bootstrap.min.css">
	<link href="//netdna.bootstrapcdn.com/bootstrap/3.2.0/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="//cdnjs.cloudflare.com/ajax/libs/bootstrap-select/1.6.3/css/bootstrap-select.min.css" />
	<link rel="stylesheet" href="style.css">
  </head>
  <body>
    <h1 class="page-header text-center">Percentage of errors</h1>
<?php

include "../db/connect.php";
$query = "SELECT * FROM gll_automation.executions";	
$Errors_table = "rio_udas_0010_20161205_000001_p1m3_copy";
$Table_2 = "SELECT * FROM gll_automation.rio_udas_0010_20161205_000001_p1m3_copyd"; 
$count_line = 0;
$count_line2 = 0;
$result = mysqli_query($con, $query);	
 	echo "<table border=1>"; //Criamos a tabela
 	echo "<tr><td WIDTH=100><b><p align=\"center\">ID</td></p></b>" 	// Aqui criamos o cabeçalho da tabela.
			."<td WIDTH=350><b><p align=\"center\">File Name</td></p></b>"
			."<td WIDTH=100><b><p align=\"center\">Line</td></p></b>"
			."<td WIDTH=200><b><p align=\"center\">Start Time</td></p></b>"
			."<td WIDTH=200><b><p align=\"center\">End Time</td></p></b>"
			."<td WIDTH=300><b><p align=\"center\">Error Message</td></p></b>"
 		."</tr>";  // Fechamos o cabeçalho. Vamos percorrer o array, e fazer a mesma coisa que fizemos em cima. Montar uma linha, e as células da tabela.
 	while($row = mysqli_fetch_array($result)) {
 	    $id         = $row['ID'];	
 		$filename   = $row['filename'];
 		$line       = $row['line'];
 		$start_time = $row['start_time'];
 		$end_time   = $row['end_time'];
 		$error_msg  = $row['error_msg'];
		If ($filename == $Errors_table){	
			echo "<tr><td><p align=\"center\">$id</p>"
					."<td><p align=\"left\">$filename</p>"
					."<td><p align=\"center\">$line</p>"
					."<td><p align=\"center\">$start_time</p>"
					."<td><p align=\"center\">$end_time</p>"
					."<td><p align=\"center\">$error_msg</td></p>"
				."</tr>";
			$count_line++;
		}	
 	}	
		echo "</table>";  // E fora do while fechamos a tabela.	
		
		if ($count_line==0) {
			echo "<br><p style=\"background:green; color:white;\" align=\"center\"><font size=\"2\" face=\"Verdana\">YAY! There are no errors for this table</font></p>";
		}
//-------------------------------------------------------------------------------------------------------
$query2 = "SELECT * FROM gll_automation.rio_udas_0010_20161205_000001_p1m3_copy";	
$count_line2 = 0;
$result2 = mysqli_query($con, $query2);
$total = 0;
 	while($row = mysqli_fetch_array($result2)) {
		$count_line2++;
	}
	$total = ($count_line*100)/$count_line2;
	$total = round ($total,3);
	if (@$total != 0){
	echo "<br><p style=\"background:red; color:white;\" align=\"center\"><font size=\"2\" face=\"Verdana\">This file has a total of $total% errors</font></p>";
	}
//-------------------------------------------------------------------------------------------------------

?>
<div class="footer" >
<img src="IBM.png" alt="IBM" style="float:left;width:42px;height:18px;">
   &copy; <a href=""> Percentage Function</a>
<i class="fa fa-circle-thin">Created by </i>Skywalker Team</a>
</div>
  <script src="https://ajax.googleapis.com/ajax/libs/jquery/1.11.2/jquery.min.js"></script>
  <script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.2/js/bootstrap.min.js"></script>
  <script src="//cdnjs.cloudflare.com/ajax/libs/bootstrap-select/1.6.3/js/bootstrap-select.min.js"></script>
  </body>
</html>