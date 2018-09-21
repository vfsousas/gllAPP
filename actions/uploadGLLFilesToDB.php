<?php
session_start();
include "../db/connect.php";
$path    = "../server/php/files/".session_id();
chmod($path, 0777);

foreach (new DirectoryIterator($path) as $file) {
	if ($file->isFile()) {
		$fileName = strtolower($file->getFilename());
		if(strpos($fileName, ".inp")){
			$myfile = fopen($path."/".$fileName, "r") or die("Unable to open file!");
		
		while(!feof($myfile)) {
			$array_line = explode("||", fgets($myfile) );
			$num_tags = count($array_line);
			break;
		}
				//limpando o nome para a tabela
			$table_name = str_replace("INP", "", $fileName);
			$table_name = str_replace("inp", "", $table_name);
			$table_name = str_replace(".", "", $table_name);
			$table_name = $_SESSION['username']."_".$_GET['nowtime']."_".$table_name;
			
			
			mysqli_query($GLOBALS['con'], "DROP TABLE IF EXISTS gll_automation.{$table_name}");
			
			$colQuery ="";
			for($j=0; $j< $num_tags; $j++){
					$colQuery .= "column_{$j} TEXT NULL,";
			}
			mysqli_next_result($GLOBALS['con']);
			$query = "CREATE TABLE IF NOT EXISTS gll_automation.{$table_name} ({$colQuery});";
			$query= str_replace(",)", ")", $query);
			if(!mysqli_query($GLOBALS['con'], $query)){
				die("ERROR: Not possible create table to import GLL File <br> Mysql output=".mysqli_error($GLOBALS['con']));
			}
			
				
			$columns = str_replace(" TEXT NULL", "", $colQuery);
			$query_import_file = "LOAD DATA INFILE 'C:/xampp/htdocs/gll_automation/server/php/files/".session_id()."/$fileName'
				INTO TABLE gll_automation.{$table_name}
				FIELDS TERMINATED BY '||'
				LINES TERMINATED BY '\n'
				({$columns})";
				$query_import_file = str_replace(",)", ")", $query_import_file);
				if(!mysqli_query($GLOBALS['con'], $query_import_file)){
					die("ERROR: Not possible create table to import GLL File <br> Mysql output=".mysqli_error($GLOBALS['con']));
				}

				$updateID = "ALTER TABLE gll_automation.{$table_name} ADD id int NOT NULL AUTO_INCREMENT primary key FIRST";

				if(!mysqli_query($GLOBALS['con'], $updateID)){
					die("ERROR: Not possible create table to import GLL File <br> Mysql output=".mysqli_error($GLOBALS['con']));
				}
				
				$updateTbaleName = "ALTER TABLE gll_automation.{$table_name} ADD tablename VARCHAR(100) NULL AFTER ID"; 
				if(!mysqli_query($GLOBALS['con'], $updateTbaleName)){
					die("ERROR: Not possible update table and insert new column tablename <br> Mysql output=".mysqli_error($GLOBALS['con']));
				}
				

				
				$updateTbaleName = "UPDATE gll_automation.{$table_name} SET tablename='{$table_name}'";
				if(!mysqli_query($GLOBALS['con'], $updateTbaleName)){
					die("ERROR: Not possible update set value um the column table name<br> Mysql output=".mysqli_error($GLOBALS['con']));
				}
				
			$num_tags = $num_tags -1;
			$query = "ALTER TABLE  gll_automation.{$table_name} DROP COLUMN column_{$num_tags};";
			if(!mysqli_query($GLOBALS['con'], $query)){
				die("ERROR: Not possible update table and insert new column tablename <br> Mysql output=".mysqli_error($GLOBALS['con']));
			}
			echo "Table $fileName upload to DB with Sucess<br>";
		}			
	}
}
?>