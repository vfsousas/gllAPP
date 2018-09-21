<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN">
<html lang="en">
<head>
    <title>Progress Bar</title>
</head>
<body>
<!-- Progress bar holder -->
<div id="progress" style="width:500px;border:1px solid #ccc;"></div>
<div id="progressDB" style="width:500px;border:1px solid #ccc;"></div>
<!-- Progress information -->
<div id="information" style="width"></div>

<?php
$tablename = "xxxxxx";
uploadFilesToFolder();
uploadFilesToDB($tablename);
echo "<h1> FIM </h1>";


function uploadFilesToFolder(){
	$total = count($_FILES['fileUpload']['name']);
	
	for($i=0; $i<$total; $i++) {
		$percent = intval($i/$total * 100)."%";
		$uploadOk = 1;
		date_default_timezone_set("Brazil/East"); //Definindo timezone padrão
		$ext = strtolower(substr($_FILES['fileUpload']['name'][$i],-4)); //Pegando extensão do arquivo
		$new_name = $_FILES['fileUpload']['name'][$i]. $ext; //Definindo um novo nome para o arquivo
		$tmpFilePath = $_FILES['fileUpload']['tmp_name'][$i];
		$table_name = $_FILES['fileUpload']['name'][$i]; //Definindo um novo nome para a tabela
		
		$GLOBALS['tablename']=$table_name;
		$dir = 'gll_files/'; //Diretório para uploads
		$target_file =  $dir.$new_name;
	
		if (file_exists($target_file)) {
			echo "Sorry, file already exists. <br>";
			$uploadOk = 0;
		}
	
		if($_FILES['fileUpload']['type'][$i]!="application/octet-stream"){
			echo "Sorry, only INP Files are allowed. <br>";
			$uploadOk = 0;
		}
	
	
		if ($uploadOk == 0) {
			echo "Sorry, your file was not uploaded. <br>";
			// if everything is ok, try to upload file
		} else {
			if (move_uploaded_file($tmpFilePath, $target_file)) {
				echo "The file ". basename( $_FILES["fileUpload"]["name"][$i]). " has been uploaded.<br>";
			} else {
				die("Sorry, there was an error uploading your file.<br>");
			}
		}
		echo '<script language="javascript">
					document.getElementById("progress").innerHTML="<div style=\"width:'.$percent.';background-color:#ddd;\">&nbsp;</div>";
					document.getElementById("information").innerHTML="'.$i.' row(s) processed.";
			 </script>';
	}
}

function uploadFilesToDB($tablename){
  include "../db/connect.php";	
  $path    = 'gll_files';
  $files = scandir($path);
  $countFiles = 0;
  $rowCount = 0;
  $startTime = date('H:i:s');
  foreach($files as $temp_files){
  	
  	
  	if(strpos($temp_files, "inp")!=false){
  		$percent = intval($countFiles/count($files) * 100)."%";
  		$myfile = fopen("gll_files/{$temp_files}", "r") or die("Unable to open file!");
  		while(!feof($myfile)) {
  			$array_line = explode("||", fgets($myfile) );
  			$num_tags = count($array_line);
  			break;
  		}
  		$table_name = str_replace("INP", "", $temp_files);
  		$table_name = str_replace("inp", "", $table_name);
  		$table_name = str_replace(".", "", $table_name);
  		//check if exists
  		$val = mysqli_query($con, "select 1 from gll_automation.{$table_name}");
  		
  		if(!$val){
  			//$colQuery = "id int(11) NOT NULL AUTO_INCREMENT,";
  			$colQuery ="";
  			for($j=0; $j< $num_tags; $j++){
  				$colQuery .= "column_{$j} TEXT NULL,";
  			}
  			//$colQuery .= "PRIMARY KEY (id)";
  			$query = "CREATE TABLE IF NOT EXISTS gll_automation.{$table_name} ({$colQuery});";
  			$query= str_replace(",)", ")", $query);
  			if(!mysqli_query($con, $query)){
  				echo $query;
  				die('fatal error'.mysql_error());
  			}
  				
  			$columns = str_replace(" TEXT NULL", "", $colQuery);
  			$query_import_file = "LOAD DATA INFILE 'C:/xampp/htdocs/gll_automation/uploads/gll_files/{$temp_files}'
  			INTO TABLE gll_automation.{$table_name}
  			COLUMNS TERMINATED BY '||'
  			LINES TERMINATED BY '\n'
  			({$columns})";
  			$query_import_file = str_replace(",)", ")", $query_import_file);
  			if(!mysqli_query($con, $query_import_file)){
  				echo $query_import_file;
  				die('fatal error'.mysql_error());
  			}

			$updateID = "ALTER TABLE gll_automation.{$table_name} ADD id int NOT NULL AUTO_INCREMENT primary key FIRST";

			if(!mysqli_query($con, $updateID)){
  				die('fatal error'.mysql_error());
  			}

  				
  			echo "Inserted {$rowCount} lines<br>";
  			Echo "Initial time {$startTime} <br>";
  			$endTime = date('H:i:s');
  			echo "End time {$endTime}";
  			echo '<script language="javascript">
					document.getElementById("progressDB").innerHTML="<div style=\"width:'.$percent.';background-color:#ddd;\">&nbsp;</div>";
					document.getElementById("information").innerHTML="'.$countFiles.' row(s) processed.";
			 </script>';
  			
  			$countFiles++;
  		}else{
  			echo "File already exists in DB";
  		}
  		fclose($myfile);
  		chmod("C:/xampp/htdocs/gll_automation/uploads/gll_files/{$temp_files}",0777);
  		unlink ("C:/xampp/htdocs/gll_automation/uploads/gll_files/{$temp_files}");
  	}
   }
  }

?>	
	