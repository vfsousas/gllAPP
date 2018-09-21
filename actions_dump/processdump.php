<?php
session_start();
include "../db/connect.php";
$path    = "../server/php/files/".session_id();
chmod($path, 0777);
	

	$query = "SELECT * FROM  gll_dump.".$_SESSION['username']."_".$_GET['nowtime']."_dumpexecution";
	$result = mysqli_query($GLOBALS['con'], $query);	

	while ($row = mysqli_fetch_assoc($result) ) { // Obtém os dados da linha atual e avança para o próximo registro
		$dump_tb_source = $row['dump_tb_source'];
		$dump_cl_source = $row['dump_cl_source'];
		$inp_cl_source = $row['inp_cl_source'];
		
		
		$query_dump_tables = "SELECT table_name FROM information_schema.TABLES WHERE table_schema = 'gll_dump'  AND table_name like '%".$_GET['nowtime']."%".strtolower($dump_tb_source)."%'";
		$result_dump_tables = mysqli_query($GLOBALS['con'], $query_dump_tables);
		while ($row_dump_tables = mysqli_fetch_assoc($result_dump_tables) ) {
			$table_name = $row_dump_tables['table_name'];
			$value_found=false;
			$query_dump_column_values = "SELECT DISTINCT $dump_cl_source FROM gll_dump.$table_name";
			$result_dump_column_values = mysqli_query($GLOBALS['con'], $query_dump_column_values);
			while ($row_dump_column_values= mysqli_fetch_assoc($result_dump_column_values) ) {
				$column_value = $row_dump_column_values["$dump_cl_source"]; // aqui eu peguei o valor da primeira linha do dump
				//buscando agora todas as tabelas de INP todos os valores que foi capturado na query anterior
				$query_inp_tables = "SELECT table_name FROM information_schema.TABLES WHERE table_schema = 'gll_automation'  AND table_name like '%".$_GET['nowtime']."_xls%'";
				$result_inp_tables = mysqli_query($GLOBALS['con'], $query_inp_tables);
				while ($row_inp_tables = mysqli_fetch_assoc($result_inp_tables) ) {
					//agora lista todas as tabelas de INP e verifica se o valor foi localizado em alguma delas
					$column_value = str_ireplace("'", "\'", $column_value);
					$full_table_name = $row_inp_tables['table_name'];		
					$query_find_value = "SELECT COUNT(DISTINCT $inp_cl_source) as countV FROM gll_automation.$full_table_name WHERE $inp_cl_source='$column_value'";
				    $result_find_value = mysqli_query($GLOBALS['con'], $query_find_value);	
					if($result_find_value === FALSE) {
						echo "Error countV <br> $query_find_value <br>";
						die(mysqli_error());
					}
					while ($row_find_value = mysqli_fetch_assoc($result_find_value) ) {
						if($row_find_value['countV']==0){
							$table_name = str_replace(strtolower($_SESSION['username'])."_", "", $table_name);
							$table_name = str_replace($_GET['nowtime']."_", "", $table_name);
							$sql  = "INSERT INTO gll_dump.".$_SESSION['username']."_".$_GET['nowtime']."_errors_results (ID, filename, row, issue, other) VALUES (NULL, '$table_name', '$dump_cl_source', 'Value $column_value not found', '')";
							if(!mysqli_query($GLOBALS['con'], $sql)){
								echo $sql;
								die('Errror inserindo em errors_results	- fatal error'.mysqli_error($GLOBALS['con']));
							}
							while(mysqli_more_results($GLOBALS['con']) && mysqli_next_result($GLOBALS['con']));
						}
					}
				
				}
			}
		}
	}
	echo "Claening database.....";
	//dropping all tables
	$query_dump_tables = "SELECT table_name FROM information_schema.TABLES WHERE table_schema = 'gll_dump'  AND table_name like '%".$_GET['nowtime']."%' AND table_name NOT LIKE  '%_errors_results%'" ;
	$result_dump_tables = mysqli_query($GLOBALS['con'], $query_dump_tables);
	if($result_dump_tables === FALSE) {
						echo "Error Drop tables <br> $query_dump_tables <br>";
						die(mysqli_error());
	}
	while ($row_dump_tables = mysqli_fetch_assoc($result_dump_tables) ) {
		$table_name = $row_dump_tables['table_name'];
		$query = "DROP TABLE gll_dump.$table_name";
		if(!mysqli_query($GLOBALS['con'], $query)){
			echo $query;
			die('ERROR drop dumo tables	- fatal error'.mysqli_error($GLOBALS['con']));
		}	
	}
	
	//dropping all tables
	$query_dump_tables = "SELECT table_name FROM information_schema.TABLES WHERE table_schema = 'gll_automation'  AND table_name like '%".$_GET['nowtime']."%' AND table_name NOT LIKE  '%_errors_results%'" ;
	$result_dump_tables = mysqli_query($GLOBALS['con'], $query_dump_tables);
	while ($row_dump_tables = mysqli_fetch_assoc($result_dump_tables) ) {
		$table_name = $row_dump_tables['table_name'];
		$query = "DROP TABLE gll_automation.$table_name";
		if(!mysqli_query($GLOBALS['con'], $query)){
			echo $query;
			die('ERROR gll_automation tables	- fatal error'.mysqli_error($GLOBALS['con']));
		}	
	}
	
	//dropping all procedures
	$query_dump_tables = "select name from mysql.proc WHERE db= 'gll_dump'  AND name like '%".$_GET['nowtime']."%'";
	$result_dump_tables = mysqli_query($GLOBALS['con'], $query_dump_tables);
	while ($row_dump_tables = mysqli_fetch_assoc($result_dump_tables) ) {
		$proc_name = $row_dump_tables['name'];
		$query = "DROP PROCEDURE gll_dump.$proc_name";
		if(!mysqli_query($GLOBALS['con'], $query)){
			echo $query;
			die('ERROR gll_automation tables	- fatal error'.mysqli_error($GLOBALS['con']));
		}	
	}
	
	echo "Claening database.....DONE!";
?>