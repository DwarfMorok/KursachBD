SELECT 
    f.FlightId,
    f.FlightNumber,
    al.AirlineName,
    al.AirlineCode,
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
    ac.Model AS AircraftModel,
    ac.RegistrationNumber,
    f.BasePrice,
    f.Status,
    f.Gate,
    f.Terminal,
    DATEDIFF(MINUTE, f.ScheduledDeparture, f.ScheduledArrival) AS DurationMinutes
FROM Flights f
INNER JOIN Airlines al ON f.AirlineId = al.AirlineId
INNER JOIN Airports dep ON f.DepartureAirportId = dep.AirportId
INNER JOIN Airports arr ON f.ArrivalAirportId = arr.AirportId
INNER JOIN Aircrafts ac ON f.AircraftId = ac.AircraftId
ORDER BY f.ScheduledDeparture DESC;