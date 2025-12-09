DECLARE @StartDate DATETIME2 = '2024-01-01';
DECLARE @EndDate DATETIME2 = '2024-12-31';

SELECT 
    FORMAT(@StartDate, 'dd.MM.yyyy') + ' - ' + FORMAT(@EndDate, 'dd.MM.yyyy') AS Period,
    COUNT(DISTINCT t.TicketId) AS TicketsSold,
    COUNT(DISTINCT b.PassengerId) AS UniquePassengers,
    COUNT(DISTINCT f.FlightId) AS FlightsCount,
    SUM(t.FinalPrice) AS TotalRevenue,
    AVG(t.FinalPrice) AS AverageTicketPrice,
    SUM(t.FinalPrice) / COUNT(DISTINCT f.FlightId) AS RevenuePerFlight
FROM Tickets t
INNER JOIN Bookings b ON t.BookingId = b.BookingId
INNER JOIN Flights f ON b.FlightId = f.FlightId
WHERE t.IssueDate BETWEEN @StartDate AND @EndDate
  AND b.BookingStatus IN ('Confirmed', 'CheckedIn');