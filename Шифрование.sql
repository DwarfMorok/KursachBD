-- ШИФРОВАНИЕ ПАРОЛЕЙ ПОЛЬЗОВАТЕЛЕЙ В СИСТЕМЕ "ПРОДАЖА АВИАБИЛЕТОВ"
USE AirlineTickets;
GO

-- 1. Создание главного ключа базы данных
IF NOT EXISTS (SELECT * FROM sys.symmetric_keys WHERE name = '##MS_DatabaseMasterKey##')
    CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'SecureAviation2024!';
GO

-- 2. Создание сертификата для шифрования
IF NOT EXISTS (SELECT * FROM sys.certificates WHERE name = 'UserPasswordCertificate')
    CREATE CERTIFICATE UserPasswordCertificate 
    WITH SUBJECT = 'User Password Encryption for Airline Tickets System';
GO

-- 3. Создание симметричного ключа
IF NOT EXISTS (SELECT * FROM sys.symmetric_keys WHERE name = 'UserPasswordEncryptionKey')
    CREATE SYMMETRIC KEY UserPasswordEncryptionKey
    WITH ALGORITHM = AES_256
    ENCRYPTION BY CERTIFICATE UserPasswordCertificate;
GO

-- 4. Создание таблицы пользователей системы (если не существует)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'SystemUsers')
BEGIN
    CREATE TABLE SystemUsers (
        UserId INT IDENTITY(1,1) PRIMARY KEY,
        UserLogin NVARCHAR(50) NOT NULL UNIQUE,
        UserPassword NVARCHAR(100) NULL,
        UserRole NVARCHAR(50) NOT NULL,
        FullName NVARCHAR(100) NOT NULL,
        Email NVARCHAR(100),
        CreatedDate DATETIME DEFAULT GETDATE(),
        IsActive BIT DEFAULT 1
    );
    
    -- Добавляем тестовых пользователей
    INSERT INTO SystemUsers (UserLogin, UserPassword, UserRole, FullName, Email) VALUES
    ('Admin', 'AdminSecurePass123', 'Administrator', 'Администратор Системы', 'admin@airlines.ru'),
    ('PublicGuest', 'GuestReadOnly456', 'Guest', 'Гостевая Учетная Запись', 'guest@airlines.ru'),
    ('BookingManager', 'ManagerPass789', 'Manager', 'Менеджер Бронирований', 'manager@airlines.ru'),
    ('ReportViewer', 'ViewerPass012', 'Viewer', 'Просмотр Отчетов', 'reports@airlines.ru');
    
    PRINT 'Таблица SystemUsers создана и заполнена тестовыми данными';
END
GO

-- 5. Создание временной таблицы для хранения оригинальных паролей
IF OBJECT_ID('tempdb..#TempUserPasswords') IS NOT NULL
    DROP TABLE #TempUserPasswords;

SELECT UserId, UserPassword AS PlainPassword
INTO #TempUserPasswords
FROM SystemUsers
WHERE UserLogin IN ('Admin', 'PublicGuest', 'BookingManager', 'ReportViewer');
GO

-- 6. Удаляем оригинальный столбец с паролями
ALTER TABLE SystemUsers DROP COLUMN UserPassword;
GO

-- 7. Добавляем столбец для зашифрованных паролей
ALTER TABLE SystemUsers ADD UserPassword VARBINARY(MAX) NULL;
GO

-- 8. Шифруем пароли и сохраняем в новый столбец
OPEN SYMMETRIC KEY UserPasswordEncryptionKey 
DECRYPTION BY CERTIFICATE UserPasswordCertificate;

UPDATE su
SET UserPassword = ENCRYPTBYKEY(KEY_GUID('UserPasswordEncryptionKey'), tup.PlainPassword)
FROM SystemUsers su
INNER JOIN #TempUserPasswords tup ON su.UserId = tup.UserId
WHERE su.UserLogin IN ('Admin', 'PublicGuest', 'BookingManager', 'ReportViewer');

CLOSE SYMMETRIC KEY UserPasswordEncryptionKey;
GO

-- 9. Удаляем временную таблицу
DROP TABLE #TempUserPasswords;
GO

-- 10. Проверка шифрования - попытка дешифровки
PRINT 'Проверка работы шифрования:';
PRINT '===========================';

OPEN SYMMETRIC KEY UserPasswordEncryptionKey 
DECRYPTION BY CERTIFICATE UserPasswordCertificate;

SELECT 
    UserId,
    UserLogin,
    UserRole,
    FullName,
    UserPassword AS EncryptedPassword,
    CONVERT(NVARCHAR(100), DECRYPTBYKEY(UserPassword)) AS DecryptedPassword,
    CASE 
        WHEN DECRYPTBYKEY(UserPassword) IS NOT NULL THEN '✓ Успешно'
        ELSE '✗ Ошибка'
    END AS EncryptionStatus
FROM SystemUsers
WHERE UserLogin IN ('Admin', 'PublicGuest');

CLOSE SYMMETRIC KEY UserPasswordEncryptionKey;
GO

-- 11. Создание хранимой процедуры для аутентификации пользователей
CREATE OR ALTER PROCEDURE AuthenticateUser
    @UserLogin NVARCHAR(50),
    @InputPassword NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @StoredPassword NVARCHAR(100);
    DECLARE @UserId INT;
    DECLARE @UserRole NVARCHAR(50);
    DECLARE @FullName NVARCHAR(100);
    DECLARE @IsActive BIT;
    
    -- Открываем ключ для дешифровки
    OPEN SYMMETRIC KEY UserPasswordEncryptionKey 
    DECRYPTION BY CERTIFICATE UserPasswordCertificate;
    
    -- Получаем и расшифровываем пароль
    SELECT 
        @UserId = UserId,
        @StoredPassword = CONVERT(NVARCHAR(100), DECRYPTBYKEY(UserPassword)),
        @UserRole = UserRole,
        @FullName = FullName,
        @IsActive = IsActive
    FROM SystemUsers
    WHERE UserLogin = @UserLogin;
    
    -- Закрываем ключ
    CLOSE SYMMETRIC KEY UserPasswordEncryptionKey;
    
    -- Проверяем аутентификацию
    IF @UserId IS NULL
    BEGIN
        SELECT 
            'FAILURE' AS Status,
            'Пользователь не найден' AS Message,
            NULL AS UserId,
            NULL AS UserRole,
            NULL AS FullName;
        RETURN;
    END
    
    IF @IsActive = 0
    BEGIN
        SELECT 
            'FAILURE' AS Status,
            'Учетная запись не активна' AS Message,
            NULL AS UserId,
            NULL AS UserRole,
            NULL AS FullName;
        RETURN;
    END
    
    IF @StoredPassword = @InputPassword
    BEGIN
        SELECT 
            'SUCCESS' AS Status,
            'Аутентификация успешна' AS Message,
            @UserId AS UserId,
            @UserRole AS UserRole,
            @FullName AS FullName;
    END
    ELSE
    BEGIN
        SELECT 
            'FAILURE' AS Status,
            'Неверный пароль' AS Message,
            NULL AS UserId,
            NULL AS UserRole,
            NULL AS FullName;
    END
END;
GO

-- 12. Создание процедуры для смены пароля
CREATE OR ALTER PROCEDURE ChangeUserPassword
    @UserLogin NVARCHAR(50),
    @OldPassword NVARCHAR(100),
    @NewPassword NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @AuthResult TABLE (
        Status NVARCHAR(20),
        Message NVARCHAR(100),
        UserId INT,
        UserRole NVARCHAR(50),
        FullName NVARCHAR(100)
    );
    
    -- Сначала аутентифицируем пользователя
    INSERT INTO @AuthResult
    EXEC AuthenticateUser @UserLogin, @OldPassword;
    
    -- Если аутентификация успешна
    IF EXISTS (SELECT 1 FROM @AuthResult WHERE Status = 'SUCCESS')
    BEGIN
        DECLARE @UserId INT;
        SELECT @UserId = UserId FROM @AuthResult;
        
        -- Открываем ключ для шифрования
        OPEN SYMMETRIC KEY UserPasswordEncryptionKey 
        DECRYPTION BY CERTIFICATE UserPasswordCertificate;
        
        -- Шифруем и сохраняем новый пароль
        UPDATE SystemUsers
        SET UserPassword = ENCRYPTBYKEY(KEY_GUID('UserPasswordEncryptionKey'), @NewPassword)
        WHERE UserId = @UserId;
        
        -- Закрываем ключ
        CLOSE SYMMETRIC KEY UserPasswordEncryptionKey;
        
        SELECT 
            'SUCCESS' AS Status,
            'Пароль успешно изменен' AS Message,
            @UserId AS UserId;
    END
    ELSE
    BEGIN
        SELECT * FROM @AuthResult;
    END
END;
GO

-- 13. Тестирование аутентификации
PRINT '';
PRINT 'Тестирование аутентификации:';
PRINT '===========================';

-- Тест 1: Успешная аутентификация Admin
EXEC AuthenticateUser 'Admin', 'AdminSecurePass123';

-- Тест 2: Успешная аутентификация PublicGuest
EXEC AuthenticateUser 'PublicGuest', 'GuestReadOnly456';

-- Тест 3: Неверный пароль
EXEC AuthenticateUser 'Admin', 'WrongPassword';

-- Тест 4: Несуществующий пользователь
EXEC AuthenticateUser 'NonExistent', 'SomePassword';
GO

-- 14. Тестирование смены пароля
PRINT '';
PRINT 'Тестирование смены пароля:';
PRINT '===========================';

-- Смена пароля для Admin
EXEC ChangeUserPassword 'Admin', 'AdminSecurePass123', 'NewAdminPassword2024!';

-- Проверка нового пароля
EXEC AuthenticateUser 'Admin', 'NewAdminPassword2024!';
EXEC AuthenticateUser 'Admin', 'AdminSecurePass123';
GO

-- 15. Создание представления для безопасного просмотра пользователей
CREATE OR ALTER VIEW SystemUsersSecure
AS
SELECT 
    UserId,
    UserLogin,
    UserRole,
    FullName,
    Email,
    CreatedDate,
    IsActive,
    '********' AS PasswordMasked, -- Маскированный пароль
    CASE 
        WHEN UserPassword IS NOT NULL THEN 'Зашифрован'
        ELSE 'Не установлен'
    END AS PasswordStatus
FROM SystemUsers;
GO

-- 16. Проверка представления
PRINT '';
PRINT 'Проверка безопасного представления:';
PRINT '==================================';
SELECT * FROM SystemUsersSecure;
GO

-- 17. Информация о созданных объектах шифрования
PRINT '';
PRINT 'ИНФОРМАЦИЯ О СИСТЕМЕ ШИФРОВАНИЯ:';
PRINT '===============================';

-- Главный ключ
SELECT 
    'Главный ключ базы данных' AS ObjectType,
    name AS ObjectName,
    'Создан' AS Status
FROM sys.symmetric_keys 
WHERE name = '##MS_DatabaseMasterKey##'

UNION ALL

-- Сертификат
SELECT 
    'Сертификат шифрования',
    name,
    'Создан'
FROM sys.certificates 
WHERE name = 'UserPasswordCertificate'

UNION ALL

-- Симметричный ключ
SELECT 
    'Симметричный ключ',
    name,
    'Создан'
FROM sys.symmetric_keys 
WHERE name = 'UserPasswordEncryptionKey'

UNION ALL

-- Зашифрованные пользователи
SELECT 
    'Зашифрованные пароли',
    'Пользователи системы',
    'Зашифровано: ' + CAST(COUNT(*) AS NVARCHAR) + ' записей'
FROM SystemUsers 
WHERE UserPassword IS NOT NULL;
GO

PRINT '';
PRINT '===============================================';
PRINT 'ШИФРОВАНИЕ ПАРОЛЕЙ ПОЛЬЗОВАТЕЛЕЙ ЗАВЕРШЕНО!';
PRINT '===============================================';
PRINT 'Зашифрованы пароли для ролей:';
PRINT '1. Admin (Администратор)';
PRINT '2. PublicGuest (Гостевая учетная запись)';
PRINT '3. BookingManager (Менеджер бронирований)';
PRINT '4. ReportViewer (Просмотр отчетов)';
PRINT '===============================================';