DECLARE @FlightNumber VARCHAR(10) = 'SU 1101';

SELECT 
    f.FlightNumber,
    al.AirlineName,
    dep.City + ' (' + dep.AirportCode + ')' AS Departure,
    arr.City + ' (' + arr.AirportCode + ')' AS Arrival,
    f.ScheduledDeparture,
    COUNT(DISTINCT t.TicketId) AS TicketsSold,
    SUM(t.FinalPrice) AS TotalRevenue,
    AVG(t.FinalPrice) AS AverageTicketPrice,
    MAX(t.FinalPrice) AS MaxTicketPrice,
    MIN(t.FinalPrice) AS MinTicketPrice
FROM Tickets t
INNER JOIN Bookings b ON t.BookingId = b.BookingId
INNER JOIN Flights f ON b.FlightId = f.FlightId
INNER JOIN Airlines al ON f.AirlineId = al.AirlineId
INNER JOIN Airports dep ON f.DepartureAirportId = dep.AirportId
INNER JOIN Airports arr ON f.ArrivalAirportId = arr.AirportId
WHERE f.FlightNumber = @FlightNumber
  AND b.BookingStatus IN ('Confirmed', 'CheckedIn')
GROUP BY f.FlightNumber, al.AirlineName, dep.City, dep.AirportCode, 
         arr.City, arr.AirportCode, f.ScheduledDeparture;