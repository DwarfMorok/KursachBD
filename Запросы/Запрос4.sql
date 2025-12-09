DECLARE @LastName NVARCHAR(50) = 'Иванов';
DECLARE @FirstName NVARCHAR(50) = 'Иван';

SELECT 
    p.PassengerId,
    p.LastName,
    p.FirstName,
    p.MiddleName,
    p.DocumentNumber,
    p.Citizenship,
    f.FlightNumber,
    al.AirlineName,
    dep.AirportCode AS DepartureCode,
    dep.City AS DepartureCity,
    dep.Country AS DepartureCountry,
    arr.AirportCode AS ArrivalCode,
    arr.City AS ArrivalCity,
    arr.Country AS ArrivalCountry,
    f.ScheduledDeparture,
    f.ScheduledArrival,
    f.ActualDeparture,
    f.ActualArrival,
    f.Status AS FlightStatus,
    s.SeatNumber,
    fc.ClassName,
    b.BookingStatus,
    b.BookingDate,
    t.TicketNumber,
    t.FinalPrice AS TicketPrice,
    pm.PaymentMethod,
    pm.PaymentDate,
    pm.PaymentStatus,
    bg.BaggageNumber,
    bg.Weight AS BaggageWeight,
    bg.Type AS BaggageType,
    bg.Status AS BaggageStatus,
    DATEDIFF(DAY, f.ScheduledDeparture, GETDATE()) AS DaysAgo
FROM Passengers p
INNER JOIN Bookings b ON p.PassengerId = b.PassengerId
INNER JOIN Flights f ON b.FlightId = f.FlightId
INNER JOIN Airlines al ON f.AirlineId = al.AirlineId
INNER JOIN Airports dep ON f.DepartureAirportId = dep.AirportId
INNER JOIN Airports arr ON f.ArrivalAirportId = arr.AirportId
INNER JOIN Seats s ON b.SeatId = s.SeatId
INNER JOIN FareClasses fc ON s.FareClassId = fc.FareClassId
LEFT JOIN Tickets t ON b.BookingId = t.BookingId
LEFT JOIN Payments pm ON t.TicketId = pm.TicketId
LEFT JOIN Baggage bg ON t.TicketId = bg.TicketId
WHERE p.LastName = @LastName 
  AND p.FirstName = @FirstName
ORDER BY f.ScheduledDeparture DESC;