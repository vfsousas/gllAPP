<?php
session_start();
include "../db/connect.php";
$path    = "../server/php/files/".session_id();
chmod($path, 0777);
$column = null;
$column_import = null;
foreach (new DirectoryIterator($path) as $file) {
	if ($file->isFile()) {
		$fileName = strtolower($file->getFilename());
		if(strpos($fileName, ".csv")){
			
			//limpando o nome para a tabela
			$table_name = str_replace("CSV", "", $fileName);
			$table_name = str_replace("csv", "", $table_name);
			$table_name = str_replace(".", "", $table_name);
			$table_name = $_SESSION['username']."_".$_GET['nowtime']."_".$table_name;
			echo "<br>Uploading CSV file = $fileName";
			
			$myfile = fopen($path."/".$fileName, "r") or die("Unable to open file!");
			while (($line = fgetcsv($myfile)) !== FALSE) {
				//$line is an array of the csv elements
				//print_r($line);
				$arr_length = count($line);
				For($i=0;$i<$arr_length;$i++){
					
					if($line[$i]<>""){
						
						if(strpos($line[$i], '.') !== FALSE ){
							$array_line = explode(".", $line[$i] );
							$column .= $array_line[1]." varchar(250), ";	
							$column_import .= $array_line[1].",";
						}else{
							$column .= $line[$i]." varchar(250), ";	
							$column_import .= $line[$i].",";
						}
					}	
				}
				
				break;
			}
			fclose($myfile);
				
			
			$query = "create table if not exists gll_dump.$table_name ($column);";
			$query = str_replace(", )", ")",$query);
			if (!mysqli_query($GLOBALS['con'], $query)) {
				echo $query;
                die('UPLOAD DUMP ERROR fatal error' . mysqli_error($GLOBALS['con']));
            }
			$query_import_file = "LOAD DATA INFILE 'C:/xampp/htdocs/gll_automation/server/php/files/".session_id()."/$fileName'
				INTO TABLE gll_dump.{$table_name}
				FIELDS TERMINATED BY ','
				LINES TERMINATED BY '\n'
				IGNORE 1 LINES
				($column_import)";
				$query_import_file = str_replace(",)", ")", $query_import_file);

				if(!mysqli_query($GLOBALS['con'], $query_import_file)){
					echo "<br>$query_import_file";
					die('Insert GLL values into table - fatal error'.mysqli_error($GLOBALS['con']));
					
				}
		
			
				//efetuando o tri, em todas as colunas
			$coluns_arr = explode(",",$column_import );	
			$arr_length = count($coluns_arr);
			For($i=0;$i<$arr_length-1;$i++){
				$query = "UPDATE gll_dump.$table_name SET ".$coluns_arr[$i]." = TRIM(".$coluns_arr[$i].")";
				if(!mysqli_query($GLOBALS['con'], $query)){
					die('TRIM COLUMNS 	- fatal error'.mysqli_error($GLOBALS['con']));
					
				}
				
			}
				$column = "";
				$column_import ="";
		}
	}
}

			$query = "call gll_dump.executedump_".$_GET['nowtime'].";";
			$query = str_replace(", )", ")",$query);
			if (!mysqli_query($GLOBALS['con'], $query)) {
                die('Call EXECUTEDUMP ERROR' . mysqli_error($GLOBALS['con']));
            }
?>