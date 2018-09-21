<?php
uploadFilesToFolder();
uplodadXLSToDB();

function uplodadXLSToDB(){
 include "../db/connect.php";

	/** Include PHPExcel */
	require_once 'PHPExcel/PHPExcel.php';
	
	// Create new PHPExcel object
	
	$objPHPExcel =  PHPExcel_IOFactory::load("xlsx_files/".$_FILES['fileUpload']['name']);
	$inputFileType = 'Excel5';
	/**  Create a new Reader of the type defined in $inputFileType  **/
	$objReader = PHPExcel_IOFactory::createReader($inputFileType);
	/**  Advise the Reader of which WorkSheets we want to load  **/
	$objReader->setLoadSheetsOnly("Sheet1");
	
	
	
	//  Get worksheet dimensions
	$sheet = $objPHPExcel->getSheet(0);
	$highestRow = $sheet->getHighestRow();
	$highestColumn = $sheet->getHighestColumn();
	
	//  Loop through each row of the worksheet in turn
	echo "numero de linhas {$highestRow}";
	$insert = "";
	$if_msg = "";
	$query_trigger = "";
	$valid = "";
	$arr = "";
	for ($row = 2; $row <= $highestRow; $row++){
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
					signal sqlstate '45000' set message_text =@msg_txt; 
				end if;";
		}
			$insert .= $field ." ".$type." ".$mandatoryRes.",";							
		//  Insert row data array into your database of choice here
	}
		

			
	$insert ="ID int(11), ". $insert .")";
	$insert = str_replace(",)", "", $insert);
	$query = "CREATE TABLE gll_automation.teste ( ".$insert.")";	
	
	//if(!mysqli_query($con, $query)){
  	//			echo $query;
  	//			die('fatal error'.mysql_error());
  	//}
	
	if($value<>""){
		
	if(!mysqli_query($con, "use gll_automation")){
  				
  				die('fatal error'.mysql_error());
  	}
	
		$clear_trigger = "DROP TRIGGER IF EXISTS 'teste'";
		//echo $clear_trigger;
		//if(!mysqli_query($con, $clear_trigger)){
  		//		die('fatal error'.mysqli_error($con));
		//}
	
		$query_trigger = "create trigger teste_trigger before insert on teste 
						   for each row 
						     begin
								$if_msg
							end";
		echo $query_trigger;
		if(!mysqli_query($con, $query_trigger)){
  				die('fatal error'.mysqli_error($con));
		}
  	
	}
	
	
}

function uploadFilesToFolder(){
		$uploadOk = 1;
		date_default_timezone_set("Brazil/East"); //Definindo timezone padrão
		$ext = strtolower(substr($_FILES['fileUpload']['name'],-4)); //Pegando extensão do arquivo
		$new_name = $_FILES['fileUpload']['name']; //Definindo um novo nome para o arquivo
		$tmpFilePath = $_FILES['fileUpload']['tmp_name'];
		$table_name = $_FILES['fileUpload']['name']; //Definindo um novo nome para a tabela

		$GLOBALS['tablename']=$table_name;
		$dir = 'xlsx_files/'; //Diretório para uploads
		$target_file =  $dir.$new_name;

		if (file_exists($target_file)) {
			echo "Sorry, file already exists. <br>";
			$uploadOk = 0;
		}

		if($_FILES['fileUpload']['type']!="application/vnd.ms-excel"){
			echo "Sorry, only INP Files are allowed. <br>";
			echo $_FILES['fileUpload']['type'];
			$uploadOk = 0;
		}


		if ($uploadOk == 0) {
			echo "Sorry, your file was not uploaded. <br>";
			// if everything is ok, try to upload file
		} else {
			if (move_uploaded_file($tmpFilePath, $target_file)) {
				echo "The file ". basename( $_FILES["fileUpload"]["name"]). " has been uploaded.<br>";
			} else {
				die("Sorry, there was an error uploading your file.<br>");
			}
		}
	}
	
?>