<?php echo "Hello World!"; 
	include "../db/connect.php";
	$query = "SELECT * FROM gll_automation.teste";	
	if(!mysqli_query($con, $query)){
  				die('fatal error'.mysql_error());
  	}else{
		echo "Conectado do DB com SuCESOOO!!";
	} 			
?>
