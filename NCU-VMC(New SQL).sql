-- MySQL Workbench Forward Engineering

SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';

-- -----------------------------------------------------
-- Schema NCU-VMC
-- -----------------------------------------------------

-- -----------------------------------------------------
-- Schema NCU-VMC
-- -----------------------------------------------------
CREATE SCHEMA IF NOT EXISTS `NCU-VMC` DEFAULT CHARACTER SET utf8mb3 ;
USE `NCU-VMC` ;

-- -----------------------------------------------------
-- Table `NCU-VMC`.`Vehicle_Models`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `NCU-VMC`.`Vehicle_Models` (
  `idModel` INT NOT NULL AUTO_INCREMENT,
  `vehicleType` VARCHAR(20) NOT NULL,
  `manufacturer` VARCHAR(25) NULL DEFAULT 'N/A',
  `modelName` VARCHAR(45) NULL DEFAULT 'N/A',
  PRIMARY KEY (`idModel`))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `NCU-VMC`.`Vehicles`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `NCU-VMC`.`Vehicles` (
  `idVehicle` INT NOT NULL AUTO_INCREMENT,
  `avaliableNow` ENUM('T', 'F') NOT NULL,
  `maintenanceComplete` ENUM('T', 'F') NULL DEFAULT 'T',
  `currentOdometer` INT NOT NULL,
  `licensePlate` VARCHAR(8) NOT NULL COMMENT 'UK license plate limit = 8 (including space) ',
  `VM_idModel` INT NOT NULL,
  PRIMARY KEY (`idVehicle`, `VM_idModel`),
  INDEX `fk_Vehicles_Vehicle_Models1_idx` (`VM_idModel` ASC) VISIBLE,
  CONSTRAINT `fk_Vehicles_Vehicle_Models1`
    FOREIGN KEY (`VM_idModel`)
    REFERENCES `NCU-VMC`.`Vehicle_Models` (`idModel`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb3;


-- -----------------------------------------------------
-- Table `NCU-VMC`.`Vehicle_Maintenance_Summary`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `NCU-VMC`.`Vehicle_Maintenance_Summary` (
  `idVehicleMaintainSummary` INT NOT NULL,
  PRIMARY KEY (`idVehicleMaintainSummary`))
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb3;


-- -----------------------------------------------------
-- Table `NCU-VMC`.`Maintenance_Form`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `NCU-VMC`.`Maintenance_Form` (
  `idMaintainanceForm` INT NOT NULL COMMENT 'Pre-numbered log number, not auto-incremented',
  `V_idVehicle` INT NOT NULL,
  `maintenanceRequired` VARCHAR(85) NOT NULL,
  `logEntryDate` DATE NOT NULL,
  `backToServiceDate` DATE NOT NULL,
  `formCompletionDate` DATE NOT NULL,
  `VMS_idVehicleMaintainSummary` INT NOT NULL,
  `maintenanceTasks` VARCHAR(85) NULL DEFAULT 'Overall Maintenance Check' COMMENT 'Default value set because, the tasks aren’t needed to be specified as they would be in the ‘Maintenance_Details_Form’ table',
  PRIMARY KEY (`idMaintainanceForm`, `V_idVehicle`, `VMS_idVehicleMaintainSummary`),
  INDEX `fk_Maintainance_Form_NCU_Vehicles1_idx` (`V_idVehicle` ASC) VISIBLE,
  INDEX `fk_Maintenance_Form_Vehicle_Maintenance_Summary1_idx` (`VMS_idVehicleMaintainSummary` ASC) VISIBLE,
  CONSTRAINT `fk_Maintainance_Form_NCU_Vehicles1`
    FOREIGN KEY (`V_idVehicle`)
    REFERENCES `NCU-VMC`.`Vehicles` (`idVehicle`),
  CONSTRAINT `fk_Maintenance_Form_Vehicle_Maintenance_Summary1`
    FOREIGN KEY (`VMS_idVehicleMaintainSummary`)
    REFERENCES `NCU-VMC`.`Vehicle_Maintenance_Summary` (`idVehicleMaintainSummary`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb3;


-- -----------------------------------------------------
-- Table `NCU-VMC`.`Mechanics`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `NCU-VMC`.`Mechanics` (
  `idMechanic` INT NOT NULL AUTO_INCREMENT,
  `nameMechanic` VARCHAR(60) NOT NULL,
  `idPayroll` INT NOT NULL,
  `InspectionAuthorisation` ENUM('T', 'F') NOT NULL,
  PRIMARY KEY (`idMechanic`))
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb3;


-- -----------------------------------------------------
-- Table `NCU-VMC`.`Parts_Inventory`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `NCU-VMC`.`Parts_Inventory` (
  `typePart` INT NOT NULL,
  `idPart` VARCHAR(45) NOT NULL,
  `quantity` INT NOT NULL,
  `minQuantityOnHand` ENUM('T', 'F') NULL DEFAULT 'F' COMMENT 'If minQuantityOnHand == T, order more parts ',
  PRIMARY KEY (`idPart`))
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb3;


-- -----------------------------------------------------
-- Table `NCU-VMC`.`Parts_Usage_Form`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `NCU-VMC`.`Parts_Usage_Form` (
  `idPartsForm` INT NOT NULL AUTO_INCREMENT,
  `partUsed` ENUM('T', 'F') NOT NULL,
  `PI_idPart` VARCHAR(45) NOT NULL,
  `partsManagerName` VARCHAR(45) NOT NULL,
  `quantityUsed` INT NOT NULL,
  `usageDate` DATE NOT NULL,
  PRIMARY KEY (`idPartsForm`, `PI_idPart`),
  INDEX `fk_Parts_Usage_Parts_Inventory1_idx` (`PI_idPart` ASC) VISIBLE,
  CONSTRAINT `fk_Parts_Usage_Parts_Inventory1`
    FOREIGN KEY (`PI_idPart`)
    REFERENCES `NCU-VMC`.`Parts_Inventory` (`idPart`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb3;


-- -----------------------------------------------------
-- Table `NCU-VMC`.`Maintenance_Details_Form`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `NCU-VMC`.`Maintenance_Details_Form` (
  `idMaintenanceDetailsForm` INT NOT NULL,
  `MF_idMaintenanceForm` INT NOT NULL,
  `matainanceItem` VARCHAR(60) NOT NULL,
  `partsUsed` VARCHAR(85) NOT NULL,
  `M_idMechanic` INT NOT NULL,
  `PUF_idPartsForm` INT NOT NULL,
  PRIMARY KEY (`idMaintenanceDetailsForm`, `MF_idMaintenanceForm`, `M_idMechanic`, `PUF_idPartsForm`),
  INDEX `fk_Maintainance_Details_Form_Maintainance_Form1_idx` (`MF_idMaintenanceForm` ASC) VISIBLE,
  INDEX `fk_Maintainance_Details_Form_Mechanics1_idx` (`M_idMechanic` ASC) VISIBLE,
  INDEX `fk_Maintenance_Details_Form_Parts_Usage_Form1_idx` (`PUF_idPartsForm` ASC) VISIBLE,
  CONSTRAINT `fk_Maintainance_Details_Form_Maintainance_Form1`
    FOREIGN KEY (`MF_idMaintenanceForm`)
    REFERENCES `NCU-VMC`.`Maintenance_Form` (`idMaintainanceForm`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_Maintainance_Details_Form_Mechanics1`
    FOREIGN KEY (`M_idMechanic`)
    REFERENCES `NCU-VMC`.`Mechanics` (`idMechanic`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_Maintenance_Details_Form_Parts_Usage_Form1`
    FOREIGN KEY (`PUF_idPartsForm`)
    REFERENCES `NCU-VMC`.`Parts_Usage_Form` (`idPartsForm`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `NCU-VMC`.`Maintenance_Bills`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `NCU-VMC`.`Maintenance_Bills` (
  `idBill` INT NOT NULL AUTO_INCREMENT,
  `payee` VARCHAR(60) NOT NULL,
  `payer` VARCHAR(60) NOT NULL,
  `tax` FLOAT NOT NULL,
  `beforeTaxTotal` FLOAT NOT NULL,
  `total` FLOAT NOT NULL,
  `accountNumber` INT NOT NULL,
  `MDF_idMaintenanceDetailsForm` INT NOT NULL,
  PRIMARY KEY (`idBill`, `MDF_idMaintenanceDetailsForm`),
  INDEX `fk_Maintanance_Bills_Maintainance_Details_Form1_idx` (`MDF_idMaintenanceDetailsForm` ASC) VISIBLE,
  CONSTRAINT `fk_Maintanance_Bills_Maintainance_Details_Form1`
    FOREIGN KEY (`MDF_idMaintenanceDetailsForm`)
    REFERENCES `NCU-VMC`.`Maintenance_Details_Form` (`idMaintenanceDetailsForm`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb3;


-- -----------------------------------------------------
-- Table `NCU-VMC`.`Bookings`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `NCU-VMC`.`Bookings` (
  `idBooking` INT NOT NULL,
  `beingUsed` ENUM('T', 'F') NULL DEFAULT 'F',
  `startDate` DATE NOT NULL,
  `endDate` DATE NOT NULL,
  `V_idVehicle` INT NOT NULL,
  PRIMARY KEY (`idBooking`, `V_idVehicle`),
  INDEX `fk_Bookings_Vehicles1_idx` (`V_idVehicle` ASC) VISIBLE,
  CONSTRAINT `fk_Bookings_Vehicles1`
    FOREIGN KEY (`V_idVehicle`)
    REFERENCES `NCU-VMC`.`Vehicles` (`idVehicle`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb3;


-- -----------------------------------------------------
-- Table `NCU-VMC`.`Departments`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `NCU-VMC`.`Departments` (
  `idDepartment` INT NOT NULL AUTO_INCREMENT,
  `thisYearMileage` INT NULL,
  `nameDepartment` VARCHAR(60) NULL,
  PRIMARY KEY (`idDepartment`))
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb3;


-- -----------------------------------------------------
-- Table `NCU-VMC`.`Faculty_Members`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `NCU-VMC`.`Faculty_Members` (
  `idFacMember` INT NOT NULL AUTO_INCREMENT,
  `nameMember` VARCHAR(60) NOT NULL,
  `D_idDepartment` INT NOT NULL,
  `mileageMember` INT NULL DEFAULT 0,
  `password` VARCHAR(60) NOT NULL,
  `userType` ENUM('regular', 'admin') NOT NULL,
  PRIMARY KEY (`idFacMember`, `D_idDepartment`),
  INDEX `fk_Faculty_Members_Departments1_idx` (`D_idDepartment` ASC) VISIBLE,
  CONSTRAINT `fk_Faculty_Members_Departments1`
    FOREIGN KEY (`D_idDepartment`)
    REFERENCES `NCU-VMC`.`Departments` (`idDepartment`))
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb3;


-- -----------------------------------------------------
-- Table `NCU-VMC`.`Member_Bookings`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `NCU-VMC`.`Member_Bookings` (
  `FM_idFacMember` INT NOT NULL,
  `B_idBookings` INT NOT NULL,
  PRIMARY KEY (`FM_idFacMember`, `B_idBookings`),
  INDEX `fk_Faculty Members_has_Bookings_Bookings1_idx` (`B_idBookings` ASC) VISIBLE,
  INDEX `fk_Faculty Members_has_Bookings_Faculty Members_idx` (`FM_idFacMember` ASC) VISIBLE,
  CONSTRAINT `fk_Faculty Members_has_Bookings_Bookings1`
    FOREIGN KEY (`B_idBookings`)
    REFERENCES `NCU-VMC`.`Bookings` (`idBooking`),
  CONSTRAINT `fk_Faculty Members_has_Bookings_Faculty Members`
    FOREIGN KEY (`FM_idFacMember`)
    REFERENCES `NCU-VMC`.`Faculty_Members` (`idFacMember`))
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb3;


-- -----------------------------------------------------
-- Table `NCU-VMC`.`Mileage_Report`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `NCU-VMC`.`Mileage_Report` (
  `idMileageReport` INT NOT NULL AUTO_INCREMENT,
  `mileageVehicle` INT NOT NULL DEFAULT 0,
  `mileageDepartment` INT NOT NULL DEFAULT 0,
  `mileageMember` INT NOT NULL DEFAULT 0,
  `V_idVehicle` INT NOT NULL,
  `FM_idFacMember` INT NOT NULL,
  `FM_D_idDepartment` INT NOT NULL,
  PRIMARY KEY (`idMileageReport`, `V_idVehicle`, `FM_idFacMember`, `FM_D_idDepartment`),
  INDEX `fk_Mileage_Report_Vehicles1_idx` (`V_idVehicle` ASC) VISIBLE,
  INDEX `fk_Mileage_Report_Faculty_Members1_idx` (`FM_idFacMember` ASC, `FM_D_idDepartment` ASC) VISIBLE,
  CONSTRAINT `fk_Mileage_Report_Vehicles1`
    FOREIGN KEY (`V_idVehicle`)
    REFERENCES `NCU-VMC`.`Vehicles` (`idVehicle`),
  CONSTRAINT `fk_Mileage_Report_Faculty_Members1`
    FOREIGN KEY (`FM_idFacMember` , `FM_D_idDepartment`)
    REFERENCES `NCU-VMC`.`Faculty_Members` (`idFacMember` , `D_idDepartment`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb3;


-- -----------------------------------------------------
-- Table `NCU-VMC`.`Parts_Usage_Report_has_Parts_Usage`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `NCU-VMC`.`Parts_Usage_Report_has_Parts_Usage` (
  `PU_R_idPartsUsageReport` INT NOT NULL,
  `PU_idPart` INT NOT NULL,
  `PU_MD_idMaintananceDetails` INT NOT NULL,
  INDEX `fk_Parts_Usage_Report_has_Parts_Usage_Parts_Usage1_idx` (`PU_idPart` ASC, `PU_MD_idMaintananceDetails` ASC) VISIBLE,
  INDEX `fk_Parts_Usage_Report_has_Parts_Usage_Parts_Usage_Report1_idx` (`PU_R_idPartsUsageReport` ASC) VISIBLE,
  CONSTRAINT `fk_Parts_Usage_Report_has_Parts_Usage_Parts_Usage1`
    FOREIGN KEY (`PU_idPart`)
    REFERENCES `NCU-VMC`.`Parts_Usage_Form` (`idPartsForm`))
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb3;


-- -----------------------------------------------------
-- Table `NCU-VMC`.`Reservation_Forms`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `NCU-VMC`.`Reservation_Forms` (
  `idReservation` INT NOT NULL,
  `expectedDeparture` DATE NOT NULL,
  `vehicleType` VARCHAR(15) NOT NULL,
  `destination` VARCHAR(45) NOT NULL,
  `FM_idFacMember` INT NOT NULL COMMENT 'Authorised faculty member',
  PRIMARY KEY (`idReservation`, `FM_idFacMember`),
  INDEX `fk_Reservation_Forms_Faculty_Members1_idx` (`FM_idFacMember` ASC) VISIBLE,
  CONSTRAINT `fk_Reservation_Forms_Faculty_Members1`
    FOREIGN KEY (`FM_idFacMember`)
    REFERENCES `NCU-VMC`.`Faculty_Members` (`idFacMember`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb3;


-- -----------------------------------------------------
-- Table `NCU-VMC`.`Vehicle_Revenue_Report`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `NCU-VMC`.`Vehicle_Revenue_Report` (
  `idRevenueReport` INT NOT NULL AUTO_INCREMENT,
  `V_idVehicle` INT NOT NULL,
  `revenueMade` DECIMAL NULL,
  PRIMARY KEY (`idRevenueReport`, `V_idVehicle`),
  INDEX `fk_Revenue_Report_Vehicles1_idx` (`V_idVehicle` ASC) VISIBLE,
  CONSTRAINT `fk_Revenue_Report_Vehicles1`
    FOREIGN KEY (`V_idVehicle`)
    REFERENCES `NCU-VMC`.`Vehicles` (`idVehicle`))
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb3;


-- -----------------------------------------------------
-- Table `NCU-VMC`.`VMC_Employees`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `NCU-VMC`.`VMC_Employees` (
  `idVMC_Employee` INT NOT NULL AUTO_INCREMENT,
  `employeeName` VARCHAR(45) NOT NULL,
  `payrollNumber` INT NOT NULL,
  PRIMARY KEY (`idVMC_Employee`))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `NCU-VMC`.`Checkout_Form`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `NCU-VMC`.`Checkout_Form` (
  `idCheckout_Form` INT NOT NULL AUTO_INCREMENT,
  `vehicleDamage` VARCHAR(45) NULL DEFAULT 'N/A',
  `usedEquipment` VARCHAR(45) NULL DEFAULT 'N/A',
  `V_idVehicle` INT NOT NULL,
  `odometerAtStart` INT ZEROFILL NOT NULL,
  `FM_idFacMember` INT NOT NULL,
  `VMCE_idVMC_Employee` INT NOT NULL,
  PRIMARY KEY (`idCheckout_Form`, `V_idVehicle`, `FM_idFacMember`, `VMCE_idVMC_Employee`),
  INDEX `fk_Checkout_Form_Vehicles1_idx` (`V_idVehicle` ASC) VISIBLE,
  INDEX `fk_Checkout_Form_Faculty_Members1_idx` (`FM_idFacMember` ASC) VISIBLE,
  INDEX `fk_Checkout_Form_VMC_Employees1_idx` (`VMCE_idVMC_Employee` ASC) VISIBLE,
  CONSTRAINT `fk_Checkout_Form_Vehicles1`
    FOREIGN KEY (`V_idVehicle`)
    REFERENCES `NCU-VMC`.`Vehicles` (`idVehicle`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_Checkout_Form_Faculty_Members1`
    FOREIGN KEY (`FM_idFacMember`)
    REFERENCES `NCU-VMC`.`Faculty_Members` (`idFacMember`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_Checkout_Form_VMC_Employees1`
    FOREIGN KEY (`VMCE_idVMC_Employee`)
    REFERENCES `NCU-VMC`.`VMC_Employees` (`idVMC_Employee`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `NCU-VMC`.`Trip_Completion_Form`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `NCU-VMC`.`Trip_Completion_Form` (
  `idTripCompletionForm` INT NOT NULL AUTO_INCREMENT,
  `startLocation` VARCHAR(45) NOT NULL,
  `finishLocation` VARCHAR(45) NOT NULL,
  `litresFuelPurchased` INT NULL DEFAULT 0,
  `maintenanceComplaints` VARCHAR(60) NOT NULL,
  `odometerAtFinish` INT NOT NULL COMMENT 'Mileage counter\n',
  `NCUCardNumber` VARCHAR(19) NULL DEFAULT 'N/A',
  `recieptAttatchIfFuelUsage` ENUM('T', 'F') NULL DEFAULT 'F',
  `CF_idCheckout_Form` INT NOT NULL,
  PRIMARY KEY (`idTripCompletionForm`, `CF_idCheckout_Form`),
  INDEX `fk_Trip-Completion_Form_Checkout_Form1_idx` (`CF_idCheckout_Form` ASC) VISIBLE,
  CONSTRAINT `fk_Trip-Completion_Form_Checkout_Form1`
    FOREIGN KEY (`CF_idCheckout_Form`)
    REFERENCES `NCU-VMC`.`Checkout_Form` (`idCheckout_Form`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `NCU-VMC`.`Department_Revenue_Report`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `NCU-VMC`.`Department_Revenue_Report` (
  `idDepartment_Revenue_Report` INT NOT NULL AUTO_INCREMENT,
  `Departments_idDepartment` INT NOT NULL,
  `revenueMade` DECIMAL NULL,
  PRIMARY KEY (`idDepartment_Revenue_Report`, `Departments_idDepartment`),
  INDEX `fk_Department_Revenue_Report_Departments1_idx` (`Departments_idDepartment` ASC) VISIBLE,
  CONSTRAINT `fk_Department_Revenue_Report_Departments1`
    FOREIGN KEY (`Departments_idDepartment`)
    REFERENCES `NCU-VMC`.`Departments` (`idDepartment`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `NCU-VMC`.`Parts_Orders`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `NCU-VMC`.`Parts_Orders` (
  `idParts_Orders` INT NOT NULL,
  `quantity` INT NOT NULL,
  `orderDate` DATE NOT NULL,
  `PI_idPart` VARCHAR(45) NOT NULL,
  PRIMARY KEY (`idParts_Orders`, `PI_idPart`),
  INDEX `fk_Parts_Orders_Parts_Inventory1_idx` (`PI_idPart` ASC) VISIBLE,
  CONSTRAINT `fk_Parts_Orders_Parts_Inventory1`
    FOREIGN KEY (`PI_idPart`)
    REFERENCES `NCU-VMC`.`Parts_Inventory` (`idPart`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;
