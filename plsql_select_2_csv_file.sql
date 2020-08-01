create or replace procedure select_2_csv_file(
    query_string     VARCHAR2,
    file_name        VARCHAR2 default 'GENERATE_CSV_FILE.csv',
    dir_name         VARCHAR2 default 'FTFER',
    seperator        VARCHAR2 default ',',
    wrap_string      VARCHAR2 default '"',
    include_headers  BOOLEAN  default true) as

    i                INTEGER := 0;
    
    l_file_handle      utl_file.file_type;
    l_the_cursor       INTEGER DEFAULT dbms_sql.open_cursor;
    l_column_value     VARCHAR2(2000);
    l_column_output    VARCHAR2(32000);
    l_status           INTEGER;
    l_column_count     NUMBER DEFAULT 0;
    l_separator        VARCHAR2(10) DEFAULT '~';
    l_line_count        NUMBER DEFAULT 0;
    l_column_desciption        dbms_sql.desc_tab;

    PROCEDURE remove_file (
        file_name_p   VARCHAR2,
        dir_name_p    VARCHAR2
    ) AS
    BEGIN
        utl_file.fremove(dir_name_p, file_name_p);
    EXCEPTION
        WHEN OTHERS THEN
            NULL;
    END;

BEGIN
    -- Parse the SQL query and describe column information
    dbms_sql.parse(l_the_cursor, query_string, dbms_sql.v7);
    dbms_sql.describe_columns(l_the_cursor, l_column_count, l_column_desciption);
    
    -- Execust the cursor
    l_status := dbms_sql.execute(l_the_cursor);
    
     FOR i IN 1..l_column_count
     LOOP
        dbms_sql.define_column(l_the_cursor, i, l_column_value, 2000);
     END LOOP;
    
    -- Remove existing file if it exists
    remove_file(file_name, dir_name);

    -- Open a new file for writing.     
    l_file_handle := utl_file.fopen(dir_name, file_name, 'W');
    
    if include_headers then
        -- Generate heading line
        l_separator := '';
        FOR i IN 1..l_column_count LOOP
            if l_column_desciption(i).col_type in (1,2,12,96) then
                l_column_output := l_column_output
                                  || l_separator
                                  || '"'
                                  || upper(l_column_desciption(i).col_name)
                                  || '"';
                l_separator := seperator;
            end if;
        END LOOP;

        -- Output header line to file
        utl_file.put_line(l_file_handle, l_column_output, true);
    end if;
    
    -- output CSV line 
    /*
    
        The column type table for determining how to output the information.
    
    VARCHAR2        1   
    NVARCHAR2       1   
    NUMBER          2   
    INTEGER         2   
    DATE            12  
    CHAR            96  
    NCHAR           96  
    CLOB            112 
    NCLOB           112 
    BLOB            113 
    BFILE           114 
    */
    l_column_output := '';
    LOOP
        EXIT WHEN ( dbms_sql.fetch_rows(l_the_cursor) <= 0 );
        l_separator := '';
        FOR i IN 1..l_column_count LOOP
            dbms_sql.column_value(l_the_cursor, i, l_column_value);
            IF l_column_desciption(i).col_type IN (
                1,
                96
            ) THEN
                l_column_output := l_column_output
                                  || l_separator
                                  || wrap_string
                                  || trim(BOTH '"' FROM l_column_value)
                                  || wrap_string;

            ELSIF l_column_desciption(i).col_type IN (
                2
            ) THEN
                l_column_output := l_column_output
                                  || l_separator
                                  || l_column_value;
            ELSIF l_column_desciption(i).col_type = 12 THEN
                l_column_output := l_column_output
                                  || l_separator
                                  || l_column_value;
            ELSE
                dbms_output.put_line('Skipping unsupported column type: '||to_char(l_column_desciption(i).col_type)||
                    l_column_desciption(i).col_name);
            END IF;

            l_separator := seperator;
        END LOOP;

        utl_file.put_line(l_file_handle, l_column_output);
        l_column_output := '';
        l_line_count := l_line_count + 1;
    END LOOP;
    
    -- Close the cursor
    dbms_sql.close_cursor(l_the_cursor);
    
    -- Close the file
    utl_file.fclose(l_file_handle);
END;
