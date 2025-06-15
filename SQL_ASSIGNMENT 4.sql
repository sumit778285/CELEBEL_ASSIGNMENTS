CREATE TABLE StudentDetails (
    StudentId VARCHAR(20) PRIMARY KEY,
    StudentName VARCHAR(100),
    GPA FLOAT,
    Branch VARCHAR(50),
    Section VARCHAR(10)
);

CREATE TABLE StudentPreference (
    StudentId VARCHAR(20),
    SubjectId VARCHAR(20),
    Preference INT,
    PRIMARY KEY (StudentId, Preference),
    FOREIGN KEY (StudentId) REFERENCES StudentDetails(StudentId),
    FOREIGN KEY (SubjectId) REFERENCES SubjectDetails(SubjectId)
);

CREATE TABLE SubjectDetails (
    SubjectId VARCHAR(20) PRIMARY KEY,
    SubjectName VARCHAR(100),
    MaxSeats INT,
    RemainingSeats INT
);

CREATE TABLE Allotments (
    SubjectId VARCHAR(20),
    StudentId VARCHAR(20),
    PRIMARY KEY (SubjectId, StudentId),
    FOREIGN KEY (SubjectId) REFERENCES SubjectDetails(SubjectId),
    FOREIGN KEY (StudentId) REFERENCES StudentDetails(StudentId)
);

CREATE TABLE UnallotedStudents (
    StudentId VARCHAR(20) PRIMARY KEY,
    FOREIGN KEY (StudentId) REFERENCES StudentDetails(StudentId)
);

DELIMITER //

CREATE PROCEDURE AllocateSubjects()
BEGIN
    -- Declare variables for iteration
    DECLARE done INT DEFAULT 0;
    DECLARE currentStudentId VARCHAR(20);
    DECLARE currentGPA FLOAT;

    -- Cursor for iterating students by GPA
    DECLARE studentCursor CURSOR FOR 
    SELECT StudentId, GPA FROM StudentDetails ORDER BY GPA DESC;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    -- Open cursor
    OPEN studentCursor;

    student_loop: LOOP
        -- Fetch next student
        FETCH studentCursor INTO currentStudentId, currentGPA;

        IF done THEN
            LEAVE student_loop;
        END IF;

        -- Iterate preferences for the current student
        DECLARE preference INT DEFAULT 1;
        DECLARE found INT DEFAULT 0;

        preference_loop: LOOP
            IF preference > 5 THEN
                LEAVE preference_loop;
            END IF;

            -- Check for subject availability based on the current preference
            IF EXISTS (
                SELECT 1 
                FROM StudentPreference SP
                JOIN SubjectDetails SD ON SP.SubjectId = SD.SubjectId
                WHERE SP.StudentId = currentStudentId
                  AND SP.Preference = preference
                  AND SD.RemainingSeats > 0
            ) THEN
                -- Allot the subject
                INSERT INTO Allotments (SubjectId, StudentId)
                SELECT SP.SubjectId, SP.StudentId
                FROM StudentPreference SP
                JOIN SubjectDetails SD ON SP.SubjectId = SD.SubjectId
                WHERE SP.StudentId = currentStudentId
                  AND SP.Preference = preference;

                -- Update remaining seats
                UPDATE SubjectDetails SD
                SET SD.RemainingSeats = SD.RemainingSeats - 1
                WHERE SD.SubjectId = (
                    SELECT SP.SubjectId
                    FROM StudentPreference SP
                    WHERE SP.StudentId = currentStudentId
                      AND SP.Preference = preference
                );

                SET found = 1;
                LEAVE preference_loop;
            END IF;

            SET preference = preference + 1;
        END LOOP preference_loop;

        -- If not allotted, mark as unallotted
        IF found = 0 THEN
            INSERT INTO UnallotedStudents (StudentId) VALUES (currentStudentId);
        END IF;
    END LOOP student_loop;

    -- Close cursor
    CLOSE studentCursor;
END //

DELIMITER ;
