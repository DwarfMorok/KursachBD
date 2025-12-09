DECLARE @FlightNumber VARCHAR(10) = 'SU 1101';

-- Получаем ID рейса и самолета
DECLARE @FlightId INT, @AircraftId INT;
SELECT @FlightId = f.FlightId, @AircraftId = f.AircraftId
FROM Flights f WHERE f.FlightNumber = @FlightNumber;

-- Все места в самолете минус занятые места на этом рейсе
SELECT 
    s.SeatId,
    s.SeatNumber,
    fc.ClassName,
    fc.ClassCode,
    s.RowNumber,
    s.Position,
    fc.Multiplier,
    ROUND(f.BasePrice * fc.Multiplier, 2) AS CalculatedPrice,
    fc.BaggageAllowance,
    fc.MealIncluded,
    fc.PriorityBoarding,
    fc.LoungeAccess,
    s.IsEmergencyExit,
    s.HasExtraLegroom,
    s.IsBulkhead
FROM Seats s
INNER JOIN FareClasses fc ON s.FareClassId = fc.FareClassId
CROSS JOIN Flights f
WHERE s.AircraftId = @AircraftId
  AND f.FlightId = @FlightId
  AND s.SeatId NOT IN (
      SELECT b.SeatId 
      FROM Bookings b 
      WHERE b.FlightId = @FlightId 
        AND b.BookingStatus NOT IN ('Cancelled', 'NoShow')
  )
ORDER BY 
    fc.FareClassId DESC, -- Сначала бизнес/первый класс
    s.RowNumber, 
    s.Position;