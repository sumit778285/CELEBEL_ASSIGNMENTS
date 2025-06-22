CREATE PROCEDURE ProcessSubjectChange
AS
BEGIN
    -- Use a Cursor to iterate over the SubjectRequest table
    DECLARE @StudentID VARCHAR(50), @RequestedSubjectID VARCHAR(50);

    DECLARE request_cursor CURSOR FOR
    SELECT StudentID, SubjectID FROM SubjectRequest;

    OPEN request_cursor;

    FETCH NEXT FROM request_cursor INTO @StudentID, @RequestedSubjectID;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Check if the student already exists in SubjectAllotments
        IF EXISTS (SELECT 1 FROM SubjectAllotments WHERE StudentID = @StudentID)
        BEGIN
            -- Get the current valid subject for the student
            DECLARE @CurrentSubjectID VARCHAR(50);
            SELECT @CurrentSubjectID = SubjectID 
            FROM SubjectAllotments 
            WHERE StudentID = @StudentID AND Is_Valid = 1;

            -- If the requested subject is different from the current subject
            IF @CurrentSubjectID != @RequestedSubjectID
            BEGIN
                -- Invalidate the current subject
                UPDATE SubjectAllotments 
                SET Is_Valid = 0 
                WHERE StudentID = @StudentID AND Is_Valid = 1;

                -- Insert the new requested subject as valid
                INSERT INTO SubjectAllotments (StudentID, SubjectID, Is_Valid)
                VALUES (@StudentID, @RequestedSubjectID, 1);
            END
        END
        ELSE
        BEGIN
            -- If the student does not exist, insert the requested subject as valid
            INSERT INTO SubjectAllotments (StudentID, SubjectID, Is_Valid)
            VALUES (@StudentID, @RequestedSubjectID, 1);
        END

        FETCH NEXT FROM request_cursor INTO @StudentID, @RequestedSubjectID;
    END;

    CLOSE request_cursor;
    DEALLOCATE request_cursor;
END;
