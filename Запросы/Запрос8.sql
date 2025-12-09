SELECT 
    COUNT(*) AS TotalChildren,
    COUNT(DISTINCT p.PassengerId) AS UniqueChildren,
    MIN(DATEDIFF(YEAR, BirthDate, GETDATE())) AS MinAge,
    MAX(DATEDIFF(YEAR, BirthDate, GETDATE())) AS MaxAge
FROM Passengers p
WHERE DATEDIFF(YEAR, p.BirthDate, GETDATE()) < 18;

-- Проверка: есть ли дети на рейсах
SELECT 
    f.FlightNumber,
    COUNT(p.PassengerId) AS ChildrenCount,
    STRING_AGG(p.LastName + ' ' + p.FirstName, ', ') AS ChildrenNames
FROM Bookings b
INNER JOIN Passengers p ON b.PassengerId = p.PassengerId
INNER JOIN Flights f ON b.FlightId = f.FlightId
WHERE b.BookingStatus = 'Confirmed'
  AND DATEDIFF(YEAR, p.BirthDate, f.ScheduledDeparture) < 18
GROUP BY f.FlightNumber
ORDER BY ChildrenCount DESC;

-- Проверка: какие рейсы имеют детей (чтобы выбрать правильный номер рейса)
SELECT TOP 5
    f.FlightNumber,
    al.AirlineName,
    dep.City + ' → ' + arr.City AS Route,
    f.ScheduledDeparture,
    COUNT(p.PassengerId) AS ChildrenOnFlight
FROM Bookings b
INNER JOIN Passengers p ON b.PassengerId = p.PassengerId
INNER JOIN Flights f ON b.FlightId = f.FlightId
INNER JOIN Airlines al ON f.AirlineId = al.AirlineId
INNER JOIN Airports dep ON f.DepartureAirportId = dep.AirportId
INNER JOIN Airports arr ON f.ArrivalAirportId = arr.AirportId
WHERE b.BookingStatus = 'Confirmed'
  AND DATEDIFF(YEAR, p.BirthDate, f.ScheduledDeparture) < 12 -- Только до 12 лет
GROUP BY f.FlightNumber, al.AirlineName, dep.City, arr.City, f.ScheduledDeparture
ORDER BY ChildrenOnFlight DESC;