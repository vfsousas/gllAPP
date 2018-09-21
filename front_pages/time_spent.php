<?php
//connect to the database
include "../db/connect.php";
//query the database
$query = "SELECT * FROM gll_automation.executions where id = 1";

//count the returned rows
$result = mysqli_query($con,$query);
//turn the results into an array
echo "<table border='1'>";
//echo '<table width="100%">'; nao sei porque tava dando erro!
echo '<thead><tr>';
echo '<th>Tempo Inicial</th>';
echo '<th>Tempo Final</th>';
echo '<th><b style="color:red">Resultado</b></th>';
//echo '<th><b>Resultado</b></th>';
echo '</tr></thead>';	

echo '<tbody>';
while($rows = $result ->fetch_array() )
{
	echo '<tr>';
   echo '<td>' . $rows['start_time'] . '</td>';
   echo '<td>' . $rows['end_time'] . '</td>'; 
   echo '<td>' . $rows['end_time'] . '</td>'; 
   echo '</tr>';
//$tempoinicial = $rows['start_time'];
//$tempofinal = $rows['end_time'];
	
//echo "<p> tempoinicial: $start_time tempofinal: $end_time </p> <br/> ";

//$tempototal = $tempofinal - $tempoinicial;	
//echo "<p> tempogasto: $tempototal </p>";
	
}
echo '</tbody></table>';

?>