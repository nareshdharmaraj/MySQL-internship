CREATE DATABASE IF NOT EXISTS BloodDonationDB;
USE BloodDonationDB;

-- Donors Table
CREATE TABLE IF NOT EXISTS Donors (
    DonorID INT AUTO_INCREMENT PRIMARY KEY,
    Name VARCHAR(100) NOT NULL,
    Age INT CHECK (Age >= 18),
    BloodGroup VARCHAR(3) NOT NULL,
    Contact VARCHAR(15) NOT NULL,
    LastDonationDate DATE
);

-- Recipients Table
CREATE TABLE IF NOT EXISTS Recipients (
    RecipientID INT AUTO_INCREMENT PRIMARY KEY,
    Name VARCHAR(100) NOT NULL,
    Age INT,
    BloodGroup VARCHAR(3) NOT NULL,
    Contact VARCHAR(15) NOT NULL,
    BloodRequired INT NOT NULL CHECK (BloodRequired > 0)
);

-- Blood Inventory
CREATE TABLE IF NOT EXISTS BloodInventory (
    BloodGroup VARCHAR(3) PRIMARY KEY,
    UnitsAvailable INT NOT NULL DEFAULT 0
);

INSERT IGNORE INTO BloodInventory (BloodGroup, UnitsAvailable) VALUES
('O+', 5), ('A+', 5), ('B+', 3), ('AB+', 6),
('O-', 2), ('A-', 1), ('B-', 0), ('AB-', 0);

-- Donations
CREATE TABLE IF NOT EXISTS Donations (
    DonationID INT AUTO_INCREMENT PRIMARY KEY,
    DonorID INT,
    BloodGroup VARCHAR(3) NOT NULL,
    DonationDate DATE NOT NULL,
    FOREIGN KEY (DonorID) REFERENCES Donors(DonorID)
);

ALTER TABLE Donations ADD COLUMN Units INT DEFAULT 1;


-- Requests
CREATE TABLE IF NOT EXISTS Requests (
    RequestID INT AUTO_INCREMENT PRIMARY KEY,
    RecipientID INT,
    BloodGroup VARCHAR(3) NOT NULL,
    UnitsRequested INT NOT NULL,
    Status VARCHAR(20) DEFAULT 'Pending',
    FOREIGN KEY (RecipientID) REFERENCES Recipients(RecipientID)
);

-- Trigger
DELIMITER $$

CREATE TRIGGER IF NOT EXISTS AfterDonationInsert
AFTER INSERT ON Donations
FOR EACH ROW
BEGIN
    UPDATE BloodInventory
    SET UnitsAvailable = UnitsAvailable + 1
    WHERE BloodGroup = NEW.BloodGroup;
END $$

DELIMITER ;

-- Procedure
DELIMITER $$

CREATE PROCEDURE IF NOT EXISTS ProcessBloodRequest(IN reqID INT)
BEGIN
    DECLARE bg VARCHAR(3);
    DECLARE units INT;
    DECLARE available INT;

    SELECT BloodGroup, UnitsRequested INTO bg, units
    FROM Requests
    WHERE RequestID = reqID;

    SELECT UnitsAvailable INTO available
    FROM BloodInventory
    WHERE BloodGroup = bg;

    IF available >= units THEN
        UPDATE BloodInventory
        SET UnitsAvailable = UnitsAvailable - units
        WHERE BloodGroup = bg;

        UPDATE Requests
        SET Status = 'Approved'
        WHERE RequestID = reqID;

    ELSE
        UPDATE Requests
        SET Status = 'Rejected'
        WHERE RequestID = reqID;
    END IF;
END $$

DELIMITER ;

ALTER TABLE Recipients ADD Status ENUM('Pending', 'Approved', 'Rejected') DEFAULT 'Pending';
