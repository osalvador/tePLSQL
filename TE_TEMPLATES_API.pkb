CREATE OR REPLACE
PACKAGE BODY te_templates_api
AS

  -- This cursor processes an XML Document into columns for the TE_TEMPLATES table.
  CURSOR  extractTemplates( p_xml in XMLType )
  IS
    SELECT xt.*
    FROM XMLTABLE( '/teplsql/templates/template'
                    PASSING p_xml
                    COLUMNS
                        "NAME"        VARCHAR2( 500 ) PATH '/template/NAME'
                      , "TEMPLATE"    CLOB            PATH '/template/TEMPLATE'
                      , "DESCRIPTION" varchar2( 500 ) PATH '/template/DESCRIPTION'
                      , CREATED_BY    VARCHAR2( 500 ) PATH '/template/CREATED_BY'
                      , CREATED_DATE  DATE            PATH '/template/CREATED_DATE'
                      , MODIFIED_BY   VARCHAR2( 500 ) PATH '/template/MODIFIED_BY'
                      , MODIFIED_DATE DATE            PATH '/template/MODIFIED_DATE'
                    ) xt;
              
  TYPE extracttemplates_t IS TABLE OF extracttemplates%rowtype;

  PROCEDURE import_error (
                            p_xml IN XMLTYPE
                          )
  AS
    l_buffer    extracttemplates_t;
    l_counter   INT := 0;
  BEGIN
    OPEN extracttemplates( p_xml );
    
    WHILE ( l_counter < 10 )
    LOOP
      l_counter   := l_counter + 1;
      
      FETCH extracttemplates BULK COLLECT INTO l_buffer LIMIT 500;
      
      FORALL i IN 1..l_buffer.count
        INSERT INTO te_templates (
            "NAME"
          , template
          , description
          , created_by
          , created_date
          , modified_by
          , modified_date
        ) VALUES (
            l_buffer( i )."NAME"
          , l_buffer( i ).template
          , l_buffer( i ).description
          , l_buffer( i ).created_by
          , l_buffer( i ).created_date
          , l_buffer( i ).modified_by
          , l_buffer( i ).modified_date
        );

      EXIT WHEN extracttemplates%notfound;
    END LOOP;

    IF extracttemplates%isopen
    THEN
      CLOSE extracttemplates;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      IF  extracttemplates%isopen
      THEN
        CLOSE extracttemplates;
      END IF;
      RAISE;
  END;
  
  PROCEDURE import_overwrite_ignore (
                                      p_xml          IN XMLTYPE
                                    , p_duplicates   IN options_t DEFAULT g_import_default
                                    )
  AS
    l_buffer   extracttemplates_t;
  BEGIN
    OPEN extracttemplates( p_xml );
    
    WHILE ( 1 = 1 )
    LOOP
      FETCH extracttemplates BULK COLLECT INTO l_buffer LIMIT 500;
      
      FORALL i IN 1..l_buffer.count
        MERGE INTO te_templates old USING (
          SELECT l_buffer( i )."NAME" "NAME"
               , l_buffer( i ).template template
               , l_buffer( i ).description description
               , l_buffer( i ).created_by created_by
               , l_buffer( i ).created_date created_date
               , l_buffer( i ).modified_by modified_by
               , l_buffer( i ).modified_date modified_date
          FROM dual
        ) new
        ON ( old."NAME" = new."NAME" )
        WHEN MATCHED THEN UPDATE SET old.template      = new.template
                                   , old.description   = new.description
                                   , old.created_by    = new.created_by
                                   , old.modified_by   = new.modified_by
                                   , old.modified_date = new.modified_date
        WHERE   p_duplicates = g_import_overwrite
        WHEN NOT MATCHED THEN INSERT (
                                          name
                                        , template
                                        , description
                                        , created_by
                                        , created_date
                                        , modified_by
                                        , modified_date
                                      ) VALUES (
                                          new.name
                                        , new.template
                                        , new.description
                                        , new.created_by
                                        , new.created_date
                                        , new.modified_by
                                        , new.modified_date )
        WHERE p_duplicates IN ( g_import_overwrite, g_import_ignore );

      EXIT WHEN extracttemplates%notfound;
    END LOOP;

    IF extracttemplates%isopen
    THEN
      CLOSE extracttemplates;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      IF extracttemplates%isopen
      THEN
        CLOSE extracttemplates;
      END IF;
      RAISE;
  END;
  
  PROCEDURE xml_import( p_xml IN XMLType
                      , p_duplicates IN options_t DEFAULT g_import_default
                      )
  AS
  BEGIN
    CASE p_duplicates
      WHEN g_import_error     THEN import_error( p_xml );
      WHEN g_import_ignore    THEN import_overwrite_ignore( p_xml, p_duplicates );
      WHEN g_import_overwrite THEN import_overwrite_ignore( p_xml, p_duplicates );
      ELSE RAISE invalid_option;
    END CASE;
  END;
  
  FUNCTION xml_export (
                        p_search_value   IN VARCHAR2 DEFAULT NULL
                      , p_search_type    IN options_t DEFAULT g_export_default
                    ) RETURN XMLTYPE
  IS
    l_buffer         xmltype;
    l_search_name    varchar2(4000);
    l_search_like    varchar2(4000);
    l_search_regexp  varchar2(4000);
  BEGIN
  
    CASE p_search_type
      WHEN g_export_exact THEN
        l_search_name   := p_search_value;
      WHEN g_export_like THEN
        l_search_like   := p_search_value;
      WHEN g_export_regexp THEN
        l_search_regexp   := p_search_value;
      WHEN g_export_dot THEN
        l_search_regexp   := p_search_value;
      ELSE
        RAISE invalid_option;
    END CASE;
    
    WITH data AS (
      SELECT
        XMLELEMENT(  "teplsql"
          , XMLELEMENT(  "templates"
            , XMLAGG(
                XMLELEMENT( "template"
                          , XMLFOREST( t."NAME"
                                    , t."TEMPLATE"
                                    , t.description
                                    , t.created_by
                                    , t.created_date
                                    , t.modified_by
                                    , t.modified_date
                                    )
                          )
                    )
                )
        ) xmldoc
      FROM te_templates t
      WHERE
           upper( t.name ) = upper( l_search_name )
        OR upper( t.name ) LIKE upper( l_search_like )
        OR REGEXP_LIKE( t.name, l_search_regexp )
    )
    SELECT xmldoc
    INTO l_buffer
    FROM  data;

    RETURN l_buffer;
  END;

  FUNCTION filebrowse_as_clob (
                                p_filename IN VARCHAR2
                              )
  RETURN CLOB AS

    l_blob           BLOB;
    l_clob           CLOB;
    l_dest_offsset   INTEGER := 1;
    l_src_offsset    INTEGER := 1;
    l_lang_context   INTEGER := dbms_lob.default_lang_ctx;
    l_warning        INTEGER;
  BEGIN
    SELECT blob_content
    INTO l_blob
--    from wwv_flow_files -- APEX 4.2
    FROM apex_application_temp_files -- APEX 5.0+
    WHERE
      name = p_filename;

    dbms_lob.createtemporary(
                              lob_loc   => l_clob
                            , cache     => false
                            );

    dbms_lob.converttoclob(
                            dest_lob       => l_clob
                          , src_blob       => l_blob
                          , amount         => dbms_lob.lobmaxsize
                          , dest_offset    => l_dest_offsset
                          , src_offset     => l_src_offsset
                          , blob_csid      => dbms_lob.default_csid
                          , lang_context   => l_lang_context
                          , warning        => l_warning
                          );

    RETURN l_clob;
  END;
  
  PROCEDURE apex_import (
                          p_filename     IN VARCHAR2
                        , p_duplicates   IN options_t DEFAULT g_import_default
                        )
  AS
    l_clob   CLOB;
    l_xml    XMLTYPE;
  BEGIN
    apex_debug.message( 'TE_TEMPLATES_API: Importing file "%s" with option "%s"', p_filename, p_duplicates );
 
    l_clob   := filebrowse_as_clob( p_filename );
    
    l_xml    := xmltype( l_clob );
    
    apex_debug.message( 'TE_TEMPLATES_API: Asserting XML "%s..."', substr( l_xml.getCLOBVal(), 1, 50 ) );
    assert_xml( l_xml );
    
    xml_import( l_xml, p_duplicates );
    apex_debug.message( 'TE_TEMPLATES_API: done' );
  END;
  
  PROCEDURE assert_xml (
                         p_xml IN XMLTYPE
                       )
  AS
  BEGIN
    IF p_xml IS NULL
    THEN
      RAISE invalid_teplsql_xml;
    END IF;
  END;
  
  FUNCTION import_options_lov( p_lang IN VARCHAR2 DEFAULT 'EN' ) RETURN lov_nt PIPELINED
  AS
    l_lang    VARCHAR2(2);
    l_buffer  lov_t;
  BEGIN
    l_lang := nvl( substr( p_lang,1,2) , 'EN' );

    CASE l_lang
      WHEN 'EN' then
        l_buffer.option_value := g_import_overwrite;  l_buffer.option_desc := 'Overwrite Matches';
        pipe row ( l_buffer );
        l_buffer.option_value := g_import_ignore;     l_buffer.option_desc := 'Skip Matches';
        pipe row ( l_buffer );
        l_buffer.option_value := g_import_error;      l_buffer.option_desc := 'Throw Error on Match';
        pipe row ( l_buffer );
      ELSE
        RAISE invalid_option;
    END CASE;
  
    RETURN;
  END;
  
  FUNCTION export_options_lov( p_lang IN VARCHAR2 DEFAULT 'EN' ) RETURN lov_nt PIPELINED
  AS
    l_lang    VARCHAR2(2);
    l_buffer  lov_t;
  BEGIN
    l_lang := nvl( substr( p_lang,1,2) , 'EN' );

    CASE l_lang
      WHEN 'EN' THEN
        l_buffer.option_value := g_export_exact;   l_buffer.option_desc := 'Case Insensitive Exact Match';
        pipe row ( l_buffer );
        l_buffer.option_value := g_export_like;    l_buffer.option_desc := 'Case Insenstive Oracle LIKE';
        pipe row ( l_buffer );
        l_buffer.option_value := g_export_regexp;  l_buffer.option_desc := 'Case Sensitive Regular Expression';
        pipe row ( l_buffer );
      ELSE
        RAISE invalid_option;
    END CASE;

    RETURN;
  END;

  PROCEDURE file_import (
                          p_oradir       IN VARCHAR2
                        , p_filename     IN VARCHAR2
                        , p_duplicates   IN options_t DEFAULT g_import_default
                        )
  AS

    l_clob           CLOB;
    l_dest_offset    INT := 1;
    l_src_offset     INT := 1;
    l_src_csid       NUMBER := nls_charset_id( 'US7ASCII' );
    l_lang_context   INTEGER := dbms_lob.default_lang_ctx;
    l_warning        INTEGER;
    l_bfile          BFILE;
    l_xml            XMLTYPE;
  BEGIN
    l_bfile   := bfilename( p_oradir, p_filename );

    dbms_lob.open( l_bfile, dbms_lob.lob_readonly  );

    dbms_lob.createtemporary( l_clob, true );

    sys.dbms_lob.loadclobfromfile(
                                    l_clob
                                  , l_bfile
                                  , dbms_lob.lobmaxsize
                                  , l_dest_offset
                                  , l_src_offset
                                  , l_src_csid
                                  , l_lang_context
                                  , l_warning
                                  );

    dbms_lob.close( l_bfile );

    l_xml     := xmltype( l_clob );

    assert_xml( l_xml );

    xml_import( l_xml, p_duplicates );
  EXCEPTION
    WHEN OTHERS THEN
      dbms_lob.close( l_bfile );
      RAISE;
  END;
  
  PROCEDURE file_export (
                            p_oradir         IN VARCHAR2
                          , p_filename       IN VARCHAR2
                          , p_search_value   IN VARCHAR2 DEFAULT NULL
                          , p_search_type    IN options_t DEFAULT g_export_default
                        )
  AS
    l_xml     XMLTYPE;
    l_file    utl_file.file_type;
    l_clob    CLOB;
    l_buffer  VARCHAR2( 32767 );
    l_amount  BINARY_INTEGER := 32767;
    l_pos     INTEGER := 1;
  BEGIN
    --get XML
    l_xml := xml_export( p_search_value, p_search_type );

    -- format CLOB
$IF false $THEN
    -- 10g does not support XMLSerialze( indent size = 2 )
    l_clob := l_xml.getCLOBVal();
$ELSE
      -- all other versions of Oracle
    SELECT
      XMLSERIALIZE( DOCUMENT xml_export(
                                        p_search_value
                                      , p_search_type
                                      ) AS CLOB
                    INDENT SIZE = 2 )
    INTO l_clob
    FROM  dual;
$END
      
      -- open file handle
      
    l_file := UTL_FILE.fopen(p_oradir, p_filename, 'w', 32767);
  
    LOOP
      DBMS_LOB.read (l_clob, l_amount, l_pos, l_buffer);
      UTL_FILE.put(l_file, l_buffer);
      l_pos := l_pos + l_amount;
    END LOOP;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      -- Expected end.
      UTL_FILE.fclose(l_file);
    WHEN OTHERS THEN
      UTL_FILE.fclose(l_file);
      RAISE;
  END;

  PROCEDURE apex_export (
                          p_filename       IN VARCHAR2
                        , p_search_value   IN VARCHAR2
                        , p_search_type    IN VARCHAR2
                        )
  AS
    l_xml    XMLTYPE;
    l_clob   CLOB;
  BEGIN
      --get CLOB
$IF false $THEN
    apex_debug.message( 'TE_TEMPLATES_API: using 10g EXPORT method' );
    -- 10g does not support XMLSerialze( indent size = 2 )
    l_xml    := xml_export( p_search_value, p_search_type );
    l_clob   := l_xml.getclobval ();
$ELSE
    apex_debug.message( 'TE_TEMPLATES_API: using 11g+ EXPORT method' );
    -- all other versions of Oracle
    SELECT XMLSerialize( document  xml_export( p_search_value, p_search_type ) as CLOB indent size = 2)
      INTO l_clob
    FROM dual;
$END
    IF dbms_lob.getlength( l_clob ) < 5 OR l_clob IS NULL
    THEN
      apex_debug.message( 'XML CLOB is too small (or NULL) to be real' );
      RAISE no_data_found;
    END IF;
      
    -- set up HTTP header
    owa_util.mime_header( 'text/xml', false
    );
 
    -- set the size so the browser knows how much to download
    htp.p( 'Content-length: ' || dbms_lob.getlength( l_clob ) );
    
    -- the filename will be used by the browser if the users does a save as
    htp.p( 'Content-Disposition:  attachment; filename="' || replace(  replace(
                                                              substr( p_filename, instr( p_filename, '/' ) + 1 )
                                                            , chr( 10 ), NULL  ) , chr( 13 ) , NULL) || '"' );
    -- close the headers            
    owa_util.http_header_close;

    -- download the BLOB
    wpg_docload.download_file( l_clob );      
                
    -- stop APEX engine
    apex_application.stop_apex_engine;
  EXCEPTION
    WHEN no_data_found THEN
      apex_debug.message( 'NO_DATA_FOUND was raised.' );
      htp.p( 'No matching templates found' );
      apex_application.stop_apex_engine;
  END;

$if false $then
<%@ template( template_name=DefaultHelperTemplates.xml ) %>
<teplsql>
  <templates>
    <template>
      <NAME>teplsql.skeleton.default.function.name</NAME>
      <TEMPLATE>${object_name}</TEMPLATE>
      <DESCRIPTION>Name of the Function/Procedure</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-08-15</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-08-15</MODIFIED_DATE>
    </template>
    <template>
      <NAME>teplsql.skeleton.default.function.bdy</NAME>
      <TEMPLATE>     return NULL;
</TEMPLATE>
      <DESCRIPTION>The body of the code</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-08-15</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-08-15</MODIFIED_DATE>
    </template>
    <template>
      <NAME>teplsql.skeleton.default.function.decl</NAME>
      <TEMPLATE>-- set variables here</TEMPLATE>
      <DESCRIPTION>variable/type/function/cursor definitions go her</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-08-15</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-08-15</MODIFIED_DATE>
    </template>
    <template>
      <NAME>teplsql.skeleton.default.function.spec</NAME>
      <TEMPLATE>function &lt;%@ include( ${this}.name ) %&gt; return varchar2</TEMPLATE>
      <DESCRIPTION>shortline specification for function/procedure</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-08-15</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-08-15</MODIFIED_DATE>
    </template>
    <template>
      <NAME>teplsql.skeleton.default.package.name</NAME>
      <TEMPLATE>${object_name}</TEMPLATE>
      <DESCRIPTION>Name of the Function/Procedure</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-08-15</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-08-15</MODIFIED_DATE>
    </template>
    <template>
      <NAME>teplsql.skeleton.default.package.body</NAME>
      <TEMPLATE>CREATE OR REPLACE
PACKAGE BODY ${schema}.&lt;%@ include( ${this}.name ) %&gt;\\n
AS
&lt;%@ include( ${this}.function.%.body ) %&gt;\\n
END;
&lt;%= &apos;/&apos; %&gt;\\n</TEMPLATE>
      <DESCRIPTION>code to generate the BODY of the package</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-08-15</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-08-15</MODIFIED_DATE>
    </template>
    <template>
      <NAME>teplsql.skeleton.default.package.specification</NAME>
      <TEMPLATE>CREATE OR REPLACE
PACKAGE ${schema}.&lt;%@ include( ${this}.name ) %&gt;\\n
AS
&lt;%@ include( ${this}.documentation ) %&gt;

&lt;%@ include( ${this}.type.%.specification ) %&gt;\\n

&lt;%@ include( ${this}.exception.%.specification ) %&gt;\\n

&lt;%@ include( ${this}.function.%.specification ) %&gt;\\n
END;
&lt;%= &apos;/&apos; %&gt;</TEMPLATE>
      <DESCRIPTION>code to generate the specification</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-08-15</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-08-15</MODIFIED_DATE>
    </template>
    <template>
      <NAME>teplsql.skeleton.default.SQL.view_name</NAME>
      <TEMPLATE>${schema}.&lt;%@ include( ${this}.name ) %&gt;</TEMPLATE>
      <DESCRIPTION>View name of SQL</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-08-15</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-08-15</MODIFIED_DATE>
    </template>
    <template>
      <NAME>teplsql.skeleton.default.SQL.cursor_name</NAME>
      <TEMPLATE>c_&lt;%@ include( ${this}.name ) %&gt;</TEMPLATE>
      <DESCRIPTION>Name of cursor version of SQL</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-08-15</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-08-15</MODIFIED_DATE>
    </template>
    <template>
      <NAME>teplsql.skeleton.default.SQL.SQL</NAME>
      <TEMPLATE>select * from dual</TEMPLATE>
      <DESCRIPTION>The actual SQL statement</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-08-15</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-08-15</MODIFIED_DATE>
    </template>
    <template>
      <NAME>teplsql.skeleton.default.SQL.name</NAME>
      <TEMPLATE>${object_name}</TEMPLATE>
      <DESCRIPTION>Name of SQL statement</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-08-15</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-08-15</MODIFIED_DATE>
    </template>
    <template>
      <NAME>teplsql.skeleton.default.exception.number</NAME>
      <TEMPLATE>-20000</TEMPLATE>
      <DESCRIPTION>Exception Number</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-08-15</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-08-15</MODIFIED_DATE>
    </template>
    <template>
      <NAME>teplsql.skeleton.default.exception.text</NAME>
      <TEMPLATE>&apos;Something went wrong&apos;</TEMPLATE>
      <DESCRIPTION>Text displayed for a RAISE_APPLICATION_EXCEPTION.
(in PL/SQL code format)</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-08-15</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-08-15</MODIFIED_DATE>
    </template>
    <template>
      <NAME>teplsql.skeleton.default.exception.name</NAME>
      <TEMPLATE>${object_name}</TEMPLATE>
      <DESCRIPTION>name of the exception</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-08-15</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-08-15</MODIFIED_DATE>
    </template>
    <template>
      <NAME>teplsql.skeleton.default.exception.raise_error</NAME>
      <TEMPLATE>raise_application_error( &lt;%@ include( ${this}.number) %&gt;, &lt;%@ include( ${this}.text ) %&gt; );</TEMPLATE>
      <DESCRIPTION>PL/Sql code that runs inside an EXCEPTION block</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-08-15</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-08-15</MODIFIED_DATE>
    </template>
    <template>
      <NAME>teplsql.skeleton.default.type.rcd_spec</NAME>
      <TEMPLATE>SUBTYPE &lt;%@ include( ${this}.rcd_name ) %&gt; ${schema}.${table_name}%ROWTYPE;</TEMPLATE>
      <DESCRIPTION>specification for RECORD TYPE.</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-08-15</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-08-15</MODIFIED_DATE>
    </template>
    <template>
      <NAME>teplsql.skeleton.default.type.nt_name</NAME>
      <TEMPLATE>&lt;%@ include( ${this}.base_name) %&gt;_nt</TEMPLATE>
      <DESCRIPTION>creates the name for the Nested Table TYPE.</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-08-15</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-08-15</MODIFIED_DATE>
    </template>
    <template>
      <NAME>teplsql.skeleton.default.type.rcd_name</NAME>
      <TEMPLATE>&lt;%@ include( ${this}.base_name ) %&gt;_rcd</TEMPLATE>
      <DESCRIPTION>Creates the name for the RECORD TYPE</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-08-15</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-08-15</MODIFIED_DATE>
    </template>
    <template>
      <NAME>teplsql.skeleton.default.type.aa_name</NAME>
      <TEMPLATE>&lt;%@ include( ${this}.base_name) %&gt;_aa</TEMPLATE>
      <DESCRIPTION>Name of the Associative Array TYPE</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-08-15</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-08-15</MODIFIED_DATE>
    </template>
    <template>
      <NAME>teplsql.skeleton.default.type.base_name</NAME>
      <TEMPLATE>${table_name}</TEMPLATE>
      <DESCRIPTION>common name for all related types</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-08-15</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-08-15</MODIFIED_DATE>
    </template>
    <template>
      <NAME>teplsql.skeleton.default.build.main</NAME>
      <TEMPLATE>&lt;%!
  cursor &quot;Columns&quot;( p_schema in varchar2, p_table_name in varchar2 ) is
      select *
      from all_tab_cols
      where owner=p_schema and table_name=p_table_name;
%&gt;

/*
  Building for ${this}

  Time       : &lt;%= systimestamp %&gt;\\n
  Schema     : ${schema}
  Table Name : ${table_name}
*/

-- simple make all
&lt;%@ include( ${this}%.make ) %&gt;</TEMPLATE>
      <DESCRIPTION>top-level Build</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-08-15</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-08-15</MODIFIED_DATE>
    </template>
    <template>
      <NAME>teplsql.skeleton.default.SQL.documentation</NAME>
      <TEMPLATE>/**
  SQL &lt;%@ include( ${this}.name ) %&gt;

*/</TEMPLATE>
      <DESCRIPTION>Documentation for the SQL in PL/doc format</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-08-15</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-08-15</MODIFIED_DATE>
    </template>
    <template>
      <NAME>teplsql.skeleton.default.exception.documentation</NAME>
      <TEMPLATE>/**
  Something didn&apos;t do what it was suppose to
*/</TEMPLATE>
      <DESCRIPTION>Documentation of the exception in PL/Doc format</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-08-15</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-08-15</MODIFIED_DATE>
    </template>
    <template>
      <NAME>teplsql.skeleton.default.function.documentation</NAME>
      <TEMPLATE>/**
  Function &lt;%@ include( ${this}.name ) %&gt;
*/</TEMPLATE>
      <DESCRIPTION>PL/Doc encoded documentation</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-08-15</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-08-15</MODIFIED_DATE>
    </template>
    <template>
      <NAME>teplsql.skeleton.default.package.documentation</NAME>
      <TEMPLATE>/**
      Place Description of Package here
@headcom
*/
</TEMPLATE>
      <DESCRIPTION>PL/Doc encoded documentation</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-08-15</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-08-15</MODIFIED_DATE>
    </template>
    <template>
      <NAME>teplsql.skeleton.default.function.body</NAME>
      <TEMPLATE>&lt;%@ include( ${this}.spec ) %&gt;\\n
AS
&lt;%@ include( ${this}.decl ) %&gt;\\n
BEGIN
&lt;%@ include( ${this}.bdy ) %&gt;\\n
END &lt;%@ include( ${this}.name ) %&gt;;\\n</TEMPLATE>
      <DESCRIPTION>Body of the function for a Package</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-08-15</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-08-15</MODIFIED_DATE>
    </template>
    <template>
      <NAME>teplsql.skeleton.default.function.specification</NAME>
      <TEMPLATE>&lt;%@ include( ${this}.documentation ) %&gt;\\n
&lt;%@ include( ${this}.spec ) %&gt;;</TEMPLATE>
      <DESCRIPTION>Specification of the function for a Package</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-08-15</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-08-15</MODIFIED_DATE>
    </template>
    <template>
      <NAME>teplsql.skeleton.default.package.make</NAME>
      <TEMPLATE>&lt;%@ include( ${this}.specification ) %&gt;

&lt;%@ include( ${this}.body ) %&gt;</TEMPLATE>
      <DESCRIPTION>makes both specification followed by the body</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-08-15</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-08-15</MODIFIED_DATE>
    </template>
    <template>
      <NAME>teplsql.skeleton.default.package.init</NAME>
      <TEMPLATE>  BEGIN
    NULL;
  end;

</TEMPLATE>
      <DESCRIPTION>Initialization code for the package</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-08-15</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-08-15</MODIFIED_DATE>
    </template>
    <template>
      <NAME>teplsql.skeleton.default.SQL.make_view</NAME>
      <TEMPLATE>create or replace
view &lt;%@ include( ${this}.view_name )%&gt;\\n
as
&lt;%@ include( ${this}.SQL )%&gt;
;</TEMPLATE>
      <DESCRIPTION>creates the VIEW</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-08-15</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-08-15</MODIFIED_DATE>
    </template>
    <template>
      <NAME>teplsql.skeleton.default.exception.specification</NAME>
      <TEMPLATE>&lt;%@ include( ${this}.name ) %&gt;  exception;
&lt;%@ include( ${this}.constant_number_name ) %&gt; constant int := &lt;%@ include( ${this}.number ) %&gt;;
&lt;%@ include( ${this}.constant_text_name ) %&gt; constant varchar2(4000) := &apos;&lt;%@ include( ${this}.name ) %&gt;&apos;;
pragma exception_init( &lt;%@ include( ${this}.name ) %&gt;, &lt;%@ include( ${this}.constant_number_name ) %&gt; );</TEMPLATE>
      <DESCRIPTION>specification for all parts of an exception.</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-08-15</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-08-15</MODIFIED_DATE>
    </template>
    <template>
      <NAME>teplsql.skeleton.default.exception.constant_text_name</NAME>
      <TEMPLATE>g_&lt;%@ include( ${this}.name ) %&gt;_txt</TEMPLATE>
      <DESCRIPTION>constant that hold the exception name as a varchar</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-08-15</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-08-15</MODIFIED_DATE>
    </template>
    <template>
      <NAME>teplsql.skeleton.default.exception.constant_number_name</NAME>
      <TEMPLATE>g_&lt;%@ include( ${this}.name ) %&gt;#</TEMPLATE>
      <DESCRIPTION>name of the constant that holds the error number.</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-08-15</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-08-15</MODIFIED_DATE>
    </template>
    <template>
      <NAME>teplsql.skeleton.default.exception.exception</NAME>
      <TEMPLATE>when &lt;%@ include( ${this}.name ) %&gt; then
    &lt;%@ include( ${this}.plsql ) %&gt;</TEMPLATE>
      <DESCRIPTION>Exception where clause for this exception.</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-08-15</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-08-15</MODIFIED_DATE>
    </template>
    <template>
      <NAME>teplsql.skeleton.default.type.specification</NAME>
      <TEMPLATE>&lt;%@ include( ${this}.documentation ) %&gt;\\n
&lt;%@ include( ${this}.rcd_spec ) %&gt;\\n
&lt;%@ include( ${this}.nt_spec ) %&gt;\\n
&lt;%@ include( ${this}.aa_spec ) %&gt;\\n</TEMPLATE>
      <DESCRIPTION>Creates the specification for a record, nested tab</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-08-15</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-08-15</MODIFIED_DATE>
    </template>
    <template>
      <NAME>teplsql.skeleton.default.type.aa_spec</NAME>
      <TEMPLATE>TYPE &lt;%@ include( ${this}.aa_name ) %&gt; is table of &lt;%@ include( ${this}.rcd_name ) %&gt; index by pls_integer;</TEMPLATE>
      <DESCRIPTION>Creates the Associative Array TYPE</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-08-15</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-08-15</MODIFIED_DATE>
    </template>
    <template>
      <NAME>teplsql.skeleton.default.type.nt_spec</NAME>
      <TEMPLATE>TYPE &lt;%@ include( ${this}.nt_name ) %&gt; is table of &lt;%@ include( ${this}.rcd_name ) %&gt;;</TEMPLATE>
      <DESCRIPTION>specification for the Nested Table TYPE</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-08-15</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-08-15</MODIFIED_DATE>
    </template>
    <template>
      <NAME>teplsql.skeleton.default.type.documentation</NAME>
      <TEMPLATE>/*
  Description of this type
*/</TEMPLATE>
      <DESCRIPTION>PL/Doc style comments</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-08-15</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-08-15</MODIFIED_DATE>
    </template>
    <template>
      <NAME>teplsql.skeleton.default.function</NAME>
      <TEMPLATE>CREATE OR REPLACE
&lt;%= &apos;&lt;&apos; %&gt;%@ include( ${pfname}.spec ) %&lt;%= &apos;&gt;&apos; %&gt;&lt;%= &apos;\&apos; || &apos;\&apos; || &apos;n&apos; %&gt;
AS
&lt;%= &apos;&lt;&apos; %&gt;%@ include( ${pfname}.decl ) %&lt;%= &apos;&gt;&apos; %&gt;&lt;%= &apos;\&apos; || &apos;\&apos; || &apos;n&apos; %&gt;
BEGIN
&lt;%= &apos;&lt;&apos; %&gt;%@ include( ${pfname}.bdy ) %&lt;%= &apos;&gt;&apos; %&gt;&lt;%= &apos;\&apos; || &apos;\&apos; || &apos;n&apos; %&gt;
END;
&lt;%= &apos;&lt;&apos; %&gt;%= &apos;/&apos; %&lt;%= &apos;&gt;&apos; %&gt;&lt;%= &apos;\&apos; || &apos;\&apos; || &apos;n&apos; %&gt;</TEMPLATE>
      <DESCRIPTION>Template for a Standalone function</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-08-15</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-08-15</MODIFIED_DATE>
    </template>
  </templates>
</teplsql>

$end
END;
/