<?php
session_start();
require_once '../excel/PHPExcel/PHPExcel.php';
include "../db/connect.php";
$path = "../server/php/files/" . session_id();
chmod($path, 0777);



//Criando a tabela de processamnto do DUMP
$query = "CREATE TABLE gll_dump.".$_SESSION['username']."_".$_GET['nowtime']."_dumpexecution (`dump_tb_source` varchar(100) NOT NULL, `dump_cl_source` varchar(100) NOT NULL, `inp_cl_source` varchar(100) NOT NULL)";
if (!mysqli_query($GLOBALS['con'], $query)) {
   Echo "<p> $query</p>";
   die("ERROR: Not possible create table to save the dump execution results <br> Mysql output=". mysqli_error($GLOBALS['con']));
}
//Fim do Criando a tabela de processamento do DUMP



foreach (new DirectoryIterator($path) as $file) {
    if ($file->isFile()) {
        $fileName = strtolower($file->getFilename());
        if (strpos($fileName, ".xls")) {
            $objPHPExcel   = PHPExcel_IOFactory::load($path . "/" . $fileName);
            $inputFileType = 'Excel5';
            /**  Create a new Reader of the type defined in $inputFileType  **/
            $objReader     = PHPExcel_IOFactory::createReader($inputFileType);
            /**  Advise the Reader of which WorkSheets we want to load  **/
            $objReader->setLoadSheetsOnly("Sheet1");
            //  Get worksheet dimensions
            $sheet         = $objPHPExcel->getSheet(0);
            $highestRow    = $sheet->getHighestRow();
            $highestColumn = $sheet->getHighestColumn();
            //  Loop through each row of the worksheet in turn
            $insert        = "";
            $if_msg        = "";
            $query_trigger = "";
            $valid         = "";
            $arr           = "";
			$xlsTableName        = $fileName;
            $xlsTableName        = str_replace(".xls", "", $xlsTableName);
			$xlstableName =  strtolower($_SESSION['username']) . "_" . $_GET['nowtime'] . "_xls_" . $xlsTableName;
			$prepare_dump ="\n  DECLARE count_dump_table TEXT;";
			$prepare_dump .="\n  DECLARE sql_text1 TEXT;";
			$prepare_dump .="\n  DECLARE count_dump_column TEXT;";
			$prepare_output = "";
			
            for ($row = 2; $row <= $highestRow; $row++) {
                //  Read a row of data into an array
                $field_name = $sheet->rangeToArray('A' . $row . ':' . $highestColumn . $row, NULL, TRUE, FALSE);
                
                $type_value   = $sheet->rangeToArray('B' . $row . ':' . $highestColumn . $row, NULL, TRUE, FALSE);
                $valid_values = $sheet->rangeToArray('C' . $row . ':' . $highestColumn . $row, NULL, TRUE, FALSE);
                $mandatory    = $sheet->rangeToArray('D' . $row . ':' . $highestColumn . $row, NULL, TRUE, FALSE);
				
				 $source_table    = $sheet->rangeToArray('E' . $row . ':' . $highestColumn . $row, NULL, TRUE, FALSE);
				 $source_field    = $sheet->rangeToArray('F' . $row . ':' . $highestColumn . $row, NULL, TRUE, FALSE);
                
                $field = strval($field_name[0][0]);
				if($field!=null){
					$mandatoryRes = null;
					$type  = strtolower($type_value[0][0]);
					$type  = str_replace("number", "int", $type);
					$type  = str_replace("varchar2", "varchar", $type);
					if ($mandatory[0][0] == "Y") {
						$mandatoryRes = " NOT NULL";
					} 
					$valid = "";
					if ($valid_values[0][0] != "") {
						$valid_value = str_replace(";", ",", $valid_values[0][0]);
						$arr         = explode(",", $valid_value);
						foreach ($arr as $value) {
							$valid .= "'" . $value . "',";
						}
						$valid .= ")";
						$valid = str_replace(",)", "", $valid);
						
						$if_msg .= "if (new.$field not in (" . $valid . ")) THEN ";
						$valid = str_replace(",", " OR ", $valid);
						$valid = str_replace("'", "", $valid);
						$if_msg .= " SET @msg_txt = concat('$field  was expected " . str_replace(",", " OR ", $valid) . ", and was found ', new.$field);
									INSERT INTO gll_automation." . $_SESSION['username'] . "_" . $_GET['nowtime'] . "_errors_results (`ID`,`filename`, `row`, `issue`) VALUES (NULL, new.tablename ,new.ID, @msg_txt);
								end if;";
					}
					if($mandatoryRes!=null){
							$insert .= $field . " " . $type . " " . $mandatoryRes . ",";

					}else{
						$insert .= $field . " " . $type. ",";
					}
					
					if($source_table[0][0]!=null){
						//validar se a tabela existe no DB
						
						$query_dump = "'SELECT COUNT(*) into @count_dump_table FROM information_schema.TABLES WHERE table_schema = ''gll_dump''  AND table_name like ''%".$_GET['nowtime']."%".strtolower($source_table[0][0])."%'' LIMIT 1'";
						$prepare_dump .= "\n  SET @sql_text1 =CONCAT($query_dump);";
						$prepare_dump .= "\n  PREPARE stmt1 FROM @sql_text1;";
						$prepare_dump .= "\n  EXECUTE stmt1;";
						$prepare_dump .= "\n  DEALLOCATE PREPARE stmt1;";
	
						$prepare_dump .= "\n  if(@count_dump_table=0) THEN "; // tabela nao existe, insere um registro na tabela de erros
							$query_dump = "INSERT IGNORE INTO gll_dump.".$_SESSION['username']."_".$_GET['nowtime']."_errors_results (ID, filename, row, issue, other) VALUES (NULL, \'".$source_table[0][0]."\', \'\', \'Table not found\',\'\')";
							//$prepare_dump .= " \n SELECT \"Tabela ". $source_table[0][0]. " NAo Localizada\";";
							$prepare_dump .= "\n  SET @sql_text1 =CONCAT('$query_dump');";
							//$prepare_dump .= "\n SELECT @sql_text1;";
							$prepare_dump .= "\n    PREPARE stmt1 FROM @sql_text1;";
							$prepare_dump .= "\n    EXECUTE stmt1;";
							$prepare_dump .= "\n    DEALLOCATE PREPARE stmt1;";
							$prepare_dump .="\n  ELSE "; //  validar se existem colunas ou apenas 1 coluna na tabela
							$prepare_output .= " \n \"tabela ". $source_table[0][0]. "Localizada\";";
							$arrORAND = "";
							$colun_names = strtoupper($source_field[0][0]);
							if(strpos($colun_names, '{AND}') !== FALSE ){
								$arrORAND         = explode("{AND}", $colun_names);
							}
							
							if(strpos($colun_names, '{OR}') !== FALSE ){
								$arrORAND         = explode("{or}", $colun_names);
							}
							$arr_length = count($arrORAND);
							
							if($arr_length>1){ // se existir colunas, validar a existencia de uma por uma
									For($i=0;$i<$arr_length;$i++){
										$query_dump = "SELECT COUNT(*) into @count_dump_column FROM information_schema.COLUMNS WHERE table_schema = ''gll_dump''  AND table_name LIKE ''%".$_GET['nowtime']."%".strtolower($source_table[0][0])."%'' AND COLUMN_NAME=''".TRIM($arrORAND[$i])."''  LIMIT 1";
										$prepare_dump .= "\n      SET @sql_text1 =CONCAT('$query_dump');";
										$prepare_dump .= "\n      PREPARE stmt1 FROM @sql_text1;";
										$prepare_dump .= "\n      EXECUTE stmt1;";
										$prepare_dump .= "\n      DEALLOCATE PREPARE stmt1;";	
										$prepare_dump .= "\n	  SELECT @sql_text1;";

										$prepare_dump .= "\n        if(@count_dump_column=0)THEN "; // tabela nao existe, insere um registro na tabela de erros
										$prepare_output .= " \n \"COluna ". $source_field[0][0]. " Nao Localizada\";";
										$query_dump = "INSERT INTO gll_dump.".$_SESSION['username']."_".$_GET['nowtime']."_errors_results (ID, filename, row, issue, other) VALUES (NULL,''".$source_table[0][0]."'', ''".TRIM($arrORAND[$i])."'', ''Column not found'', '''')";
										$prepare_dump .= "\n          SET @sql_text1 =CONCAT('$query_dump');";
										$prepare_dump .= "\n          PREPARE stmt1 FROM @sql_text1;";
										$prepare_dump .= "\n          EXECUTE stmt1;";
										$prepare_dump .= "\n          DEALLOCATE PREPARE stmt1;";
										$prepare_dump .= "\n      ELSE";
										$query_dump = "INSERT INTO  gll_dump.".$_SESSION['username']."_".$_GET['nowtime']."_dumpexecution(dump_tb_source, dump_cl_source, inp_cl_source) VALUES (''".$source_table[0][0]."'', ''".TRIM($arrORAND[$i])."'', ''".$field_name[0][0]."'')";
										$prepare_dump .= "\n          SET @sql_text1 =CONCAT('$query_dump');";
										$prepare_dump .= "\n          PREPARE stmt1 FROM @sql_text1;";
										$prepare_dump .= "\n          EXECUTE stmt1;";
										$prepare_dump .= "\n          DEALLOCATE PREPARE stmt1;";
										$prepare_dump .="\n     END IF; ";
										
										$prepare_output .= " \n \"COluna ". $source_field[0][0]. " Localizada\";";

																				
									}
							}else{// se tiver apenas 1 coluna, validar se ela existe
								For($i=0;$i<$arr_length;$i++){
										
										$query_dump = "SELECT COUNT(*) into @count_dump_column FROM information_schema.COLUMNS WHERE table_schema = ''gll_dump''  AND table_name LIKE ''%".$_GET['nowtime']."%".$source_table[0][0]."%'' AND COLUMN_NAME = ''".$source_field[0][0]."'' LIMIT 1";
										$prepare_dump .= "\n    SET @sql_text1 =CONCAT('$query_dump');"; 
										$prepare_dump .= "\n    PREPARE stmt1 FROM @sql_text1;";
										$prepare_dump .= "\n    EXECUTE stmt1;";
										$prepare_dump .= "\n    DEALLOCATE PREPARE stmt1;";	

										$prepare_dump .= "\n     if(@count_dump_column=0)THEN "; // tabela nao existe, insere um registro na tabela de erros
										$query_dump = "INSERT INTO gll_dump.".$_SESSION['username']."_".$_GET['nowtime']."_errors_results (ID, filename, row, issue, other) VALUES (NULL, ''".$source_table[0][0]."'', ''".$source_field[0][0]."'', ''Column not found'', '''')";
										$prepare_dump .= "\n         SET @sql_text1 =CONCAT('$query_dump');";
										$prepare_dump .= "\n         PREPARE stmt1 FROM @sql_text1;";
										$prepare_dump .= "\n         EXECUTE stmt1;";
										$prepare_dump .= "\n         DEALLOCATE PREPARE stmt1;";
										$prepare_dump .= "\n      ELSE";
										$query_dump = "INSERT INTO  gll_dump.".$_SESSION['username']."_".$_GET['nowtime']."_dumpexecution (dump_tb_source, dump_cl_source, inp_cl_source) VALUES (''".$source_table[0][0]."'', ''".$source_field[0][0]."'', ''".$field_name[0][0]."'');";
										$prepare_dump .= "\n          SET @sql_text1 =CONCAT('$query_dump');";
										$prepare_dump .= "\n          PREPARE stmt1 FROM @sql_text1;";
										$prepare_dump .= "\n          EXECUTE stmt1;";
										$prepare_dump .= "\n          DEALLOCATE PREPARE stmt1;";
										$prepare_dump .="\n     END IF; ";

								}
							}
						$prepare_dump .="\n   END IF; ";
						}
						
					
					//echo $prepare_dump;
	
				}
                
                //  Insert row data array into your database of choice here
            }
          //  $prepare_dump .=" SELECT $prepare_output;";
			
			//cria a procedure para validar o DUMP
			$query = "CREATE OR REPLACE PROCEDURE gll_dump.executedump_". $_GET['nowtime']."()";
			$query .= "\n  begin ";
			$query .= $prepare_dump;
			$query .= " end;";

            if (!mysqli_query($GLOBALS['con'], $query)) {
				Echo "<p> $query</p>";
				
                die("ERROR: Not possible create the procedure to execute the dump tests<br> Mysql output=". mysqli_error($GLOBALS['con']));
            }
			
            
          $insert = "ID int(11), tablename VARCHAR(100), " . $insert . ")";
          $insert = str_replace(",)", "", $insert);
          $query = "CREATE TABLE gll_automation.$xlstableName( " . $insert . ")";
           if (!mysqli_query($GLOBALS['con'], $query)) {
              die("ERROR: Not possible create the procedure to execute the dump tests<br> Mysql output=" . mysqli_error($GLOBALS['con']));
		}
            
            if ($if_msg <> "") {
                
                
                if (!mysqli_query($GLOBALS['con'], "use gll_automation")) {
                    
                    die('8)fatal error' . mysqli_error($GLOBALS['con']));
                }
				
                foreach (new DirectoryIterator($path) as $xlsFile) {
                    if ($xlsFile->isFile()) {
                        $xlsFileName = strtolower($xlsFile->getFilename());
                        if (strpos($xlsFileName, ".xls")) {
                            $xlsFileName   = strtolower($_SESSION['username'] . "_" . $_GET['nowtime']."_" . str_replace(".xls", "", $xlsFileName));
                            $clear_trigger = "DROP TRIGGER IF EXISTS 'gll_automation." . $xlsFileName . "'";
                            //echo $clear_trigger;
                            //if(!mysqli_query($con, $clear_trigger)){
                            //		die('fatal error'.mysqli_error($con));
                            //}
                            
                            $query_trigger = "create trigger gll_automation." .$xlsFileName . " before insert on " . $_SESSION['username'] . "_" . $_GET['nowtime'] . "_xls_" . $xlsTableName . " 
													   for each row 
														 begin
															$if_msg
														end";
                            if (!mysqli_query($GLOBALS['con'], $query_trigger)) {
                               echo $query_trigger;
                                die("ERROR: Not possible create the trigger <br> Mysql output=". mysqli_error($GLOBALS['con']));
                            }
                        }
                    }
                }               
            }
        }
    }
}
?>