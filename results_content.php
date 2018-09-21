<?php

	include "./db/connect.php";
	$table_name = $_GET['table'];
	$query = "SELECT *  FROM gll_automation.$table_name";
	$result = mysqli_query($GLOBALS['con'], $query);	
	if(!$result){die('fatal error'.mysqli_error($GLOBALS['con']));}
echo "<table border='1'>"; //Criamos a tabela
				echo "<tr>" 	//Aqui criamos o cabeçalho da tabela.
						."<td>FileName</td>"
						."<td>row</td>"
						."<td>defect</td>"
						."</tr>"; // 
	$myVar="";
	while ($row = mysqli_fetch_assoc($result) ) { // Obtém os dados da linha atual e avança para o próximo registro
			$myVar = $row['issue'];
			$filename = $row['filename'];
			$rowNumber = $row['row'];
		echo "<tr><td>$filename"
				."<td>$rowNumber</td>"
				."<td>$myVar</td>"
				."</tr>";
		}
	echo "</table>"; // E fora do while fechamos a tabela.
				
				


    /* free result set */
    mysqli_free_result($result);
?>