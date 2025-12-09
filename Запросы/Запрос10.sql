SELECT 
    f.FlightId,
    f.FlightNumber,
    al.AirlineName,
    al.AirlineCode,
    dep.AirportCode + ' - ' + dep.City AS Departure,
    arr.AirportCode + ' - ' + arr.City AS Arrival,
    f.ScheduledDeparture,
    f.ScheduledArrival,
    ac.Model AS AircraftModel,
    ac.TotalSeats,
    -- Статистика по пассажирам
    COUNT(DISTINCT b.PassengerId) AS PassengersCount,
    COUNT(DISTINCT CASE WHEN b.BookingStatus IN ('Confirmed', 'CheckedIn') 
                   THEN b.PassengerId END) AS ConfirmedPassengers,
    COUNT(DISTINCT CASE WHEN b.BookingStatus = 'Cancelled' 
                   THEN b.PassengerId END) AS CancelledPassengers,
    COUNT(DISTINCT CASE WHEN b.BookingStatus = 'NoShow' 
                   THEN b.PassengerId END) AS NoShowPassengers,
    -- Загрузка самолета
    FORMAT(COUNT(DISTINCT CASE WHEN b.BookingStatus IN ('Confirmed', 'CheckedIn') 
                          THEN b.PassengerId END) * 100.0 / ac.TotalSeats, 'N1') + '%' AS LoadFactor,
    -- Дети на рейсе
    COUNT(DISTINCT CASE WHEN DATEDIFF(YEAR, p.BirthDate, f.ScheduledDeparture) < 12 
                   THEN p.PassengerId END) AS ChildrenCount
FROM Flights f
INNER JOIN Airlines al ON f.AirlineId = al.AirlineId
INNER JOIN Airports dep ON f.DepartureAirportId = dep.AirportId
INNER JOIN Airports arr ON f.ArrivalAirportId = arr.AirportId
INNER JOIN Aircrafts ac ON f.AircraftId = ac.AircraftId
LEFT JOIN Bookings b ON f.FlightId = b.FlightId
LEFT JOIN Passengers p ON b.PassengerId = p.PassengerId
GROUP BY f.FlightId, f.FlightNumber, al.AirlineName, al.AirlineCode,
         dep.AirportCode, dep.City, arr.AirportCode, arr.City,
         f.ScheduledDeparture, f.ScheduledArrival, ac.Model, ac.TotalSeats
ORDER BY f.ScheduledDeparture DESC;