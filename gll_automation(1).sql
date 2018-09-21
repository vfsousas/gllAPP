-- phpMyAdmin SQL Dump
-- version 4.6.5.2
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: 08-Ago-2017 às 19:18
-- Versão do servidor: 10.1.21-MariaDB
-- PHP Version: 7.1.1

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `gll_automation`
--

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `droplike` (`pattern` VARCHAR(20))  begin
  set group_concat_max_len = 65535;
  select @drop:= concat( 'drop table ', group_concat(table_name) , ';' ) from information_schema.tables where table_schema = "gll_automation" and table_name like pattern;
  prepare statement from @drop;
  execute statement;
end$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `populate` (IN `gll_table` VARCHAR(100) CHARSET utf8, IN `xls_table` VARCHAR(100), IN `exec_table` VARCHAR(100), IN `tmstmp` INT(20))  NO SQL
BEGIN
DECLARE rowcount INT;
DECLARE max_length INT;
DECLARE column_count INT;
DECLARE column_count_gll INT;
DECLARE triggnermsg TEXT;
DECLARE col_name TEXT;
DECLARE datatype VARCHAR(15);
DECLARE col_value TEXT;
DECLARE x  INT;
DECLARE y INT;
DECLARE E INT;
DECLARE M TEXT;
DECLARE result text;
DECLARE gllID INT;
DECLARE currentCount INT;
DECLARE done INT DEFAULT 0;
DECLARE sqlstate_code INT DEFAULT 0;
DECLARE start_time TEXT ;
DECLARE end_time TEXT;
DECLARE opt_table TEXT;
DECLARE number_result TEXT;
DECLARE date_value TEXT;
DECLARE gllcolumncount INT;
DECLARE xlscolumncount INT;
DECLARE isnullable TEXT;
DECLARE mysql_errno INT DEFAULT 0; 
DECLARE message_text TEXT;
DECLARE curs_xlstable CURSOR FOR SELECT character_maximum_length, data_type, COLUMN_NAME, IS_NULLABLE   FROM information_schema.columns  WHERE table_name = @xlstable AND ordinal_position >2;
DECLARE curs CURSOR FOR SELECT trigger_msg FROM trigger_warnings WHERE timestmp = tmstmp;

DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
DECLARE CONTINUE HANDLER FOR 1054 SET e=1054, M="Data too long for column at row ";
DECLARE CONTINUE HANDLER FOR 1243 SET e=1243, M="Data too long for column at row ";
DECLARE CONTINUE HANDLER FOR 1048 SET e=1048, M="Data too long for column at row ";


SET @resulttable = exec_table;
SET @xlstable = xls_table;
SET @glltable = gll_table;
SET @timeStamp = tmstmp;


Set global thread_cache_size = 4;
Set global query_cache_size = 1024*1024*1024;
Set global query_cache_limit=768*1024;
Set global query_cache_min_res_unit = 2048;
Set long_query_time = 5;

SET @start_time = now();

SET @sql_text1 = concat('SELECT count(*) into @gllcolumncount FROM information_schema.columns WHERE table_name =  ''',@glltable, '''');
PREPARE stmt1 FROM @sql_text1;
EXECUTE stmt1;
DEALLOCATE PREPARE stmt1;

SET @sql_text1 = concat('SELECT count(*) into @xlscolumncount FROM information_schema.columns WHERE table_name =  ''',@xlstable, '''');
PREPARE stmt1 FROM @sql_text1;
EXECUTE stmt1;
DEALLOCATE PREPARE stmt1;


IF(@gllcolumncount<> @xlscolumncount)THEN
	SET @sql_insert = CONCAT('INSERT INTO gll_automation.',@resulttable ,' (ID, filename, row, issue, other) VALUES (NULL, ''',@glltable,''', 0, ','''Wrong number of columns between MAP and INP File, INP File contains ',@gllcolumncount,' columns and XLS file contains',@xlscolumncount,' columns'', '''')');
    PREPARE stmt2 FROM @sql_insert;
	EXECUTE stmt2;
	DEALLOCATE PREPARE stmt2;
	SET @gllcolumncount = -1;
END IF;

IF(@gllcolumncount>0) THEN
	SET @opt_table = CONCAT('optimize table ', @xlstable);
	PREPARE stmt1 FROM @opt_table;

	SET @opt_table = CONCAT('optimize table ', @glltable );
	PREPARE stmt1 FROM @opt_table;


	SET x=1;
	SET @glltable = gll_table;
	SET @sql_text1 = concat('SELECT COUNT(ID) into @rowcount FROM ',@glltable);
	PREPARE stmt1 FROM @sql_text1;
	EXECUTE stmt1;
	DEALLOCATE PREPARE stmt1;
	SET E=0;
	SET @sql_column_count = CONCAT('SELECT count(*) into @column_count FROM information_schema.columns WHERE table_name = ''', @xlstable,'''');
	PREPARE stmt2 FROM @sql_column_count;
	EXECUTE stmt2;
	DEALLOCATE PREPARE stmt2;

		IF NOT done THEN
			WHILE x <= @rowcount DO
				SET y=0;
				OPEN curs_xlstable;
					cicle: REPEAT
					FETCH curs_xlstable INTO max_length, datatype, col_name, isnullable;
					SET @sql_table_max_lenght_gll  = CONCAT('SELECT LENGTH(column_',y,'), column_',y,' into @column_count_gll, @col_value FROM  ',@glltable,' WHERE ID = ', x);
					PREPARE stmt2 FROM @sql_table_max_lenght_gll;
					EXECUTE stmt2;
					DEALLOCATE PREPARE stmt2;
					IF ( @column_count_gll> max_length) THEN
						SET @sql_insert_error = CONCAT('INSERT INTO gll_automation.',@resulttable ,' (ID, filename, row, issue, other) VALUES (NULL, ''',@glltable,''', ',x,', ''',col_name  , ' is bigger than expected, expected: ',max_length, ', found: ', @col_value ,'(', @column_count_gll,')'', '''')');
                        PREPARE stmt2 FROM @sql_insert_error;
						EXECUTE stmt2;
						DEALLOCATE PREPARE stmt2;
					END IF;
					
					IF (datatype = 'int' AND @col_value<>'') then
						IF TRIM(@col_value) NOT REGEXP '^[0-9]+$' THEN
							if(@col_value="") THEN
								set @number_result = "NULL";
								else
								set @number_result = @col_value;
							END IF;
							SET @sql_insert_error = CONCAT('INSERT INTO gll_automation.',@resulttable ,' (ID, filename, row, issue) VALUES (NULL, ''',@glltable,''', ',x,', ''',col_name  , ' was expected a number, found: ', @number_result,''')');
							PREPARE stmt2 FROM @sql_insert_error;
							EXECUTE stmt2;
							DEALLOCATE PREPARE stmt2;
						END IF;
					END IF;
                    IF (datatype = 'double' AND @col_value<>'') then
						IF TRIM(@col_value) NOT REGEXP '^[[:digit:]]+\\.{0,1}[[:digit:]]*$' THEN
							if(@col_value="") THEN
								set @number_result = "NULL";
								else
								set @number_result = @col_value;
							END IF;
							SET @sql_insert_error = CONCAT('INSERT INTO gll_automation.',@resulttable ,' (ID, filename, row, issue) VALUES (NULL, ''',@glltable,''', ',x,', ''',col_name  , ' was expected a DOUBLE, found: ', @number_result,''')');
							PREPARE stmt2 FROM @sql_insert_error;
							EXECUTE stmt2;
							DEALLOCATE PREPARE stmt2;
						END IF;
					END IF;
                    
                    IF (isnullable = 'NO' AND @col_value='') then
							SET @sql_insert_error = CONCAT('INSERT INTO gll_automation.',@resulttable ,' (ID, filename, row, issue) VALUES (NULL, ''',@glltable,''', ',x,', ''',col_name  , ' was expected any value, found null value'')');
							SELECT @col_value;
                            PREPARE stmt2 FROM @sql_insert_error;
							EXECUTE stmt2;
							DEALLOCATE PREPARE stmt2;
					END IF;
					
                    
					IF (INSTR(datatype, 'date') > 0 ) then
						IF(@col_value <>  "") THEN
							SET @sql_insert_error = CONCAT('SELECT IFNULL(DAYNAME(''',@col_value,''') , '''') into @date_value');
                            PREPARE stmt2 FROM @sql_insert_error;
							EXECUTE stmt2;
							DEALLOCATE PREPARE stmt2;
							IF(@date_value =  "") THEN
									SET @sql_insert_error = CONCAT('INSERT INTO gll_automation.',@resulttable ,' (ID, filename, row, issue, other) VALUES (NULL, ''',@glltable,''', ',x,', ''',col_name  , ' wrong data format, found ',@col_value,''', '''')');
                                    PREPARE stmt2 FROM @sql_insert_error;
									EXECUTE stmt2;
									DEALLOCATE PREPARE stmt2;
							END IF;
						END IF;
					END IF;
					SET @column_count_gll = 0;
					SET @max_length = 0;
					SET  y = y + 1; 
					UNTIL done END REPEAT cicle;
					SET done = 0;
					CLOSE curs_xlstable;
					
					
					SET @sql_text1 =concat('INSERT INTO ',@xlstable, ' SELECT * FROM ',  @glltable, ' WHERE ID=', x);  
					PREPARE stmt2 FROM @sql_text1;
					EXECUTE stmt2;
					DEALLOCATE PREPARE stmt2;
				  

				SET  x = x + 1; 
			END WHILE;
		END IF;
END IF;


set @end_time = now();

SELECT CONCAT('Start time: ',@start_time, ' - end time ', @end_time);
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Estrutura da tabela `audit`
--

CREATE TABLE `audit` (
  `id` int(11) NOT NULL,
  `owner` varchar(30) NOT NULL,
  `files` text NOT NULL,
  `start_time` datetime NOT NULL,
  `end_time` datetime NOT NULL,
  `rows_count` int(11) NOT NULL,
  `defects_found` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Extraindo dados da tabela `audit`
--

INSERT INTO `audit` (`id`, `owner`, `files`, `start_time`, `end_time`, `rows_count`, `defects_found`) VALUES
(1, 'vanderson', ';vfsudas_schedule_1497332766_rio_cust_0040_20170509_000542_r2m1;vfsudas_schedule_1497332766_rio_cust_0040_20170509_000543_r2m1;vfsudas_schedule_1497332766_rio_cust_0040_20170509_000544_r2m1;vfsudas_schedule_1497332766_rio_cust_0040_20170509_000545_r2m1;vfsudas_schedule_1497332766_rio_cust_0040_20170509_000548_r2m1;vfsudas_schedule_1497332766_rio_cust_0040_20170509_000549_r2m1;vfsudas_schedule_1497332766_rio_cust_0040_20170509_000550_r2m1;vfsudas_schedule_1497332766_rio_cust_0040_20170509_000554_r2m1;vfsudas_schedule_1497332766_rio_cust_0040_20170509_000556_r2m1;vfsudas_schedule_1497332766_rio_cust_0040_20170509_000557_r2m1', '2017-06-13 02:46:58', '2017-06-13 02:48:28', 10000, 8),
(2, 'vanderson', ';vfsudas_1497334128_rio_cust_0040_20170509_000542_r2m1', '2017-06-13 03:09:23', '2017-06-13 03:09:45', 1000, 8),
(3, 'vanderson', ';vfsudas_1497333235_stms_udas_0160_20170322_000063_r2m1', '2017-06-13 02:55:14', '2017-06-13 03:20:35', 0, 267282),
(4, 'vanderson', ';rkaiber_1497381056_rio_cust_0040_20170612_000001_r1m3;rkaiber_1497381056_rio_cust_0040_20170612_000002_r1m3;rkaiber_1497381056_rio_cust_0040_20170612_000003_r1m3', '2017-06-13 16:51:11', '2017-06-13 17:01:47', 21568, 68365),
(5, 'vanderson', ';willian_1497383008_stms_udas_0160_20170322_000063_r2m1', '2017-06-13 16:51:11', '2017-06-13 17:32:18', 0, 267282),
(6, 'vanderson', ';rkaiber_1497383662_rio_cust_0075_20170612_000227_r1m3;rkaiber_1497383662_rio_cust_0075_20170612_000228_r1m3;rkaiber_1497383662_rio_cust_0075_20170612_000229_r1m3;rkaiber_1497383662_rio_cust_0075_20170612_000230_r1m3', '2017-06-13 16:58:12', '2017-06-13 19:27:23', 600346, 1200692),
(7, 'vanderson', ';rkaiber_1497547213_stms_bbnms_0010_20170517_000001_r1m3;rkaiber_1497547213_stms_bbnms_0010_20170517_000002_r1m3;rkaiber_1497547213_stms_bbnms_0010_20170517_000003_r1m3;rkaiber_1497547213_stms_bbnms_0010_20170517_000004_r1m3;rkaiber_1497547213_stms_bbnms_0010_20170517_000005_r1m3;rkaiber_1497547213_stms_bbnms_0010_20170517_000006_r1m3;rkaiber_1497547213_stms_bbnms_0010_20170517_000007_r1m3;rkaiber_1497547213_stms_bbnms_0010_20170517_000008_r1m3;rkaiber_1497547213_stms_bbnms_0010_20170517_000009_r1m3;rkaiber_1497547213_stms_bbnms_0010_20170517_000010_r1m3', '2017-06-15 14:21:44', '2017-06-15 14:42:50', 111715, 223430),
(8, 'vanderson', ';rkaiber_1497548240_stms_bbnms_0010_20170517_000001_r1m3;rkaiber_1497548240_stms_bbnms_0010_20170517_000002_r1m3;rkaiber_1497548240_stms_bbnms_0010_20170517_000003_r1m3;rkaiber_1497548240_stms_bbnms_0010_20170517_000004_r1m3;rkaiber_1497548240_stms_bbnms_0010_20170517_000005_r1m3;rkaiber_1497548240_stms_bbnms_0010_20170517_000006_r1m3;rkaiber_1497548240_stms_bbnms_0010_20170517_000007_r1m3;rkaiber_1497548240_stms_bbnms_0010_20170517_000008_r1m3;rkaiber_1497548240_stms_bbnms_0010_20170517_000009_r1m3;rkaiber_1497548240_stms_bbnms_0010_20170517_000010_r1m3', '2017-06-15 14:39:38', '2017-06-15 15:02:11', 111715, 175850),
(9, 'vanderson', ';_1497553303_stms_udas_0010_20170517_000004_r1m3', '2017-06-15 16:02:16', '2017-06-15 16:02:17', 0, 0),
(10, 'vanderson', ';mroland_1497553400_stms_udas_0010_20170517_000004_r1m3', '2017-06-15 16:03:53', '2017-06-15 16:03:53', 0, 0),
(11, 'vanderson', ';mroland_1497553524_stms_udas_0010_20170517_000004_r1m3', '2017-06-15 16:06:05', '2017-06-15 16:06:05', 0, 0),
(12, 'vanderson', ';mroland_1497554117_stms_udas_0010_20170517_000004_r1m3', '2017-06-15 16:15:50', '2017-06-15 16:15:50', 0, 0),
(13, 'vanderson', ';rkaiber_1497552783_stms_bbnms_0010_20170517_000001_r1m3;rkaiber_1497552783_stms_bbnms_0010_20170517_000002_r1m3;rkaiber_1497552783_stms_bbnms_0010_20170517_000003_r1m3;rkaiber_1497552783_stms_bbnms_0010_20170517_000004_r1m3;rkaiber_1497552783_stms_bbnms_0010_20170517_000005_r1m3;rkaiber_1497552783_stms_bbnms_0010_20170517_000006_r1m3;rkaiber_1497552783_stms_bbnms_0010_20170517_000007_r1m3;rkaiber_1497552783_stms_bbnms_0010_20170517_000008_r1m3;rkaiber_1497552783_stms_bbnms_0010_20170517_000009_r1m3;rkaiber_1497552783_stms_bbnms_0010_20170517_000010_r1m3', '2017-06-15 15:54:36', '2017-06-15 16:21:41', 111715, 111715),
(14, 'vanderson', ';mzelim_1497555650_stms_udas_0020_20170517_000010_r1m3;mzelim_1497555650_stms_udas_0020_20170517_000009_r1m3;mzelim_1497555650_stms_udas_0020_20170517_000007_r1m3;mzelim_1497555650_stms_udas_0020_20170517_000006_r1m3;mzelim_1497555650_stms_udas_0020_20170517_000004_r1m3;mzelim_1497555650_stms_udas_0020_20170517_000003_r1m3;mzelim_1497555650_stms_udas_0020_20170517_000002_r1m3;mzelim_1497555650_stms_udas_0020_20170517_000001_r1m3', '2017-06-15 16:42:49', '2017-06-15 16:42:52', 0, 8),
(15, 'vanderson', ';rkaiber_1497553760_stms_bbnms_0020_20170517_000001_r1m3;rkaiber_1497553760_stms_bbnms_0020_20170517_000002_r1m3;rkaiber_1497553760_stms_bbnms_0020_20170517_000003_r1m3;rkaiber_1497553760_stms_bbnms_0020_20170517_000004_r1m3;rkaiber_1497553760_stms_bbnms_0020_20170517_000005_r1m3;rkaiber_1497553760_stms_bbnms_0020_20170517_000006_r1m3;rkaiber_1497553760_stms_bbnms_0020_20170517_000007_r1m3;rkaiber_1497553760_stms_bbnms_0020_20170517_000008_r1m3;rkaiber_1497553760_stms_bbnms_0020_20170517_000009_r1m3;rkaiber_1497553760_stms_bbnms_0020_20170517_000010_r1m3', '2017-06-15 16:12:18', '2017-06-15 16:49:01', 0, 0),
(16, 'vanderson', ';rkaiber_1497554149_stms_bbnms_0020_20170517_000001_r1m3;rkaiber_1497554149_stms_bbnms_0020_20170517_000002_r1m3;rkaiber_1497554149_stms_bbnms_0020_20170517_000003_r1m3;rkaiber_1497554149_stms_bbnms_0020_20170517_000004_r1m3;rkaiber_1497554149_stms_bbnms_0020_20170517_000005_r1m3;rkaiber_1497554149_stms_bbnms_0020_20170517_000006_r1m3;rkaiber_1497554149_stms_bbnms_0020_20170517_000007_r1m3;rkaiber_1497554149_stms_bbnms_0020_20170517_000008_r1m3;rkaiber_1497554149_stms_bbnms_0020_20170517_000009_r1m3;rkaiber_1497554149_stms_bbnms_0020_20170517_000010_r1m3', '2017-06-15 16:18:06', '2017-06-15 16:51:54', 0, 0),
(17, 'vanderson', ';rkaiber_1497556487_rio_bbnms_0020_20170613_000001_r1m3;rkaiber_1497556487_rio_bbnms_0020_20170613_000002_r1m3;rkaiber_1497556487_rio_bbnms_0020_20170613_000003_r1m3;rkaiber_1497556487_rio_bbnms_0020_20170613_000004_r1m3;rkaiber_1497556487_rio_bbnms_0020_20170613_000005_r1m3;rkaiber_1497556487_rio_bbnms_0020_20170613_000006_r1m3;rkaiber_1497556487_rio_bbnms_0020_20170613_000007_r1m3;rkaiber_1497556487_rio_bbnms_0020_20170613_000008_r1m3;rkaiber_1497556487_rio_bbnms_0020_20170613_000009_r1m3;rkaiber_1497556487_rio_bbnms_0020_20170613_000010_r1m3', '2017-06-15 16:55:52', '2017-06-15 17:35:17', 0, 0),
(18, 'vanderson', ';rkaiber_1497556317_stms_bbnms_0020_20170517_000001_r1m3;rkaiber_1497556317_stms_bbnms_0020_20170517_000002_r1m3;rkaiber_1497556317_stms_bbnms_0020_20170517_000003_r1m3;rkaiber_1497556317_stms_bbnms_0020_20170517_000004_r1m3;rkaiber_1497556317_stms_bbnms_0020_20170517_000005_r1m3;rkaiber_1497556317_stms_bbnms_0020_20170517_000006_r1m3;rkaiber_1497556317_stms_bbnms_0020_20170517_000007_r1m3;rkaiber_1497556317_stms_bbnms_0020_20170517_000008_r1m3;rkaiber_1497556317_stms_bbnms_0020_20170517_000009_r1m3;rkaiber_1497556317_stms_bbnms_0020_20170517_000010_r1m3', '2017-06-15 16:53:28', '2017-06-15 18:15:16', 0, 0),
(19, 'vanderson', ';mzelim_1497556775_stms_udas_0020_20170517_000010_r1m3;mzelim_1497556775_stms_udas_0020_20170517_000009_r1m3;mzelim_1497556775_stms_udas_0020_20170517_000007_r1m3;mzelim_1497556775_stms_udas_0020_20170517_000006_r1m3;mzelim_1497556775_stms_udas_0020_20170517_000004_r1m3;mzelim_1497556775_stms_udas_0020_20170517_000003_r1m3;mzelim_1497556775_stms_udas_0020_20170517_000002_r1m3;mzelim_1497556775_stms_udas_0020_20170517_000001_r1m3', '2017-06-15 17:03:00', '2017-06-15 18:23:23', 0, 0),
(20, 'vanderson', ';vanderson_1497574551582_rio_cust_0040_20170509_000557_r2m1', '2017-06-15 21:56:53', '2017-06-15 21:57:00', 1000, 0),
(21, 'vanderson', ';vanderson_1497612786455_rio_bbnms_0030_20170613_000001_r1m3;vanderson_1497612786455_rio_bbnms_0030_20170613_000002_r1m3;vanderson_1497612786455_rio_bbnms_0030_20170613_000003_r1m3;vanderson_1497612786455_rio_bbnms_0030_20170613_000004_r1m3;vanderson_1497612786455_rio_bbnms_0030_20170613_000005_r1m3;vanderson_1497612786455_rio_bbnms_0030_20170613_000006_r1m3;vanderson_1497612786455_rio_bbnms_0030_20170613_000007_r1m3;vanderson_1497612786455_rio_bbnms_0030_20170613_000008_r1m3;vanderson_1497612786455_rio_bbnms_0030_20170613_000009_r1m3;vanderson_1497612786455_rio_bbnms_0030_20170613_000010_r1m3', '2017-06-16 08:34:26', '2017-06-16 08:34:27', 81483, 10),
(22, 'vanderson', ';vanderson_1497614270953_stms_cust_0040_20170517_000001_r1m3;vanderson_1497614270953_stms_cust_0040_20170517_000002_r1m3;vanderson_1497614270953_stms_cust_0040_20170517_000003_r1m3;vanderson_1497614270953_stms_cust_0040_20170517_000004_r1m3;vanderson_1497614270953_stms_cust_0040_20170517_000005_r1m3;vanderson_1497614270953_stms_cust_0040_20170517_000006_r1m3;vanderson_1497614270953_stms_cust_0040_20170517_000007_r1m3;vanderson_1497614270953_stms_cust_0040_20170517_000008_r1m3;vanderson_1497614270953_stms_cust_0040_20170517_000009_r1m3', '2017-06-16 08:59:24', '2017-06-16 08:59:25', 101607, 9),
(23, 'vanderson', ';vanderson_1497615740681_stms_udas_0010_20170517_000002_r1m3', '2017-06-16 09:23:08', '2017-06-16 09:23:08', 11544, 1),
(24, 'vanderson', ';vanderson_1497620156244_rio_cust_0040_20170509_000542_r2m1', '2017-06-16 10:36:46', '2017-06-16 10:36:56', 1000, 6),
(25, 'vanderson', ';vanderson_1497623514649_rio_cust_0040_20170509_000542_r2m1', '2017-06-16 11:33:57', '2017-06-16 11:34:07', 1000, 6),
(26, 'vanderson', ';vanderson_1497624151086_stms_bbnms_0010_20170517_000001_r1m3;vanderson_1497624151086_stms_bbnms_0010_20170517_000002_r1m3;vanderson_1497624151086_stms_bbnms_0010_20170517_000003_r1m3;vanderson_1497624151086_stms_bbnms_0010_20170517_000004_r1m3;vanderson_1497624151086_stms_bbnms_0010_20170517_000005_r1m3', '2017-06-16 11:43:45', '2017-06-16 11:43:45', 57765, 5),
(27, 'vanderson', ';vanderson_1497624516381_stms_bbnms_0010_20170517_000001_r1m3', '2017-06-16 11:49:23', '2017-06-16 11:49:23', 12094, 1),
(28, 'vanderson', ';vanderson_1497624815517_stms_bbnms_0010_20170517_000001_r1m3', '2017-06-16 11:54:21', '2017-06-16 11:55:24', 12094, 0),
(29, 'vanderson', ';vanderson_1497625114062_stms_bbnms_0010_20170517_000001_r1m3', '2017-06-16 11:59:20', '2017-06-16 12:00:28', 12094, 0),
(30, 'vanderson', ';vanderson_1497625261612_stms_bbnms_0010_20170517_000001_r1m3', '2017-06-16 12:01:48', '2017-06-16 12:02:57', 12094, 1),
(31, 'vanderson', ';vanderson_1497625786620_stms_bbnms_0010_20170517_000001_r1m3', '2017-06-16 12:10:33', '2017-06-16 12:11:41', 12094, 2),
(32, 'vanderson', ';vanderson_1497630120014_stms_bbnms_0010_20170517_000001_r1m3', '2017-06-16 13:23:15', '2017-06-16 13:25:16', 12094, 3),
(33, 'vanderson', ';vanderson_1497630806236_stms_bbnms_0010_20170517_000001_r1m3', '2017-06-16 13:34:17', '2017-06-16 13:37:12', 12094, 3),
(34, 'vanderson', ';vanderson_1497634650765_stms_cust_0050_20170517_000001_r1m3;vanderson_1497634650765_stms_cust_0050_20170517_000002_r1m3;vanderson_1497634650765_stms_cust_0050_20170517_000003_r1m3;vanderson_1497634650765_stms_cust_0050_20170517_000004_r1m3;vanderson_1497634650765_stms_cust_0050_20170517_000005_r1m3;vanderson_1497634650765_stms_cust_0050_20170517_000006_r1m3;vanderson_1497634650765_stms_cust_0050_20170517_000007_r1m3;vanderson_1497634650765_stms_cust_0050_20170517_000008_r1m3;vanderson_1497634650765_stms_cust_0050_20170517_000009_r1m3;vanderson_1497634650765_stms_cust_0050_20170517_000010_r1m3', '2017-06-16 14:42:48', '2017-06-16 14:42:53', 199798, 10),
(35, 'vanderson', ';vanderson_1497633538811_stms_cust_0040_20170517_000001_r1m3;vanderson_1497633538811_stms_cust_0040_20170517_000002_r1m3;vanderson_1497633538811_stms_cust_0040_20170517_000003_r1m3;vanderson_1497633538811_stms_cust_0040_20170517_000004_r1m3;vanderson_1497633538811_stms_cust_0040_20170517_000005_r1m3;vanderson_1497633538811_stms_cust_0040_20170517_000006_r1m3;vanderson_1497633538811_stms_cust_0040_20170517_000007_r1m3;vanderson_1497633538811_stms_cust_0040_20170517_000008_r1m3;vanderson_1497633538811_stms_cust_0040_20170517_000009_r1m3;vanderson_1497633538811_stms_cust_0040_20170517_000010_r1m3', '2017-06-16 14:22:28', '2017-06-16 15:00:59', 111715, 111715),
(36, 'vanderson', ';vanderson_1497636176800_stms_cust_0070_20170517_000001_r1m3;vanderson_1497636176800_stms_cust_0070_20170517_000002_r1m3;vanderson_1497636176800_stms_cust_0070_20170517_000003_r1m3;vanderson_1497636176800_stms_cust_0070_20170517_000004_r1m3;vanderson_1497636176800_stms_cust_0070_20170517_000005_r1m3;vanderson_1497636176800_stms_cust_0070_20170517_000006_r1m3;vanderson_1497636176800_stms_cust_0070_20170517_000007_r1m3;vanderson_1497636176800_stms_cust_0070_20170517_000008_r1m3;vanderson_1497636176800_stms_cust_0070_20170517_000009_r1m3;vanderson_1497636176800_stms_cust_0070_20170517_000010_r1m3', '2017-06-16 15:18:52', '2017-06-16 15:18:53', 1882813, 10),
(37, 'vanderson', ';vanderson_1497639574791_stms_cust_0075_20170517_000001_r1m3;vanderson_1497639574791_stms_cust_0075_20170517_000002_r1m3;vanderson_1497639574791_stms_cust_0075_20170517_000003_r1m3;vanderson_1497639574791_stms_cust_0075_20170517_000004_r1m3;vanderson_1497639574791_stms_cust_0075_20170517_000005_r1m3;vanderson_1497639574791_stms_cust_0075_20170517_000006_r1m3;vanderson_1497639574791_stms_cust_0075_20170517_000007_r1m3;vanderson_1497639574791_stms_cust_0075_20170517_000008_r1m3;vanderson_1497639574791_stms_cust_0075_20170517_000009_r1m3;vanderson_1497639574791_stms_cust_0075_20170517_000010_r1m3', '2017-06-16 16:15:34', '2017-06-16 16:15:35', 3212985, 10),
(38, 'vanderson', ';vanderson_1497641512072_stms_cust_0075_20170517_000001_r1m3;vanderson_1497641512072_stms_cust_0075_20170517_000002_r1m3;vanderson_1497641512072_stms_cust_0075_20170517_000003_r1m3;vanderson_1497641512072_stms_cust_0075_20170517_000004_r1m3;vanderson_1497641512072_stms_cust_0075_20170517_000005_r1m3;vanderson_1497641512072_stms_cust_0075_20170517_000006_r1m3', '2017-06-16 16:41:39', '2017-06-16 16:41:39', 2039252, 6),
(39, 'vanderson', '', '2017-06-16 17:12:17', '2017-06-16 17:12:17', 0, 0),
(40, 'vanderson', ';vanderson_1497643839043_stms_cust_0500_20170517_000001_r1m3;vanderson_1497643839043_stms_cust_0500_20170517_000002_r1m3;vanderson_1497643839043_stms_cust_0500_20170517_000003_r1m3;vanderson_1497643839043_stms_cust_0500_20170517_000004_r1m3;vanderson_1497643839043_stms_cust_0500_20170517_000005_r1m3;vanderson_1497643839043_stms_cust_0500_20170517_000006_r1m3;vanderson_1497643839043_stms_cust_0500_20170517_000007_r1m3;vanderson_1497643839043_stms_cust_0500_20170517_000008_r1m3;vanderson_1497643839043_stms_cust_0500_20170517_000009_r1m3;vanderson_1497643839043_stms_cust_0500_20170517_000010_r1m3', '2017-06-16 17:12:31', '2017-06-16 17:12:33', 111715, 10),
(41, 'vanderson', ';vanderson_1497643989482_teste_colunas', '2017-06-16 17:14:04', '2017-06-16 17:14:04', 1, 1),
(42, 'vanderson', ';vanderson_1497644299417_teste_colunas', '2017-06-16 17:19:51', '2017-06-16 17:19:51', 1, 1),
(43, 'vanderson', ';vanderson_1497644390757_teste_colunas', '2017-06-16 17:21:32', '2017-06-16 17:21:32', 1, 1),
(44, 'vanderson', ';vanderson_1497644417805_teste_colunas', '2017-06-16 17:22:04', '2017-06-16 17:22:04', 1, 1),
(45, 'vanderson', ';vanderson_1497644473155_teste_colunas', '2017-06-16 17:23:07', '2017-06-16 17:23:07', 1, 1),
(46, 'vanderson', ';vanderson_1497644738680_teste_colunas', '2017-06-16 17:26:23', '2017-06-16 17:26:23', 1, 1),
(47, 'vanderson', ';vanderson_1497644690070_stms_bbnms_0010_20170517_000001_r1m3', '2017-06-16 17:25:41', '2017-06-16 17:26:56', 12094, 3),
(48, 'vanderson', ';vanderson_1497645181562_teste_colunas', '2017-06-16 17:34:29', '2017-06-16 17:34:29', 1, 1),
(49, 'vanderson', ';vanderson_1497645300041_teste_colunas', '2017-06-16 17:36:44', '2017-06-16 17:36:46', 1, 1),
(50, 'vanderson', ';vanderson_1497645314652_teste_colunas', '2017-06-16 17:37:01', '2017-06-16 17:37:02', 1, 1),
(51, 'vanderson', ';vanderson_1497645331675_teste_colunas', '2017-06-16 17:37:36', '2017-06-16 17:37:37', 1, 1),
(52, 'vanderson', ';vanderson_1497645461178_teste_colunas', '2017-06-16 17:40:09', '2017-06-16 17:40:10', 1, 1),
(53, 'vanderson', ';vanderson_1497645793062_teste_colunas', '2017-06-16 17:46:12', '2017-06-16 17:46:15', 1, 1),
(54, 'vanderson', ';vanderson_1497645527183_stms_invc_0110_20170517_000001_r1m3;vanderson_1497645527183_stms_invc_0110_20170517_000002_r1m3;vanderson_1497645527183_stms_invc_0110_20170517_000003_r1m3;vanderson_1497645527183_stms_invc_0110_20170517_000004_r1m3;vanderson_1497645527183_stms_invc_0110_20170517_000005_r1m3;vanderson_1497645527183_stms_invc_0110_20170517_000006_r1m3;vanderson_1497645527183_stms_invc_0110_20170517_000007_r1m3;vanderson_1497645527183_stms_invc_0110_20170517_000008_r1m3;vanderson_1497645527183_stms_invc_0110_20170517_000009_r1m3;vanderson_1497645527183_stms_invc_0110_20170517_000010_r1m3', '2017-06-16 17:46:37', '2017-06-16 17:46:46', 340013, 10),
(55, 'vanderson', ';vanderson_1497645936154_teste_colunas', '2017-06-16 17:48:34', '2017-06-16 17:48:34', 1, 7),
(56, 'vanderson', ';vanderson_1497879501683_stms_cust_0010_20170517_000001_r1m3;vanderson_1497879501683_stms_cust_0010_20170517_000002_r1m3;vanderson_1497879501683_stms_cust_0010_20170517_000003_r1m3;vanderson_1497879501683_stms_cust_0010_20170517_000004_r1m3;vanderson_1497879501683_stms_cust_0010_20170517_000005_r1m3;vanderson_1497879501683_stms_cust_0010_20170517_000006_r1m3;vanderson_1497879501683_stms_cust_0010_20170517_000007_r1m3;vanderson_1497879501683_stms_cust_0010_20170517_000008_r1m3;vanderson_1497879501683_stms_cust_0010_20170517_000009_r1m3;vanderson_1497879501683_stms_cust_0010_20170517_000010_r1m3', '2017-06-19 10:40:13', '2017-06-19 10:40:15', 111715, 10),
(57, 'vanderson', '', '2017-06-19 11:10:38', '2017-06-19 11:10:38', 0, 0),
(58, 'vanderson', ';vanderson_1497881475535_stms_cust_0020_20170517_000001_r1m3;vanderson_1497881475535_stms_cust_0020_20170517_000002_r1m3;vanderson_1497881475535_stms_cust_0020_20170517_000003_r1m3;vanderson_1497881475535_stms_cust_0020_20170517_000004_r1m3;vanderson_1497881475535_stms_cust_0020_20170517_000005_r1m3;vanderson_1497881475535_stms_cust_0020_20170517_000006_r1m3;vanderson_1497881475535_stms_cust_0020_20170517_000007_r1m3;vanderson_1497881475535_stms_cust_0020_20170517_000008_r1m3;vanderson_1497881475535_stms_cust_0020_20170517_000009_r1m3;vanderson_1497881475535_stms_cust_0020_20170517_000010_r1m3', '2017-06-19 11:14:05', '2017-06-19 11:14:07', 111715, 10),
(59, 'vanderson', ';vanderson_1497881787302_stms_cust_0050_20170517_000001_r1m3;vanderson_1497881787302_stms_cust_0050_20170517_000002_r1m3;vanderson_1497881787302_stms_cust_0050_20170517_000003_r1m3;vanderson_1497881787302_stms_cust_0050_20170517_000004_r1m3;vanderson_1497881787302_stms_cust_0050_20170517_000005_r1m3;vanderson_1497881787302_stms_cust_0050_20170517_000006_r1m3;vanderson_1497881787302_stms_cust_0050_20170517_000007_r1m3;vanderson_1497881787302_stms_cust_0050_20170517_000008_r1m3;vanderson_1497881787302_stms_cust_0050_20170517_000009_r1m3;vanderson_1497881787302_stms_cust_0050_20170517_000010_r1m3', '2017-06-19 11:18:50', '2017-06-19 11:18:52', 199798, 10),
(60, 'vanderson', ';vanderson_1497882583213_stms_invc_0110_20170517_000060_r1m3', '2017-06-19 11:30:50', '2017-06-19 11:30:50', 94349, 1),
(61, 'vanderson', '', '2017-06-21 18:57:36', '2017-06-21 18:57:36', 0, 0),
(62, 'vanderson', '', '2017-06-21 18:57:36', '2017-06-21 18:57:36', 0, 0),
(63, 'vanderson', ';vanderson_1497986166103_stms_cust_0020_20170517_000004_r1m3', '2017-06-21 18:57:36', '2017-06-21 18:57:36', 1, 0),
(64, 'vanderson', '', '2017-06-21 18:57:36', '2017-06-21 18:57:36', 0, 0),
(65, 'vanderson', ';vanderson_1497985051043_stms_cust_0020_20170517_000004_r1m3', '2017-06-21 18:57:36', '2017-06-21 18:57:40', 1, 1),
(66, 'vanderson', ';vanderson_1497985399436_stms_cust_0020_20170517_000004_r1m3', '2017-06-21 18:57:36', '2017-06-21 18:57:41', 1, 1),
(67, 'vanderson', ';vanderson_1497985619369_stms_cust_0020_20170517_000004_r1m3', '2017-06-21 18:57:36', '2017-06-21 18:57:42', 1, 1),
(68, 'vanderson', ';vanderson_1497908508541_edw_cust_0010_20170613_000001_r1m3', '2017-06-21 18:57:36', '2017-06-21 18:57:42', 2255904, 1),
(69, 'vanderson', ';vanderson_1497986052988_stms_cust_0020_20170517_000004_r1m3', '2017-06-21 18:57:36', '2017-06-21 18:57:43', 1, 1),
(70, 'vanderson', ';vanderson_1497985196752_stms_cust_0020_20170517_000004_r1m3', '2017-06-21 18:57:36', '2017-06-21 18:57:50', 1, 1),
(71, 'vanderson', ';vanderson_1497985520960_stms_cust_0020_20170517_000004_r1m3', '2017-06-21 18:57:36', '2017-06-21 18:57:50', 1, 1),
(72, 'vanderson', ';vanderson_1497983606203_stms_cust_0010_20170517_000001_r1m3', '2017-06-21 18:57:36', '2017-06-21 18:57:53', 1, 1),
(73, 'vanderson', ';vanderson_1497983776928_stms_cust_0010_20170517_000001_r1m3', '2017-06-21 18:57:36', '2017-06-21 18:58:00', 1, 20),
(74, 'vanderson', ';vanderson_1497912407807_stms_invc_0120_20170517_000001_r1m3;vanderson_1497912407807_stms_invc_0120_20170517_000002_r1m3;vanderson_1497912407807_stms_invc_0120_20170517_000003_r1m3;vanderson_1497912407807_stms_invc_0120_20170517_000004_r1m3;vanderson_1497912407807_stms_invc_0120_20170517_000005_r1m3;vanderson_1497912407807_stms_invc_0120_20170517_000006_r1m3;vanderson_1497912407807_stms_invc_0120_20170517_000007_r1m3;vanderson_1497912407807_stms_invc_0120_20170517_000008_r1m3;vanderson_1497912407807_stms_invc_0120_20170517_000009_r1m3;vanderson_1497912407807_stms_invc_0120_20170517_000010_r1m3', '2017-06-21 18:57:36', '2017-06-21 18:58:10', 1880205, 10),
(75, 'vanderson', ';vanderson_1498058260890_rio_bbnms_0040_20170613_000001_r1m3;vanderson_1498058260890_rio_bbnms_0040_20170613_000002_r1m3;vanderson_1498058260890_rio_bbnms_0040_20170613_000003_r1m3;vanderson_1498058260890_rio_bbnms_0040_20170613_000004_r1m3;vanderson_1498058260890_rio_bbnms_0040_20170613_000005_r1m3;vanderson_1498058260890_rio_bbnms_0040_20170613_000006_r1m3;vanderson_1498058260890_rio_bbnms_0040_20170613_000007_r1m3;vanderson_1498058260890_rio_bbnms_0040_20170613_000008_r1m3;vanderson_1498058260890_rio_bbnms_0040_20170613_000009_r1m3;vanderson_1498058260890_rio_bbnms_0040_20170613_000010_r1m3;vanderson_1498058260890_rio_bbnms_0040_20170613_000011_r1m3;vanderson_1498058260890_rio_bbnms_0040_20170613_000012_r1m3;vanderson_1498058260890_rio_bbnms_0040_20170613_000013_r1m3;vanderson_1498058260890_rio_bbnms_0040_20170613_000014_r1m3;vanderson_1498058260890_rio_bbnms_0040_20170613_000015_r1m3;vanderson_1498058260890_rio_bbnms_0040_20170613_000016_r1m3;vanderson_1498058260890_rio_bbnms_0040_20170613_000017_r1m3;vanderson_1498058260890_rio_bbnms_0040_20170613_000018_r1m3;vanderson_1498058260890_rio_bbnms_0040_20170613_000019_r1m3;vanderson_1498058260890_rio_bbnms_0040_20170613_000020_r1m3', '2017-06-21 18:57:36', '2017-06-21 18:58:26', 256745, 20),
(76, 'vanderson', ';vanderson_1498059541284_rio_bbnms_0050_20170613_000172_r1m3;vanderson_1498059541284_rio_bbnms_0050_20170613_000173_r1m3;vanderson_1498059541284_rio_bbnms_0050_20170613_000174_r1m3;vanderson_1498059541284_rio_bbnms_0050_20170613_000175_r1m3;vanderson_1498059541284_rio_bbnms_0050_20170613_000176_r1m3;vanderson_1498059541284_rio_bbnms_0050_20170613_000177_r1m3;vanderson_1498059541284_rio_bbnms_0050_20170613_000178_r1m3;vanderson_1498059541284_rio_bbnms_0050_20170613_000179_r1m3;vanderson_1498059541284_rio_bbnms_0050_20170613_000180_r1m3;vanderson_1498059541284_rio_bbnms_0050_20170613_000181_r1m3;vanderson_1498059541284_rio_bbnms_0050_20170613_000182_r1m3;vanderson_1498059541284_rio_bbnms_0050_20170613_000183_r1m3;vanderson_1498059541284_rio_bbnms_0050_20170613_000184_r1m3;vanderson_1498059541284_rio_bbnms_0050_20170613_000185_r1m3;vanderson_1498059541284_rio_bbnms_0050_20170613_000186_r1m3;vanderson_1498059541284_rio_bbnms_0050_20170613_000187_r1m3;vanderson_1498059541284_rio_bbnms_0050_20170613_000188_r1m3;vanderson_1498059541284_rio_bbnms_0050_20170613_000189_r1m3;vanderson_1498059541284_rio_bbnms_0050_20170613_000190_r1m3;vanderson_1498059541284_rio_bbnms_0050_20170613_000191_r1m3;vanderson_1498059541284_rio_bbnms_0050_20170613_000192_r1m3;vanderson_1498059541284_rio_bbnms_0050_20170613_000193_r1m3;vanderson_1498059541284_rio_bbnms_0050_20170613_000194_r1m3;vanderson_1498059541284_rio_bbnms_0050_20170613_000195_r1m3;vanderson_1498059541284_rio_bbnms_0050_20170613_000196_r1m3;vanderson_1498059541284_rio_bbnms_0050_20170613_000197_r1m3;vanderson_1498059541284_rio_bbnms_0050_20170613_000198_r1m3;vanderson_1498059541284_rio_bbnms_0050_20170613_000199_r1m3;vanderson_1498059541284_rio_bbnms_0050_20170613_000200_r1m3;vanderson_1498059541284_rio_bbnms_0050_20170613_000201_r1m3;vanderson_1498059541284_rio_bbnms_0050_20170613_000202_r1m3;vanderson_1498059541284_rio_bbnms_0050_20170613_000203_r1m3;vanderson_1498059541284_rio_bbnms_0050_20170613_000204_r1m3;vanderson_1498059541284_rio_bbnms_0050_20170613_000205_r1m3;vanderson_1498059541284_rio_bbnms_0050_20170613_000206_r1m3;vanderson_1498059541284_rio_bbnms_0050_20170613_000207_r1m3;vanderson_1498059541284_rio_bbnms_0050_20170613_000208_r1m3;vanderson_1498059541284_rio_bbnms_0050_20170613_000209_r1m3;vanderson_1498059541284_rio_bbnms_0050_20170613_000210_r1m3;vanderson_1498059541284_rio_bbnms_0050_20170613_000211_r1m3;vanderson_1498059541284_rio_bbnms_0050_20170613_000212_r1m3;vanderson_1498059541284_rio_bbnms_0050_20170613_000213_r1m3;vanderson_1498059541284_rio_bbnms_0050_20170613_000214_r1m3;vanderson_1498059541284_rio_bbnms_0050_20170613_000215_r1m3;vanderson_1498059541284_rio_bbnms_0050_20170613_000216_r1m3;vanderson_1498059541284_rio_bbnms_0050_20170613_000217_r1m3;vanderson_1498059541284_rio_bbnms_0050_20170613_000218_r1m3;vanderson_1498059541284_rio_bbnms_0050_20170613_000219_r1m3;vanderson_1498059541284_rio_bbnms_0050_20170613_000220_r1m3;vanderson_1498059541284_rio_bbnms_0050_20170613_000221_r1m3;vanderson_1498059541284_rio_bbnms_0050_20170613_000222_r1m3;vanderson_1498059541284_rio_bbnms_0050_20170613_000223_r1m3;vanderson_1498059541284_rio_bbnms_0050_20170613_000224_r1m3;vanderson_1498059541284_rio_bbnms_0050_20170613_000225_r1m3;vanderson_1498059541284_rio_bbnms_0050_20170613_000226_r1m3;vanderson_1498059541284_rio_bbnms_0050_20170613_000227_r1m3;vanderson_1498059541284_rio_bbnms_0050_20170613_000228_r1m3;vanderson_1498059541284_rio_bbnms_0050_20170613_000229_r1m3;vanderson_1498059541284_rio_bbnms_0050_20170613_000230_r1m3;vanderson_1498059541284_rio_bbnms_0050_20170613_000231_r1m3;vanderson_1498059541284_rio_bbnms_0050_20170613_000232_r1m3;vanderson_1498059541284_rio_bbnms_0050_20170613_000233_r1m3;vanderson_1498059541284_rio_bbnms_0050_20170613_000234_r1m3;vanderson_1498059541284_rio_bbnms_0050_20170613_000235_r1m3;vanderson_1498059541284_rio_bbnms_0050_20170613_000236_r1m3;vanderson_1498059541284_rio_bbnms_0050_20170613_000237_r1m3;vanderson_1498059541284_rio_bbnms_0050_20170613_000238_r1m3;vanderson_1498059541284_rio_bbnms_0050_20170613_000239_r1m3', '2017-06-21 18:57:36', '2017-06-21 18:58:51', 18486, 50),
(77, 'vanderson', ';vanderson_1498067189980_rio_bbnms_0070_20170613_000078_r1m3;vanderson_1498067189980_rio_bbnms_0070_20170613_000079_r1m3;vanderson_1498067189980_rio_bbnms_0070_20170613_000080_r1m3;vanderson_1498067189980_rio_bbnms_0070_20170613_000081_r1m3;vanderson_1498067189980_rio_bbnms_0070_20170613_000082_r1m3;vanderson_1498067189980_rio_bbnms_0070_20170613_000083_r1m3;vanderson_1498067189980_rio_bbnms_0070_20170613_000084_r1m3;vanderson_1498067189980_rio_bbnms_0070_20170613_000085_r1m3;vanderson_1498067189980_rio_bbnms_0070_20170613_000086_r1m3;vanderson_1498067189980_rio_bbnms_0070_20170613_000087_r1m3;vanderson_1498067189980_rio_bbnms_0070_20170613_000088_r1m3;vanderson_1498067189980_rio_bbnms_0070_20170613_000089_r1m3;vanderson_1498067189980_rio_bbnms_0070_20170613_000090_r1m3;vanderson_1498067189980_rio_bbnms_0070_20170613_000091_r1m3;vanderson_1498067189980_rio_bbnms_0070_20170613_000092_r1m3;vanderson_1498067189980_rio_bbnms_0070_20170613_000093_r1m3;vanderson_1498067189980_rio_bbnms_0070_20170613_000094_r1m3;vanderson_1498067189980_rio_bbnms_0070_20170613_000095_r1m3;vanderson_1498067189980_rio_bbnms_0070_20170613_000096_r1m3;vanderson_1498067189980_rio_bbnms_0070_20170613_000097_r1m3;vanderson_1498067189980_rio_bbnms_0070_20170613_000098_r1m3;vanderson_1498067189980_rio_bbnms_0070_20170613_000099_r1m3;vanderson_1498067189980_rio_bbnms_0070_20170613_000100_r1m3;vanderson_1498067189980_rio_bbnms_0070_20170613_000101_r1m3;vanderson_1498067189980_rio_bbnms_0070_20170613_000102_r1m3;vanderson_1498067189980_rio_bbnms_0070_20170613_000103_r1m3;vanderson_1498067189980_rio_bbnms_0070_20170613_000104_r1m3;vanderson_1498067189980_rio_bbnms_0070_20170613_000105_r1m3;vanderson_1498067189980_rio_bbnms_0070_20170613_000106_r1m3;vanderson_1498067189980_rio_bbnms_0070_20170613_000107_r1m3;vanderson_1498067189980_rio_bbnms_0070_20170613_000108_r1m3;vanderson_1498067189980_rio_bbnms_0070_20170613_000109_r1m3;vanderson_1498067189980_rio_bbnms_0070_20170613_000110_r1m3;vanderson_1498067189980_rio_bbnms_0070_20170613_000111_r1m3;vanderson_1498067189980_rio_bbnms_0070_20170613_000112_r1m3;vanderson_1498067189980_rio_bbnms_0070_20170613_000113_r1m3;vanderson_1498067189980_rio_bbnms_0070_20170613_000114_r1m3;vanderson_1498067189980_rio_bbnms_0070_20170613_000115_r1m3;vanderson_1498067189980_rio_bbnms_0070_20170613_000116_r1m3;vanderson_1498067189980_rio_bbnms_0070_20170613_000117_r1m3;vanderson_1498067189980_rio_bbnms_0070_20170613_000118_r1m3;vanderson_1498067189980_rio_bbnms_0070_20170613_000119_r1m3', '2017-06-21 18:57:36', '2017-06-21 18:59:02', 17706, 42),
(78, 'vanderson', ';vanderson_1497985699044_stms_invc_0140_20170517_000001_r1m3;vanderson_1497985699044_stms_invc_0140_20170517_000002_r1m3;vanderson_1497985699044_stms_invc_0140_20170517_000003_r1m3;vanderson_1497985699044_stms_invc_0140_20170517_000004_r1m3;vanderson_1497985699044_stms_invc_0140_20170517_000005_r1m3;vanderson_1497985699044_stms_invc_0140_20170517_000006_r1m3;vanderson_1497985699044_stms_invc_0140_20170517_000007_r1m3;vanderson_1497985699044_stms_invc_0140_20170517_000008_r1m3;vanderson_1497985699044_stms_invc_0140_20170517_000009_r1m3;vanderson_1497985699044_stms_invc_0140_20170517_000010_r1m3', '2017-06-21 18:57:36', '2017-06-21 18:59:09', 378268, 10),
(79, 'vanderson', ';vanderson_1497990087983_rio_bbnms_0030_20170613_000041_r1m3;vanderson_1497990087983_rio_bbnms_0030_20170613_000042_r1m3;vanderson_1497990087983_rio_bbnms_0030_20170613_000043_r1m3;vanderson_1497990087983_rio_bbnms_0030_20170613_000044_r1m3;vanderson_1497990087983_rio_bbnms_0030_20170613_000045_r1m3;vanderson_1497990087983_rio_bbnms_0030_20170613_000046_r1m3;vanderson_1497990087983_rio_bbnms_0030_20170613_000047_r1m3;vanderson_1497990087983_rio_bbnms_0030_20170613_000048_r1m3;vanderson_1497990087983_rio_bbnms_0030_20170613_000049_r1m3;vanderson_1497990087983_rio_bbnms_0030_20170613_000050_r1m3;vanderson_1497990087983_rio_bbnms_0030_20170613_000051_r1m3;vanderson_1497990087983_rio_bbnms_0030_20170613_000052_r1m3;vanderson_1497990087983_rio_bbnms_0030_20170613_000053_r1m3;vanderson_1497990087983_rio_bbnms_0030_20170613_000054_r1m3;vanderson_1497990087983_rio_bbnms_0030_20170613_000055_r1m3;vanderson_1497990087983_rio_bbnms_0030_20170613_000056_r1m3;vanderson_1497990087983_rio_bbnms_0030_20170613_000057_r1m3;vanderson_1497990087983_rio_bbnms_0030_20170613_000058_r1m3;vanderson_1497990087983_rio_bbnms_0030_20170613_000059_r1m3;vanderson_1497990087983_rio_bbnms_0030_20170613_000060_r1m3;vanderson_1497990087983_rio_bbnms_0030_20170613_000061_r1m3;vanderson_1497990087983_rio_bbnms_0030_20170613_000062_r1m3;vanderson_1497990087983_rio_bbnms_0030_20170613_000063_r1m3;vanderson_1497990087983_rio_bbnms_0030_20170613_000064_r1m3;vanderson_1497990087983_rio_bbnms_0030_20170613_000065_r1m3;vanderson_1497990087983_rio_bbnms_0030_20170613_000066_r1m3;vanderson_1497990087983_rio_bbnms_0030_20170613_000067_r1m3;vanderson_1497990087983_rio_bbnms_0030_20170613_000068_r1m3;vanderson_1497990087983_rio_bbnms_0030_20170613_000069_r1m3;vanderson_1497990087983_rio_bbnms_0030_20170613_000070_r1m3;vanderson_1497990087983_rio_bbnms_0030_20170613_000071_r1m3;vanderson_1497990087983_rio_bbnms_0030_20170613_000072_r1m3;vanderson_1497990087983_rio_bbnms_0030_20170613_000073_r1m3;vanderson_1497990087983_rio_bbnms_0030_20170613_000074_r1m3;vanderson_1497990087983_rio_bbnms_0030_20170613_000075_r1m3;vanderson_1497990087983_rio_bbnms_0030_20170613_000076_r1m3;vanderson_1497990087983_rio_bbnms_0030_20170613_000077_r1m3;vanderson_1497990087983_rio_bbnms_0030_20170613_000078_r1m3;vanderson_1497990087983_rio_bbnms_0030_20170613_000079_r1m3;vanderson_1497990087983_rio_bbnms_0030_20170613_000080_r1m3;vanderson_1497990087983_rio_bbnms_0030_20170613_000081_r1m3;vanderson_1497990087983_rio_bbnms_0030_20170613_000082_r1m3;vanderson_1497990087983_rio_bbnms_0030_20170613_000083_r1m3;vanderson_1497990087983_rio_bbnms_0030_20170613_000084_r1m3;vanderson_1497990087983_rio_bbnms_0030_20170613_000085_r1m3;vanderson_1497990087983_rio_bbnms_0030_20170613_000086_r1m3', '2017-06-21 18:57:36', '2017-06-21 18:59:17', 427161, 46),
(80, 'vanderson', ';vanderson_1498059969244_rio_bbnms_0060_20170613_000080_r1m3;vanderson_1498059969244_rio_bbnms_0060_20170613_000081_r1m3;vanderson_1498059969244_rio_bbnms_0060_20170613_000082_r1m3;vanderson_1498059969244_rio_bbnms_0060_20170613_000083_r1m3;vanderson_1498059969244_rio_bbnms_0060_20170613_000084_r1m3;vanderson_1498059969244_rio_bbnms_0060_20170613_000085_r1m3;vanderson_1498059969244_rio_bbnms_0060_20170613_000086_r1m3;vanderson_1498059969244_rio_bbnms_0060_20170613_000087_r1m3;vanderson_1498059969244_rio_bbnms_0060_20170613_000088_r1m3;vanderson_1498059969244_rio_bbnms_0060_20170613_000089_r1m3;vanderson_1498059969244_rio_bbnms_0060_20170613_000090_r1m3;vanderson_1498059969244_rio_bbnms_0060_20170613_000091_r1m3;vanderson_1498059969244_rio_bbnms_0060_20170613_000092_r1m3;vanderson_1498059969244_rio_bbnms_0060_20170613_000093_r1m3;vanderson_1498059969244_rio_bbnms_0060_20170613_000094_r1m3;vanderson_1498059969244_rio_bbnms_0060_20170613_000095_r1m3;vanderson_1498059969244_rio_bbnms_0060_20170613_000096_r1m3;vanderson_1498059969244_rio_bbnms_0060_20170613_000097_r1m3;vanderson_1498059969244_rio_bbnms_0060_20170613_000098_r1m3;vanderson_1498059969244_rio_bbnms_0060_20170613_000099_r1m3;vanderson_1498059969244_rio_bbnms_0060_20170613_000100_r1m3;vanderson_1498059969244_rio_bbnms_0060_20170613_000101_r1m3;vanderson_1498059969244_rio_bbnms_0060_20170613_000102_r1m3;vanderson_1498059969244_rio_bbnms_0060_20170613_000103_r1m3;vanderson_1498059969244_rio_bbnms_0060_20170613_000104_r1m3;vanderson_1498059969244_rio_bbnms_0060_20170613_000105_r1m3;vanderson_1498059969244_rio_bbnms_0060_20170613_000106_r1m3;vanderson_1498059969244_rio_bbnms_0060_20170613_000107_r1m3;vanderson_1498059969244_rio_bbnms_0060_20170613_000108_r1m3;vanderson_1498059969244_rio_bbnms_0060_20170613_000109_r1m3;vanderson_1498059969244_rio_bbnms_0060_20170613_000110_r1m3;vanderson_1498059969244_rio_bbnms_0060_20170613_000111_r1m3;vanderson_1498059969244_rio_bbnms_0060_20170613_000112_r1m3;vanderson_1498059969244_rio_bbnms_0060_20170613_000113_r1m3;vanderson_1498059969244_rio_bbnms_0060_20170613_000114_r1m3;vanderson_1498059969244_rio_bbnms_0060_20170613_000115_r1m3;vanderson_1498059969244_rio_bbnms_0060_20170613_000116_r1m3', '2017-06-21 18:57:36', '2017-06-21 18:59:32', 103578, 37),
(81, 'vanderson', ';vanderson_1498066508849_rio_bbnms_0070_20170613_000078_r1m3;vanderson_1498066508849_rio_bbnms_0070_20170613_000079_r1m3;vanderson_1498066508849_rio_bbnms_0070_20170613_000080_r1m3;vanderson_1498066508849_rio_bbnms_0070_20170613_000081_r1m3;vanderson_1498066508849_rio_bbnms_0070_20170613_000082_r1m3;vanderson_1498066508849_rio_bbnms_0070_20170613_000083_r1m3;vanderson_1498066508849_rio_bbnms_0070_20170613_000084_r1m3;vanderson_1498066508849_rio_bbnms_0070_20170613_000085_r1m3;vanderson_1498066508849_rio_bbnms_0070_20170613_000086_r1m3;vanderson_1498066508849_rio_bbnms_0070_20170613_000087_r1m3;vanderson_1498066508849_rio_bbnms_0070_20170613_000088_r1m3;vanderson_1498066508849_rio_bbnms_0070_20170613_000089_r1m3;vanderson_1498066508849_rio_bbnms_0070_20170613_000090_r1m3;vanderson_1498066508849_rio_bbnms_0070_20170613_000091_r1m3;vanderson_1498066508849_rio_bbnms_0070_20170613_000092_r1m3;vanderson_1498066508849_rio_bbnms_0070_20170613_000093_r1m3;vanderson_1498066508849_rio_bbnms_0070_20170613_000094_r1m3;vanderson_1498066508849_rio_bbnms_0070_20170613_000095_r1m3;vanderson_1498066508849_rio_bbnms_0070_20170613_000096_r1m3;vanderson_1498066508849_rio_bbnms_0070_20170613_000097_r1m3;vanderson_1498066508849_rio_bbnms_0070_20170613_000098_r1m3;vanderson_1498066508849_rio_bbnms_0070_20170613_000099_r1m3;vanderson_1498066508849_rio_bbnms_0070_20170613_000100_r1m3;vanderson_1498066508849_rio_bbnms_0070_20170613_000101_r1m3;vanderson_1498066508849_rio_bbnms_0070_20170613_000102_r1m3;vanderson_1498066508849_rio_bbnms_0070_20170613_000103_r1m3;vanderson_1498066508849_rio_bbnms_0070_20170613_000104_r1m3;vanderson_1498066508849_rio_bbnms_0070_20170613_000105_r1m3;vanderson_1498066508849_rio_bbnms_0070_20170613_000106_r1m3;vanderson_1498066508849_rio_bbnms_0070_20170613_000107_r1m3;vanderson_1498066508849_rio_bbnms_0070_20170613_000108_r1m3;vanderson_1498066508849_rio_bbnms_0070_20170613_000109_r1m3;vanderson_1498066508849_rio_bbnms_0070_20170613_000110_r1m3;vanderson_1498066508849_rio_bbnms_0070_20170613_000111_r1m3;vanderson_1498066508849_rio_bbnms_0070_20170613_000112_r1m3;vanderson_1498066508849_rio_bbnms_0070_20170613_000113_r1m3;vanderson_1498066508849_rio_bbnms_0070_20170613_000114_r1m3;vanderson_1498066508849_rio_bbnms_0070_20170613_000115_r1m3;vanderson_1498066508849_rio_bbnms_0070_20170613_000116_r1m3;vanderson_1498066508849_rio_bbnms_0070_20170613_000117_r1m3;vanderson_1498066508849_rio_bbnms_0070_20170613_000118_r1m3;vanderson_1498066508849_rio_bbnms_0070_20170613_000119_r1m3', '2017-06-21 18:57:36', '2017-06-21 18:59:35', 17706, 42),
(82, 'vanderson', ';vanderson_1498087068786_stms_cust_0020_20170517_000004_r1m3', '2017-06-21 20:19:18', '2017-06-21 20:19:20', 1, 62),
(83, 'vanderson', ';vanderson_1498087107974_stms_cust_0020_20170517_000004_r1m3', '2017-06-21 20:20:02', '2017-06-21 20:20:04', 1, 62),
(84, 'vanderson', ';vanderson_1498087132281_stms_cust_0020_20170517_000004_r1m3', '2017-06-21 20:20:31', '2017-06-21 20:20:34', 1, 62),
(85, 'vanderson', ';vanderson_1498087153192_stms_cust_0020_20170517_000004_r1m3', '2017-06-21 20:20:59', '2017-06-21 20:21:03', 1, 62),
(86, 'vanderson', '', '2017-06-21 20:23:21', '2017-06-21 20:23:22', 0, 0),
(87, 'vanderson', '', '2017-06-21 20:25:17', '2017-06-21 20:25:18', 0, 0),
(88, 'vanderson', '', '2017-06-21 20:26:31', '2017-06-21 20:26:31', 0, 0),
(89, 'vanderson', '', '2017-06-21 20:29:53', '2017-06-21 20:29:54', 0, 0),
(90, 'vanderson', '', '2017-06-21 20:30:18', '2017-06-21 20:30:19', 0, 0),
(91, 'vanderson', '', '2017-06-21 20:31:14', '2017-06-21 20:31:15', 0, 0),
(92, 'vanderson', '', '2017-06-21 20:32:42', '2017-06-21 20:32:43', 0, 0),
(93, 'vanderson', '', '2017-06-21 20:35:32', '2017-06-21 20:35:33', 0, 0),
(94, 'vanderson', '', '2017-06-21 20:36:09', '2017-06-21 20:36:10', 0, 0),
(95, 'vanderson', '', '2017-06-21 20:37:20', '2017-06-21 20:37:21', 0, 0),
(96, 'vanderson', '', '2017-06-21 20:37:59', '2017-06-21 20:38:00', 0, 0),
(97, 'vanderson', '', '2017-06-21 20:38:57', '2017-06-21 20:38:58', 0, 0),
(98, 'vanderson', '', '2017-06-21 20:39:19', '2017-06-21 20:39:20', 0, 0),
(99, 'vanderson', ';vanderson_1497988171342_rio_bbnms_0020_20170613_000001_r1m3;vanderson_1497988171342_rio_bbnms_0020_20170613_000002_r1m3;vanderson_1497988171342_rio_bbnms_0020_20170613_000003_r1m3;vanderson_1497988171342_rio_bbnms_0020_20170613_000004_r1m3;vanderson_1497988171342_rio_bbnms_0020_20170613_000005_r1m3;vanderson_1497988171342_rio_bbnms_0020_20170613_000006_r1m3;vanderson_1497988171342_rio_bbnms_0020_20170613_000007_r1m3;vanderson_1497988171342_rio_bbnms_0020_20170613_000008_r1m3;vanderson_1497988171342_rio_bbnms_0020_20170613_000009_r1m3;vanderson_1497988171342_rio_bbnms_0020_20170613_000010_r1m3;vanderson_1497988171342_rio_bbnms_0020_20170613_000011_r1m3;vanderson_1497988171342_rio_bbnms_0020_20170613_000012_r1m3;vanderson_1497988171342_rio_bbnms_0020_20170613_000013_r1m3;vanderson_1497988171342_rio_bbnms_0020_20170613_000014_r1m3;vanderson_1497988171342_rio_bbnms_0020_20170613_000015_r1m3;vanderson_1497988171342_rio_bbnms_0020_20170613_000016_r1m3;vanderson_1497988171342_rio_bbnms_0020_20170613_000017_r1m3;vanderson_1497988171342_rio_bbnms_0020_20170613_000018_r1m3;vanderson_1497988171342_rio_bbnms_0020_20170613_000019_r1m3;vanderson_1497988171342_rio_bbnms_0020_20170613_000020_r1m3', '2017-06-21 18:57:36', '2017-06-21 20:55:15', 99999, 599994),
(100, 'vanderson', ';vanderson_1497908891740_rio_cust_0040_20170612_000001_r1m3;vanderson_1497908891740_rio_cust_0040_20170612_000002_r1m3;vanderson_1497908891740_rio_cust_0040_20170612_000003_r1m3;vanderson_1497908891740_rio_cust_0040_20170612_000004_r1m3;vanderson_1497908891740_rio_cust_0040_20170612_000005_r1m3;vanderson_1497908891740_rio_cust_0040_20170612_000006_r1m3;vanderson_1497908891740_rio_cust_0040_20170612_000007_r1m3;vanderson_1497908891740_rio_cust_0040_20170612_000008_r1m3;vanderson_1497908891740_rio_cust_0040_20170612_000009_r1m3;vanderson_1497908891740_rio_cust_0040_20170612_000010_r1m3', '2017-06-21 18:57:36', '2017-06-21 20:57:19', 64363, 1418697),
(101, 'vanderson', ';vandeco_1498102368076_rio_cust_0040_20170509_000542_r2m1;vandeco_1498102368076_rio_cust_0040_20170509_000543_r2m1;vandeco_1498102368076_rio_cust_0040_20170509_000544_r2m1;vandeco_1498102368076_rio_cust_0040_20170509_000545_r2m1;vandeco_1498102368076_rio_cust_0040_20170509_000548_r2m1;vandeco_1498102368076_rio_cust_0040_20170509_000549_r2m1;vandeco_1498102368076_rio_cust_0040_20170509_000550_r2m1;vandeco_1498102368076_rio_cust_0040_20170509_000554_r2m1;vandeco_1498102368076_rio_cust_0040_20170509_000556_r2m1;vandeco_1498102368076_rio_cust_0040_20170509_000557_r2m1', '2017-06-22 00:36:45', '2017-06-22 00:39:07', 10000, 198598),
(102, 'vanderson', ';vandeco_1498105196295_rio_cust_0040_20170509_000542_r2m1;vandeco_1498105196295_rio_cust_0040_20170509_000543_r2m1;vandeco_1498105196295_rio_cust_0040_20170509_000544_r2m1;vandeco_1498105196295_rio_cust_0040_20170509_000545_r2m1;vandeco_1498105196295_rio_cust_0040_20170509_000548_r2m1;vandeco_1498105196295_rio_cust_0040_20170509_000549_r2m1;vandeco_1498105196295_rio_cust_0040_20170509_000550_r2m1;vandeco_1498105196295_rio_cust_0040_20170509_000554_r2m1;vandeco_1498105196295_rio_cust_0040_20170509_000556_r2m1;vandeco_1498105196295_rio_cust_0040_20170509_000557_r2m1', '2017-06-22 01:21:28', '2017-06-22 01:23:47', 10000, 198598),
(103, 'vanderson', ';vandeco_1498105645569_rio_cust_0040_20170509_000542_r2m1;vandeco_1498105645569_rio_cust_0040_20170509_000543_r2m1;vandeco_1498105645569_rio_cust_0040_20170509_000544_r2m1;vandeco_1498105645569_rio_cust_0040_20170509_000545_r2m1;vandeco_1498105645569_rio_cust_0040_20170509_000548_r2m1;vandeco_1498105645569_rio_cust_0040_20170509_000549_r2m1;vandeco_1498105645569_rio_cust_0040_20170509_000550_r2m1;vandeco_1498105645569_rio_cust_0040_20170509_000554_r2m1;vandeco_1498105645569_rio_cust_0040_20170509_000556_r2m1;vandeco_1498105645569_rio_cust_0040_20170509_000557_r2m1', '2017-06-22 01:30:08', '2017-06-22 01:32:33', 10000, 198598),
(104, 'vandeco', ';vandeco_1498110140130_rio_cust_0040_20170509_000542_r2m1', '2017-06-22 02:45:07', '2017-06-22 02:45:23', 1000, 19961),
(105, 'vandeco', ';vandeco_1498110381659_rio_cust_0040_20170509_000542_r2m1', '2017-06-22 02:47:05', '2017-06-22 02:47:21', 1000, 19961),
(106, 'vandeco', ';vandeco_1498110490369_rio_cust_0040_20170509_000542_r2m1', '2017-06-22 02:49:08', '2017-06-22 02:49:23', 1000, 19961),
(107, 'vandeco', ';vandeco_1498110903041_stms_udas_0160_20170322_000063_r2m1', '2017-06-22 02:56:37', '2017-06-22 03:22:44', 100698, 280605),
(108, 'Vanderson', ';vanderson_1498151223107_rio_cust_0040_20170509_000542_r2m1;vanderson_1498151223107_rio_cust_0040_20170509_000543_r2m1;vanderson_1498151223107_rio_cust_0040_20170509_000544_r2m1;vanderson_1498151223107_rio_cust_0040_20170509_000545_r2m1;vanderson_1498151223107_rio_cust_0040_20170509_000548_r2m1;vanderson_1498151223107_rio_cust_0040_20170509_000549_r2m1;vanderson_1498151223107_rio_cust_0040_20170509_000550_r2m1;vanderson_1498151223107_rio_cust_0040_20170509_000554_r2m1;vanderson_1498151223107_rio_cust_0040_20170509_000556_r2m1;vanderson_1498151223107_rio_cust_0040_20170509_000557_r2m1', '2017-06-22 14:10:45', '2017-06-22 14:13:10', 10000, 198598),
(109, 'vandeco', ';vandeco_1498152513370_rio_cust_0040_20170509_000542_r2m1;vandeco_1498152513370_rio_cust_0040_20170509_000543_r2m1;vandeco_1498152513370_rio_cust_0040_20170509_000544_r2m1;vandeco_1498152513370_rio_cust_0040_20170509_000545_r2m1;vandeco_1498152513370_rio_cust_0040_20170509_000548_r2m1;vandeco_1498152513370_rio_cust_0040_20170509_000549_r2m1;vandeco_1498152513370_rio_cust_0040_20170509_000550_r2m1;vandeco_1498152513370_rio_cust_0040_20170509_000554_r2m1;vandeco_1498152513370_rio_cust_0040_20170509_000556_r2m1;vandeco_1498152513370_rio_cust_0040_20170509_000557_r2m1', '2017-06-22 14:30:53', '2017-06-22 14:33:08', 10000, 198598),
(110, 'Vanderson', ';vanderson_1498155900522_rio_cust_0040_20170509_000542_r2m1', '2017-06-22 15:26:03', '2017-06-22 15:26:26', 1000, 19961),
(111, 'Vanderson', ';vanderson_1498155932716_rio_cust_0040_20170509_000542_r2m1', '2017-06-22 15:26:42', '2017-06-22 15:26:58', 1000, 19961),
(112, 'Vanderson', ';vanderson_1498156307132_rio_cust_0040_20170509_000542_r2m1', '2017-06-22 15:34:00', '2017-06-22 15:34:17', 1000, 19961),
(113, 'Vanderson', ';vanderson_1498156363037_rio_cust_0040_20170509_000542_r2m1', '2017-06-22 15:35:06', '2017-06-22 15:35:21', 1000, 19961),
(114, 'Vanderson', ';vanderson_1498157253257_rio_cust_0040_20170509_000542_r2m1', '2017-06-22 15:50:06', '2017-06-22 15:50:21', 1000, 19961),
(115, 'Vanderson', ';vanderson_1498160077265_rio_cust_0040_20170509_000542_r2m1', '2017-06-22 16:36:17', '2017-06-22 16:36:17', 1000, 1),
(116, 'Vanderson', ';vanderson_1498160135500_rio_cust_0040_20170509_000542_r2m1', '2017-06-22 16:37:20', '2017-06-22 16:37:20', 1000, 1),
(117, 'Vanderson', ';vanderson_1498160209491_rio_cust_0040_20170509_000542_r2m1', '2017-06-22 16:38:38', '2017-06-22 16:38:38', 1000, 1),
(118, 'Vanderson', ';vanderson_1498160315513_rio_cust_0040_20170509_000542_r2m1', '2017-06-23 14:34:31', '2017-06-23 14:34:32', 1000, 1),
(119, 'Vanderson', ';vanderson_1498160498440_rio_cust_0040_20170509_000542_r2m1', '2017-06-23 14:34:31', '2017-06-23 14:34:32', 1000, 1),
(120, 'Vanderson', ';vanderson_1498160444629_rio_cust_0040_20170509_000542_r2m1', '2017-06-23 14:34:31', '2017-06-23 14:34:32', 1000, 1),
(121, 'Vanderson', ';vanderson_1498160872695_rio_cust_0040_20170509_000542_r2m1', '2017-06-23 14:34:31', '2017-06-23 14:34:32', 1000, 1),
(122, 'Vanderson', ';vanderson_1498160663812_rio_cust_0040_20170509_000542_r2m1', '2017-06-23 14:34:31', '2017-06-23 14:34:32', 1000, 1),
(123, 'Vanderson', ';vanderson_1498160853952_rio_cust_0040_20170509_000542_r2m1', '2017-06-23 14:34:31', '2017-06-23 14:34:32', 1000, 1),
(124, 'Vanderson', ';vanderson_1498160387251_rio_cust_0040_20170509_000542_r2m1', '2017-06-23 14:34:31', '2017-06-23 14:34:32', 1000, 1),
(125, 'Vanderson', ';vanderson_1498160525266_rio_cust_0040_20170509_000542_r2m1', '2017-06-23 14:34:31', '2017-06-23 14:34:33', 1000, 1),
(126, 'Vanderson', ';vanderson_1498655765569_rio_cust_0040_20170509_000542_r2m1', '2017-06-28 10:18:46', '2017-06-28 10:18:46', 1000, 1),
(127, 'Vanderson', ';vanderson_1498655780171_rio_cust_0040_20170509_000542_r2m1', '2017-06-28 10:19:02', '2017-06-28 10:19:12', 1000, 6148),
(128, 'Vanderson', ';vanderson_1498655795150_rio_cust_0040_20170509_000542_r2m1', '2017-06-28 10:19:20', '2017-06-28 10:19:32', 1000, 6148),
(129, 'Vanderson', ';vanderson_1498655841996_rio_cust_0040_20170509_000542_r2m1', '2017-06-28 10:20:09', '2017-06-28 10:20:21', 1000, 9148),
(130, 'Vanderson', '', '2017-06-28 10:22:57', '2017-06-28 10:22:57', 0, 0),
(131, 'Vanderson', '', '2017-06-28 10:23:07', '2017-06-28 10:23:07', 0, 0),
(132, 'Vanderson', '', '2017-06-28 10:23:16', '2017-06-28 10:23:16', 0, 0),
(133, 'Vanderson', '', '2017-06-28 10:23:28', '2017-06-28 10:23:28', 0, 0),
(134, 'Vanderson', ';vanderson_1498656049480_rio_cust_0040_20170509_000542_r2m1', '2017-06-28 10:23:55', '2017-06-28 10:24:08', 1000, 9148),
(135, 'Vanderson', ';vanderson_1498657481220_rio_cust_0040_20170509_000542_r2m1', '2017-06-28 10:51:22', '2017-06-28 10:51:22', 1000, 1),
(136, 'Vanderson', ';vanderson_1498657291966_rio_cust_0040_20170509_000542_r2m1', '2017-06-28 10:51:22', '2017-06-28 10:51:41', 1000, 9148),
(137, 'Vanderson', ';vanderson_1498657612417_rio_cust_0040_20170509_000542_r2m1', '2017-06-28 10:51:22', '2017-06-28 10:51:43', 1000, 6150),
(138, 'Vanderson', '', '2017-06-28 11:02:50', '2017-06-28 11:02:50', 0, 0),
(139, 'Vanderson', ';vanderson_1498658629422_rio_cust_0040_20170509_000542_r2m1', '2017-06-28 11:04:52', '2017-06-28 11:05:02', 1000, 6332),
(140, 'Vanderson', ';vanderson_1498659267208_rio_cust_0040_20170509_000542_r2m1', '2017-06-28 11:16:23', '2017-06-28 11:16:35', 1000, 6332),
(141, 'Vanderson', ';vanderson_1498659585790_rio_cust_0040_20170509_000542_r2m1', '2017-06-28 11:22:09', '2017-06-28 11:22:17', 1000, 0),
(142, 'Vanderson', ';vanderson_1498659693933_rio_cust_0040_20170509_000542_r2m1', '2017-06-28 11:22:26', '2017-06-28 11:22:35', 1000, 0),
(143, 'Vanderson', ';vanderson_1498659895265_rio_cust_0040_20170509_000542_r2m1', '2017-06-28 11:26:04', '2017-06-28 11:26:14', 1000, 1),
(144, 'Vanderson', ';vanderson_1498659986491_rio_cust_0040_20170509_000542_r2m1;vanderson_1498659986491_rio_cust_0040_20170509_000543_r2m1', '2017-06-28 11:27:46', '2017-06-28 11:28:03', 2000, 2);
INSERT INTO `audit` (`id`, `owner`, `files`, `start_time`, `end_time`, `rows_count`, `defects_found`) VALUES
(145, 'Vanderson', ';vanderson_1498660007608_rio_cust_0040_20170509_000542_r2m1;vanderson_1498660007608_rio_cust_0040_20170509_000543_r2m1', '2017-06-28 11:28:11', '2017-06-28 11:28:30', 2000, 2),
(146, 'Vanderson', ';vanderson_1498660143469_rio_cust_0040_20170509_000542_r2m1;vanderson_1498660143469_rio_cust_0040_20170509_000543_r2m1', '2017-06-28 11:30:35', '2017-06-28 11:30:52', 2000, 0),
(147, 'Vanderson', ';vanderson_1498660208368_rio_cust_0040_20170509_000542_r2m1;vanderson_1498660208368_rio_cust_0040_20170509_000543_r2m1', '2017-06-28 11:31:44', '2017-06-28 11:32:00', 2000, 0),
(148, 'Vanderson', ';vanderson_1498660317644_rio_cust_0040_20170509_000542_r2m1;vanderson_1498660317644_rio_cust_0040_20170509_000543_r2m1', '2017-06-28 11:33:42', '2017-06-28 11:34:00', 2000, 0),
(149, 'Vanderson', ';vanderson_1498660331518_rio_cust_0040_20170509_000542_r2m1;vanderson_1498660331518_rio_cust_0040_20170509_000543_r2m1', '2017-06-28 11:33:56', '2017-06-28 11:34:24', 2000, 0),
(150, 'Vanderson', ';vanderson_1498660369951_rio_cust_0040_20170509_000542_r2m1;vanderson_1498660369951_rio_cust_0040_20170509_000543_r2m1', '2017-06-28 11:34:42', '2017-06-28 11:34:58', 2000, 2),
(151, 'Vanderson', ';vanderson_1498660531519_rio_cust_0040_20170509_000542_r2m1;vanderson_1498660531519_rio_cust_0040_20170509_000543_r2m1', '2017-06-28 11:36:19', '2017-06-28 11:36:37', 2000, 2),
(152, 'Vanderson', ';vanderson_1498661134091_rio_cust_0040_20170509_000542_r2m1;vanderson_1498661134091_rio_cust_0040_20170509_000543_r2m1', '2017-06-28 11:49:01', '2017-06-28 11:49:20', 2000, 2),
(153, 'Vanderson', ';vanderson_1498665458775_rio_cust_0040_20170509_000542_r2m1;vanderson_1498665458775_rio_cust_0040_20170509_000543_r2m1', '2017-06-28 12:59:15', '2017-06-28 12:59:43', 2000, 2),
(154, 'Vanderson', ';vanderson_1498665674548_rio_cust_0040_20170509_000542_r2m1;vanderson_1498665674548_rio_cust_0040_20170509_000543_r2m1', '2017-06-28 13:02:08', '2017-06-28 13:02:28', 2000, 2),
(155, 'Vanderson', ';vanderson_1498666215718_rio_cust_0040_20170509_000542_r2m1;vanderson_1498666215718_rio_cust_0040_20170509_000543_r2m1', '2017-06-28 13:12:35', '2017-06-28 13:12:58', 2000, 2),
(156, 'Vanderson', ';vanderson_1498665863729_rio_cust_0040_20170509_000542_r2m1;vanderson_1498665863729_rio_cust_0040_20170509_000543_r2m1', '2017-06-28 13:12:35', '2017-06-28 13:12:58', 2000, 2),
(157, 'Vanderson', ';vanderson_1498667658680_rio_cust_0040_20170509_000542_r2m1;vanderson_1498667658680_rio_cust_0040_20170509_000543_r2m1', '2017-06-28 13:35:26', '2017-06-28 13:35:43', 2000, 2),
(158, 'Vanderson', ';vanderson_1498667805998_rio_cust_0040_20170509_000542_r2m1;vanderson_1498667805998_rio_cust_0040_20170509_000543_r2m1', '2017-06-28 13:38:43', '2017-06-28 13:39:04', 2000, 3),
(159, 'Vanderson', ';vanderson_1498668242452_rio_cust_0040_20170509_000542_r2m1;vanderson_1498668242452_rio_cust_0040_20170509_000543_r2m1', '2017-06-28 13:44:49', '2017-06-28 13:45:10', 2000, 3),
(160, 'Vanderson', ';vanderson_1498668341315_rio_cust_0040_20170509_000542_r2m1;vanderson_1498668341315_rio_cust_0040_20170509_000543_r2m1', '2017-06-28 13:46:49', '2017-06-28 13:47:12', 2000, 3),
(161, 'Vanderson', ';vanderson_1498668939706_rio_cust_0040_20170509_000542_r2m1;vanderson_1498668939706_rio_cust_0040_20170509_000543_r2m1', '2017-06-28 15:57:03', '2017-06-28 15:57:49', 2000, 39830),
(162, 'Vanderson', ';vanderson_1498676137979_rio_cust_0040_20170509_000542_r2m1;vanderson_1498676137979_rio_cust_0040_20170509_000543_r2m1', '2017-06-28 15:57:09', '2017-06-28 15:57:57', 2000, 39829),
(163, 'Vanderson', ';vanderson_1498677018833_rio_cust_0040_20170509_000542_r2m1;vanderson_1498677018833_rio_cust_0040_20170509_000543_r2m1', '2017-06-28 16:12:36', '2017-06-28 16:13:14', 2000, 39829),
(164, 'Vanderson', ';vanderson_1498677852674_rio_cust_0040_20170509_000542_r2m1;vanderson_1498677852674_rio_cust_0040_20170509_000543_r2m1', '2017-06-28 16:28:33', '2017-06-28 16:28:49', 2000, 2),
(165, 'Vanderson', ';vanderson_1498677958733_rio_cust_0040_20170509_000542_r2m1;vanderson_1498677958733_rio_cust_0040_20170509_000543_r2m1', '2017-06-28 16:30:37', '2017-06-28 16:31:03', 2000, 39829),
(166, 'Vanderson', ';vanderson_1498679506456_rio_cust_0040_20170509_000542_r2m1;vanderson_1498679506456_rio_cust_0040_20170509_000543_r2m1', '2017-06-28 17:10:38', '2017-06-28 17:11:02', 2000, 45630),
(167, 'Vanderson', ';vanderson_1498680608008_rio_cust_0040_20170509_000542_r2m1', '2017-06-28 17:14:21', '2017-06-28 17:14:29', 1000, 1),
(168, 'Vanderson', ';vanderson_1498680629078_rio_cust_0040_20170509_000542_r2m1', '2017-06-28 17:14:42', '2017-06-28 17:14:50', 1000, 1),
(169, 'Vanderson', ';vanderson_1498680756367_rio_cust_0040_20170509_000542_r2m1', '2017-06-28 17:16:52', '2017-06-28 17:16:52', 1000, 1),
(170, 'Vanderson', ';vanderson_1498680809629_rio_cust_0040_20170509_000542_r2m1', '2017-06-28 17:17:47', '2017-06-28 17:17:47', 1000, 1),
(171, 'Vanderson', ';vanderson_1498680847507_rio_cust_0040_20170509_000542_r2m1', '2017-06-28 17:18:26', '2017-06-28 17:18:26', 1000, 1),
(172, 'Vanderson', ';vanderson_1498680902705_rio_cust_0040_20170509_000542_r2m1', '2017-06-28 17:19:22', '2017-06-28 17:19:22', 1000, 1),
(173, 'Vanderson', ';vanderson_1498680914568_rio_cust_0040_20170509_000542_r2m1', '2017-06-28 17:19:34', '2017-06-28 17:19:34', 1000, 1),
(174, 'Vanderson', ';vanderson_1498680984765_rio_cust_0040_20170509_000542_r2m1', '2017-06-28 17:20:45', '2017-06-28 17:20:45', 1000, 1),
(175, 'Vanderson', ';vanderson_1498681051833_rio_cust_0040_20170509_000542_r2m1', '2017-06-28 17:21:55', '2017-06-28 17:22:04', 1000, 1),
(176, 'Vanderson', ';vanderson_1498681133163_rio_cust_0040_20170509_000542_r2m1', '2017-06-28 17:23:18', '2017-06-28 17:23:29', 1000, 1001),
(177, 'Vanderson', ';vanderson_1498681298952_rio_cust_0040_20170509_000542_r2m1', '2017-06-28 17:26:08', '2017-06-28 17:26:17', 1000, 1004),
(178, 'Vanderson', ';vanderson_1498682051298_rio_cust_0040_20170509_000542_r2m1', '2017-06-28 17:34:52', '2017-06-28 17:35:03', 1000, 1985),
(179, 'Vanderson', ';vanderson_1498682250450_rio_cust_0040_20170509_000542_r2m1', '2017-06-28 17:38:17', '2017-06-28 17:38:27', 1000, 1985),
(180, 'Vanderson', ';vanderson_1498682384012_rio_cust_0040_20170509_000542_r2m1', '2017-06-28 17:40:33', '2017-06-28 17:40:42', 1000, 1004),
(181, 'Vanderson', ';vanderson_1498682491280_rio_cust_0040_20170509_000542_r2m1', '2017-06-28 17:42:23', '2017-06-28 17:42:34', 1000, 1006),
(182, 'Vanderson', ';vanderson_1498682695692_rio_cust_0040_20170509_000542_r2m1', '2017-06-28 17:45:51', '2017-06-28 17:46:00', 1000, 1005),
(183, 'Vanderson', ';vanderson_1498682901563_rio_cust_0040_20170509_000542_r2m1', '2017-06-28 17:49:21', '2017-06-28 17:49:30', 1000, 1005),
(184, 'Vanderson', ';vanderson_1498683171868_rio_cust_0040_20170509_000542_r2m1', '2017-06-28 17:53:58', '2017-06-28 17:54:09', 1000, 2005),
(185, 'Vanderson', ';vanderson_1498683314483_rio_cust_0040_20170509_000542_r2m1', '2017-06-28 17:56:23', '2017-06-28 17:56:34', 1000, 2005),
(186, 'Vanderson', ';vanderson_1498683546695_rio_cust_0040_20170509_000542_r2m1', '2017-06-28 18:00:21', '2017-06-28 18:00:31', 1000, 2005),
(187, 'Vanderson', ';vanderson_1498683680203_rio_cust_0040_20170509_000542_r2m1', '2017-06-28 18:02:40', '2017-06-28 18:02:50', 1000, 2005),
(188, 'Vanderson', ';vanderson_1498745794219_rio_cust_0040_20170509_000542_r2m1', '2017-06-29 11:20:51', '2017-06-29 11:21:01', 1000, 2005),
(189, 'Vanderson', ';vanderson_1498745947775_rio_cust_0040_20170509_000542_r2m1', '2017-06-29 11:23:47', '2017-06-29 11:23:58', 1000, 1986),
(190, 'Vanderson', ';vanderson_1498746130958_rio_cust_0040_20170509_000542_r2m1', '2017-06-29 11:27:16', '2017-06-29 11:27:26', 1000, 1986),
(191, 'Vanderson', ';vanderson_1498746194383_rio_cust_0040_20170509_000542_r2m1', '2017-06-29 11:28:25', '2017-06-29 11:28:35', 1000, 1986),
(192, 'Vanderson', ';vanderson_1498746650737_rio_cust_0040_20170509_000542_r2m1', '2017-06-29 11:36:48', '2017-06-29 11:36:59', 1000, 1986),
(193, 'Vanderson', ';vanderson_1498746872743_rio_cust_0040_20170509_000542_r2m1', '2017-06-29 11:40:50', '2017-06-29 11:41:01', 1000, 1006),
(194, 'Vanderson', ';vanderson_1498747079967_rio_cust_0040_20170509_000542_r2m1', '2017-06-29 11:44:37', '2017-06-29 11:44:47', 1000, 1007),
(195, 'Vanderson', ';vanderson_1498747097170_rio_cust_0040_20170509_000542_r2m1', '2017-06-29 11:44:57', '2017-06-29 11:45:06', 1000, 1007),
(196, 'Vanderson', ';vanderson_1498747529728_rio_cust_0040_20170509_000542_r2m1;vanderson_1498747529728_rio_cust_0040_20170509_000543_r2m1', '2017-06-29 11:46:20', '2017-06-29 11:46:40', 2000, 2008),
(197, 'Vanderson', ';vanderson_1498747728123_rio_cust_0040_20170509_000542_r2m1', '2017-06-29 11:49:30', '2017-06-29 11:49:40', 1000, 1008),
(198, 'Vanderson', ';vanderson_1498747842504_rio_cust_0040_20170509_000542_r2m1', '2017-06-29 11:51:36', '2017-06-29 11:51:46', 1000, 1009),
(199, 'Vanderson', ';vanderson_1498751673785_rio_cust_0040_20170509_000542_r2m1', '2017-06-29 12:55:48', '2017-06-29 12:55:57', 1000, 9),
(200, 'Vanderson', ';vanderson_1498751969527_rio_cust_0040_20170509_000542_r2m1', '2017-06-29 13:01:07', '2017-06-29 13:01:20', 1000, 10),
(201, 'Vanderson', ';vanderson_1498752002951_rio_cust_0040_20170509_000542_r2m1', '2017-06-29 13:01:45', '2017-06-29 13:01:54', 1000, 10),
(202, 'Vanderson', ';vanderson_1498752143520_rio_cust_0040_20170509_000542_r2m1', '2017-06-29 13:04:15', '2017-06-29 13:04:25', 1000, 9),
(203, 'Vanderson', ';vanderson_1498752332438_rio_cust_0040_20170509_000542_r2m1', '2017-06-29 13:06:20', '2017-06-29 13:06:28', 1000, 9),
(204, 'Vanderson', ';vanderson_1498758017360_rio_cust_0040_20170509_000542_r2m1;vanderson_1498758017360_rio_cust_0040_20170509_000543_r2m1;vanderson_1498758017360_rio_cust_0040_20170509_000544_r2m1;vanderson_1498758017360_rio_cust_0040_20170509_000545_r2m1;vanderson_1498758017360_rio_cust_0040_20170509_000548_r2m1;vanderson_1498758017360_rio_cust_0040_20170509_000549_r2m1;vanderson_1498758017360_rio_cust_0040_20170509_000550_r2m1;vanderson_1498758017360_rio_cust_0040_20170509_000554_r2m1;vanderson_1498758017360_rio_cust_0040_20170509_000556_r2m1;vanderson_1498758017360_rio_cust_0040_20170509_000557_r2m1', '2017-06-29 14:43:23', '2017-06-29 14:44:54', 10000, 10),
(205, 'Vanderson', ';vanderson_1498759865277_rio_cust_0040_20170509_000542_r2m1', '2017-06-29 15:12:03', '2017-06-29 15:12:12', 1000, 9),
(206, 'Vanderson', ';vanderson_1498760042575_rio_cust_0040_20170509_000542_r2m1;vanderson_1498760042575_rio_cust_0040_20170509_000544_r2m1;vanderson_1498760042575_rio_cust_0040_20170509_000545_r2m1;vanderson_1498760042575_rio_cust_0040_20170509_000548_r2m1', '2017-06-29 15:15:32', '2017-06-29 15:16:08', 4000, 9),
(207, 'Vanderson', ';vanderson_1498760143720_rio_cust_0040_20170509_000542_r2m1;vanderson_1498760143720_rio_cust_0040_20170509_000544_r2m1;vanderson_1498760143720_rio_cust_0040_20170509_000545_r2m1;vanderson_1498760143720_rio_cust_0040_20170509_000548_r2m1;vanderson_1498760143720_rio_cust_0040_20170509_000554_r2m1;vanderson_1498760143720_rio_cust_0040_20170509_000556_r2m1;vanderson_1498760143720_rio_cust_0040_20170509_000557_r2m1', '2017-06-29 15:17:35', '2017-06-29 15:18:36', 7000, 9),
(208, 'rkaiber', ';rkaiber_1498760811873_stms_cust_0010_20170517_000001_r1m3;rkaiber_1498760811873_stms_cust_0010_20170517_000002_r1m3;rkaiber_1498760811873_stms_cust_0010_20170517_000003_r1m3', '2017-06-29 15:28:14', '2017-06-29 15:28:14', 35006, 3),
(209, 'Vanderson', ';vanderson_1498760748670_rio_cust_0040_20170509_000542_r2m1;vanderson_1498760748670_rio_cust_0040_20170509_000543_r2m1;vanderson_1498760748670_rio_cust_0040_20170509_000544_r2m1;vanderson_1498760748670_rio_cust_0040_20170509_000545_r2m1;vanderson_1498760748670_rio_cust_0040_20170509_000548_r2m1;vanderson_1498760748670_rio_cust_0040_20170509_000549_r2m1;vanderson_1498760748670_rio_cust_0040_20170509_000550_r2m1;vanderson_1498760748670_rio_cust_0040_20170509_000554_r2m1;vanderson_1498760748670_rio_cust_0040_20170509_000556_r2m1;vanderson_1498760748670_rio_cust_0040_20170509_000557_r2m1', '2017-06-29 15:27:33', '2017-06-29 15:29:11', 10000, 10),
(210, 'Vanderson', ';vanderson_1498765606744_stms_cust_0010_20170517_000001_r1m3', '2017-06-29 16:48:30', '2017-06-29 16:50:16', 12094, 33079),
(211, 'rkaiber', ';rkaiber_1498766171913_stms_cust_0010_20170517_000001_r1m3;rkaiber_1498766171913_stms_cust_0010_20170517_000002_r1m3;rkaiber_1498766171913_stms_cust_0010_20170517_000003_r1m3', '2017-06-29 16:57:26', '2017-06-29 17:03:40', 35006, 81271),
(212, 'rkaiber', ';rkaiber_1498766835258_stms_cust_0030_20170517_000001_r1m3;rkaiber_1498766835258_stms_cust_0030_20170517_000002_r1m3', '2017-06-29 17:08:34', '2017-06-29 17:14:14', 32822, 0),
(213, 'Willian', ';willian_1498767650219_bbnms_0010_20170622_000001_r1m3_1', '2017-06-29 17:21:25', '2017-06-29 17:21:25', 10, 20),
(214, 'terminator', ';terminator_1499175374050_rio_cust_0040_20170612_000001_r1m3;terminator_1499175374050_rio_cust_0040_20170612_000002_r1m3;terminator_1499175374050_rio_cust_0040_20170612_000003_r1m3;terminator_1499175374050_rio_cust_0040_20170612_000004_r1m3;terminator_1499175374050_rio_cust_0040_20170612_000005_r1m3;terminator_1499175374050_rio_cust_0040_20170612_000006_r1m3;terminator_1499175374050_rio_cust_0040_20170612_000007_r1m3;terminator_1499175374050_rio_cust_0040_20170612_000008_r1m3;terminator_1499175374050_rio_cust_0040_20170612_000009_r1m3;terminator_1499175374050_rio_cust_0040_20170612_000010_r1m3;terminator_1499175374050_rio_cust_0040_20170612_000011_r1m3;terminator_1499175374050_rio_cust_0040_20170612_000012_r1m3', '2017-07-04 10:38:27', '2017-07-04 10:56:38', 76504, 306487),
(215, 'Vanderson', ';vanderson_1499799714804_rio_cust_0040_20170509_000542_r2m1', '2017-07-11 16:07:17', '2017-07-11 16:07:29', 1000, 3002),
(216, 'vanderson', ';vanderson_1499801346380_rio_cust_0040_20170509_000542_r2m1;vanderson_1499801346380_rio_cust_0040_20170509_000543_r2m1;vanderson_1499801346380_rio_cust_0040_20170509_000544_r2m1', '2017-07-11 16:30:27', '2017-07-11 16:31:00', 3000, 9002),
(217, 'Vanderson', ';vanderson_1500488531272_rio_cust_0040_20170509_000542_r2m1', '2017-07-19 15:23:18', '2017-07-19 15:23:18', 1000, 1),
(218, 'rkaiber', ';rkaiber_1500488693509_stms_cust_0010_20170517_000005_r1m3;rkaiber_1500488693509_stms_cust_0010_20170517_000006_r1m3', '2017-07-19 15:25:51', '2017-07-19 15:25:51', 22894, 2),
(219, 'Vanderson', ';vanderson_1500489386278_rio_cust_0040_20170509_000542_r2m1', '2017-07-19 15:37:59', '2017-07-19 15:37:59', 1000, 1),
(220, 'Vanderson', '', '2017-07-20 18:56:50', '2017-07-20 18:56:50', 0, 0),
(221, 'rkaiber', ';rkaiber_1500648828623_stms_cust_0010_20170517_000001_r1m3', '2017-07-21 11:54:42', '2017-07-21 11:54:42', 12094, 1),
(222, 'rkaiber', ';rkaiber_1500654236694_stms_cust_0010_20170517_000001_r1m3;rkaiber_1500654236694_stms_cust_0010_20170517_000002_r1m3', '2017-07-21 13:25:07', '2017-07-21 13:25:07', 23638, 2);

-- --------------------------------------------------------

--
-- Estrutura da tabela `loginattempts`
--

CREATE TABLE `loginattempts` (
  `IP` varchar(20) NOT NULL,
  `Attempts` int(11) NOT NULL,
  `LastLogin` datetime NOT NULL,
  `Username` varchar(65) DEFAULT NULL,
  `ID` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Extraindo dados da tabela `loginattempts`
--

INSERT INTO `loginattempts` (`IP`, `Attempts`, `LastLogin`, `Username`, `ID`) VALUES
('9.80.233.72', 2, '2017-06-16 03:05:16', 'testeste', 1),
('9.80.233.72', 2, '2017-06-16 03:06:55', 'Vanderson', 2),
('9.85.202.146', 1, '2017-06-16 15:32:57', 'Vanderson', 3),
('9.85.156.160', 1, '2017-06-16 16:40:25', 'Vanderson', 4),
('9.18.203.6', 1, '2017-06-16 16:40:27', 'rkaiber', 5),
('9.78.146.197', 1, '2017-06-16 16:40:34', 'Willian', 6),
('9.78.147.111', 1, '2017-06-16 16:40:45', 'mzlim', 7),
('9.78.144.43', 2, '2017-06-16 20:10:51', 'terminator', 8),
('9.78.139.34', 1, '2017-06-16 22:10:44', 'mzlim', 9),
('9.80.198.135', 1, '2017-06-16 22:22:21', 'Vanderson', 10),
('9.18.253.140', 1, '2017-06-19 15:37:05', 'Willian', 11),
('9.7.39.131', 1, '2017-06-19 16:25:42', 'rkaiber', 12),
('9.8.8.151', 1, '2017-06-20 18:18:07', 'Willian', 13),
('9.8.9.117', 1, '2017-06-20 20:21:02', 'terminator', 14),
('9.85.131.37', 1, '2017-06-20 20:29:34', 'Vanderson', 15),
('9.78.141.131', 1, '2017-06-21 16:01:50', 'terminator', 16),
('9.85.166.79', 2, '2017-06-21 23:53:20', 'vandeco', 17),
('9.85.166.79', 1, '2017-06-22 02:49:11', 'Vanderson', 18),
('9.7.42.194', 1, '2017-06-29 16:09:29', 'Vanderson', 19),
('9.18.197.207', 1, '2017-06-29 20:24:47', 'rkaiber', 20),
('9.8.15.112', 1, '2017-06-29 22:18:18', 'Willian', 21),
('9.78.132.33', 1, '2017-07-04 15:05:21', 'terminator', 22),
('9.8.13.6', 1, '2017-07-04 16:30:09', 'Willian', 23),
('9.78.138.219', 1, '2017-07-11 20:33:58', 'Willian', 24),
('9.85.181.114', 4, '2017-07-11 21:00:02', 'Vanderson', 26),
('9.18.199.46', 1, '2017-07-11 21:49:14', 'rkaiber', 27),
('9.80.216.198', 1, '2017-07-19 20:14:09', 'Vanderson', 28),
('9.7.38.214', 2, '2017-07-19 20:14:33', 'rk5536', 29),
('9.7.38.214', 1, '2017-07-19 20:21:55', 'rkaiber', 30),
('9.80.234.191', 1, '2017-07-20 23:55:38', 'Vanderson', 32),
('9.78.141.169', 1, '2017-07-25 21:02:57', 'rkaiber', 33);

-- --------------------------------------------------------

--
-- Estrutura da tabela `members`
--

CREATE TABLE `members` (
  `id` char(23) NOT NULL,
  `username` varchar(65) NOT NULL DEFAULT '',
  `password` varchar(65) NOT NULL DEFAULT '',
  `email` varchar(65) NOT NULL,
  `verified` tinyint(1) NOT NULL DEFAULT '0',
  `mod_timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Extraindo dados da tabela `members`
--

INSERT INTO `members` (`id`, `username`, `password`, `email`, `verified`, `mod_timestamp`) VALUES
('1061071915943eda3ed40d', 'mzlim', '$2y$10$FnPgDdASWnk954HdN8hvoOiZiloBCUanWGgCqaTSGrQ5mi9AkCTWe', 'mroland@br.ibm.com', 1, '2017-06-16 14:39:49'),
('11551420955943ed79654c2', 'rkaiber', '$2y$10$.O29RxzEL1HzUQlHWCGqWuej9R5Cr1dH53ltcqkw4y7tPrxK25g5a', 'rkaiber@br.ibm.com', 1, '2017-06-16 14:39:38'),
('1385953848594411ac211a7', 'terminator', '$2y$10$1CM0X6YpJUbvhHHdBtU4YOuWl3H4LPw5nplWRBxZPbFUegxh9oJP6', 'mgavrons@br.ibm.com', 1, '2017-06-16 18:03:03'),
('149773005943ed7d9cdda', 'Willian', '$2y$10$6B9KxeSc.8V2XX16jK/B.uvEEZziFxuRJ5J60S8dol5sTb3ZZDAJq', 'wrs@br.ibm.com', 1, '2017-06-16 14:40:02'),
('16741290594aea0394f34', 'Vandeco', '$2y$10$nkEFiLDnsIhpvCauHYpjj.J4loMh5PJbUnZcWXj1q0VQO9ip8SvFK', 'vandersom@br.ibm.com', 1, '2017-06-21 21:54:19'),
('1880837321596520647bf07', 'Vanderson', '$2y$10$p85J8ZtIzfEC/ROp85KSWOEogBzpzUdbTfWrw6hAaI2gwcesnRKpq', 'vfsousa@br.ibm.com', 1, '2017-07-11 19:01:08'),
('1888155662595b92b1671ea', 'chitrpan', '$2y$10$jPRTwCKwENfEAA0JEBzjBejDePudkDuTpZ2T9HMGe6to9cfozSaB2', 'chitrpan@in.ibm.com', 1, '2017-07-04 15:15:29'),
('205462167159705c3b96743', 'chitra.pandey2007', '$2y$10$E7nvqE8vTYPR6zf0PH.2zOEF.c/FBgaJ2UDsZfv/.sgceb6Dh.SMe', 'chitra.pandey2007@gmail.com', 0, '2017-07-20 07:31:07');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `audit`
--
ALTER TABLE `audit`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `loginattempts`
--
ALTER TABLE `loginattempts`
  ADD PRIMARY KEY (`ID`);

--
-- Indexes for table `members`
--
ALTER TABLE `members`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `username_UNIQUE` (`username`),
  ADD UNIQUE KEY `id_UNIQUE` (`id`),
  ADD UNIQUE KEY `email_UNIQUE` (`email`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `audit`
--
ALTER TABLE `audit`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=223;
--
-- AUTO_INCREMENT for table `loginattempts`
--
ALTER TABLE `loginattempts`
  MODIFY `ID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=34;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
