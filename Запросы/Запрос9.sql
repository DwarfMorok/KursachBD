-- По номеру документа
DECLARE @PassengerDocument VARCHAR(20) = (SELECT TOP 1 DocumentNumber FROM Passengers);
DECLARE @StartDate DATETIME2 = '2024-01-01';
DECLARE @EndDate DATETIME2 = GETDATE();

SELECT 
    p.PassengerId,
    p.LastName + ' ' + p.FirstName + ISNULL(' ' + p.MiddleName, '') AS PassengerName,
    p.DocumentNumber,
    p.BirthDate,
    DATEDIFF(YEAR, p.BirthDate, GETDATE()) AS Age,
    p.Citizenship,
    @StartDate AS PeriodStart,
    @EndDate AS PeriodEnd,
    -- Статистика по билетам
    COUNT(DISTINCT t.TicketId) AS TicketsPurchased,
    COUNT(DISTINCT b.FlightId) AS UniqueFlights,
    COUNT(DISTINCT f.AirlineId) AS UniqueAirlines,
    SUM(t.FinalPrice) AS TotalSpent,
    FORMAT(AVG(t.FinalPrice), 'N2') AS AverageTicketPrice,
    FORMAT(MAX(t.FinalPrice), 'N2') AS MostExpensiveTicket,
    FORMAT(MIN(t.FinalPrice), 'N2') AS CheapestTicket,
    -- Детализация по классам
    SUM(CASE WHEN fc.ClassCode = 'F' THEN 1 ELSE 0 END) AS FirstClassTickets,
    SUM(CASE WHEN fc.ClassCode = 'B' THEN 1 ELSE 0 END) AS BusinessClassTickets,
    SUM(CASE WHEN fc.ClassCode = 'P' THEN 1 ELSE 0 END) AS PremiumEconomyTickets,
    SUM(CASE WHEN fc.ClassCode = 'E' THEN 1 ELSE 0 END) AS EconomyTickets,
    -- Суммы по классам
    FORMAT(SUM(CASE WHEN fc.ClassCode = 'F' THEN t.FinalPrice ELSE 0 END), 'N2') AS FirstClassSpent,
    FORMAT(SUM(CASE WHEN fc.ClassCode = 'B' THEN t.FinalPrice ELSE 0 END), 'N2') AS BusinessClassSpent,
    FORMAT(SUM(CASE WHEN fc.ClassCode = 'P' THEN t.FinalPrice ELSE 0 END), 'N2') AS PremiumEconomySpent,
    FORMAT(SUM(CASE WHEN fc.ClassCode = 'E' THEN t.FinalPrice ELSE 0 END), 'N2') AS EconomySpent,
    -- Активность по месяцам
    (SELECT STRING_AGG(FORMAT(DATEPART(MONTH, t2.IssueDate), '00') + '/' + 
                      CAST(DATEPART(YEAR, t2.IssueDate) AS VARCHAR), ', ')
     FROM Tickets t2
     INNER JOIN Bookings b2 ON t2.BookingId = b2.BookingId
     WHERE b2.PassengerId = p.PassengerId
       AND t2.IssueDate BETWEEN @StartDate AND @EndDate) AS ActiveMonths
FROM Passengers p
INNER JOIN Bookings b ON p.PassengerId = b.PassengerId
INNER JOIN Tickets t ON b.BookingId = t.BookingId
INNER JOIN Flights f ON b.FlightId = f.FlightId
INNER JOIN Seats s ON b.SeatId = s.SeatId
INNER JOIN FareClasses fc ON s.FareClassId = fc.FareClassId
WHERE p.DocumentNumber = @PassengerDocument
  AND t.IssueDate BETWEEN @StartDate AND @EndDate
  AND b.BookingStatus IN ('Confirmed', 'CheckedIn')
GROUP BY p.PassengerId, p.LastName, p.FirstName, p.MiddleName, 
         p.DocumentNumber, p.BirthDate, p.Citizenship;