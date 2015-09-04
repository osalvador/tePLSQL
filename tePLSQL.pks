/* Formatted on 03/09/2015 17:28:24 (QP5 v5.115.810.9015) */
CREATE OR REPLACE PACKAGE teplsql
AS
   --Define Associative Array
   TYPE t_assoc_array
   IS
      TABLE OF VARCHAR2 (32767)
         INDEX BY VARCHAR2 (255);

   --Print procedures, print data into tePLSQL Buffer.
   PROCEDURE PRINT (p_data IN CLOB);

   PROCEDURE p (p_data IN CLOB);

   PROCEDURE PRINT (p_data IN VARCHAR2);

   PROCEDURE p (p_data IN VARCHAR2);

   PROCEDURE PRINT (p_data IN NUMBER);

   PROCEDURE p (p_data IN NUMBER);

   --Render function.
   FUNCTION render (p_template IN CLOB, p_vars IN t_assoc_array)
      RETURN CLOB;
END teplsql;
/