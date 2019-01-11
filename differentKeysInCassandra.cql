/*
Cassandra has many types of key:
primary key,
partition key, 
composite key 
clustering key
*/

/*
The primary key is a general concept to indicate one or more columns used to retrieve data from a Table. They alltogether
represents each row of the column uniquely.

In cassandra if you are trying to insert duplicates using "INSERT INTO" command, it will overwrite the existing value
*/

CREATE TABLE dummy.duplicate_rows (
    age int PRIMARY KEY,
    name text
);

INSERT INTO duplicate_rows (age, name) VALUES (23,'Sankar');

INSERT INTO duplicate_rows (age, name) VALUES (23,'Samrat');

cqlsh:dummy> SELECT * FROM duplicate_rows;

 age | name
-----+--------
  23 | Samrat
  
  --so "Sankar" has been overwritten by "Samrat"


/*
But the primary key can also be COMPOSITE (aka COMPOUND), generated from more than one column.
*/

CREATE TABLE employee(
ID int,
Employer text,
Salary int,
country text,
PRIMARY KEY(ID,country)
);

INSERT INTO employee (id, country) VALUES (1,'India');

--This will have the country and salary column as "null". "ID" and "country" fields has to be entered being part of PK.

/*
In a situation of COMPOSITE primary key, the "first part" of the key is called PARTITION KEY 
(in this example key_part_one is the partition key) and the second part of the key is the CLUSTERING KEY 
(in this example key_part_two)
*/

--if you see the definition of the table, you will get an idea about the structure 

cqlsh:dummy> desc table employee 

CREATE TABLE dummy.employee (
    id int,
    country text,
    employer text,
    salary int,
    PRIMARY KEY (id, country)
) WITH CLUSTERING ORDER BY (country ASC);

INSERT INTO employee (id, country, employer , salary ) VALUES ( 2,'US','Kagel',100000);

--so in this case "id" and "country" together will be defining each row uniquely

INSERT INTO employee (id, country, employer , salary ) VALUES ( 2,'US','Infy',100000);

--this row will overwrite the last line of INSERT

/*
The Partition Key is responsible for data distribution across your nodes. On your partition key, partitioning algorithm will work.
The Clustering Key is responsible for data sorting within the partition.
Also range queries ( < , >) should be performed on clustering keys, it wouldnt work on Partition key.
*/

--also we can have both partition and clustering key made by more columns, here's how::

CREATE TABLE adultData(
Age int,
Employer text,
Salary int,
education text,
educationYear int,
maritalStatus text,
jobdesignation text,
familyStatus text,
colour text,
gender text,
Points1 int,
Points2 int,
Points3 int,
country text,
salaryType text,
PRIMARY KEY ((Age,Employer,Salary,education,educationYear),Points1,Points2,Points3,salaryType,gender,jobdesignation,maritalStatus,country,colour)
);

cqlsh:dummy> DESC TABLE adultdata;

CREATE TABLE dummy.adultdata (
    age int,
    employer text,
    salary int,
    education text,
    educationyear int,
    points1 int,
    points2 int,
    points3 int,
    salarytype text,
    gender text,
    jobdesignation text,
    maritalstatus text,
    country text,
    colour text,
    familystatus text,
    PRIMARY KEY ((age, employer, salary, education, educationyear), points1, points2, points3, salarytype, gender, jobdesignation, maritalstatus, country, colour)
) WITH CLUSTERING ORDER BY (points1 ASC, points2 ASC, points3 ASC, salarytype ASC, gender ASC, jobdesignation ASC, maritalstatus ASC, country ASC, colour ASC)

--you can see the clustering key has started with Points1

/*
Query based on where clause is a "thing" to understand in cassandra otherwise you would many times end up getting error in where
clause.

the partition key is the minimum-specifier needed to perform a query using a where clause. we can query based on all key 
(both partition and clustering) as well.
*/


/*
If you have a composite partition key, like the following ::

PRIMARY KEY((col1, col2), col10, col4))
You can perform query only by passing at least both col1 and col2, these are the 2 columns that define the partition key. 
The "general" rule to make query is you have to pass at least all partition key columns, then you can add optionally each 
clustering key in the order they're set.

so the valid queries are (excluding secondary indexes)::
col1 and col2
col1 and col2 and col10
col1 and col2 and col10 and col 4
*/


/*
A primary key uniquely identifies a row.
A composite key is a key formed from multiple columns.
A partition key is the primary lookup to find a set of rows, i.e. a partition.
A clustering key is the part of the primary key that isn't the partition key (and defines the ordering within a partition).
Examples:

PRIMARY KEY (a): The partition key is a.
PRIMARY KEY (a, b): The partition key is a, the clustering key is b.
PRIMARY KEY ((a, b)): The composite partition key is (a, b).
PRIMARY KEY (a, b, c): The partition key is a, the composite clustering key is (b, c).
PRIMARY KEY ((a, b), c): The composite partition key is (a, b), the clustering key is c.
PRIMARY KEY ((a, b), c, d): The composite partition key is (a, b), the composite clustering key is (c, d).
*/

--we can use ordering on the clustering keys while defining the table::

CREATE TABLE timeseries (
  event_type text,
  insertion_time timestamp,
  event blob,
  PRIMARY KEY (event_type, insertion_time)
)
WITH CLUSTERING ORDER BY (insertion_time DESC);


/*
Static Column :: In a table that uses clustering columns, non-clustering columns can be declared static in the table 
definition. Static columns are only static within a given partition.
You can use the DISTINCT keyword to select static columns although DISTINCT only works on partition keys.
A table that does not define any clustering columns cannot have a static column. The table having no clustering columns has a 
one-row partition in which every column is inherently static.
A table defined with the COMPACT STORAGE directive cannot have a static column.
A column designated to be the partition key cannot be static.
*/

CREATE TABLE testStatic (
Name text,
random text STATIC,
value int,
PRIMARY KEY (Name,value)
);

INSERT INTO teststatic (name, random, value) VALUES ('PK1','Static value',0)                          
                           
cqlsh:test> select * FROM teststatic ;

 name | value | random
------+-------+--------------
  PK1 |     0 | Static value
  
 
INSERT INTO teststatic (name, random, value) VALUES ('PK1','Static value should not change',1);
 
cqlsh:test> select * FROM teststatic ;

 name | value | random
------+-------+--------------------------------
  PK1 |     0 | Static value should not change
  PK1 |     1 | Static value should not change
  
 --the first row value has automatically changed, because as the partitioning key was same for both the rows, static column 
 --"random" had to be same as well.

INSERT INTO teststatic (name, random, value) VALUES ('PK2','Static value should not change PK2',1);

cqlsh:test> select * from teststatic ;

 name | value | random
------+-------+------------------------------------
  PK2 |     1 | Static value should not change PK2
  PK1 |     0 |     Static value should not change
  PK1 |     1 |     Static value should not change
  
  
  
  