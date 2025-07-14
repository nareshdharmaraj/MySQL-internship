-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Jul 14, 2025 at 12:40 PM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `blooddonationdb`
--

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `ProcessBloodRequest` (IN `reqID` INT)   BEGIN
    DECLARE bg VARCHAR(3);
    DECLARE units INT;
    DECLARE available INT;

    -- Get BloodGroup and UnitsRequested for this request
    SELECT BloodGroup, UnitsRequested INTO bg, units
    FROM Requests
    WHERE RequestID = reqID;

    -- Get available stock for that BloodGroup
    SELECT UnitsAvailable INTO available
    FROM BloodInventory
    WHERE BloodGroup = bg;

    -- Check if stock is enough
    IF available >= units THEN
        -- Deduct units from inventory
        UPDATE BloodInventory
        SET UnitsAvailable = UnitsAvailable - units
        WHERE BloodGroup = bg;

        -- Mark request as Approved
        UPDATE Requests
        SET Status = 'Approved'
        WHERE RequestID = reqID;

    ELSE
        -- Mark request as Rejected
        UPDATE Requests
        SET Status = 'Rejected'
        WHERE RequestID = reqID;

    END IF;

END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `bloodinventory`
--

CREATE TABLE `bloodinventory` (
  `BloodGroup` varchar(3) NOT NULL,
  `UnitsAvailable` int(11) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `bloodinventory`
--

INSERT INTO `bloodinventory` (`BloodGroup`, `UnitsAvailable`) VALUES
('A+', 0),
('A-', 0),
('AB+', 8),
('AB-', 2),
('B+', 5),
('B-', 0),
('O+', 1),
('O-', 0);

-- --------------------------------------------------------

--
-- Table structure for table `donations`
--

CREATE TABLE `donations` (
  `DonationID` int(11) NOT NULL,
  `DonorID` int(11) DEFAULT NULL,
  `BloodGroup` varchar(3) NOT NULL,
  `DonationDate` date NOT NULL,
  `Units` int(11) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `donations`
--

INSERT INTO `donations` (`DonationID`, `DonorID`, `BloodGroup`, `DonationDate`, `Units`) VALUES
(1, 1, 'O+', '2025-03-20', 1),
(2, 1, 'O+', '2025-03-20', 1),
(3, 1, 'O+', '2025-03-20', 1),
(4, 2, 'AB+', '2025-07-14', 1),
(5, 2, 'AB+', '2025-07-10', 1),
(6, 2, 'AB+', '2025-07-10', 1),
(7, 2, 'AB+', '2025-07-10', 1),
(8, 2, 'AB+', '2025-07-10', 1),
(9, 2, 'AB+', '2025-07-10', 1),
(10, 2, 'AB+', '2025-07-10', 1),
(11, 5, 'B+', '2025-07-14', 1),
(12, 3, 'O+', '2024-07-14', 1),
(13, 5, 'B+', '2025-08-13', 2),
(14, 6, 'AB-', '2025-07-14', 2);

--
-- Triggers `donations`
--
DELIMITER $$
CREATE TRIGGER `AfterDonationInsert` AFTER INSERT ON `donations` FOR EACH ROW BEGIN
    UPDATE BloodInventory
    SET UnitsAvailable = UnitsAvailable + 1
    WHERE BloodGroup = NEW.BloodGroup;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `donors`
--

CREATE TABLE `donors` (
  `DonorID` int(11) NOT NULL,
  `Name` varchar(100) NOT NULL,
  `Age` int(11) DEFAULT NULL CHECK (`Age` >= 18),
  `BloodGroup` varchar(3) NOT NULL,
  `Contact` varchar(15) NOT NULL,
  `LastDonationDate` date DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `donors`
--

INSERT INTO `donors` (`DonorID`, `Name`, `Age`, `BloodGroup`, `Contact`, `LastDonationDate`) VALUES
(1, 'Rahul Sharma', 28, 'O+', '9876543210', '2025-03-01'),
(2, 'Sharma', 28, 'O+', '9876543201', '2025-03-01'),
(3, 'Rahul', 25, 'O+', '1234565432', '1234-02-01'),
(4, 'ram', 22, 'AB+', '1234567890', '2025-01-31'),
(5, 'manoj', 23, 'B+', '6574839201', '2025-04-10'),
(6, 'Naresh', 19, 'AB-', '7200754566', '2025-07-14');

-- --------------------------------------------------------

--
-- Table structure for table `recipients`
--

CREATE TABLE `recipients` (
  `RecipientID` int(11) NOT NULL,
  `Name` varchar(100) NOT NULL,
  `Age` int(11) DEFAULT NULL,
  `BloodGroup` varchar(3) NOT NULL,
  `Contact` varchar(15) NOT NULL,
  `BloodRequired` int(11) NOT NULL CHECK (`BloodRequired` > 0),
  `Status` enum('Pending','Approved','Rejected') DEFAULT 'Pending'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `recipients`
--

INSERT INTO `recipients` (`RecipientID`, `Name`, `Age`, `BloodGroup`, `Contact`, `BloodRequired`, `Status`) VALUES
(1, 'Aditi Verma', 35, 'O+', '9898989898', 2, 'Rejected'),
(2, 'Verma', 35, 'O+', '9898989998', 2, 'Approved'),
(3, 'Aditi', 35, 'O+', '1234543212', 2, 'Rejected'),
(4, 'raman', 23, 'B+', '1234543212', 3, 'Rejected'),
(5, 'sukanth', 30, 'A+', '8907654321', 3, 'Rejected'),
(7, 'yamuna', 14, 'A+', '1092873465', 2, 'Rejected'),
(8, 'Anjali', 20, 'AB-', '3452176098', 1, 'Approved'),
(9, 'kumar', 24, 'O-', '6534987012', 1, 'Rejected');

-- --------------------------------------------------------

--
-- Table structure for table `requests`
--

CREATE TABLE `requests` (
  `RequestID` int(11) NOT NULL,
  `RecipientID` int(11) DEFAULT NULL,
  `BloodGroup` varchar(3) NOT NULL,
  `UnitsRequested` int(11) NOT NULL,
  `Status` varchar(20) DEFAULT 'Pending'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `requests`
--

INSERT INTO `requests` (`RequestID`, `RecipientID`, `BloodGroup`, `UnitsRequested`, `Status`) VALUES
(1, 1, 'O+', 2, 'Rejected');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `bloodinventory`
--
ALTER TABLE `bloodinventory`
  ADD PRIMARY KEY (`BloodGroup`);

--
-- Indexes for table `donations`
--
ALTER TABLE `donations`
  ADD PRIMARY KEY (`DonationID`),
  ADD KEY `DonorID` (`DonorID`);

--
-- Indexes for table `donors`
--
ALTER TABLE `donors`
  ADD PRIMARY KEY (`DonorID`),
  ADD UNIQUE KEY `unique_name` (`Name`);

--
-- Indexes for table `recipients`
--
ALTER TABLE `recipients`
  ADD PRIMARY KEY (`RecipientID`),
  ADD UNIQUE KEY `unique_name` (`Name`);

--
-- Indexes for table `requests`
--
ALTER TABLE `requests`
  ADD PRIMARY KEY (`RequestID`),
  ADD KEY `RecipientID` (`RecipientID`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `donations`
--
ALTER TABLE `donations`
  MODIFY `DonationID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=15;

--
-- AUTO_INCREMENT for table `donors`
--
ALTER TABLE `donors`
  MODIFY `DonorID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `recipients`
--
ALTER TABLE `recipients`
  MODIFY `RecipientID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;

--
-- AUTO_INCREMENT for table `requests`
--
ALTER TABLE `requests`
  MODIFY `RequestID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `donations`
--
ALTER TABLE `donations`
  ADD CONSTRAINT `donations_ibfk_1` FOREIGN KEY (`DonorID`) REFERENCES `donors` (`DonorID`);

--
-- Constraints for table `requests`
--
ALTER TABLE `requests`
  ADD CONSTRAINT `requests_ibfk_1` FOREIGN KEY (`RecipientID`) REFERENCES `recipients` (`RecipientID`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
