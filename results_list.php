<?php

	include "./db/connect.php";
	
	$query = "SELECT table_name AS 'results' FROM information_schema.tables WHERE table_name like '%errors_results%'";
	$result = mysqli_query($GLOBALS['con'], $query);	

	while ($row = mysqli_fetch_assoc($result) ) { // Obtém os dados da linha atual e avança para o próximo registro
			echo "<a href=results_content.php?table=".$row['results']."> ".$row['results']."</a><br>";
		}
		
?>