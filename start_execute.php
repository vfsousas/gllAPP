<html>
<body>
<div id="msg" style="font-size:largest;">
<!-- you can set whatever style you want on this -->
Loading, please wait...
</div>
<div id="body" style="display:none;">
<!-- everything else -->
</div>
</body>
</html>

<?php
include "./db/connect.php";
require_once 'excel/PHPExcel/PHPExcel.php';

$nowtime = time();

session_start();

$main_folder = "/server/php/files/".session_id();

//$gll_folder = 'uploads/gll_file/'.$_POST['username']."/".$nowtime;
//$xls_folder = 'uploads/xls_file/'.$_POST['username']."/".$nowtime;
	
//echo "start uploda files".getDatetimeNow()."<br>";

//createFolder();
//uploadGLLFilesToFolder();
//uploadXLSFilesToFolder();
//echo "end uploda files".getDatetimeNow()."<br>";

//echo "start exeution".getDatetimeNow()."<br>";

//dropUserTables();


Echo "start execution";
//uploadGLLFilesToDB();
//uploadXLSFilesToDB();
//createResultstable();
callProcedures();
//droptables();

echo "End execution".getDatetimeNow()."<br>";


function getDatetimeNow() {
    $tz_object = new DateTimeZone('Brazil/East');
    //date_default_timezone_set('Brazil/East');

    $datetime = new DateTime();
    $datetime->setTimezone($tz_object);
    return $datetime->format('Y\-m\-d\ h:i:s');
}


Function droptables(){
		$tmstmp = $GLOBALS['nowtime'];
	
		$query = "SELECT CONCAT( 'DROP TABLE ', GROUP_CONCAT(table_name) , ';' ) AS statement FROM information_schema.tables WHERE table_schema = 'gll_automation' AND table_name LIKE '%{$tmstmp}_rio%' ";
		$result = mysqli_query($GLOBALS['con'], $query);
		
		if(!$result){
  				die('1)fatal error'.mysqli_error($GLOBALS['con']));
		}
	
		while ($exibe = mysqli_fetch_assoc($result) ) { // Obtém os dados da linha atual e avança para o próximo registro
			//echo $exibe["statement"];
			if(!mysqli_query($GLOBALS['con'], $exibe["statement"])){
  				die('2) fatal error'.mysqli_error($GLOBALS['con']));
		}
		}
		
		$query = "SELECT CONCAT( 'DROP TABLE ', GROUP_CONCAT(table_name) , ';' ) AS statement FROM information_schema.tables WHERE table_schema = 'gll_automation' AND table_name LIKE '%{$tmstmp}_xls_%' ";
		$result = mysqli_query($GLOBALS['con'], $query);
		
		if(!$result){
  				die('3) fatal error'.mysqli_error($GLOBALS['con']));
		}
	
		while ($exibe = mysqli_fetch_assoc($result) ) { // Obtém os dados da linha atual e avança para o próximo registro
			if(!mysqli_query($GLOBALS['con'], $exibe["statement"])){
  				die('4) fatal error'.mysqli_error($GLOBALS['con']));
		}
		}
	
}

function callProcedures(){
	
	$path    = "server/php/files/".session_id();
	chmod($path, 0777);
	
	$start_time = date('mm/dd/YYYY h:i:s', time());;
	$event_create = "CREATE 
	EVENT gll_automation.".$_GET['username']."_".$GLOBALS['nowtime']."_".$GLOBALS['xlstable']."
	ON SCHEDULE AT CURRENT_TIMESTAMP + INTERVAL 30 SECOND
	 DO BEGIN
	 
	 SELECT now() into @starttime;\n
	";
	
	$query = "";
	$gll_files_pool = "";
	$total_rows = 0;
	$total_rows_errors = 0;
	$results = $_GET['username']."_".$GLOBALS['nowtime']."_errors_results";
	$xlsfile = $GLOBALS['xlfile'];
	$xlsfile = str_replace(".xls", "", $xlsfile);
	$xlsfile = $_GET['username']."_".$GLOBALS['nowtime']."_xls_".$xlsfile;
	$tmstmp = $GLOBALS['nowtime'];
	
	foreach (new DirectoryIterator($path) as $file) {
		if ($file->isFile()) {
			$fileName = strtolower($file->getFilename());
			if(strpos($fileName, ".inp")){
				//gll_table, xls_table, result_table
				$gllfile = strtolower($_GET['username']."_".$GLOBALS['nowtime']."_".$fileName);
				$gllfile_new = str_replace(".inp", "", $gllfile);
				$gll_files_pool =$gll_files_pool.";".$gllfile_new;
				
				$result = mysqli_query($GLOBALS['con'], "select count(*) FROM gll_automation.$gllfile_new");
				if (!$result) {
					printf("Error: %s\n", mysqli_error($GLOBALS['con']));
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
					printf("Error: %s\n", mysqli_error($GLOBALS['con']));
					exit();
				}
		}	
		$row = mysqli_fetch_array($result);
			$total_rows_errors = $total_rows_errors + $row[0];
			//$event_create =  $event_create.' DROP EVENT IF EXISTS '.$GLOBALS['xlstable'].';';
			$event_create .= "\n ".strtolower("DROP TABLE IF EXISTS ".$xlsfile.";");
			$event_create .= "SET @end_time = now();";
			$event_create .= "INSERT INTO `audit` (`id`, `owner`, `files`, `start_time`, `end_time`, `rows_count`, `defects_found`) VALUES (NULL, 'vanderson', '$gll_files_pool', @starttime, now(), '$total_rows', (select count(*) FROM $results));";
			$event_create = $event_create ."END";
			if(!mysqli_query($GLOBALS['con'], $event_create)){
						echo "<BR>$event_create<br>";
						die('12) CREATE EVENT - fatal error'.mysqli_error($GLOBALS['con']));
			}
}


function createResultstable(){

	$query = "CREATE TABLE gll_automation.".$_GET['username']."_".$GLOBALS['nowtime']."_errors_results (
				ID int(11) NOT NULL,
				filename varchar(300) NOT NULL,
				row varchar(30) NOT NULL,
				issue varchar(300) NOT NULL,
				other varchar(100) NOT NULL)";
	if(!mysqli_query($GLOBALS['con'], $query)){
  				die('5)fatal error'.mysqli_error($GLOBALS['con']));
	}
	
	$query = "ALTER TABLE gll_automation.".$_GET['username']."_".$GLOBALS['nowtime']."_errors_results ADD PRIMARY KEY (ID)";
	if(!mysqli_query($GLOBALS['con'], $query)){
  				die('6) fatal error'.mysqli_error($GLOBALS['con']));
	}
	
	$query = "ALTER TABLE gll_automation.".$_GET['username']."_".$GLOBALS['nowtime']."_errors_results MODIFY ID int(11) NOT NULL AUTO_INCREMENT";
	if(!mysqli_query($GLOBALS['con'], $query)){
  				die('7) fatal error'.mysqli_error($GLOBALS['con']));
	}
}

function uploadXLSFilesToDB(){
	$path    = "server/php/files/".session_id();
	chmod($path, 0777);
	
	foreach (new DirectoryIterator($path) as $file) {
		if ($file->isFile()) {
			print $file->getFilename() . "\n";
			$fileName = strtolower($file->getFilename());
			if(strpos($fileName, ".xls")){
				$objPHPExcel =  PHPExcel_IOFactory::load($path."/".$fileName);
				$inputFileType = 'Excel5';
				/**  Create a new Reader of the type defined in $inputFileType  **/
				$objReader = PHPExcel_IOFactory::createReader($inputFileType);
				/**  Advise the Reader of which WorkSheets we want to load  **/
				$objReader->setLoadSheetsOnly("Sheet1");
				$GLOBALS['xlfile'] = $fileName;
				//  Get worksheet dimensions
				$sheet = $objPHPExcel->getSheet(0);
				$highestRow = $sheet->getHighestRow();
				$highestColumn = $sheet->getHighestColumn();
				//  Loop through each row of the worksheet in turn
				$insert = "";
				$if_msg = "";
				$query_trigger = "";
				$valid = "";
				$arr = "";
				for ($row = 2; $row <= $highestRow-1; $row++){
					//  Read a row of data into an array
					$field_name = $sheet->rangeToArray('A' . $row . ':' . $highestColumn . $row,
							NULL,
							TRUE,
							FALSE);

					$type_value = $sheet->rangeToArray('B' . $row . ':' . $highestColumn . $row,
							NULL,
							TRUE,
							FALSE);
					$valid_values = $sheet->rangeToArray('C' . $row . ':' . $highestColumn . $row,
							NULL,
							TRUE,
							FALSE);
					$mandatory = $sheet->rangeToArray('D' . $row . ':' . $highestColumn . $row,
							NULL,
							TRUE,
							FALSE);

					$field = strval($field_name[0][0]);
					$type = strtolower($type_value[0][0]);
					$type = str_replace("number", "int", $type);
					$type = str_replace("varchar2", "varchar", $type);
					if($mandatory[0][0]=="Y"){
						$mandatoryRes = " NOT NULL";			
					}else{
						$mandatoryRes = " NULL";			
					}
					$valid = "";
					if($valid_values[0][0]!=""){
						$valid_value = str_replace(";", ",", $valid_values[0][0]);
						$arr = explode(",", $valid_value);				
						foreach ($arr as $value) {
							$valid .= "'".$value."',";
						}	
						$valid .= ")";
						$valid =  str_replace(",)", "", $valid);

						$if_msg .= "if (new.$field not in (".$valid.")) then"; 
						$valid = str_replace(",", " OR ", $valid);
						$valid = str_replace("'", "", $valid);		
						$if_msg .= " SET @msg_txt = concat('In the field $field  was expected ".str_replace(",", " OR ", $valid).", and was found ', new.$field);
								INSERT INTO gll_automation.".$_GET['username']."_".$GLOBALS['nowtime']."_errors_results (`ID`,`filename`, `row`, `issue`) VALUES (NULL, '".$GLOBALS['tablename']."' ,new.ID, @msg_txt);
							end if;";
					}
						$insert .= $field ." ".$type." ".$mandatoryRes.",";							
					//  Insert row data array into your database of choice here
				}
		

			
				$insert ="ID int(11), ". $insert .")";
				$insert = str_replace(",)", "", $insert);
				$xlsTableName = $fileName;
				$xlsTableName = str_replace(".xls", "", $xlsTableName);
				$query = "CREATE TABLE gll_automation.".$_GET['username']."_".$GLOBALS['nowtime']."_xls_".$xlsTableName."( ".$insert.")";	
				$GLOBALS['xlstable']=$xlsTableName;

				if(!mysqli_query($GLOBALS['con'], $query)){
					die('XLSTBALENAME fatal error'.mysqli_error($GLOBALS['con']));
				}
				
				if($if_msg<>""){
					
				if(!mysqli_query($GLOBALS['con'], "use gll_automation")){
							
							die('8)fatal error'.mysqli_error($GLOBALS['con']));
				}
				
					$clear_trigger = "DROP TRIGGER IF EXISTS 'gll_automation.".$_GET['username']."_".$GLOBALS['nowtime']."_".$xlsTableName."'";
					//echo $clear_trigger;
					//if(!mysqli_query($con, $clear_trigger)){
					//		die('fatal error'.mysqli_error($con));
					//}
				
					$query_trigger = "create trigger gll_automation".$_GET['username']."_".$GLOBALS['nowtime']."_xls_".$xlsTableName." before insert on ".$_GET['username']."_".$GLOBALS['nowtime']."_xls_".$xlsTableName." 
									   for each row 
										 begin
											$if_msg
										end";
					//echo $query_trigger."<BR><BR>";
					if(!mysqli_query($GLOBALS['con'], $query_trigger)){
							echo $query_trigger;
							die('9) fatal error'.mysqli_error($GLOBALS['con']));
					}
				
				}	
							
						}
					}
	}
		
}


function uploadGLLFilesToDB(){
	
	$path    = "server/php/files/".session_id();
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
				$table_name = $_GET['username']."_".$GLOBALS['nowtime']."_".$table_name;
				$GLOBALS['tablename'] = $table_name;
				
				mysqli_query($GLOBALS['con'], "DROP TABLE IF EXISTS gll_automation.{$table_name}");
				
				$colQuery ="";
				for($j=0; $j< $num_tags; $j++){
						$colQuery .= "column_{$j} TEXT NULL,";
				}
				mysqli_next_result($GLOBALS['con']);
				$query = "CREATE TABLE IF NOT EXISTS gll_automation.{$table_name} ({$colQuery});";
				$query= str_replace(",)", ")", $query);
				if(!mysqli_query($GLOBALS['con'], $query)){
					die('Create table - fatal error'.mysqli_error($GLOBALS['con']));
				}
				
					
				$columns = str_replace(" TEXT NULL", "", $colQuery);
				$query_import_file = "LOAD DATA INFILE 'C:/xampp/htdocs/gll_automation/server/php/files/".session_id()."/$fileName'
					INTO TABLE gll_automation.{$table_name}
					FIELDS TERMINATED BY '||'
					LINES TERMINATED BY '\n'
					({$columns})";
					$query_import_file = str_replace(",)", ")", $query_import_file);
					if(!mysqli_query($GLOBALS['con'], $query_import_file)){
						die('Insert GLL values into table - fatal error'.mysqli_error($GLOBALS['con']));
					}

					$updateID = "ALTER TABLE gll_automation.{$table_name} ADD id int NOT NULL AUTO_INCREMENT primary key FIRST";

					if(!mysqli_query($GLOBALS['con'], $updateID)){
						die('Updating ID - fatal error'.mysqli_error($GLOBALS['con']));
					}
					
				$num_tags = $num_tags -1;
				$query = "ALTER TABLE  gll_automation.{$table_name} DROP COLUMN column_{$num_tags};";
				if(!mysqli_query($GLOBALS['con'], $query)){
					die('ALTER TABLE - fatal error'.mysqli_error($GLOBALS['con']));
				}
			}			
		}
	}	
}

function dropUserTables(){
	$query = "call gll_automation.droplike(\"".$_POST['username']."%\")";
  	if(!mysqli_query($GLOBALS['con'], $query)){
  			die('10) fatal error'.mysql_error());
  	}
}


function uploadXLSFilesToFolder(){
		$uploadOk = 1;
		date_default_timezone_set("Brazil/East"); //Definindo timezone padrão
		$ext = strtolower(substr($_FILES['fileXLSUpload']['name'],-4)); //Pegando extensão do arquivo
		$new_name = $_FILES['fileXLSUpload']['name']; //Definindo um novo nome para o arquivo
		$tmpFilePath = $_FILES['fileXLSUpload']['tmp_name'];
		$table_name = $_FILES['fileXLSUpload']['name']; //Definindo um novo nome para a tabela

		$GLOBALS['tablename']=$table_name;
		$dir = $GLOBALS['xls_folder']."/"; //Diretório para uploads
		$target_file =  $dir.$new_name;

		if (file_exists($target_file)) {
			echo "Sorry, file already exists. <br>";
			$uploadOk = 0;
		}
		
		if($_FILES['fileXLSUpload']['type']!="application/vnd.ms-excel"){
			echo "Sorry, only XLS Files are allowed. <br>";
			$uploadOk = 0;
		}


		if ($uploadOk == 0) {
			echo "Sorry, your file was not uploaded. <br>";
			// if everything is ok, try to upload file
		} else {
			if (move_uploaded_file($tmpFilePath, $target_file)) {
				echo "The file ". basename( $_FILES["fileXLSUpload"]["name"]). " has been uploaded.<br>";
			} else {
				die("Sorry, there was an error uploading your file.<br>");
			}
		}
	}
	
	
function createFolder(){

	if (!file_exists($GLOBALS['gll_folder'] )) {
		mkdir($GLOBALS['gll_folder'] , 0777, true);
	}

	if (!file_exists($GLOBALS['xls_folder'])) {
		mkdir($GLOBALS['xls_folder'], 0777, true);
	}
}

function uploadGLLFilesToFolder(){
	$total = count($_FILES['fileGLLUpload']['name']);
	
	for($i=0; $i<$total; $i++) {
		$percent = intval($i/$total * 100)."%";
		$uploadOk = 1;
		date_default_timezone_set("Brazil/East"); //Definindo timezone padrão
		$ext = strtolower(substr($_FILES['fileGLLUpload']['name'][$i],-4)); //Pegando extensão do arquivo
		$new_name = $_FILES['fileGLLUpload']['name'][$i]; //Definindo um novo nome para o arquivo
		$tmpFilePath = $_FILES['fileGLLUpload']['tmp_name'][$i];
		$table_name = $_FILES['fileGLLUpload']['name'][$i]; //Definindo um novo nome para a tabela
		
		$GLOBALS['tablename']=$table_name;
		$dir = $GLOBALS['gll_folder']."/"; //Diretório para uploads
		$target_file =  $dir.$new_name;
	
		if (file_exists($target_file)) {
			echo "Sorry, file already exists. <br>";
			$uploadOk = 0;
		}
		
		if($_FILES['fileGLLUpload']['type'][$i]!="application/octet-stream"){
			echo $_FILES['fileGLLUpload']['type'][$i];
			echo "Sorry, only INP Files are allowed. <br>";
			$uploadOk = 0;
		}
	
	
		if ($uploadOk == 0) {
			echo "Sorry, your file was not uploaded. <br>";
			// if everything is ok, try to upload file
		} else {
			if (move_uploaded_file($tmpFilePath, $target_file)) {
				echo "The file ". basename( $_FILES["fileGLLUpload"]["name"][$i]). " has been uploaded.<br>";
			} else {
				die("Sorry, there was an error uploading your file.<br>");
			}
		}
	}
}




 ?>
