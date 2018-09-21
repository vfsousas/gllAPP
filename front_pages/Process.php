<?php
//connect to the database
include "../db/connect.php";
//query the database
$query = "SELECT * FROM gll_automation.executions";

//count the returned rows
$result = mysqli_query($con,$query);

//turn the results into an array
 //echo "<table border='1'>"; //Criamos a tabela 
echo "<table border='1'>";
//echo '<table width="100%">'; nao sei porque tava dando erro!
echo '<thead><tr>';
echo '<th>ID</th>';
echo '<th>FileName</th>';
echo '<th>Line</th>';
echo '<th>Error_msg</th>';
echo '</tr></thead>';

echo '<tbody>';

while($rows = $result ->fetch_assoc() )
{
echo '<tr>';
   echo '<td>' . $rows['ID'] . '</td>';
   echo '<td>' . $rows['filename'] . '</td>';
   echo '<td>' . $rows['line'] . '</td>';
   echo '<td>' . $rows['error_msg'] . '</td>';
   echo '</tr>';


//	$id			= $rows['ID'];
//	$filename	= $rows['filename'];
//	$line		= $rows['line'];
//	$error		= $rows['error_msg'];
//	echo "<p>id:$ID filename:$filename line:$line error:$error_msg </p> <br /> " ;
	


}
echo '</tbody></table>';
?>



