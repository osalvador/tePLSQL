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
END;
