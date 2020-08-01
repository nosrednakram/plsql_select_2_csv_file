# plsql_select_2_csv_file
Simple small procedure to covert a query as string into a CSV file. Does NOT support lob objects.

## Overview
At my job we often have a need to generate CSV files for bridging data. For end users we us AS_XLSX which is a great package but when RAW CSV we kept re-inventing the wheel. This package uses dbms_sql so it can do some introspection for setting column type and getting column names for headings etc. It's very small and can easily be incorporated into other project code etc. It writes to a file because we've found spooling to not work on very large datasets. I'll be working on some additional scripts to help with moving files around. 

## Usage

The only required parameter is the **query_string** which is just a select query. You will generally also want to supply the **file_name**. **CAUTIION: It will always remove an existing file with that name.** For your purposes I would suggest changing the default **dir_name** to what you use at your organization.   The user will need write access ganted for the directory. If you don't use directories easy enought to google setting up. I addeed a few options with logical default to mange the file output:

   * **seperator**: ,
   * **wrap_string**: "
   * **include_heading**: true

To set the output date format you should alter the NLS_DATA_FORMAT before calling.

**ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD';**

## Example 
'''sql
alter SESSION  set NLS_DATE_FORMAT = 'YYYY-MM-DD';
begin
csv_file_from_query_string(
    query_string => q'#select * from table where column_name = value#',
    file_name => 'employee.csv'
    );
end;
```
