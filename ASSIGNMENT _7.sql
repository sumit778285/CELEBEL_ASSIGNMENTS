CREATE PROCEDURE sp_scd_type_0()
BEGIN
    INSERT INTO dim_customer (id, name, address, city, updated_at)
    SELECT s.id, s.name, s.address, s.city, s.updated_at
    FROM stg_customer s
    LEFT JOIN dim_customer d ON s.id = d.id
    WHERE d.id IS NULL;
END;

CREATE PROCEDURE sp_scd_type_1()
BEGIN
    -- Update existing
    UPDATE dim_customer d
    JOIN stg_customer s ON d.id = s.id
    SET d.name = s.name,
        d.address = s.address,
        d.city = s.city,
        d.updated_at = s.updated_at;

    -- Insert new
    INSERT INTO dim_customer (id, name, address, city, updated_at)
    SELECT s.id, s.name, s.address, s.city, s.updated_at
    FROM stg_customer s
    LEFT JOIN dim_customer d ON s.id = d.id
    WHERE d.id IS NULL;
END;

CREATE PROCEDURE sp_scd_type_2()
BEGIN
    -- Expire old record
    UPDATE dim_customer d
    JOIN stg_customer s ON d.id = s.id
    SET d.end_date = CURRENT_DATE,
        d.current_flag = 0
    WHERE (d.name <> s.name OR d.address <> s.address OR d.city <> s.city)
      AND d.current_flag = 1;

    -- Insert new version
    INSERT INTO dim_customer (id, name, address, city, start_date, end_date, current_flag, version)
    SELECT s.id, s.name, s.address, s.city, CURRENT_DATE, NULL, 1,
           IFNULL(d.version, 0) + 1
    FROM stg_customer s
    LEFT JOIN dim_customer d ON s.id = d.id
    AND d.current_flag = 1
    WHERE d.id IS NULL OR d.name <> s.name OR d.address <> s.address OR d.city <> s.city;
END;

CREATE PROCEDURE sp_scd_type_3()
BEGIN
    UPDATE dim_customer d
    JOIN stg_customer s ON d.id = s.id
    SET d.previous_address = d.address,
        d.address = s.address,
        d.updated_at = s.updated_at
    WHERE d.address <> s.address;

    -- Insert new records
    INSERT INTO dim_customer (id, name, address, previous_address, city, updated_at)
    SELECT s.id, s.name, s.address, NULL, s.city, s.updated_at
    FROM stg_customer s
    LEFT JOIN dim_customer d ON s.id = d.id
    WHERE d.id IS NULL;
END;

CREATE PROCEDURE sp_scd_type_4()
BEGIN
    -- Insert into history table
    INSERT INTO hist_customer (id, name, address, city, updated_at)
    SELECT d.id, d.name, d.address, d.city, d.updated_at
    FROM dim_customer d
    JOIN stg_customer s ON d.id = s.id
    WHERE d.name <> s.name OR d.address <> s.address OR d.city <> s.city;

    -- Update current table
    UPDATE dim_customer d
    JOIN stg_customer s ON d.id = s.id
    SET d.name = s.name,
        d.address = s.address,
        d.city = s.city,
        d.updated_at = s.updated_at;

    -- Insert new rows
    INSERT INTO dim_customer (id, name, address, city, updated_at)
    SELECT s.id, s.name, s.address, s.city, s.updated_at
    FROM stg_customer s
    LEFT JOIN dim_customer d ON s.id = d.id
    WHERE d.id IS NULL;
END;

CREATE PROCEDURE sp_scd_type_6()
BEGIN
    -- Expire old current record
    UPDATE dim_customer d
    JOIN stg_customer s ON d.id = s.id
    SET d.end_date = CURRENT_DATE,
        d.current_flag = 0
    WHERE d.current_flag = 1
      AND (d.name <> s.name OR d.address <> s.address OR d.city <> s.city);

    -- Insert new record
    INSERT INTO dim_customer (id, name, address, previous_address, city,
                              start_date, end_date, current_flag, version)
    SELECT s.id, s.name, s.address, d.address, s.city,
           CURRENT_DATE, NULL, 1, IFNULL(d.version, 0) + 1
    FROM stg_customer s
    LEFT JOIN dim_customer d ON s.id = d.id AND d.current_flag = 1
    WHERE d.id IS NULL OR d.name <> s.name OR d.address <> s.address OR d.city <> s.city;
END;

