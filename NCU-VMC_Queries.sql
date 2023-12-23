-- -----------------------------------------------------

-- CREATING VIEWS

-- -----------------------------------------------------

-- 1.) Display all available vehicles on a given date.

-- (Error with duplication; happened when had 'many-to-many' relationship between Vehicles and Bookings.
-- Resolved by deleting the Vehicles_Has_Bookings table and making 'one-to-many' relationship between 
-- Vehicles and Bookings)

CREATE VIEW All_Vehicles_Avaliable
AS
SELECT -- Columns which will be displayed in grid
    v.idVehicle, 
    vm.modelName,
    vm.manufacturer
FROM
    Vehicles v
JOIN 
    Vehicle_Models vm ON v.VM_idModel = vm.idModel
LEFT JOIN 
    Bookings b ON v.idVehicle = b.V_idVehicle
WHERE -- Display Vehicles with no booking and no booking overlapping the inputted date
    (b.V_idVehicle IS NULL 
    OR '2023-12-17' NOT BETWEEN b.startDate AND b.endDate
    OR b.startDate IS NULL)
    AND avaliableNow = 'T'; -- Only displays the vehicles which are avaliable now
    
-- 2 .) Display how many vehicles each department has used, and who are the most
-- recurrent faculty members using the service.

-- Displays amount of vehicles each department has used (id, name, vehicles used)
CREATE VIEW Vehicle_Usage_Departments
AS
SELECT
    d.idDepartment,
    d.nameDepartment,
    COUNT(cf.V_idVehicle) AS vehiclesUsed
FROM
    Departments d
LEFT JOIN
    Faculty_Members fm ON d.idDepartment = fm.D_idDepartment
LEFT JOIN
    Checkout_Form cf ON fm.idFacMember = cf.FM_idFacMember
GROUP BY
    d.idDepartment, d.nameDepartment
ORDER BY -- From high to low, order departments vehicle useage
    vehiclesUsed DESC;

-- Display most recurrent members using the service (id, name, amount used)
CREATE VIEW Vehicle_Usage_Members
AS
SELECT
	fm.idFacMember,
    fm.nameMember,
    COUNT(cf.idCheckout_Form) AS serviceUsedCount
FROM
	Faculty_Members fm
LEFT JOIN
	Checkout_Form cf ON fm.idFacMember = cf.FM_idFacMember
GROUP BY
	fm.idFacMember, fm.nameMember
ORDER BY
	serviceUsedCount DESC;

-- Display the total mileage driven by a department or faculty member this year.
CREATE VIEW Yearly_Mileage_Departments
AS
SELECT
    fm.idFacMember,
    fm.idDepartment,
    SUM(cf.odometerAtStart - tcf.odometerAtFinish) AS employeeMileage
FROM
    Trip_Completion_Form tc
JOIN
    Checkout_Form cf ON tc.CF_idCheckout_Form = cf.idCheckout_Form
JOIN
    Faculty_Members fm ON cf.idFacMember = fm.idFacMember
WHERE
    YEAR(tc.date) = YEAR(CURDATE())
GROUP BY
    fm.idDepartment, fm.idFacMember;

	
SELECT * FROM All_Vehicles_Avaliable;
SELECT * FROM Vehicle_Usage_Departments;
SELECT * FROM Vehicle_Usage_Members;

-- -----------------------------------------------------

-- CREATING PROCEDURES

-- -----------------------------------------------------

-- Maintenance Form
DELIMITER $$
CREATE PROCEDURE Create_Maintenance_Log(
    IN p_V_idVehicle INT,
    IN p_maintenanceRequired VARCHAR(85),
    IN p_maintenanceTasks VARCHAR(85),
    IN p_idMechanic INT,
    IN p_partsUsed VARCHAR(85)
)
BEGIN
    INSERT INTO Maintenance_Form(V_idVehicle, maintenanceRequired, logEntryDate)
    VALUES (p_V_idVehicle, p_maintenanceRequired, CURDATE()); -- uses current date

-- gets the last id of the inserted values
    SET @idMaintenanceDetailsForm = LAST_INSERT_ID();

    INSERT INTO Maintenance_Details_Form(idMaintenanceForm, matainanceItem, partsUsed, M_idMechanic)
    VALUES (@idMaintenanceDetailsForm, p_maintenanceTasks, p_partsUsed, p_idMechanic);

-- sets back to service date when maintenance is complete
    UPDATE Maintenance_Form
    SET backToServiceDate = CURDATE()
    WHERE idMaintenanceForm = @idMaintenanceDetailsForm;

-- FIND_IN_SET to split the ',' seperated values
    INSERT INTO Parts_Usage_Form (idMaintenanceForm, PI_idPart)
    SELECT @idMaintenanceDetailsForm, CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(p_partsUsed, ',', n.digit+1), ',', -1) AS UNSIGNED) AS PI_idPart
    FROM numbers n
    WHERE n.digit < LENGTH(p_partsUsed) - LENGTH(REPLACE(p_partsUsed, ',', '')) + 1;

    SELECT 'Maintenance Log is submitted, thank you.' AS message;
END $$
DELIMITER ;

-- All reports need access privilages
-- all are made monthly
DELIMITER $$
-- by vehicles and departments
CREATE PROCEDURE Create_Revenue_Report()
BEGIN

END $$
DELIMITER ;

DELIMITER $$
-- mileage driven by a vehicle, by department, 
-- and by faculty members within a department
CREATE PROCEDURE Create_Mileage_Report()
BEGIN

END $$
DELIMITER ;

DELIMITER $$
-- no details in brief? basic, which parts used, log id 
CREATE PROCEDURE Create_Parts_Usage_Report()
BEGIN

END $$
DELIMITER ;

DELIMITER $$
-- no details in brief again. log, job, vehicleid, bills
CREATE PROCEDURE Create_Vehicle_Maintenance_Summary()
BEGIN

END $$
DELIMITER ;

-- Reservation Form
DELIMITER $$
CREATE PROCEDURE Create_Reservation_Log(
    IN p_expectedDeparture DATE,
    IN p_vehicleType VARCHAR(15),
    IN p_destinatiodestinationn VARCHAR(45),
    IN p_idFacMember INT
)
BEGIN
    INSERT INTO Reservation_Forms (expectedDeparture, vehicleType, destination, FM_idFacMember)
    VALUES (p_expectedDeparture, p_vehicleType, p_destination, p_FM_idFacMember);
    
    SELECT "Reservation has been submitted, thank you. " AS message;
END $$
DELIMITER ;


-- -----------------------------------------------------

-- CREATING TRIGGERS

-- -----------------------------------------------------

-- Triggers dont need to be called, they are activated when a condition is/isnt met
-- trigger declared fields/variables given naming convention 't_', showing they are part of the trigger

DELIMITER $$
CREATE TRIGGER Parts_Monitoring
AFTER UPDATE ON Parts_Inventory
FOR EACH ROW
BEGIN
    DECLARE t_orderAmount INT;
    
-- minimum quantity of any part 
    SET @minQuantityOnHand = 3;
    
-- check if part is at the minimum or not
    IF NEW.quantity < @minQuantityOnHand THEN
	-- set amount of parts which need to be ordered
        SET t_orderAmount = @minQuantityOnHand + 2;
        
		-- insert placed order into Parts_Orders table
        INSERT INTO Parts_Orders (PI_idPart, quantity, orderDate)
        VALUES (NEW.idPart, t_orderAmount, CURDATE());
        
		-- update inventory in respect to the parts order
        UPDATE Parts_Inventory
        SET quantity = NEW.quantity + t_orderAmount
        WHERE idPart = NEW.idPart;
        
        -- message for confirmation
        SELECT 'Order Recieved: Part Identification - ' || NEW.idPart || '. Quantity on hand - ' || NEW.quantity
        AS message;
    END IF;
END $$
DELIMITER ;


DELIMITER $$
CREATE TRIGGER Check_For_Reservation
BEFORE INSERT ON Bookings
FOR EACH ROW
BEGIN
    DECLARE t_reservationCount INT;

-- check for reservation on given vehicle
    SELECT COUNT(*) INTO t_reservationCount
    FROM Reservation_Forms
    WHERE idVehicle = NEW.idVehicle
      AND expectedDeparture = NEW.expectedDeparture;

-- condition prevents any bookings without reservations
    IF t_reservationCount = 0 THEN
    -- error handling, exception code
        SIGNAL SQLSTATE '45000' -- '45' indicates user defined exception
								-- (subclass code of '000' showing its a generic exception)
	-- message set, corresponds to the SQLSTATE exception
        SET MESSAGE_TEXT = 'Cannot sign out the vehicle without a prior reservation.';
    END IF;
END $$
DELIMITER ;


DELIMITER $$
CREATE TRIGGER Maintenance_Discrepancies_Checker
AFTER UPDATE ON Vehicles
FOR EACH ROW
BEGIN
    DECLARE t_maintenanceFinished INT;
    
-- check maintenance status and search through the forms
    IF NEW.maintenanceComplete = 'T' THEN
        SELECT COUNT(*) INTO t_maintenanceFinished
        FROM Maintenance_Form AS mf
        JOIN Maintenance_Details_Form AS mdf ON mf.idMaintainanceForm = mdf.idMaintainanceForm
        WHERE mf.V_idVehicle = NEW.idVehicle;
        
		-- if forms are not complete, run the error exception
        IF t_maintenanceFinished = 0 THEN
            UPDATE Vehicles
            SET maintenanceComplete = 'F'
            WHERE idVehicle = NEW.idVehicle;
            
            -- error handling: state code 45, showing user defined exception. log and forms not completed
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Error: forms are not completed correctly.';
        END IF;
    END IF;
END $$
DELIMITER ;


-- -----------------------------------------------------

-- ADDING VALUES

-- -----------------------------------------------------

INSERT INTO Vehicle_Models(modelName, vehicleType, manufacturer)
	-- Model, Vehicle Type, Manufacturer
	VALUES
		("Focus", "Sedan", "Ford"),
        ("Transit", "Van", "Ford"),
        ("Ducato", "Van", "Fiat"),
        ("Caravelle", "Minibus", "Volkswagen"),
        ("Vivaro", "Minibus", "Vauxhall"),
        ("Trafic", "Minibus", "Renault"),
        ("Vario", "Minibus", "Mercedes-Benz"),
        ("Civic", "Sedan", "Honda"),
        ("Camry", "Sedan", "Toyota"),
		("E-Class", "Sedan", "Mercedes-Benz"),
        ("A3", "Sedan", "Audi"),
        ("911", "Sports Car", "Porche"),
        ("Qashqai", "SUV", "Nissan"),
        ("Hilux", "Pick-Up Truck", "Toyota"),
        ("Berlingo", "Minibus", "Citroen"),
        ("Sprinter", "Van", "Mercedes"),
        ("Ranger", "Pick-Up Truck", "Ford"),
        ("3-Series", "Sedan", "BMW"),
        ("A6", "Sedan", "Audi");


INSERT INTO Vehicles (VM_idModel, avaliableNow, 
	maintenanceComplete, currentOdometer, licensePlate)
    -- Model (Foreign Key), Avaliable, Maintenance Status, Mileage, Plate Number
	VALUES 
		("1", 'T', 'F', "26845", "LR56 NET"),
		("2", 'T', 'F', "75342", "BT17 ARB"),
		("2", 'F', 'T', "80945", "FD59 URL"),
		("3", 'T', 'F', "45689", "AE10 ONG"),
		("4", 'F', 'T', "121502", "RQ14 JIU"),
		("5", 'T', 'F', "36234", "ZT69 RUN"),
		("5", 'T', 'F', "23961", "IP70 LRU"),
		("6", 'T', 'F', "72987", "WE65 BUT"),
		("7", 'F', 'T', "120885", "DF57 JBY"),
		("7", 'T', 'F', "97002", "QA62 XYZ"),
		("8", 'T', 'F', "12034", "FN22 WEE"),
		("9", 'T', 'F', "67004", "TY15 NVM"),
		("10", 'F', 'T', "58112", "PR17 XTR"),
		("11", 'T', 'F', "34755", "SD66 DCG"),
		("11", 'F', 'T', "34755", "IK66 WOI"),
		("12", 'F', 'T', "145671", "YE64 BOI"),
		("10", 'T', 'F', "34755", "AS18 YUM"),
		("13", 'T', 'F', "34512", "QP17 BAK"),
		("13", 'T', 'F', "55300", "SY67 ZUC"),
		("14", 'T', 'F', "15983", "SX72 GUM"),
		("15", 'T', 'F', "10234", "UN71 JON"),
		("15", 'T', 'F', "25854", "CT67 MAX"),
		("15", 'F', 'T', "87045", "LM64 LUK"),
		("16", 'T', 'F', "80432", "GG56 EZP"),
		("16", 'T', 'F', "45368", "CS64 GOO"),
		("17", 'T', 'F', "19367", "MC69 MLG"),
		("18", 'T', 'F', "89236", "QX14 UIS"),
		("18", 'F', 'T', "34521", "NG63 QWC"),
		("18", 'F', 'T', "18932", "LH13 ZUQ"),
		("19", 'T', 'F', "41115", "DB68 COC"),
		("19", 'F', 'T', "63256", "VB19 SUS");

INSERT INTO Faculty_Members(nameMember, D_idDepartment, 
	mileageMember, password, userType)
    VALUES
		("John Smith", 1, 267, "SmithJ!!!", 'regular'),
        ("Ben Smith", 2, 47, "SmithB!!!", 'regular'),
        ("Derrick Ntim", 3, 593, "NtimD!!!", 'admin'),
        ("Yarris Honour", 4, 1212, "HonourY!!!", 'regular'),
        ("Alan Turing", 5, 322, "TuringA!!!", 'regular'),
        ("William Quince", 6, 864, "QuinceW!!!", 'regular'),
        ("Vibin Dewan", 7, 231, "DewanV!!!", 'regular'),
        ("Amy Wood", 8, 432, "WoodA!!!", 'regular'),
        ("Oliver Tombling", 9, 164, "TomblingO!!!", 'admin'),
        ("Calum Hunt", 10, 862, "HuntC!!!", 'admin'),
        ("Ralf Burns", 11, 268, "BurnsR!!!", 'regular'),
        ("Gabe Deutsch", 12, 486, "DeutschG!!!", 'regular'),
        ("Lexx Little", 13, 342, "LittleL!!!", 'regular'),
        ("Olive Turner", 14, 653, "TurnerO!!!", 'regular'),
        ("Niamh Moran", 15, 864, "MoranN!!!", 'regular'),
        ("Thomas Baiting", 16, 164, "BaitingT!!!", 'regular'),
        ("Max Wilkinson", 17, 999, "WilkinsonM!!!", 'admin'),
        ("Jack Honour", 18, 998, "HonourJ!!!", 'admin'),
        ("Raul Menendez", 19, 413, "MenendezR!!!", 'regular'),
        ("Damien Hird", 20, 913, "HirdD!!!", 'regular'),
        ("Luka Wilkinson", 21, 764, "WilkinsonL!!!", 'admin'),
        ("Crystal Fenton", 22, 234, "FentonC!!!", 'regular'),
        ("Ella Brown", 23, 543, "BrownE!!!", 'regular'),
        ("Grace Black", 24, 982, "BlackG!!!", 'admin'),
        ("Jana Kassem", 25, 643, "KassemJ!!!", 'admin'),
        ("Anthony Wokanoka", 26, 854, "WokanokaA!!!", 'regular'),
        ("Ahmed Caserkar", 27, 458, "CaserkarA!!!", 'regular'),
        ("Alexander Gabins", 28, 333, "GabinsA!!!", 'regular'),
        ("Alfie Sugdon", 29, 137, "SugdonA!!!", 'regular'),
        ("Tim Collow", 30, 1001, "CollowT!!!", 'regular');
        
INSERT INTO Departments(thisYearMileage, nameDepartment)
	VALUES
		(12534, "Mathematics"),
        (5432, "Philisophy"),
        (25677, "English"),
        (75422, "Art"),
        (77422, "Music"),
        (8322, "Performing Arts"),
        (34442, "Engineering"),
        (78996, "Computer Science"),
        (22344, "Education"),
        (56654, "Law"),
        (23444, "Business"),
        (12534, "Medicine"),
        (34521, "Languages"),
        (56443, "Chemistry"),
        (88764, "Physics"),
        (22455, "Biology"),
        (24565, "Religious Studies"),
        (36742, "Pharmacology"),
        (78644, "Biomedical Science"),
        (77544, "Aerospace Engineering"),
        (33556, "Sports Science"),
        (66777, "Urban Planning"),
        (88664, "Agricultural Science"),
        (22344, "Media Studies"),
        (77886, "Architecture"),
        (46887, "Photography"),
        (77654, "Graphic Design"),
        (77553, "Event Management"),
        (56775, "Games Computing"),
        (77543, "Criminology"),
        (65432, "Forensics");

INSERT INTO VMC_Employees(employeeName, payrollNumber)
	VALUES
		("Robert Deen", 1),
        ("Harry Francis", 2),
        ("Ellie Baker", 3),
        ("Taylor Dawson", 4),
		("Iman Gadzhi", 5),
        ("Tony Feurgerson", 6),
        ("Mike Tyson", 7),
        ("Anthony Joshuwa", 8),
        ("Paul Scott", 9),
        ("Jon Mountain", 10),
        ("Susan Brader", 11),
        ("Quin Deolo", 12),
        ("Zami Jaun", 13),
        ("Polly Camden", 14),
        ("Bob Under", 15),
        ("Ben Dover", 16),
        ("Anne Robbie", 17),
        ("Tanner Jackson", 18),
        ("Jack Drake", 19),
        ("Nathan Drake", 20),
        ("Sulivan O'leary", 21),
        ("Piotr Karvail", 22),
        ("Sean Ellington", 23),
        ("Alfie Fox", 24),
        ("Robert Greene", 25),
        ("Alec Brader", 26),
        ("Alexander Kurups", 27),
        ("Christopher Robinson", 28),
        ("Matthew Fauk", 29),
        ("Andy Walker", 30);

INSERT INTO Checkout_Form(V_idVehicle, FM_idFacMember, 
	vehicleDamage, usedEquipment, VMCE_idVMC_Employee, odometerAtStart)
    VALUES
		(4, 2, "Scratch on bonet", "N/A", 26, 120564),
        (15, 8, "N/A", "N/A", 26, 86978),
        (12, 12, "Loose wheel nut", "Wheel Wrench", 26, 32075),
        (1, 3, "N/A", "N/A", 27, 25679),
        (4, 18, "N/A", "N/A", 26, 20342),
        (28, 2, "Scratch on bonet", "N/A", 2, 45321),
        (30, 23, "Loose wheel nut", "Wheel Wrench", 8, 26994),
        (25, 19, "N/A", "N/A", 29, 22453),
        (31, 14, "N/A", "N/A", 6, 24463),
        (25, 11, "Broken seat adjustment, driver side", "N/A", 29, 24483),
        (22, 19, "Radio sound adjustment broken", "N/A", 23, 22453),
        (14, 19, "N/A", "N/A", 21, 20452),
        (5, 9, "N/A", "N/A", 30, 2453),
        (1, 3, "N/A", "N/A", 29, 18453),
        (16, 11, "N/A", "N/A", 1, 34189),
        (7, 23, "N/A", "N/A", 19, 63453),
        (5, 7, "N/A", "N/A", 4, 36123),
        (25, 17, "Dent in rear door", "N/A", 17, 25553),
        (6, 10, "Windowscreen chip", "N/A", 3, 2453),
        (6, 20, "Windowscreen chip", "N/A", 29, 4001),
        (6, 21, "N/A", "N/A", 28, 40203),
        (17, 7, "Hole in grille", "N/A", 4, 35983),
        (2, 30, "N/A", "N/A", 29, 34453),
        (23, 13, "N/A", "N/A", 11, 26253),
        (9, 9, "N/A", "N/A", 8, 12453),
        (5, 1, "N/A", "N/A", 9, 6453),
        (22, 24, "N/A", "N/A", 21, 22633),
        (8, 3, "N/A", "N/A", 2, 32413),
        (11, 13, "N/A", "N/A", 1, 29133),
        (29, 23, "N/A", "N/A", 28, 41411);
        
INSERT INTO Trip_Completion_Form(CF_idCheckout_Form, startLocation,
	finishLocation, odometerAtFinish, maintenanceComplaints, NCUCardNumber,
    litresFuelPurchased, recieptAttatchIfFuelUsage)
    -- Per Litre: Petrol £1.50, Diesel £1.60p
    VALUES
		(1, "NCU", "NCU", 120709, "N/A", "1234 5678 9012 3456", 24, "T"),
        (2, "NCU", "VMC", 87060, "Steering wheel drifing to left", "1234 5678 9012 3456", 32, "T"),
        (3, "NCU", "NCU", 32174, "Striring wheel drifing to right", "1234 5678 9012 3456", 11, "T"),
        (4, "NCU", "NCU", 25780,"N/A", "1234 5678 9012 3456", 53, "T"),
        (5, "NCU", "VMC", 20462, "N/A", "1234 5678 9012 3456", 65, "T"),
        (6, "NCU", "NCU", 45451,"N/A", "1234 5678 9012 3456", 17, "T"),
        (7, "VMC", "VMC", 27082, "N/A", "1234 5678 9012 3456", 73, "T"),
        (8, "NCU", "NCU", 22530, "N/A", "1234 5678 9012 3456", 93, "T"),
        (9, "NCU", "NCU", 24558, "N/A", "1234 5678 9012 3456", 101, "T"),
        (10, "VMC", "NCU", 24527, "N/A", "N/A", 0, "F"),
        (11, "NCU", "NCU", 22542, "Passenger seat loose, moving everywhere", "1234 5678 9012 3456", 45, "T"),
        (12, "NCU", "NCU", 20557, "Driver side headlight need replacing", "1234 5678 9012 3456", 43, "T"),
        (13, "VMC", "NCU", 2559, "N/A", "1234 5678 9012 3456", 37, "T"),
        (14, "NCU", "NCU", 18654, "Driver side fog light need replacing", "1234 5678 9012 3456", 84, "T"),
        (15, "NCU", "NCU", 34339, "N/A", "1234 5678 9012 3456", 53, "T"),
        (16, "NCU", "VMC", 63478, "Passenger side broken brake light", "N/A", 0, "F"),
        (17, "VMC", "NCU", 36249, "N/A", "1234 5678 9012 3456", 12, "T"),
        (18, "NCU", "VMC", 25718, "N/A", "1234 5678 9012 3456", 73, "T"),
        (19, "NCU", "NCU", 2703, "N/A", "1234 5678 9012 3456", 78, "T"),
        (20, "NCU", "NCU", 4157, "N/A", "1234 5678 9012 3456", 56, "T"),
        (21, "VMC", "VMC", 40351, "N/A", "1234 5678 9012 3456", 49, "T"),
        (22, "NCU", "NCU", "36001", "Engine light on dash", "N/A", 0, "F"),
        (23, "NCU", "NCU", "34552", "Radio stations not configured", "1234 5678 9012 3456", 77, "T"),
        (24, "NCU", "VMC", "26395", "N/A", "1234 5678 9012 3456", 33, "T"),
        (25, "NCU", "NCU", "12616", "N/A", "1234 5678 9012 3456", 53, "T"),
        (26, "NCU", "NCU", "6627", "Tyre pressure light on dash", "1234 5678 9012 3456", 64, "T"),
        (27, "NCU", "VMC", "22815", "N/A", "1234 5678 9012 3456", 64, "T"),
        (28, "NCU", "NCU", "32616", "N/A", "1234 5678 9012 3456", 78, "T"),
        (29, "NCU", "VMC", "29245", "N/A", "1234 5678 9012 3456", 32, "T"),
        (30, "NCU", "NCU", "41499", "N/A", "1234 5678 9012 3456", 42, "T");

CALL Create_Reservation_Form('2024-2-22', 'Sedan', 'Bletchley Park', 1);
CALL Create_Maintenance_Log(1, 'Annual Safety Check', 'Check brakes,Inspect tires', 2, 'Brake Pads, Tire');




