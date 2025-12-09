-- ============================================
-- SQL-ЗАПРОСЫ ДЛЯ ИНФОРМАЦИОННОЙ СИСТЕМЫ 
-- «ПРОДАЖА АВИАБИЛЕТОВ»
-- ============================================

USE AirlineTickets;
GO

-- 1. ВЫДАТЬ СПИСОК ВСЕХ АВИАРЕЙСОВ
SELECT 
    f.FlightId,
    f.FlightNumber,
    al.AirlineName,
    dep.AirportName + ' (' + dep.AirportCode + ')' AS Аэропорт_вылета,
    arr.AirportName + ' (' + arr.AirportCode + ')' AS Аэропорт_прилета,
    f.ScheduledDeparture AS Вылет_по_расписанию,
    f.ScheduledArrival AS Прилет_по_расписанию,
    ac.AircraftModel AS Самолет,
    f.BasePrice AS Базовая_цена
FROM Flights f
INNER JOIN Airlines al ON f.AircraftId IN (SELECT AircraftId FROM Aircrafts WHERE AirlineId = al.AirlineId)
INNER JOIN Airports dep ON f.DepartureAirportId = dep.AirportId
INNER JOIN Airports arr ON f.ArrivalAirportId = arr.AirportId
INNER JOIN Aircrafts ac ON f.AircraftId = ac.AircraftId
ORDER BY f.ScheduledDeparture;
GO

-- 2. ВЫВЕСТИ СПИСОК ВСЕХ ПАССАЖИРОВ ЗАДАННОГО АВИАРЕЙСА
-- Параметр: @FlightId = 1
DECLARE @FlightId INT = 1;

SELECT 
    p.PassengerId,
    p.LastName + ' ' + p.FirstName AS ФИО,
    p.BirthDate AS Дата_рождения,
    p.DocumentNumber AS Номер_документа,
    p.PhoneNumber AS Телефон,
    p.Email AS Email,
    b.BookingDate AS Дата_бронирования,
    s.SeatNumber AS Номер_места,
    fc.ClassName AS Класс_обслуживания,
    t.FinalPrice AS Стоимость_билета
FROM Bookings b
INNER JOIN Passengers p ON b.PassengerId = p.PassengerId
INNER JOIN Tickets t ON b.BookingId = t.BookingId
INNER JOIN Seats s ON b.SeatId = s.SeatId
INNER JOIN FareClasses fc ON s.FareClassId = fc.FareClassId
WHERE b.FlightId = @FlightId 
  AND b.BookingStatus IN ('Подтверждено', 'Оплачено')
ORDER BY p.LastName, p.FirstName;
GO

-- 3. ВЫДАТЬ СПИСОК СВОБОДНЫХ МЕСТ ДЛЯ ЗАДАННОГО АВИАРЕЙСА
-- Параметр: @FlightId = 1
DECLARE @FlightId INT = 1;

SELECT 
    s.SeatId,
    s.SeatNumber AS Номер_места,
    fc.ClassName AS Класс,
    ac.AircraftModel AS Самолет,
    'Свободно' AS Статус
FROM Seats s
INNER JOIN FareClasses fc ON s.FareClassId = fc.FareClassId
INNER JOIN Aircrafts ac ON s.AircraftId = ac.AircraftId
WHERE s.AircraftId = (SELECT AircraftId FROM Flights WHERE FlightId = @FlightId)
  AND s.SeatId NOT IN (
      SELECT b.SeatId 
      FROM Bookings b 
      WHERE b.FlightId = @FlightId 
        AND b.BookingStatus IN ('Подтверждено', 'Ожидает оплаты')
  )
ORDER BY 
    CASE 
        WHEN fc.ClassName = 'Первый' THEN 1
        WHEN fc.ClassName = 'Бизнес' THEN 2
        WHEN fc.ClassName = 'Комфорт' THEN 3
        ELSE 4
    END,
    s.SeatNumber;
GO

-- 4. СФОРМИРОВАТЬ СПРАВКУ ПО ПАССАЖИРУ (ОБО ВСЕХ ЕГО ПЕРЕДВИЖЕНИЯХ)
-- Параметр: @PassengerId = 1
DECLARE @PassengerId INT = 1;

SELECT 
    p.PassengerId,
    p.LastName + ' ' + p.FirstName AS Пассажир,
    f.FlightNumber AS Номер_рейса,
    dep.City + ' (' + dep.AirportCode + ')' AS Город_вылета,
    arr.City + ' (' + arr.AirportCode + ')' AS Город_прилета,
    f.ScheduledDeparture AS Дата_вылета,
    f.ScheduledArrival AS Дата_прилета,
    s.SeatNumber AS Место,
    fc.ClassName AS Класс,
    t.FinalPrice AS Стоимость,
    b.BookingStatus AS Статус_бронирования
FROM Bookings b
INNER JOIN Passengers p ON b.PassengerId = p.PassengerId
INNER JOIN Flights f ON b.FlightId = f.FlightId
INNER JOIN Airports dep ON f.DepartureAirportId = dep.AirportId
INNER JOIN Airports arr ON f.ArrivalAirportId = arr.AirportId
INNER JOIN Tickets t ON b.BookingId = t.BookingId
INNER JOIN Seats s ON b.SeatId = s.SeatId
INNER JOIN FareClasses fc ON s.FareClassId = fc.FareClassId
WHERE p.PassengerId = @PassengerId
ORDER BY f.ScheduledDeparture DESC;
GO

-- 5. РАССЧИТАТЬ СТОИМОСТЬ ВСЕХ ПРОДАННЫХ БИЛЕТОВ ЗА ЗАДАННЫЙ ПЕРИОД ВРЕМЕНИ
-- Параметры: @StartDate = '2024-12-01', @EndDate = '2024-12-31'
DECLARE @StartDate DATE = '2024-12-01';
DECLARE @EndDate DATE = '2024-12-31';

SELECT 
    SUM(t.FinalPrice) AS Общая_стоимость_проданных_билетов,
    COUNT(*) AS Количество_билетов,
    AVG(t.FinalPrice) AS Средняя_стоимость_билета
FROM Tickets t
INNER JOIN Bookings b ON t.BookingId = b.BookingId
WHERE b.BookingStatus = 'Подтверждено'
  AND t.IssueDate BETWEEN @StartDate AND @EndDate;
GO

-- 6. РАССЧИТАТЬ СТОИМОСТЬ ВСЕХ ПРОДАННЫХ БИЛЕТОВ НА ЗАДАННЫЙ АВИАРЕЙС
-- Параметр: @FlightId = 1
DECLARE @FlightId INT = 1;

SELECT 
    f.FlightNumber AS Номер_рейса,
    COUNT(t.TicketId) AS Количество_проданных_билетов,
    SUM(t.FinalPrice) AS Общая_выручка,
    AVG(t.FinalPrice) AS Средняя_цена_билета,
    MIN(t.FinalPrice) AS Минимальная_цена,
    MAX(t.FinalPrice) AS Максимальная_цена
FROM Tickets t
INNER JOIN Bookings b ON t.BookingId = b.BookingId
INNER JOIN Flights f ON b.FlightId = f.FlightId
WHERE b.FlightId = @FlightId 
  AND b.BookingStatus = 'Подтверждено'
GROUP BY f.FlightNumber;
GO

-- 7. РАССЧИТАТЬ СТОИМОСТЬ ВСЕХ НЕПРОДАННЫХ БИЛЕТОВ НА ЗАДАННЫЙ АВИАРЕЙС
-- (потенциальная выручка от свободных мест)
-- Параметр: @FlightId = 1
DECLARE @FlightId INT = 1;

SELECT 
    f.FlightNumber AS Номер_рейса,
    COUNT(s.SeatId) AS Количество_свободных_мест,
    SUM(f.BasePrice * 
        CASE 
            WHEN fc.ClassName = 'Первый' THEN 3.0
            WHEN fc.ClassName = 'Бизнес' THEN 2.0
            WHEN fc.ClassName = 'Комфорт' THEN 1.5
            ELSE 1.0
        END) AS Потенциальная_выручка
FROM Seats s
INNER JOIN FareClasses fc ON s.FareClassId = fc.FareClassId
CROSS JOIN Flights f
WHERE f.FlightId = @FlightId
  AND s.AircraftId = f.AircraftId
  AND s.SeatId NOT IN (
      SELECT b.SeatId 
      FROM Bookings b 
      WHERE b.FlightId = @FlightId 
        AND b.BookingStatus IN ('Подтверждено', 'Ожидает оплаты')
  )
GROUP BY f.FlightNumber;
GO

-- 8. ВЫДАТЬ СПИСКИ ДЕТЕЙ ДЛЯ ЗАДАННОГО АВИАРЕЙСА
-- (дети до 12 лет)
-- Параметр: @FlightId = 1
DECLARE @FlightId INT = 1;

SELECT 
    p.PassengerId,
    p.LastName + ' ' + p.FirstName AS Ребенок,
    p.BirthDate AS Дата_рождения,
    DATEDIFF(YEAR, p.BirthDate, GETDATE()) AS Возраст,
    p.DocumentNumber AS Свидетельство_о_рождении,
    s.SeatNumber AS Место,
    fc.ClassName AS Класс,
    t.FinalPrice AS Стоимость_детского_билета,
    (SELECT LastName + ' ' + FirstName 
     FROM Passengers 
     WHERE PassengerId = b.PassengerId) AS Сопровождающий
FROM Bookings b
INNER JOIN Passengers p ON b.PassengerId = p.PassengerId
INNER JOIN Tickets t ON b.BookingId = t.BookingId
INNER JOIN Seats s ON b.SeatId = s.SeatId
INNER JOIN FareClasses fc ON s.FareClassId = fc.FareClassId
WHERE b.FlightId = @FlightId 
  AND b.BookingStatus = 'Подтверждено'
  AND DATEDIFF(YEAR, p.BirthDate, GETDATE()) < 12
ORDER BY p.BirthDate DESC;
GO

-- 9. ДЛЯ ПАССАЖИРА РАССЧИТАТЬ СТОИМОСТЬ ПРИОБРЕТЕННЫХ БИЛЕТОВ ЗА ЗАДАННЫЙ ИНТЕРВАЛ ВРЕМЕНИ
-- Параметры: @PassengerId = 1, @StartDate = '2024-01-01', @EndDate = '2024-12-31'
DECLARE @PassengerId INT = 1;
DECLARE @StartDate DATE = '2024-01-01';
DECLARE @EndDate DATE = '2024-12-31';

SELECT 
    p.PassengerId,
    p.LastName + ' ' + p.FirstName AS Пассажир,
    COUNT(t.TicketId) AS Количество_купленных_билетов,
    SUM(t.FinalPrice) AS Общая_стоимость,
    MIN(t.FinalPrice) AS Минимальная_стоимость,
    MAX(t.FinalPrice) AS Максимальная_стоимость,
    AVG(t.FinalPrice) AS Средняя_стоимость
FROM Tickets t
INNER JOIN Bookings b ON t.BookingId = b.BookingId
INNER JOIN Passengers p ON b.PassengerId = p.PassengerId
WHERE p.PassengerId = @PassengerId
  AND t.IssueDate BETWEEN @StartDate AND @EndDate
  AND b.BookingStatus = 'Подтверждено'
GROUP BY p.PassengerId, p.LastName, p.FirstName;
GO

-- 10. РАССЧИТАТЬ КОЛИЧЕСТВО ПАССАЖИРОВ ДЛЯ КАЖДОГО АВИАРЕЙСА
SELECT 
    f.FlightId,
    f.FlightNumber AS Номер_рейса,
    dep.City + ' → ' + arr.City AS Маршрут,
    f.ScheduledDeparture AS Вылет,
    COUNT(b.BookingId) AS Количество_пассажиров,
    ac.TotalSeats AS Всего_мест_в_самолете,
    CAST(COUNT(b.BookingId) AS FLOAT) / ac.TotalSeats * 100 AS Загрузка_самолета_в_процентах
FROM Flights f
INNER JOIN Airports dep ON f.DepartureAirportId = dep.AirportId
INNER JOIN Airports arr ON f.ArrivalAirportId = arr.AirportId
INNER JOIN Aircrafts ac ON f.AircraftId = ac.AircraftId
LEFT JOIN Bookings b ON f.FlightId = b.FlightId 
    AND b.BookingStatus = 'Подтверждено'
GROUP BY f.FlightId, f.FlightNumber, dep.City, arr.City, 
         f.ScheduledDeparture, ac.TotalSeats
ORDER BY f.ScheduledDeparture;
GO

-- 11. ДОПОЛНИТЕЛЬНЫЙ ЗАПРОС: ПОИСК РЕЙСОВ ПО КРИТЕРИЯМ
-- Параметры: @DepartureCity = 'Москва', @ArrivalCity = 'Санкт-Петербург', @Date = '2024-12-20'
DECLARE @DepartureCity NVARCHAR(100) = 'Москва';
DECLARE @ArrivalCity NVARCHAR(100) = 'Санкт-Петербург';
DECLARE @Date DATE = '2024-12-20';

SELECT 
    f.FlightNumber,
    al.AirlineName AS Авиакомпания,
    dep.AirportName AS Аэропорт_вылета,
    arr.AirportName AS Аэропорт_прилета,
    f.ScheduledDeparture AS Вылет,
    f.ScheduledArrival AS Прилет,
    ac.AircraftModel AS Самолет,
    f.BasePrice AS Базовая_цена,
    (SELECT COUNT(*) 
     FROM Seats s 
     WHERE s.AircraftId = f.AircraftId 
       AND s.SeatId NOT IN (
           SELECT b.SeatId 
           FROM Bookings b 
           WHERE b.FlightId = f.FlightId 
             AND b.BookingStatus IN ('Подтверждено', 'Ожидает оплаты')
       )) AS Свободных_мест
FROM Flights f
INNER JOIN Airlines al ON f.AircraftId IN (SELECT AircraftId FROM Aircrafts WHERE AirlineId = al.AirlineId)
INNER JOIN Airports dep ON f.DepartureAirportId = dep.AirportId
INNER JOIN Airports arr ON f.ArrivalAirportId = arr.AirportId
INNER JOIN Aircrafts ac ON f.AircraftId = ac.AircraftId
WHERE dep.City = @DepartureCity
  AND arr.City = @ArrivalCity
  AND CAST(f.ScheduledDeparture AS DATE) = @Date
  AND f.ScheduledDeparture > GETDATE()
ORDER BY f.ScheduledDeparture;
GO

-- 12. ХРАНИМАЯ ПРОЦЕДУРА ДЛЯ БРОНИРОВАНИЯ МЕСТА
CREATE OR ALTER PROCEDURE BookFlightSeat
    @PassengerId INT,
    @FlightId INT,
    @SeatId INT,
    @BookingStatus NVARCHAR(30) = 'Ожидает оплаты'
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Проверка существования пассажира
        IF NOT EXISTS (SELECT 1 FROM Passengers WHERE PassengerId = @PassengerId)
            THROW 50001, 'Пассажир не найден', 1;
            
        -- Проверка существования рейса
        IF NOT EXISTS (SELECT 1 FROM Flights WHERE FlightId = @FlightId)
            THROW 50002, 'Рейс не найден', 1;
            
        -- Проверка существования места
        IF NOT EXISTS (SELECT 1 FROM Seats WHERE SeatId = @SeatId)
            THROW 50003, 'Место не найдено', 1;
            
        -- Проверка, что место свободно на данном рейсе
        IF EXISTS (
            SELECT 1 
            FROM Bookings 
            WHERE FlightId = @FlightId 
              AND SeatId = @SeatId 
              AND BookingStatus IN ('Подтверждено', 'Ожидает оплаты')
        )
            THROW 50004, 'Место уже забронировано', 1;
            
        -- Создание бронирования
        INSERT INTO Bookings (PassengerId, FlightId, SeatId, BookingStatus)
        VALUES (@PassengerId, @FlightId, @SeatId, @BookingStatus);
        
        DECLARE @NewBookingId INT = SCOPE_IDENTITY();
        
        COMMIT TRANSACTION;
        
        SELECT 
            'Успешно' AS Статус,
            @NewBookingId AS Номер_бронирования,
            'Бронирование создано' AS Сообщение;
            
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
            
        SELECT 
            'Ошибка' AS Статус,
            ERROR_NUMBER() AS Код_ошибки,
            ERROR_MESSAGE() AS Сообщение_об_ошибке;
    END CATCH;
END;
GO

-- Пример вызова процедуры бронирования
-- EXEC BookFlightSeat @PassengerId = 1, @FlightId = 1, @SeatId = 100;
-- GO

-- 13. ПРЕДСТАВЛЕНИЕ ДЛЯ ОТОБРАЖЕНИЯ АКТИВНЫХ БРОНИРОВАНИЙ
CREATE OR ALTER VIEW ActiveBookingsView
AS
SELECT 
    b.BookingId,
    p.LastName + ' ' + p.FirstName AS Пассажир,
    f.FlightNumber AS Номер_рейса,
    dep.City + ' → ' + arr.City AS Маршрут,
    f.ScheduledDeparture AS Вылет,
    s.SeatNumber AS Место,
    fc.ClassName AS Класс,
    b.BookingDate AS Дата_бронирования,
    b.BookingStatus AS Статус,
    ISNULL(t.FinalPrice, f.BasePrice) AS Стоимость
FROM Bookings b
INNER JOIN Passengers p ON b.PassengerId = p.PassengerId
INNER JOIN Flights f ON b.FlightId = f.FlightId
INNER JOIN Airports dep ON f.DepartureAirportId = dep.AirportId
INNER JOIN Airports arr ON f.ArrivalAirportId = arr.AirportId
INNER JOIN Seats s ON b.SeatId = s.SeatId
INNER JOIN FareClasses fc ON s.FareClassId = fc.FareClassId
LEFT JOIN Tickets t ON b.BookingId = t.BookingId
WHERE b.BookingStatus IN ('Подтверждено', 'Ожидает оплаты')
  AND f.ScheduledDeparture > GETDATE();
GO

-- Пример использования представления
-- SELECT * FROM ActiveBookingsView ORDER BY Вылет;
-- GO

PRINT '============================================';
PRINT 'ВСЕ ЗАПРОСЫ УСПЕШНО СОЗДАНЫ!';
PRINT '============================================';
GO