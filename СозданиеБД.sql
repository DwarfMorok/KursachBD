-- ============================================
-- СОЗДАНИЕ И ПОЛНОЕ НАПОЛНЕНИЕ БАЗЫ ДАННЫХ
-- "ПРОДАЖА АВИАБИЛЕТОВ"
-- ============================================

-- 1. УДАЛЕНИЕ СТАРОЙ БАЗЫ ДАННЫХ
IF DB_ID('AirlineTickets') IS NOT NULL
BEGIN
    ALTER DATABASE AirlineTickets SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE AirlineTickets;
END
GO

-- 2. СОЗДАНИЕ НОВОЙ БАЗЫ ДАННЫХ
CREATE DATABASE AirlineTickets;
GO

USE AirlineTickets;
GO

-- 3. СОЗДАНИЕ ТАБЛИЦ
-- 3.1. Авиакомпании
CREATE TABLE Airlines (
    AirlineId INT IDENTITY(1,1) PRIMARY KEY,
    AirlineName NVARCHAR(100) NOT NULL,
    AirlineCode CHAR(2) NOT NULL UNIQUE,
    Country NVARCHAR(50) NOT NULL,
    ContactPhone VARCHAR(20),
    Email NVARCHAR(100),
    Website NVARCHAR(100)
);

-- 3.2. Аэропорты
CREATE TABLE Airports (
    AirportId INT IDENTITY(1,1) PRIMARY KEY,
    AirportCode CHAR(3) NOT NULL UNIQUE,
    AirportName NVARCHAR(150) NOT NULL,
    City NVARCHAR(100) NOT NULL,
    Country NVARCHAR(50) NOT NULL,
    TimeZone NVARCHAR(50) NOT NULL,
    Latitude DECIMAL(10,6),
    Longitude DECIMAL(10,6)
);

-- 3.3. Классы обслуживания
CREATE TABLE FareClasses (
    FareClassId INT IDENTITY(1,1) PRIMARY KEY,
    ClassName NVARCHAR(50) NOT NULL UNIQUE,
    ClassCode CHAR(1) NOT NULL UNIQUE,
    Multiplier DECIMAL(3,2) NOT NULL DEFAULT 1.0,
    BaggageAllowance NVARCHAR(50) NOT NULL,
    MealIncluded BIT NOT NULL DEFAULT 1,
    PriorityBoarding BIT NOT NULL DEFAULT 0,
    LoungeAccess BIT NOT NULL DEFAULT 0
);

-- 3.4. Самолеты
CREATE TABLE Aircrafts (
    AircraftId INT IDENTITY(1,1) PRIMARY KEY,
    AirlineId INT NOT NULL,
    Model NVARCHAR(100) NOT NULL,
    RegistrationNumber VARCHAR(20) NOT NULL UNIQUE,
    Manufacturer NVARCHAR(50) NOT NULL,
    TotalSeats INT NOT NULL,
    EconomySeats INT NOT NULL,
    BusinessSeats INT NOT NULL,
    FirstClassSeats INT NOT NULL,
    YearOfManufacture INT NOT NULL,
    FOREIGN KEY (AirlineId) REFERENCES Airlines(AirlineId),
    CONSTRAINT CHK_Seats_Total CHECK (TotalSeats = EconomySeats + BusinessSeats + FirstClassSeats),
    CONSTRAINT CHK_Year CHECK (YearOfManufacture BETWEEN 1990 AND YEAR(GETDATE()))
);

-- 3.5. Рейсы
CREATE TABLE Flights (
    FlightId INT IDENTITY(1,1) PRIMARY KEY,
    FlightNumber VARCHAR(10) NOT NULL,
    AirlineId INT NOT NULL,
    DepartureAirportId INT NOT NULL,
    ArrivalAirportId INT NOT NULL,
    AircraftId INT NOT NULL,
    ScheduledDeparture DATETIME2 NOT NULL,
    ScheduledArrival DATETIME2 NOT NULL,
    ActualDeparture DATETIME2 NULL,
    ActualArrival DATETIME2 NULL,
    BasePrice DECIMAL(10,2) NOT NULL,
    Status NVARCHAR(20) NOT NULL DEFAULT 'Scheduled',
    Gate VARCHAR(10) NULL,
    Terminal VARCHAR(5) NULL,
    FOREIGN KEY (AirlineId) REFERENCES Airlines(AirlineId),
    FOREIGN KEY (DepartureAirportId) REFERENCES Airports(AirportId),
    FOREIGN KEY (ArrivalAirportId) REFERENCES Airports(AirportId),
    FOREIGN KEY (AircraftId) REFERENCES Aircrafts(AircraftId),
    CONSTRAINT CHK_Flight_Dates CHECK (ScheduledArrival > ScheduledDeparture),
    CONSTRAINT CHK_Status CHECK (Status IN ('Scheduled', 'Boarding', 'Departed', 'Arrived', 'Cancelled', 'Delayed')),
    CONSTRAINT CHK_Price CHECK (BasePrice > 0)
);

-- 3.6. Пассажиры
CREATE TABLE Passengers (
    PassengerId INT IDENTITY(1,1) PRIMARY KEY,
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    MiddleName NVARCHAR(50) NULL,
    BirthDate DATE NOT NULL,
    Gender CHAR(1) NOT NULL,
    DocumentType NVARCHAR(20) NOT NULL,
    DocumentNumber VARCHAR(20) NOT NULL UNIQUE,
    Citizenship NVARCHAR(50) NOT NULL,
    PhoneNumber VARCHAR(20),
    Email NVARCHAR(100),
    FrequentFlyerNumber VARCHAR(20) NULL,
    CONSTRAINT CHK_Gender CHECK (Gender IN ('M', 'F')),
    CONSTRAINT CHK_Age CHECK (DATEDIFF(YEAR, BirthDate, GETDATE()) BETWEEN 0 AND 120)
);

-- 3.7. Места в самолетах
CREATE TABLE Seats (
    SeatId INT IDENTITY(1,1) PRIMARY KEY,
    AircraftId INT NOT NULL,
    SeatNumber VARCHAR(4) NOT NULL,
    FareClassId INT NOT NULL,
    RowNumber INT NOT NULL,
    Position CHAR(1) NOT NULL,
    IsEmergencyExit BIT NOT NULL DEFAULT 0,
    HasExtraLegroom BIT NOT NULL DEFAULT 0,
    IsBulkhead BIT NOT NULL DEFAULT 0,
    FOREIGN KEY (AircraftId) REFERENCES Aircrafts(AircraftId),
    FOREIGN KEY (FareClassId) REFERENCES FareClasses(FareClassId),
    CONSTRAINT UQ_Seat_Per_Aircraft UNIQUE (AircraftId, SeatNumber),
    CONSTRAINT CHK_Position CHECK (Position IN ('A', 'B', 'C', 'D', 'E', 'F', 'W')),
    CONSTRAINT CHK_Row CHECK (RowNumber > 0 AND RowNumber < 100)
);

-- 3.8. Бронирования
CREATE TABLE Bookings (
    BookingId INT IDENTITY(1,1) PRIMARY KEY,
    PassengerId INT NOT NULL,
    FlightId INT NOT NULL,
    SeatId INT NOT NULL,
    BookingDate DATETIME2 NOT NULL DEFAULT GETDATE(),
    BookingStatus NVARCHAR(20) NOT NULL DEFAULT 'Pending',
    SpecialRequests NVARCHAR(500) NULL,
    CreatedBy NVARCHAR(50) NULL,
    FOREIGN KEY (PassengerId) REFERENCES Passengers(PassengerId),
    FOREIGN KEY (FlightId) REFERENCES Flights(FlightId),
    FOREIGN KEY (SeatId) REFERENCES Seats(SeatId),
    CONSTRAINT CHK_BookingStatus CHECK (BookingStatus IN ('Pending', 'Confirmed', 'Cancelled', 'NoShow', 'CheckedIn'))
);

-- 3.9. Билеты
CREATE TABLE Tickets (
    TicketId INT IDENTITY(1,1) PRIMARY KEY,
    BookingId INT NOT NULL UNIQUE,
    TicketNumber VARCHAR(13) NOT NULL UNIQUE,
    FareClassId INT NOT NULL,
    FinalPrice DECIMAL(10,2) NOT NULL,
    IssueDate DATETIME2 NOT NULL DEFAULT GETDATE(),
    IssuedBy NVARCHAR(50) NULL,
    IsElectronic BIT NOT NULL DEFAULT 1,
    FOREIGN KEY (BookingId) REFERENCES Bookings(BookingId),
    FOREIGN KEY (FareClassId) REFERENCES FareClasses(FareClassId),
    CONSTRAINT CHK_TicketNumber CHECK (LEN(TicketNumber) = 13 AND TicketNumber NOT LIKE '%[^0-9]%')
);

-- 3.10. Платежи
CREATE TABLE Payments (
    PaymentId INT IDENTITY(1,1) PRIMARY KEY,
    TicketId INT NOT NULL,
    Amount DECIMAL(10,2) NOT NULL,
    PaymentDate DATETIME2 NOT NULL DEFAULT GETDATE(),
    PaymentMethod NVARCHAR(20) NOT NULL,
    PaymentStatus NVARCHAR(20) NOT NULL DEFAULT 'Completed',
    TransactionId VARCHAR(50) NULL,
    FOREIGN KEY (TicketId) REFERENCES Tickets(TicketId),
    CONSTRAINT CHK_PaymentMethod CHECK (PaymentMethod IN ('CreditCard', 'DebitCard', 'Cash', 'BankTransfer', 'Online')),
    CONSTRAINT CHK_PaymentStatus CHECK (PaymentStatus IN ('Pending', 'Completed', 'Failed', 'Refunded'))
);

-- 3.11. Багаж
CREATE TABLE Baggage (
    BaggageId INT IDENTITY(1,1) PRIMARY KEY,
    TicketId INT NOT NULL,
    BaggageNumber VARCHAR(20) NOT NULL UNIQUE,
    Weight DECIMAL(5,2) NOT NULL,
    Type NVARCHAR(20) NOT NULL,
    Status NVARCHAR(20) NOT NULL DEFAULT 'CheckedIn',
    FOREIGN KEY (TicketId) REFERENCES Tickets(TicketId),
    CONSTRAINT CHK_Weight CHECK (Weight BETWEEN 0 AND 50),
    CONSTRAINT CHK_BaggageType CHECK (Type IN ('Hand', 'Checked', 'Oversized', 'Special'))
);
GO

-- 4. СОЗДАНИЕ ИНДЕКСОВ
CREATE INDEX IX_Flights_Departure ON Flights(DepartureAirportId, ScheduledDeparture);
CREATE INDEX IX_Flights_Arrival ON Flights(ArrivalAirportId, ScheduledArrival);
CREATE INDEX IX_Flights_Status ON Flights(Status, ScheduledDeparture);
CREATE INDEX IX_Flights_Airline ON Flights(AirlineId, ScheduledDeparture);

CREATE INDEX IX_Bookings_Passenger ON Bookings(PassengerId, BookingDate);
CREATE INDEX IX_Bookings_Flight ON Bookings(FlightId, BookingStatus);
CREATE INDEX IX_Bookings_StatusDate ON Bookings(BookingStatus, BookingDate);

CREATE INDEX IX_Passengers_Document ON Passengers(DocumentNumber);
CREATE INDEX IX_Passengers_Name ON Passengers(LastName, FirstName);
CREATE INDEX IX_Passengers_BirthDate ON Passengers(BirthDate);

CREATE INDEX IX_Tickets_Number ON Tickets(TicketNumber);
CREATE INDEX IX_Tickets_IssueDate ON Tickets(IssueDate);

CREATE INDEX IX_Seats_AircraftClass ON Seats(AircraftId, FareClassId);
GO

-- 5. НАПОЛНЕНИЕ БАЗЫ ДАННЫХ БОЛЬШИМ КОЛИЧЕСТВОМ ДАННЫХ
PRINT 'Начало наполнения базы данных...';
GO

-- 5.1. Авиакомпании (20 компаний)
INSERT INTO Airlines (AirlineName, AirlineCode, Country, ContactPhone, Email, Website) VALUES
('Аэрофлот', 'SU', 'Россия', '+74951234567', 'info@aeroflot.ru', 'www.aeroflot.ru'),
('S7 Airlines', 'S7', 'Россия', '+78007000707', 'info@s7.ru', 'www.s7.ru'),
('Уральские авиалинии', 'U6', 'Россия', '+73432888888', 'info@uralairlines.ru', 'www.uralairlines.ru'),
('Победа', 'DP', 'Россия', '+74954808080', 'info@pobeda.aero', 'www.pobeda.aero'),
('Turkish Airlines', 'TK', 'Турция', '+902123638383', 'info@turkishairlines.com', 'www.turkishairlines.com'),
('Emirates', 'EK', 'ОАЭ', '+97142444444', 'contact@emirates.com', 'www.emirates.com'),
('Lufthansa', 'LH', 'Германия', '+49696960', 'info@lufthansa.com', 'www.lufthansa.com'),
('Air France', 'AF', 'Франция', '+33892032020', 'contact@airfrance.fr', 'www.airfrance.fr'),
('British Airways', 'BA', 'Великобритания', '+442078548850', 'customer.relations@ba.com', 'www.britishairways.com'),
('Aeroflot Nord', '5N', 'Россия', '+78127035555', 'info@aeroflot-nord.ru', 'www.aeroflot-nord.ru'),
('Red Wings', 'WZ', 'Россия', '+78007778899', 'info@flyredwings.com', 'www.flyredwings.com'),
('Nordwind Airlines', 'N4', 'Россия', '+74959805555', 'info@nordwindairlines.ru', 'www.nordwindairlines.ru'),
('Azur Air', 'ZF', 'Россия', '+74959801010', 'info@azurair.ru', 'www.azurair.ru'),
('Pegasus Airlines', 'PC', 'Турция', '+902123688080', 'info@pegasus.com', 'www.flypgs.com'),
('Qatar Airways', 'QR', 'Катар', '+97440230000', 'info@qatarairways.com', 'www.qatarairways.com'),
('Singapore Airlines', 'SQ', 'Сингапур', '+6562238888', 'customer_relations@singaporeair.com', 'www.singaporeair.com'),
('AirAsia', 'AK', 'Малайзия', '+60321712000', 'support@airasia.com', 'www.airasia.com'),
('Delta Air Lines', 'DL', 'США', '+18002211212', 'customer.service@delta.com', 'www.delta.com'),
('United Airlines', 'UA', 'США', '+18008648333', 'customer.relations@united.com', 'www.united.com'),
('American Airlines', 'AA', 'США', '+18004337300', 'customer.relations@aa.com', 'www.aa.com');
GO

-- 5.2. Аэропорты (30 аэропортов)
INSERT INTO Airports (AirportCode, AirportName, City, Country, TimeZone, Latitude, Longitude) VALUES
-- Российские аэропорты
('SVO', 'Шереметьево', 'Москва', 'Россия', 'Europe/Moscow', 55.972641, 37.414581),
('DME', 'Домодедово', 'Москва', 'Россия', 'Europe/Moscow', 55.414566, 37.899494),
('LED', 'Пулково', 'Санкт-Петербург', 'Россия', 'Europe/Moscow', 59.800292, 30.262503),
('AER', 'Сочи', 'Сочи', 'Россия', 'Europe/Moscow', 43.449928, 39.956589),
('KRR', 'Пашковский', 'Краснодар', 'Россия', 'Europe/Moscow', 45.034689, 39.170539),
('OVB', 'Толмачево', 'Новосибирск', 'Россия', 'Asia/Novosibirsk', 55.012622, 82.650656),
('KHV', 'Хабаровск', 'Хабаровск', 'Россия', 'Asia/Vladivostok', 48.528044, 135.188536),
('UFA', 'Уфа', 'Уфа', 'Россия', 'Asia/Yekaterinburg', 54.557511, 55.874417),
('KZN', 'Казань', 'Казань', 'Россия', 'Europe/Moscow', 55.606186, 49.278728),
('ROV', 'Платов', 'Ростов-на-Дону', 'Россия', 'Europe/Moscow', 47.493888, 39.924444),
-- Международные аэропорты
('IST', 'Стамбул', 'Стамбул', 'Турция', 'Europe/Istanbul', 41.262222, 28.727778),
('CDG', 'Шарль де Голль', 'Париж', 'Франция', 'Europe/Paris', 49.009722, 2.547778),
('DXB', 'Дубай', 'Дубай', 'ОАЭ', 'Asia/Dubai', 25.252778, 55.364444),
('JFK', 'Кеннеди', 'Нью-Йорк', 'США', 'America/New_York', 40.639722, -73.778889),
('LHR', 'Хитроу', 'Лондон', 'Великобритания', 'Europe/London', 51.477500, -0.461389),
('FRA', 'Франкфурт', 'Франкфурт', 'Германия', 'Europe/Berlin', 50.037933, 8.562152),
('AMS', 'Схипхол', 'Амстердам', 'Нидерланды', 'Europe/Amsterdam', 52.308613, 4.763889),
('PEK', 'Пекин Столичный', 'Пекин', 'Китай', 'Asia/Shanghai', 40.079917, 116.603111),
('HND', 'Ханеда', 'Токио', 'Япония', 'Asia/Tokyo', 35.553333, 139.781111),
('SIN', 'Чанги', 'Сингапур', 'Сингапур', 'Asia/Singapore', 1.359167, 103.989444),
('BKK', 'Суварнабхуми', 'Бангкок', 'Таиланд', 'Asia/Bangkok', 13.690000, 100.750000),
('SYD', 'Кингсфорд Смит', 'Сидней', 'Австралия', 'Australia/Sydney', -33.939922, 151.175276),
('YYZ', 'Пирсон', 'Торонто', 'Канада', 'America/Toronto', 43.677500, -79.630833),
('GRU', 'Гуарульюс', 'Сан-Паулу', 'Бразилия', 'America/Sao_Paulo', -23.435556, -46.473056),
('DOH', 'Хамад', 'Доха', 'Катар', 'Asia/Qatar', 25.260556, 51.613889),
('ICN', 'Инчхон', 'Сеул', 'Южная Корея', 'Asia/Seoul', 37.460191, 126.440697),
('MAD', 'Барахас', 'Мадрид', 'Испания', 'Europe/Madrid', 40.493556, -3.566764),
('MUC', 'Мюнхен', 'Мюнхен', 'Германия', 'Europe/Berlin', 48.353783, 11.786086),
('ZRH', 'Цюрих', 'Цюрих', 'Швейцария', 'Europe/Zurich', 47.464722, 8.549167),
('FCO', 'Фьюмичино', 'Рим', 'Италия', 'Europe/Rome', 41.800278, 12.238889);
GO

-- 5.3. Классы обслуживания
INSERT INTO FareClasses (ClassName, ClassCode, Multiplier, BaggageAllowance, MealIncluded, PriorityBoarding, LoungeAccess) VALUES
('Эконом', 'E', 1.0, '1x23кг', 1, 0, 0),
('Эконом+', 'P', 1.3, '2x23кг', 1, 1, 0),
('Бизнес', 'B', 2.5, '2x32кг', 1, 1, 1),
('Первый', 'F', 4.0, '3x32кг', 1, 1, 1);
GO

-- 5.4. Самолеты (25 самолетов разных авиакомпаний)
INSERT INTO Aircrafts (AirlineId, Model, RegistrationNumber, Manufacturer, TotalSeats, EconomySeats, BusinessSeats, FirstClassSeats, YearOfManufacture) VALUES
-- Аэрофлот
(1, 'Boeing 737-800', 'VP-BGI', 'Boeing', 189, 162, 24, 3, 2015),
(1, 'Airbus A320', 'VP-BWP', 'Airbus', 180, 150, 24, 6, 2016),
(1, 'Boeing 777-300', 'VP-BGF', 'Boeing', 402, 350, 42, 10, 2017),
(1, 'Airbus A330', 'VQ-BOZ', 'Airbus', 301, 259, 30, 12, 2018),
-- S7 Airlines
(2, 'Airbus A321', 'VQ-BRE', 'Airbus', 220, 190, 24, 6, 2019),
(2, 'Boeing 737-800', 'VQ-BUZ', 'Boeing', 189, 162, 24, 3, 2020),
(2, 'Embraer 170', 'RA-02817', 'Embraer', 78, 78, 0, 0, 2018),
-- Turkish Airlines
(5, 'Boeing 777-300', 'TC-LNB', 'Boeing', 349, 300, 39, 10, 2019),
(5, 'Airbus A330', 'TC-JNC', 'Airbus', 289, 249, 30, 10, 2020),
-- Emirates
(6, 'Airbus A380', 'A6-EQI', 'Airbus', 517, 399, 76, 42, 2018),
(6, 'Boeing 777', 'A6-EGO', 'Boeing', 354, 310, 32, 12, 2019),
-- Lufthansa
(7, 'Airbus A350', 'D-AIXP', 'Airbus', 293, 247, 32, 14, 2020),
(7, 'Boeing 747-8', 'D-ABYA', 'Boeing', 364, 310, 44, 10, 2017),
-- Air France
(8, 'Airbus A350', 'F-HTYU', 'Airbus', 324, 292, 28, 4, 2021),
(8, 'Boeing 777', 'F-GSQJ', 'Boeing', 310, 280, 24, 6, 2019),
-- British Airways
(9, 'Airbus A380', 'G-XLEB', 'Airbus', 469, 303, 97, 69, 2016),
(9, 'Boeing 787', 'G-ZBKB', 'Boeing', 214, 154, 35, 25, 2020),
-- Другие российские авиакомпании
(10, 'Boeing 737-800', 'RA-73251', 'Boeing', 189, 162, 24, 3, 2014),
(11, 'Boeing 737-800', 'RA-73252', 'Boeing', 189, 162, 24, 3, 2015),
(12, 'Boeing 777-300', 'RA-73253', 'Boeing', 402, 350, 42, 10, 2016),
(13, 'Boeing 767-300', 'RA-73254', 'Boeing', 290, 250, 30, 10, 2013),
-- Международные авиакомпании
(14, 'Airbus A320', 'TC-NBA', 'Airbus', 180, 150, 24, 6, 2017),
(15, 'Boeing 777', 'A7-BAC', 'Boeing', 335, 281, 42, 12, 2021),
(16, 'Airbus A380', '9V-SKU', 'Airbus', 471, 303, 86, 82, 2019);
GO

-- 5.5. Генерация мест в самолетах (функция)
PRINT 'Генерация мест в самолетах...';
GO

CREATE PROCEDURE GenerateSeatsForAircraft
    @AircraftId INT,
    @TotalSeats INT,
    @FirstClassRows INT = 2,
    @BusinessRows INT = 6,
    @PremiumEconomyRows INT = 10,
    @SeatsPerRow INT = 6
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @SeatNumber VARCHAR(4);
    DECLARE @RowNum INT = 1;
    DECLARE @SeatCount INT = 0;
    DECLARE @Position CHAR(1);
    DECLARE @Positions CHAR(6) = 'ABCDEF';
    DECLARE @FareClassId INT;
    
    -- Удаляем старые места для этого самолета
    DELETE FROM Seats WHERE AircraftId = @AircraftId;
    
    -- Первый класс (ряды 1-2)
    WHILE @RowNum <= @FirstClassRows AND @SeatCount < @TotalSeats
    BEGIN
        DECLARE @SeatInRow INT = 1;
        WHILE @SeatInRow <= @SeatsPerRow AND @SeatCount < @TotalSeats
        BEGIN
            SET @Position = SUBSTRING(@Positions, @SeatInRow, 1);
            SET @SeatNumber = CAST(@RowNum AS VARCHAR) + @Position;
            SET @FareClassId = 4; -- Первый класс
            
            INSERT INTO Seats (AircraftId, SeatNumber, FareClassId, RowNumber, Position)
            VALUES (@AircraftId, @SeatNumber, @FareClassId, @RowNum, @Position);
            
            SET @SeatCount = @SeatCount + 1;
            SET @SeatInRow = @SeatInRow + 1;
        END
        SET @RowNum = @RowNum + 1;
    END
    
    -- Бизнес класс (следующие ряды)
    DECLARE @BusinessEndRow INT = @RowNum + @BusinessRows - 1;
    WHILE @RowNum <= @BusinessEndRow AND @SeatCount < @TotalSeats
    BEGIN
        SET @SeatInRow = 1;
        WHILE @SeatInRow <= @SeatsPerRow AND @SeatCount < @TotalSeats
        BEGIN
            SET @Position = SUBSTRING(@Positions, @SeatInRow, 1);
            SET @SeatNumber = CAST(@RowNum AS VARCHAR) + @Position;
            SET @FareClassId = 3; -- Бизнес класс
            
            INSERT INTO Seats (AircraftId, SeatNumber, FareClassId, RowNumber, Position)
            VALUES (@AircraftId, @SeatNumber, @FareClassId, @RowNum, @Position);
            
            SET @SeatCount = @SeatCount + 1;
            SET @SeatInRow = @SeatInRow + 1;
        END
        SET @RowNum = @RowNum + 1;
    END
    
    -- Эконом+ (следующие ряды)
    DECLARE @PremiumEndRow INT = @RowNum + @PremiumEconomyRows - 1;
    WHILE @RowNum <= @PremiumEndRow AND @SeatCount < @TotalSeats
    BEGIN
        SET @SeatInRow = 1;
        WHILE @SeatInRow <= @SeatsPerRow AND @SeatCount < @TotalSeats
        BEGIN
            SET @Position = SUBSTRING(@Positions, @SeatInRow, 1);
            SET @SeatNumber = CAST(@RowNum AS VARCHAR) + @Position;
            SET @FareClassId = 2; -- Эконом+
            
            INSERT INTO Seats (AircraftId, SeatNumber, FareClassId, RowNumber, Position)
            VALUES (@AircraftId, @SeatNumber, @FareClassId, @RowNum, @Position);
            
            SET @SeatCount = @SeatCount + 1;
            SET @SeatInRow = @SeatInRow + 1;
        END
        SET @RowNum = @RowNum + 1;
    END
    
    -- Эконом (остальные места)
    DECLARE @MaxRows INT = CEILING(CAST(@TotalSeats - @SeatCount AS FLOAT) / @SeatsPerRow) + @RowNum - 1;
    WHILE @RowNum <= @MaxRows AND @SeatCount < @TotalSeats
    BEGIN
        SET @SeatInRow = 1;
        WHILE @SeatInRow <= @SeatsPerRow AND @SeatCount < @TotalSeats
        BEGIN
            SET @Position = SUBSTRING(@Positions, @SeatInRow, 1);
            SET @SeatNumber = CAST(@RowNum AS VARCHAR) + @Position;
            SET @FareClassId = 1; -- Эконом
            
            INSERT INTO Seats (AircraftId, SeatNumber, FareClassId, RowNumber, Position)
            VALUES (@AircraftId, @SeatNumber, @FareClassId, @RowNum, @Position);
            
            SET @SeatCount = @SeatCount + 1;
            SET @SeatInRow = @SeatInRow + 1;
        END
        SET @RowNum = @RowNum + 1;
    END
    
    PRINT 'Создано ' + CAST(@SeatCount AS VARCHAR) + ' мест для самолета ID ' + CAST(@AircraftId AS VARCHAR);
END
GO

-- Генерация мест для всех самолетов
DECLARE @AircraftCursor CURSOR;
DECLARE @CurrentAircraftId INT;
DECLARE @CurrentTotalSeats INT;

SET @AircraftCursor = CURSOR FOR
SELECT AircraftId, TotalSeats FROM Aircrafts;

OPEN @AircraftCursor;
FETCH NEXT FROM @AircraftCursor INTO @CurrentAircraftId, @CurrentTotalSeats;

WHILE @@FETCH_STATUS = 0
BEGIN
    EXEC GenerateSeatsForAircraft @CurrentAircraftId, @CurrentTotalSeats;
    FETCH NEXT FROM @AircraftCursor INTO @CurrentAircraftId, @CurrentTotalSeats;
END

CLOSE @AircraftCursor;
DEALLOCATE @AircraftCursor;
GO

DROP PROCEDURE GenerateSeatsForAircraft;
GO

-- 5.6. Пассажиры (100 пассажиров)
PRINT 'Добавление пассажиров...';
GO

-- Создаем временную таблицу с именами и фамилиями
CREATE TABLE #TempNames (
    FirstName NVARCHAR(50),
    LastName NVARCHAR(50),
    Gender CHAR(1)
);

INSERT INTO #TempNames (FirstName, LastName, Gender) VALUES
('Иван', 'Иванов', 'M'), ('Мария', 'Петрова', 'F'), ('Алексей', 'Сидоров', 'M'), ('Екатерина', 'Козлова', 'F'),
('Дмитрий', 'Васильев', 'M'), ('Анна', 'Смирнова', 'F'), ('Сергей', 'Попов', 'M'), ('Ольга', 'Лебедева', 'F'),
('Андрей', 'Новиков', 'M'), ('Наталья', 'Морозова', 'F'), ('Михаил', 'Волков', 'M'), ('Елена', 'Соловьева', 'F'),
('Александр', 'Зайцев', 'M'), ('Ирина', 'Павлова', 'F'), ('Владимир', 'Семенов', 'M'), ('Татьяна', 'Голубева', 'F'),
('Павел', 'Виноградов', 'M'), ('Юлия', 'Богданова', 'F'), ('Николай', 'Воробьев', 'M'), ('Марина', 'Федорова', 'F'),
('Артем', 'Михайлов', 'M'), ('Светлана', 'Беляева', 'F'), ('Игорь', 'Тарасов', 'M'), ('Лариса', 'Белова', 'F'),
('Роман', 'Комаров', 'M'), ('Алиса', 'Орлова', 'F'), ('Виталий', 'Киселев', 'M'), ('Валентина', 'Макарова', 'F'),
('Олег', 'Андреев', 'M'), ('Галина', 'Николаева', 'F'), ('Станислав', 'Кузнецов', 'M'), ('Ксения', 'Соколова', 'F'),
('Виктор', 'Егоров', 'M'), ('Вероника', 'Ильина', 'F'), ('Георгий', 'Максимов', 'M'), ('Анастасия', 'Полякова', 'F'),
('Федор', 'Романов', 'M'), ('Евгения', 'Филиппова', 'F'), ('Ярослав', 'Карпов', 'M'), ('Дарья', 'Александрова', 'F');

-- Добавляем пассажиров
DECLARE @Counter INT = 1;
DECLARE @FirstName NVARCHAR(50);
DECLARE @LastName NVARCHAR(50);
DECLARE @Gender CHAR(1);
DECLARE @BirthDate DATE;
DECLARE @DocumentNumber VARCHAR(20);

WHILE @Counter <= 100
BEGIN
    SELECT TOP 1 @FirstName = FirstName, @LastName = LastName, @Gender = Gender 
    FROM #TempNames 
    ORDER BY NEWID();
    
    -- Генерируем дату рождения (от 1 до 80 лет назад)
    SET @BirthDate = DATEADD(YEAR, -1 * (ABS(CHECKSUM(NEWID())) % 80 + 1), GETDATE());
    SET @BirthDate = DATEADD(DAY, ABS(CHECKSUM(NEWID())) % 365, @BirthDate);
    
    -- Генерируем номер документа
    SET @DocumentNumber = 
        CASE 
            WHEN DATEDIFF(YEAR, @BirthDate, GETDATE()) < 14 
            THEN 'CHILD' + RIGHT('00000' + CAST(@Counter AS VARCHAR), 5)
            ELSE RIGHT('0000' + CAST(ABS(CHECKSUM(NEWID())) % 10000 AS VARCHAR), 4) + 
                 RIGHT('000000' + CAST(@Counter AS VARCHAR), 6)
        END;
    
    INSERT INTO Passengers (FirstName, LastName, MiddleName, BirthDate, Gender, 
                           DocumentType, DocumentNumber, Citizenship, PhoneNumber, Email)
    VALUES (
        @FirstName,
        @LastName,
        CASE WHEN ABS(CHECKSUM(NEWID())) % 3 = 0 THEN NULL 
             ELSE LEFT(@FirstName, 1) + 'ович' -- Упрощенное отчество
        END,
        @BirthDate,
        @Gender,
        CASE WHEN DATEDIFF(YEAR, @BirthDate, GETDATE()) < 14 
             THEN 'Свидетельство' 
             ELSE 'Паспорт' 
        END,
        @DocumentNumber,
        'Россия',
        '+7' + RIGHT('0000000000' + CAST(9000000000 + ABS(CHECKSUM(NEWID())) % 1000000000 AS VARCHAR), 10),
        LOWER(@FirstName) + '.' + LOWER(@LastName) + CAST(ABS(CHECKSUM(NEWID())) % 100 AS VARCHAR) + '@mail.ru'
    );
    
    SET @Counter = @Counter + 1;
END

DROP TABLE #TempNames;
GO

-- 5.7. Рейсы (50 рейсов - прошлые, текущие и будущие)
PRINT 'Добавление рейсов...';
GO

INSERT INTO Flights (FlightNumber, AirlineId, DepartureAirportId, ArrivalAirportId, AircraftId, 
                     ScheduledDeparture, ScheduledArrival, BasePrice, Status, Gate, Terminal)
SELECT * FROM (
    -- Прошлые рейсы (20 штук)
    VALUES 
    ('SU 1001', 1, 1, 3, 1, DATEADD(DAY, -30, GETDATE()), DATEADD(HOUR, 2, DATEADD(DAY, -30, GETDATE())), 4500.00, 'Arrived', 'A10', 'D'),
    ('SU 1002', 1, 3, 1, 1, DATEADD(DAY, -29, GETDATE()), DATEADD(HOUR, 2, DATEADD(DAY, -29, GETDATE())), 4500.00, 'Arrived', 'B05', 'D'),
    ('S7 2001', 2, 1, 4, 5, DATEADD(DAY, -28, GETDATE()), DATEADD(HOUR, 3, DATEADD(DAY, -28, GETDATE())), 6800.00, 'Arrived', 'C15', 'C'),
    ('U6 3001', 3, 1, 5, 6, DATEADD(DAY, -27, GETDATE()), DATEADD(HOUR, 2.5, DATEADD(DAY, -27, GETDATE())), 5500.00, 'Arrived', 'D22', 'B'),
    ('TK 4001', 5, 11, 1, 8, DATEADD(DAY, -26, GETDATE()), DATEADD(HOUR, 4, DATEADD(DAY, -26, GETDATE())), 12000.00, 'Arrived', 'E05', 'F'),
    ('SU 1003', 1, 1, 6, 2, DATEADD(DAY, -25, GETDATE()), DATEADD(HOUR, 2.5, DATEADD(DAY, -25, GETDATE())), 5000.00, 'Arrived', 'A12', 'D'),
    ('S7 2002', 2, 4, 1, 5, DATEADD(DAY, -24, GETDATE()), DATEADD(HOUR, 3, DATEADD(DAY, -24, GETDATE())), 7200.00, 'Arrived', 'C08', 'C'),
    ('DP 5001', 4, 1, 3, 4, DATEADD(DAY, -23, GETDATE()), DATEADD(HOUR, 2, DATEADD(DAY, -23, GETDATE())), 3500.00, 'Arrived', 'F01', 'A'),
    ('SU 1004', 1, 3, 7, 1, DATEADD(DAY, -22, GETDATE()), DATEADD(HOUR, 5, DATEADD(DAY, -22, GETDATE())), 8500.00, 'Arrived', 'A15', 'D'),
    ('TK 4002', 5, 1, 11, 9, DATEADD(DAY, -21, GETDATE()), DATEADD(HOUR, 4, DATEADD(DAY, -21, GETDATE())), 12500.00, 'Arrived', 'E08', 'F'),
    ('LH 6001', 7, 16, 1, 12, DATEADD(DAY, -20, GETDATE()), DATEADD(HOUR, 3.5, DATEADD(DAY, -20, GETDATE())), 15000.00, 'Arrived', 'G03', 'E'),
    ('AF 7001', 8, 12, 1, 14, DATEADD(DAY, -19, GETDATE()), DATEADD(HOUR, 4, DATEADD(DAY, -19, GETDATE())), 14000.00, 'Arrived', 'H07', 'G'),
    ('BA 8001', 9, 15, 1, 16, DATEADD(DAY, -18, GETDATE()), DATEADD(HOUR, 4.5, DATEADD(DAY, -18, GETDATE())), 16000.00, 'Arrived', 'I12', 'H'),
    ('EK 9001', 6, 13, 1, 10, DATEADD(DAY, -17, GETDATE()), DATEADD(HOUR, 6, DATEADD(DAY, -17, GETDATE())), 22000.00, 'Arrived', 'J05', 'J'),
    ('SU 1005', 1, 1, 8, 3, DATEADD(DAY, -16, GETDATE()), DATEADD(HOUR, 7, DATEADD(DAY, -16, GETDATE())), 18000.00, 'Arrived', 'A18', 'D'),
    ('S7 2003', 2, 1, 9, 7, DATEADD(DAY, -15, GETDATE()), DATEADD(HOUR, 3, DATEADD(DAY, -15, GETDATE())), 6500.00, 'Arrived', 'C12', 'C'),
    ('U6 3002', 3, 5, 1, 6, DATEADD(DAY, -14, GETDATE()), DATEADD(HOUR, 2.5, DATEADD(DAY, -14, GETDATE())), 5200.00, 'Arrived', 'D15', 'B'),
    ('SU 1006', 1, 10, 1, 2, DATEADD(DAY, -13, GETDATE()), DATEADD(HOUR, 2, DATEADD(DAY, -13, GETDATE())), 4800.00, 'Arrived', 'A08', 'D'),
    ('TK 4003', 5, 1, 12, 8, DATEADD(DAY, -12, GETDATE()), DATEADD(HOUR, 3, DATEADD(DAY, -12, GETDATE())), 11500.00, 'Arrived', 'E12', 'F'),
    ('DP 5002', 4, 3, 4, 4, DATEADD(DAY, -11, GETDATE()), DATEADD(HOUR, 2.5, DATEADD(DAY, -11, GETDATE())), 4000.00, 'Arrived', 'F08', 'A'),
    
    -- Текущие/будущие рейсы (30 штук)
    ('SU 1101', 1, 1, 3, 1, DATEADD(HOUR, 2, GETDATE()), DATEADD(HOUR, 4, GETDATE()), 4700.00, 'Boarding', 'A11', 'D'),
    ('SU 1102', 1, 3, 1, 1, DATEADD(HOUR, 6, GETDATE()), DATEADD(HOUR, 8, GETDATE()), 4700.00, 'Scheduled', 'B06', 'D'),
    ('S7 2101', 2, 1, 4, 5, DATEADD(DAY, 1, GETDATE()), DATEADD(HOUR, 3, DATEADD(DAY, 1, GETDATE())), 7000.00, 'Scheduled', 'C16', 'C'),
    ('U6 3101', 3, 1, 5, 6, DATEADD(DAY, 1, DATEADD(HOUR, 4, GETDATE())), DATEADD(HOUR, 6.5, DATEADD(DAY, 1, GETDATE())), 5700.00, 'Scheduled', 'D23', 'B'),
    ('TK 4101', 5, 11, 1, 8, DATEADD(DAY, 2, GETDATE()), DATEADD(HOUR, 4, DATEADD(DAY, 2, GETDATE())), 12500.00, 'Scheduled', 'E06', 'F'),
    ('SU 1103', 1, 1, 6, 2, DATEADD(DAY, 2, DATEADD(HOUR, 8, GETDATE())), DATEADD(HOUR, 10.5, DATEADD(DAY, 2, GETDATE())), 5200.00, 'Scheduled', 'A13', 'D'),
    ('S7 2102', 2, 4, 1, 5, DATEADD(DAY, 3, GETDATE()), DATEADD(HOUR, 3, DATEADD(DAY, 3, GETDATE())), 7500.00, 'Scheduled', 'C09', 'C'),
    ('DP 5101', 4, 1, 3, 4, DATEADD(DAY, 3, DATEADD(HOUR, 12, GETDATE())), DATEADD(HOUR, 14, DATEADD(DAY, 3, GETDATE())), 3700.00, 'Scheduled', 'F02', 'A'),
    ('SU 1104', 1, 3, 7, 1, DATEADD(DAY, 4, GETDATE()), DATEADD(HOUR, 5, DATEADD(DAY, 4, GETDATE())), 8800.00, 'Scheduled', 'A16', 'D'),
    ('TK 4102', 5, 1, 11, 9, DATEADD(DAY, 4, DATEADD(HOUR, 16, GETDATE())), DATEADD(HOUR, 20, DATEADD(DAY, 4, GETDATE())), 12800.00, 'Scheduled', 'E09', 'F'),
    ('LH 6101', 7, 16, 1, 12, DATEADD(DAY, 5, GETDATE()), DATEADD(HOUR, 3.5, DATEADD(DAY, 5, GETDATE())), 15500.00, 'Scheduled', 'G04', 'E'),
    ('AF 7101', 8, 12, 1, 14, DATEADD(DAY, 5, DATEADD(HOUR, 14, GETDATE())), DATEADD(HOUR, 18, DATEADD(DAY, 5, GETDATE())), 14500.00, 'Scheduled', 'H08', 'G'),
    ('BA 8101', 9, 15, 1, 16, DATEADD(DAY, 6, GETDATE()), DATEADD(HOUR, 4.5, DATEADD(DAY, 6, GETDATE())), 16500.00, 'Scheduled', 'I13', 'H'),
    ('EK 9101', 6, 13, 1, 10, DATEADD(DAY, 6, DATEADD(HOUR, 22, GETDATE())), DATEADD(DAY, 7, DATEADD(HOUR, 4, GETDATE())), 22500.00, 'Scheduled', 'J06', 'J'),
    ('SU 1105', 1, 1, 8, 3, DATEADD(DAY, 7, GETDATE()), DATEADD(HOUR, 7, DATEADD(DAY, 7, GETDATE())), 18500.00, 'Scheduled', 'A19', 'D'),
    ('S7 2103', 2, 1, 9, 7, DATEADD(DAY, 8, GETDATE()), DATEADD(HOUR, 3, DATEADD(DAY, 8, GETDATE())), 6800.00, 'Scheduled', 'C13', 'C'),
    ('U6 3102', 3, 5, 1, 6, DATEADD(DAY, 8, DATEADD(HOUR, 10, GETDATE())), DATEADD(HOUR, 12.5, DATEADD(DAY, 8, GETDATE())), 5400.00, 'Scheduled', 'D16', 'B'),
    ('SU 1106', 1, 10, 1, 2, DATEADD(DAY, 9, GETDATE()), DATEADD(HOUR, 2, DATEADD(DAY, 9, GETDATE())), 5000.00, 'Scheduled', 'A09', 'D'),
    ('TK 4103', 5, 1, 12, 8, DATEADD(DAY, 9, DATEADD(HOUR, 18, GETDATE())), DATEADD(HOUR, 21, DATEADD(DAY, 9, GETDATE())), 11800.00, 'Scheduled', 'E13', 'F'),
    ('DP 5102', 4, 3, 4, 4, DATEADD(DAY, 10, GETDATE()), DATEADD(HOUR, 2.5, DATEADD(DAY, 10, GETDATE())), 4200.00, 'Scheduled', 'F09', 'A'),
    ('SU 1107', 1, 1, 13, 1, DATEADD(DAY, 11, GETDATE()), DATEADD(HOUR, 8, DATEADD(DAY, 11, GETDATE())), 25000.00, 'Scheduled', 'A20', 'D'),
    ('EK 9102', 6, 1, 13, 11, DATEADD(DAY, 12, GETDATE()), DATEADD(HOUR, 6, DATEADD(DAY, 12, GETDATE())), 23000.00, 'Scheduled', 'J07', 'J'),
    ('LH 6102', 7, 1, 16, 13, DATEADD(DAY, 13, GETDATE()), DATEADD(HOUR, 3, DATEADD(DAY, 13, GETDATE())), 15200.00, 'Scheduled', 'G05', 'E'),
    ('AF 7102', 8, 1, 12, 15, DATEADD(DAY, 14, GETDATE()), DATEADD(HOUR, 4, DATEADD(DAY, 14, GETDATE())), 14800.00, 'Scheduled', 'H09', 'G'),
    ('BA 8102', 9, 1, 15, 17, DATEADD(DAY, 15, GETDATE()), DATEADD(HOUR, 4.5, DATEADD(DAY, 15, GETDATE())), 16800.00, 'Scheduled', 'I14', 'H'),
    ('QR 1111', 15, 1, 26, 22, DATEADD(DAY, 16, GETDATE()), DATEADD(HOUR, 5, DATEADD(DAY, 16, GETDATE())), 21000.00, 'Scheduled', 'K01', 'K'),
    ('SQ 1212', 16, 1, 20, 23, DATEADD(DAY, 17, GETDATE()), DATEADD(HOUR, 10, DATEADD(DAY, 17, GETDATE())), 28000.00, 'Scheduled', 'L01', 'L'),
    ('AA 1313', 19, 1, 14, 18, DATEADD(DAY, 18, GETDATE()), DATEADD(HOUR, 11, DATEADD(DAY, 18, GETDATE())), 30000.00, 'Scheduled', 'M01', 'M'),
    ('DL 1414', 18, 1, 14, 19, DATEADD(DAY, 19, GETDATE()), DATEADD(HOUR, 11.5, DATEADD(DAY, 19, GETDATE())), 29000.00, 'Scheduled', 'N01', 'N'),
    ('AK 1515', 17, 1, 21, 21, DATEADD(DAY, 20, GETDATE()), DATEADD(HOUR, 9, DATEADD(DAY, 20, GETDATE())), 19000.00, 'Scheduled', 'O01', 'O')
) AS FlightsData(
    FlightNumber, AirlineId, DepartureAirportId, ArrivalAirportId, AircraftId, 
    ScheduledDeparture, ScheduledArrival, BasePrice, Status, Gate, Terminal
);
GO

-- 5.8. Бронирования (200 бронирований)
PRINT 'Добавление бронирований...';
GO

DECLARE @FlightCount INT = (SELECT COUNT(*) FROM Flights);
DECLARE @PassengerCount INT = (SELECT COUNT(*) FROM Passengers);
DECLARE @BookingCounter INT = 1;
DECLARE @FlightId INT;
DECLARE @PassengerId INT;
DECLARE @SeatId INT;
DECLARE @AircraftId INT;
DECLARE @Status NVARCHAR(20);
DECLARE @BookingDate DATETIME2;

-- Получаем список всех мест с информацией о самолетах
SELECT 
    s.SeatId,
    s.AircraftId,
    s.FareClassId,
    s.SeatNumber,
    ROW_NUMBER() OVER (PARTITION BY s.AircraftId ORDER BY s.SeatId) as SeatNum
INTO #AvailableSeats
FROM Seats s;

WHILE @BookingCounter <= 200
BEGIN
    -- Выбираем случайный рейс
    SET @FlightId = (SELECT TOP 1 FlightId FROM Flights ORDER BY NEWID());
    
    -- Получаем самолет для этого рейса
    SET @AircraftId = (SELECT AircraftId FROM Flights WHERE FlightId = @FlightId);
    
    -- Выбираем случайного пассажира
    SET @PassengerId = ABS(CHECKSUM(NEWID())) % @PassengerCount + 1;
    
    -- Выбираем случайное свободное место на этом самолете
    SELECT TOP 1 @SeatId = SeatId 
    FROM #AvailableSeats 
    WHERE AircraftId = @AircraftId 
      AND SeatId NOT IN (
          SELECT SeatId 
          FROM Bookings 
          WHERE FlightId = @FlightId
      )
    ORDER BY NEWID();
    
    -- Если нет свободных мест, пропускаем
    IF @SeatId IS NULL
    BEGIN
        SET @BookingCounter = @BookingCounter + 1;
        CONTINUE;
    END
    
    -- Определяем статус бронирования
    SET @Status = CASE 
        WHEN @BookingCounter % 10 = 0 THEN 'Cancelled'
        WHEN @BookingCounter % 7 = 0 THEN 'NoShow'
        WHEN @BookingCounter % 5 = 0 THEN 'Pending'
        WHEN @BookingCounter % 3 = 0 THEN 'CheckedIn'
        ELSE 'Confirmed'
    END;
    
    -- Генерируем дату бронирования (от 30 дней до 1 дня до вылета)
    DECLARE @DepartureDate DATETIME2 = (SELECT ScheduledDeparture FROM Flights WHERE FlightId = @FlightId);
    SET @BookingDate = DATEADD(DAY, -1 * (ABS(CHECKSUM(NEWID())) % 30 + 1), @DepartureDate);
    
    INSERT INTO Bookings (PassengerId, FlightId, SeatId, BookingDate, BookingStatus, SpecialRequests, CreatedBy)
    VALUES (
        @PassengerId,
        @FlightId,
        @SeatId,
        @BookingDate,
        @Status,
        CASE 
            WHEN @BookingCounter % 15 = 0 THEN 'Вегетарианское питание'
            WHEN @BookingCounter % 12 = 0 THEN 'Детское кресло'
            WHEN @BookingCounter % 9 = 0 THEN 'Инвалидное кресло'
            WHEN @BookingCounter % 6 = 0 THEN 'Халяль питание'
            ELSE NULL
        END,
        CASE 
            WHEN @BookingCounter % 4 = 0 THEN 'Website'
            WHEN @BookingCounter % 3 = 0 THEN 'MobileApp'
            WHEN @BookingCounter % 2 = 0 THEN 'CallCenter'
            ELSE 'AirportCounter'
        END
    );
    
    SET @BookingCounter = @BookingCounter + 1;
END

DROP TABLE #AvailableSeats;
GO

-- 5.9. Билеты (только для подтвержденных бронирований)
PRINT 'Добавление билетов...';
GO

INSERT INTO Tickets (BookingId, TicketNumber, FareClassId, FinalPrice, IssueDate, IssuedBy, IsElectronic)
SELECT 
    b.BookingId,
    -- Генерируем номер билета по стандарту IATA: 3 цифры авиакомпании + 10 цифр номера
    RIGHT('000' + CAST(al.AirlineId AS VARCHAR), 3) + 
    RIGHT('0000000000' + CAST(ROW_NUMBER() OVER (ORDER BY b.BookingId) + 1000000000 AS VARCHAR), 10),
    s.FareClassId,
    -- Рассчитываем финальную цену: базовая цена * множитель класса ± случайная скидка/надбавка
    ROUND(f.BasePrice * fc.Multiplier * (1.0 + (CAST(ABS(CHECKSUM(NEWID())) % 20 AS FLOAT) - 10) / 100), 2),
    b.BookingDate,
    b.CreatedBy,
    CASE WHEN ABS(CHECKSUM(NEWID())) % 5 = 0 THEN 0 ELSE 1 END
FROM Bookings b
INNER JOIN Flights f ON b.FlightId = f.FlightId
INNER JOIN Airlines al ON f.AirlineId = al.AirlineId
INNER JOIN Seats s ON b.SeatId = s.SeatId
INNER JOIN FareClasses fc ON s.FareClassId = fc.FareClassId
WHERE b.BookingStatus IN ('Confirmed', 'CheckedIn')
  AND b.BookingId NOT IN (SELECT BookingId FROM Tickets);
GO

-- 5.10. Платежи (для всех билетов)
PRINT 'Добавление платежей...';
GO

INSERT INTO Payments (TicketId, Amount, PaymentDate, PaymentMethod, PaymentStatus, TransactionId)
SELECT 
    t.TicketId,
    t.FinalPrice,
    DATEADD(MINUTE, ABS(CHECKSUM(NEWID())) % 60, t.IssueDate), -- Платеж в течение часа после выписки
    CASE ABS(CHECKSUM(NEWID())) % 5
        WHEN 0 THEN 'Cash'
        WHEN 1 THEN 'BankTransfer'
        WHEN 2 THEN 'DebitCard'
        WHEN 3 THEN 'Online'
        ELSE 'CreditCard'
    END,
    'Completed',
    'TXN' + RIGHT('0000000000' + CAST(ROW_NUMBER() OVER (ORDER BY t.TicketId) + 1000000000 AS VARCHAR), 10)
FROM Tickets t
WHERE t.TicketId NOT IN (SELECT TicketId FROM Payments);
GO

-- 5.11. Багаж (для 70% билетов)
PRINT 'Добавление багажа...';
GO

INSERT INTO Baggage (TicketId, BaggageNumber, Weight, Type, Status)
SELECT 
    t.TicketId,
    t.TicketNumber + 'B' + CAST(ROW_NUMBER() OVER (PARTITION BY t.TicketId ORDER BY NEWID()) AS VARCHAR),
    CASE 
        WHEN ABS(CHECKSUM(NEWID())) % 10 = 0 THEN CAST(ABS(CHECKSUM(NEWID())) % 30 + 5 AS DECIMAL(5,2)) -- Oversized
        WHEN ABS(CHECKSUM(NEWID())) % 3 = 0 THEN CAST(ABS(CHECKSUM(NEWID())) % 10 + 5 AS DECIMAL(5,2)) -- Hand
        ELSE CAST(ABS(CHECKSUM(NEWID())) % 20 + 15 AS DECIMAL(5,2)) -- Checked
    END,
    CASE ABS(CHECKSUM(NEWID())) % 10
        WHEN 0 THEN 'Oversized'
        WHEN 1 THEN 'Special'
        WHEN 2 THEN 'Hand'
        ELSE 'Checked'
    END,
    CASE 
        WHEN f.Status = 'Arrived' THEN 'Delivered'
        WHEN f.Status IN ('Departed', 'Boarding') THEN 'Loaded'
        ELSE 'CheckedIn'
    END
FROM Tickets t
INNER JOIN Bookings b ON t.BookingId = b.BookingId
INNER JOIN Flights f ON b.FlightId = f.FlightId
WHERE ABS(CHECKSUM(NEWID())) % 100 < 70 -- 70% билетов имеют багаж
  AND t.TicketId NOT IN (SELECT TicketId FROM Baggage)
  AND (ABS(CHECKSUM(NEWID())) % 3 = 0 OR ABS(CHECKSUM(NEWID())) % 2 = 0); -- Некоторые имеют несколько мест багажа
GO

-- 6. СОЗДАНИЕ ПРЕДСТАВЛЕНИЙ
PRINT 'Создание представлений...';
GO

-- 6.1. Представление активных бронирований
CREATE VIEW ActiveBookings AS
SELECT 
    b.BookingId,
    p.PassengerId,
    p.LastName + ' ' + p.FirstName + ISNULL(' ' + p.MiddleName, '') AS PassengerName,
    p.DocumentNumber,
    f.FlightId,
    f.FlightNumber,
    al.AirlineName,
    dep.AirportCode AS DepartureCode,
    dep.City AS DepartureCity,
    arr.AirportCode AS ArrivalCode,
    arr.City AS ArrivalCity,
    f.ScheduledDeparture,
    f.ScheduledArrival,
    s.SeatNumber,
    fc.ClassName,
    fc.ClassCode,
    b.BookingDate,
    b.BookingStatus,
    t.TicketNumber,
    t.FinalPrice,
    DATEDIFF(HOUR, GETDATE(), f.ScheduledDeparture) AS HoursToDeparture,
    CASE 
        WHEN DATEDIFF(HOUR, GETDATE(), f.ScheduledDeparture) < 24 THEN 'Срочный'
        WHEN DATEDIFF(HOUR, GETDATE(), f.ScheduledDeparture) < 72 THEN 'Ближайший'
        ELSE 'Плановый'
    END AS Priority
FROM Bookings b
INNER JOIN Passengers p ON b.PassengerId = p.PassengerId
INNER JOIN Flights f ON b.FlightId = f.FlightId
INNER JOIN Airlines al ON f.AirlineId = al.AirlineId
INNER JOIN Airports dep ON f.DepartureAirportId = dep.AirportId
INNER JOIN Airports arr ON f.ArrivalAirportId = arr.AirportId
INNER JOIN Seats s ON b.SeatId = s.SeatId
INNER JOIN FareClasses fc ON s.FareClassId = fc.FareClassId
LEFT JOIN Tickets t ON b.BookingId = t.BookingId
WHERE b.BookingStatus IN ('Confirmed', 'Pending', 'CheckedIn')
  AND f.ScheduledDeparture > GETDATE();
GO

-- 6.2. Представление детей на рейсах (для запроса 8)
CREATE VIEW ChildrenOnFlights AS
SELECT 
    f.FlightId,
    f.FlightNumber,
    al.AirlineName,
    dep.City AS DepartureCity,
    arr.City AS ArrivalCity,
    f.ScheduledDeparture,
    p.PassengerId,
    p.LastName + ' ' + p.FirstName AS ChildName,
    p.BirthDate,
    DATEDIFF(YEAR, p.BirthDate, GETDATE()) AS Age,
    p.DocumentNumber AS ChildDocument,
    s.SeatNumber,
    fc.ClassName,
    b.BookingStatus,
    t.TicketNumber,
    t.FinalPrice AS TicketPrice
FROM Bookings b
INNER JOIN Passengers p ON b.PassengerId = p.PassengerId
INNER JOIN Flights f ON b.FlightId = f.FlightId
INNER JOIN Airlines al ON f.AirlineId = al.AirlineId
INNER JOIN Airports dep ON f.DepartureAirportId = dep.AirportId
INNER JOIN Airports arr ON f.ArrivalAirportId = arr.AirportId
INNER JOIN Seats s ON b.SeatId = s.SeatId
INNER JOIN FareClasses fc ON s.FareClassId = fc.FareClassId
LEFT JOIN Tickets t ON b.BookingId = t.BookingId
WHERE b.BookingStatus = 'Confirmed'
  AND DATEDIFF(YEAR, p.BirthDate, GETDATE()) < 12;
GO

-- 7. ФИНАЛЬНАЯ ПРОВЕРКА И СТАТИСТИКА
PRINT '===============================================';
PRINT 'ФИНАЛЬНАЯ СТАТИСТИКА БАЗЫ ДАННЫХ:';
PRINT '===============================================';
GO

SELECT 'Авиакомпании' AS Объект, COUNT(*) AS Количество FROM Airlines
UNION ALL SELECT 'Аэропорты', COUNT(*) FROM Airports
UNION ALL SELECT 'Самолеты', COUNT(*) FROM Aircrafts
UNION ALL SELECT 'Места в самолетах', COUNT(*) FROM Seats
UNION ALL SELECT 'Рейсы', COUNT(*) FROM Flights
UNION ALL SELECT 'Пассажиры', COUNT(*) FROM Passengers
UNION ALL SELECT 'Бронирования', COUNT(*) FROM Bookings
UNION ALL SELECT 'Билеты', COUNT(*) FROM Tickets
UNION ALL SELECT 'Платежи', COUNT(*) FROM Payments
UNION ALL SELECT 'Багаж', COUNT(*) FROM Baggage
UNION ALL SELECT 'Активные бронирования', COUNT(*) FROM ActiveBookings
UNION ALL SELECT 'Дети на рейсах (запрос 8)', COUNT(*) FROM ChildrenOnFlights
ORDER BY Количество DESC;
GO

-- Статистика по возрастам пассажиров
SELECT 
    'Дети (0-11 лет)' AS Возрастная_категория,
    COUNT(*) AS Количество,
    FORMAT(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM Passengers), 'N1') + '%' AS Процент
FROM Passengers 
WHERE DATEDIFF(YEAR, BirthDate, GETDATE()) < 12
UNION ALL
SELECT 
    'Подростки (12-17 лет)',
    COUNT(*),
    FORMAT(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM Passengers), 'N1') + '%'
FROM Passengers 
WHERE DATEDIFF(YEAR, BirthDate, GETDATE()) BETWEEN 12 AND 17
UNION ALL
SELECT 
    'Взрослые (18-60 лет)',
    COUNT(*),
    FORMAT(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM Passengers), 'N1') + '%'
FROM Passengers 
WHERE DATEDIFF(YEAR, BirthDate, GETDATE()) BETWEEN 18 AND 60
UNION ALL
SELECT 
    'Пенсионеры (60+ лет)',
    COUNT(*),
    FORMAT(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM Passengers), 'N1') + '%'
FROM Passengers 
WHERE DATEDIFF(YEAR, BirthDate, GETDATE()) > 60;
GO

-- Статистика по статусам рейсов
SELECT 
    Status AS Статус_рейса,
    COUNT(*) AS Количество,
    FORMAT(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM Flights), 'N1') + '%' AS Процент
FROM Flights
GROUP BY Status
ORDER BY COUNT(*) DESC;
GO

PRINT '===============================================';
PRINT 'БАЗА ДАННЫХ УСПЕШНО СОЗДАНА И НАПОЛНЕНА!';
PRINT 'ВСЕ ЗАПРОСЫ БУДУТ РАБОТАТЬ С ДАННЫМИ.';
PRINT '===============================================';