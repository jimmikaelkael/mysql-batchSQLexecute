DELIMITER $$

/*
 * This routine execute some SQL statements passed as parameter
 * params:
 *  - sqlStatements(MEDIUMTEXT): the text containing all the SQL to execute
 *  - delimiter(VARCHAR 255)   : the delimiter string between the SQL statements
 *  - autocommit(INT)          : set wether auto-commit mode is used or not (0/1)
 *
 * The goal of this routine is too clearly improve the execution speed
 * on several statements when you use MySQL Connector for example:
 *  - instead of sending a request for each INSERT or UPDATE or anything else,
 * you can build a string containing all the statements to execute and call
 * this procedure to batch execute it on the remote server, thus gaining a lot
 * of time in execution. Everyone knows how Connector is slow with INSERT like
 * commands...
 * To speed up things even more, you can set autocommit to 0.
 *
 * Example of use: CALL batchSQLexecute('INSERT INTO myTable (val) VALUES(123); INSERT INTO myTable (val) VALUES(456);', ';', 0);
 *
 * Signed-off-by: Michael Jimenez <jimmikaelkael@wanadoo.fr>
 */

DROP PROCEDURE IF EXISTS `batchSQLexecute`$$
CREATE PROCEDURE `batchSQLexecute`(sqlStatements MEDIUMTEXT, delimiter VARCHAR(255), autocommit INT)
BEGIN
  DECLARE done INT DEFAULT 0;
  DECLARE pos INT DEFAULT 0;
  DECLARE delimiterLen INT;

  SET delimiterLen = LENGTH(delimiter);

  IF autocommit = 0 THEN
    SET AUTOCOMMIT = 0;
  END IF;

  REPEAT
    SET pos = INSTR(sqlStatements, delimiter);
    IF pos = 0 THEN
      SET @req = sqlStatements;
      SET done = 1;
    ELSE
      SET @req = SUBSTRING_INDEX(sqlStatements, delimiter, 1);
      SET sqlStatements = SUBSTRING(sqlStatements, pos+delimiterLen, LENGTH(sqlStatements) - pos+delimiterLen);
    END IF;

    IF LENGTH(@req) > 0 THEN
      PREPARE stmt1 FROM @req;
      EXECUTE stmt1;
      DEALLOCATE PREPARE stmt1;
    END IF;
  UNTIL done END REPEAT;

  IF autocommit = 0 THEN
    COMMIT;
  END IF;
END$$

DELIMITER ;

