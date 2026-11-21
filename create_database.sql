-- База данных для веб-приложения «Турфирма»
-- СУБД: MS SQL Server (выполняется в SQL Server Management Studio)

IF DB_ID('TourismWeb') IS NULL
    CREATE DATABASE TourismWeb;
GO

USE TourismWeb;
GO

-- ---------- Справочник туров (перечень услуг) ----------
IF OBJECT_ID('Orders', 'U') IS NOT NULL DROP TABLE Orders;
IF OBJECT_ID('Clients', 'U') IS NOT NULL DROP TABLE Clients;
IF OBJECT_ID('Tours', 'U') IS NOT NULL DROP TABLE Tours;
GO

CREATE TABLE Tours (
    TourID       INT IDENTITY(1,1) PRIMARY KEY,   -- первичный ключ
    TourName     NVARCHAR(100) NOT NULL,
    Country      NVARCHAR(60)  NOT NULL,
    DurationDays INT           NOT NULL,
    Price        DECIMAL(10,2) NOT NULL
);
GO

-- ---------- Справочник клиентов ----------
CREATE TABLE Clients (
    ClientID INT IDENTITY(1,1) PRIMARY KEY,       -- первичный ключ
    FullName NVARCHAR(120) NOT NULL,
    Phone    NVARCHAR(20)  NOT NULL
);
GO

-- ---------- Переменная информация: заказы ----------
CREATE TABLE Orders (
    OrderID   INT IDENTITY(1,1) PRIMARY KEY,      -- первичный ключ
    ClientID  INT NOT NULL,
    TourID    INT NOT NULL,
    OrderDate DATE NOT NULL CONSTRAINT DF_Orders_Date DEFAULT GETDATE(),
    Persons   INT  NOT NULL CONSTRAINT DF_Orders_Persons DEFAULT 1,
    Status    NVARCHAR(20) NOT NULL CONSTRAINT DF_Orders_Status DEFAULT N'новый',

    CONSTRAINT FK_Orders_Clients FOREIGN KEY (ClientID)
        REFERENCES Clients (ClientID),
    CONSTRAINT FK_Orders_Tours FOREIGN KEY (TourID)
        REFERENCES Tours (TourID)
);
GO

-- ---------- Тестовые данные ----------
INSERT INTO Tours (TourName, Country, DurationDays, Price) VALUES
(N'Золотое кольцо России', N'Россия',  5, 35000.00),
(N'Сочи — море и горы',    N'Россия',  7, 52000.00),
(N'Анталия, всё включено', N'Турция', 10, 89000.00),
(N'Шарм-эль-Шейх',         N'Египет',  9, 76000.00),
(N'Пекин и Великая стена', N'Китай',  12, 124000.00);

INSERT INTO Clients (FullName, Phone) VALUES
(N'Иванов Пётр Сергеевич',    N'+7-910-123-45-67'),
(N'Смирнова Анна Игоревна',   N'+7-920-234-56-78'),
(N'Кузнецов Олег Дмитриевич', N'+7-930-345-67-89');

INSERT INTO Orders (ClientID, TourID, OrderDate, Persons, Status) VALUES
(1, 1, '2026-11-10', 2, N'оплачен'),
(2, 3, '2026-11-15', 1, N'новый'),
(3, 5, '2026-11-18', 3, N'новый');
GO
