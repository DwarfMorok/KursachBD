DECLARE @FlightNumber VARCHAR(10) = 'SU 1101';

-- Получаем ID рейса, самолета и базовую цену
DECLARE @FlightId INT, @AircraftId INT, @BasePrice DECIMAL(10,2);
SELECT @FlightId = f.FlightId, @AircraftId = f.AircraftId, @BasePrice = f.BasePrice
FROM Flights f WHERE f.FlightNumber = @FlightNumber;

-- Стоимость всех свободных мест
WITH FreeSeats AS (
    SELECT 
        s.SeatId,
        s.SeatNumber,
        fc.ClassName,
        fc.ClassCode,
        fc.Multiplier,
        ROUND(@BasePrice * fc.Multiplier, 2) AS CalculatedPrice
    FROM Seats s
    INNER JOIN FareClasses fc ON s.FareClassId = fc.FareClassId
    WHERE s.AircraftId = @AircraftId
      AND s.SeatId NOT IN (
          SELECT b.SeatId 
          FROM Bookings b 
          WHERE b.FlightId = @FlightId 
            AND b.BookingStatus NOT IN ('Cancelled', 'NoShow')
      )
)
SELECT 
    @FlightNumber AS FlightNumber,
    COUNT(*) AS AvailableSeats,
    SUM(CalculatedPrice) AS PotentialRevenue,
    -- Детали по классам обслуживания
    SUM(CASE WHEN ClassCode = 'F' THEN 1 ELSE 0 END) AS FirstClassSeats,
    SUM(CASE WHEN ClassCode = 'B' THEN 1 ELSE 0 END) AS BusinessSeats,
    SUM(CASE WHEN ClassCode = 'P' THEN 1 ELSE 0 END) AS PremiumEconomySeats,
    SUM(CASE WHEN ClassCode = 'E' THEN 1 ELSE 0 END) AS EconomySeats,
    -- Стоимость по классам
    SUM(CASE WHEN ClassCode = 'F' THEN CalculatedPrice ELSE 0 END) AS FirstClassRevenue,
    SUM(CASE WHEN ClassCode = 'B' THEN CalculatedPrice ELSE 0 END) AS BusinessRevenue,
    SUM(CASE WHEN ClassCode = 'P' THEN CalculatedPrice ELSE 0 END) AS PremiumEconomyRevenue,
    SUM(CASE WHEN ClassCode = 'E' THEN CalculatedPrice ELSE 0 END) AS EconomyRevenue
FROM FreeSeats;