CREATE DATABASE employee;

USE employee;

CREATE TABLE Departments (
    department_id INT,
    department_name VARCHAR(100)
);

CREATE TABLE Location (
    location_id INT,
    location VARCHAR(30)
);

CREATE TABLE Employees (
    employee_id INT,
    employee_name VARCHAR(50),
    gender ENUM('M', 'F'),
    age INT,
    hire_date DATE,
    designation VARCHAR(100),
    department_id INT,
    location_id INT,
    salary DECIMAL(10,2)
);

-- Q2:Aiter table
Alter table Employees add column email varchar(50);
ALTER TABLE Employees MODIFY designation VARCHAR(200);
ALTER TABLE Employees drop column age;
ALTER TABLE Employees RENAME COLUMN hire_date TO date_of_joining;

-- Q3:Table Renaming
RENAME TABLE Departments TO Departments_Info;
RENAME TABLE Location TO Locations;

-- Q4:TRUNCATE
 TRUNCATE Table Employees;
 
 -- Q5:Database & Table Dropping (DROP)
 DROP Table Employees;
 DROP  Database employee;
 
-- Constraints

CREATE DATABASE employee;
USE employee;

CREATE TABLE departments (
    department_id INT PRIMARY KEY ,
    department_name VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE location (
    location_id INT PRIMARY KEY AUTO_INCREMENT,
    location VARCHAR(30) NOT NULL UNIQUE
);

CREATE TABLE employees (
   employee_id INT PRIMARY KEY,
    employee_name VARCHAR(50) NOT NULL,
    gender ENUM('M', 'F'),
    age INT check(age>18),
    hire_date DATE default (CURRENT_DATE),
    designation VARCHAR(100),
    department_id INT,
    location_id INT,
    salary DECIMAL(10,2),

    FOREIGN KEY (department_id)
        REFERENCES departments(department_id),

    FOREIGN KEY (location_id)
        REFERENCES location(location_id)
        );


