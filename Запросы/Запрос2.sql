DECLARE @FlightNumber VARCHAR(10) = 'SU 1101';

SELECT 
    p.PassengerId,
    p.LastName,
    p.FirstName,
    p.MiddleName,
    p.BirthDate,
    DATEDIFF(YEAR, p.BirthDate, GETDATE()) AS Age,
    p.Gender,
    p.DocumentType,
    p.DocumentNumber,
    p.Citizenship,
    p.PhoneNumber,
    p.Email,
    p.FrequentFlyerNumber,
    b.BookingId,
    s.SeatNumber,
    fc.ClassName,
    b.BookingStatus,
    b.BookingDate,
    b.SpecialRequests,
    t.TicketNumber,
    t.FinalPrice AS TicketPrice,
    pm.PaymentMethod,
    pm.PaymentStatus
FROM Bookings b
INNER JOIN Passengers p ON b.PassengerId = p.PassengerId
INNER JOIN Flights f ON b.FlightId = f.FlightId
INNER JOIN Seats s ON b.SeatId = s.SeatId
INNER JOIN FareClasses fc ON s.FareClassId = fc.FareClassId
LEFT JOIN Tickets t ON b.BookingId = t.BookingId
LEFT JOIN Payments pm ON t.TicketId = pm.TicketId
WHERE f.FlightNumber = @FlightNumber
  AND b.BookingStatus NOT IN ('Cancelled')
ORDER BY p.LastName, p.FirstName;