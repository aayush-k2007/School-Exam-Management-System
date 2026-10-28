-- =========================================================================
-- School Examination Management System - MySQL Final Schema
-- =========================================================================

CREATE DATABASE IF NOT EXISTS school_exam_db;
USE school_exam_db;

-- 1. Department Table
CREATE TABLE Department (
    D_ID VARCHAR(10) PRIMARY KEY,
    D_Name VARCHAR(50) NOT NULL UNIQUE,
    HOD_Name VARCHAR(50) NOT NULL
);

-- 2. Teacher Table
CREATE TABLE Teacher (
    T_ID VARCHAR(10) PRIMARY KEY,
    T_Name VARCHAR(50) NOT NULL,
    Qualification VARCHAR(50),
    Email VARCHAR(100) UNIQUE,
    Phone VARCHAR(15) UNIQUE,
    D_ID VARCHAR(10) NOT NULL,
    FOREIGN KEY (D_ID) REFERENCES Department(D_ID) ON DELETE CASCADE
);

-- 3. Course Table
CREATE TABLE Course (
    Course_ID VARCHAR(10) PRIMARY KEY,
    Course_Name VARCHAR(50) NOT NULL,
    Duration VARCHAR(20) NOT NULL,
    D_ID VARCHAR(10) NOT NULL,
    FOREIGN KEY (D_ID) REFERENCES Department(D_ID) ON DELETE CASCADE
);

-- 4. Subject Table
CREATE TABLE Subject (
    Sub_Code VARCHAR(10) PRIMARY KEY,
    Sub_Name VARCHAR(50) NOT NULL,
    Credit INT CHECK (Credit > 0),
    T_ID VARCHAR(10),
    Course_ID VARCHAR(10) NOT NULL,
    FOREIGN KEY (T_ID) REFERENCES Teacher(T_ID) ON DELETE SET NULL,
    FOREIGN KEY (Course_ID) REFERENCES Course(Course_ID) ON DELETE CASCADE
);

-- 5. Student Table
CREATE TABLE Student (
    S_ID VARCHAR(10) PRIMARY KEY,
    S_Name VARCHAR(50) NOT NULL,
    DOB DATE NOT NULL,
    Gender VARCHAR(10) CHECK (Gender IN ('Male', 'Female', 'Other')),
    Phone VARCHAR(15) UNIQUE,
    Email VARCHAR(100) UNIQUE,
    Address VARCHAR(100),
    Admission_Year INT CHECK (Admission_Year >= 2000),
    D_ID VARCHAR(10) NOT NULL,
    Course_ID VARCHAR(10) NOT NULL,
    FOREIGN KEY (D_ID) REFERENCES Department(D_ID) ON DELETE CASCADE,
    FOREIGN KEY (Course_ID) REFERENCES Course(Course_ID) ON DELETE CASCADE
);

-- 6. Attendance Table
CREATE TABLE Attendance (
    Attendance_ID VARCHAR(10) PRIMARY KEY,
    Attendance_Percent DECIMAL(5,2) CHECK (Attendance_Percent BETWEEN 0 AND 100),
    Eligibility_Status VARCHAR(20) CHECK (Eligibility_Status IN ('Eligible', 'Not Eligible')),
    S_ID VARCHAR(10) NOT NULL,
    FOREIGN KEY (S_ID) REFERENCES Student(S_ID) ON DELETE CASCADE
);

-- 7. Exam Table
CREATE TABLE Exam (
    Exam_ID VARCHAR(10) PRIMARY KEY,
    Exam_Name VARCHAR(50) NOT NULL,
    Exam_Date DATE NOT NULL,
    Semester INT CHECK (Semester BETWEEN 1 AND 8),
    Course_ID VARCHAR(10) NOT NULL,
    FOREIGN KEY (Course_ID) REFERENCES Course(Course_ID) ON DELETE CASCADE
);

-- 8. Exam_Schedule Table
CREATE TABLE Exam_Schedule (
    Schedule_ID VARCHAR(10) PRIMARY KEY,
    Exam_Date DATE NOT NULL,
    Start_Time VARCHAR(10) NOT NULL,
    End_Time VARCHAR(10) NOT NULL,
    Hall_No VARCHAR(10) NOT NULL,
    Exam_ID VARCHAR(10) NOT NULL,
    Sub_Code VARCHAR(10) NOT NULL,
    FOREIGN KEY (Exam_ID) REFERENCES Exam(Exam_ID) ON DELETE CASCADE,
    FOREIGN KEY (Sub_Code) REFERENCES Subject(Sub_Code) ON DELETE CASCADE
);

-- 9. Marks Table
CREATE TABLE Marks (
    Mark_ID VARCHAR(10) PRIMARY KEY,
    Internal_Marks DECIMAL(5,2) NOT NULL CHECK (Internal_Marks BETWEEN 0 AND 40),
    External_Marks DECIMAL(5,2) NOT NULL CHECK (External_Marks BETWEEN 0 AND 60),
    Total DECIMAL(5,2) GENERATED ALWAYS AS (Internal_Marks + External_Marks) STORED,
    Grade VARCHAR(2) CHECK (Grade IN ('A+', 'A', 'B', 'C', 'D', 'F')),
    S_ID VARCHAR(10) NOT NULL,
    Sub_Code VARCHAR(10) NOT NULL,
    Exam_ID VARCHAR(10) NOT NULL,
    FOREIGN KEY (S_ID) REFERENCES Student(S_ID) ON DELETE CASCADE,
    FOREIGN KEY (Sub_Code) REFERENCES Subject(Sub_Code) ON DELETE CASCADE,
    FOREIGN KEY (Exam_ID) REFERENCES Exam(Exam_ID) ON DELETE CASCADE
);

-- 10. Result Table (Using backticks around `Rank` since it is a MySQL reserved keyword)
CREATE TABLE Result (
    Result_ID VARCHAR(10) PRIMARY KEY,
    GPA DECIMAL(3,2) CHECK (GPA BETWEEN 0.00 AND 10.00),
    `Rank` INT CHECK (`Rank` > 0),
    Result_Status VARCHAR(20) CHECK (Result_Status IN ('Passed', 'Failed', 'Promoted')),
    S_ID VARCHAR(10) NOT NULL,
    Exam_ID VARCHAR(10) NOT NULL,
    FOREIGN KEY (S_ID) REFERENCES Student(S_ID) ON DELETE CASCADE,
    FOREIGN KEY (Exam_ID) REFERENCES Exam(Exam_ID) ON DELETE CASCADE
);

-- =========================================================================
-- Initial Sample Data Inserts
-- =========================================================================

INSERT INTO Department VALUES 
('D101', 'Computer Science', 'Ramesh'),
('D102', 'Electrical Eng', 'Sunita'),
('D103', 'Mechanical Eng', 'Vikram'),
('D104', 'Civil Eng', 'Anil'),
('D105', 'Information Tech', 'Kavita');

INSERT INTO Teacher VALUES 
('T01', 'Rajesh', 'Ph.D. CS', 'rajesh@univ.ac.in', '9876543210', 'D101'),
('T02', 'Ananya', 'M.Tech EE', 'ananya@univ.ac.in', '9876543211', 'D102'),
('T03', 'Suresh', 'Ph.D. ME', 'suresh@univ.ac.in', '9876543212', 'D103'),
('T04', 'Deepak', 'M.Tech CE', 'deepak@univ.ac.in', '9876543213', 'D104'),
('T05', 'Meena', 'Ph.D. IT', 'meena@univ.ac.in', '9876543214', 'D105');

INSERT INTO Course VALUES 
('C10', 'B.Tech CSE', '4 Years', 'D101'),
('C20', 'B.Tech EEE', '4 Years', 'D102'),
('C30', 'B.Tech ME', '4 Years', 'D103'),
('C40', 'B.Tech CE', '4 Years', 'D104'),
('C50', 'B.Tech IT', '4 Years', 'D105');

INSERT INTO Subject VALUES 
('BACSE101', 'DBMS', 4, 'T01', 'C10'),
('BACSE202', 'DSA', 4, 'T01', 'C10'),
('BAEEE101', 'Circuits', 3, 'T02', 'C20'),
('BAMEC101', 'Thermodynamics', 4, 'T03', 'C30'),
('BACIV101', 'Structures', 3, 'T04', 'C40');

INSERT INTO Student VALUES 
('S001', 'Aarav', '2002-05-14', 'Male', '9988776655', 'aarav@gmail.com', '12 MG Road', 2022, 'D101', 'C10'),
('S002', 'Priya', '2001-11-20', 'Female', '9988776656', 'priya@gmail.com', '45 Anna Nagar', 2022, 'D101', 'C10'),
('S003', 'Rohan', '2002-03-10', 'Male', '9988776657', 'rohan@gmail.com', '78 Park Street', 2022, 'D102', 'C20'),
('S004', 'Sneha', '2001-08-25', 'Female', '9988776658', 'sneha@gmail.com', '12 Ring Road', 2022, 'D103', 'C30'),
('S005', 'Karan', '2002-12-05', 'Male', '9988776659', 'karan@gmail.com', '56 Lake View', 2022, 'D104', 'C40');

INSERT INTO Attendance VALUES 
('ATT01', 88.50, 'Eligible', 'S001'),
('ATT02', 65.00, 'Not Eligible', 'S002'),
('ATT03', 92.00, 'Eligible', 'S003'),
('ATT04', 78.00, 'Eligible', 'S004'),
('ATT05', 81.50, 'Eligible', 'S005');

INSERT INTO Exam VALUES 
('EX100', 'End Sem Dec 2025', '2025-12-10', 5, 'C10'),
('EX200', 'End Sem Dec 2025', '2025-12-11', 5, 'C20'),
('EX300', 'End Sem Dec 2025', '2025-12-12', 5, 'C30'),
('EX400', 'End Sem Dec 2025', '2025-12-13', 5, 'C40'),
('EX500', 'End Sem Dec 2025', '2025-12-14', 5, 'C50');

INSERT INTO Exam_Schedule VALUES 
('SCH01', '2025-12-10', '09:30 AM', '12:30 PM', 'Hall A', 'EX100', 'BACSE101'),
('SCH02', '2025-12-12', '09:30 AM', '12:30 PM', 'Hall B', 'EX100', 'BACSE202'),
('SCH03', '2025-12-11', '02:00 PM', '05:00 PM', 'Hall C', 'EX200', 'BAEEE101'),
('SCH04', '2025-12-12', '02:00 PM', '05:00 PM', 'Hall D', 'EX300', 'BAMEC101'),
('SCH05', '2025-12-13', '09:30 AM', '12:30 PM', 'Hall E', 'EX400', 'BACIV101');

INSERT INTO Marks (Mark_ID, Internal_Marks, External_Marks, Grade, S_ID, Sub_Code, Exam_ID) VALUES 
('M01', 38.00, 52.00, 'A+', 'S001', 'BACSE101', 'EX100'),
('M02', 25.50, 41.00, 'B', 'S002', 'BACSE101', 'EX100'),
('M03', 36.00, 49.00, 'A', 'S001', 'BACSE202', 'EX100'),
('M04', 32.00, 45.00, 'B', 'S003', 'BAEEE101', 'EX200'),
('M05', 39.00, 55.00, 'A+', 'S004', 'BAMEC101', 'EX300');

INSERT INTO Result VALUES 
('R01', 9.20, 1, 'Passed', 'S001', 'EX100'),
('R02', 6.50, 2, 'Passed', 'S002', 'EX100'),
('R03', 7.80, 1, 'Passed', 'S003', 'EX200'),
('R04', 9.40, 1, 'Passed', 'S004', 'EX300'),
('R05', 8.10, 1, 'Passed', 'S005', 'EX400');