# Веб-приложение «Турфирма» (Delphi 10.2 + IIS + MS SQL Server)

## Состав работы

1. **Анализ рынка** информационных систем, построенных по архитектуре веб-приложений,
   и оценка возможностей их использования в компании — [docs/analysis.md](docs/analysis.md).
2. **Веб-приложение** на Delphi 10.2 (технология WebBroker, публикация через
   MS Internet Information Server) — [src/](src/).
3. **База данных** для веб-приложения в MS SQL Server — [sql/create_database.sql](sql/create_database.sql).

## Что делает приложение

Корпоративный сайт турфирмы на технологии ISAPI:

- `/` — главная страница с навигацией;
- `/tours` — каталог туров, данные читаются из БД MS SQL Server;
- `/order` — форма оформления заказа (GET) и приём заказа (POST) с записью в БД.

Приложение демонстрирует классическую трёхзвенную веб-архитектуру:
браузер (тонкий клиент) → IIS + ISAPI DLL на Delphi → MS SQL Server.

## Сборка приложения

1. Откройте Delphi 10.2 (RAD Studio).
2. **File → New → Other → Delphi Projects → Web → Web Server Application**,
   тип сервера — **ISAPI/ISA Dynamic Link Library**.
3. В появившемся веб-модуле добавьте действия (Actions) в Object Inspector
   так, как указано в файле `src/WebModuleUnit1.dfm`, и свяжите их с обработчиками
   из `src/WebModuleUnit1.pas` (или просто замените содержимое файлов проекта
   файлами из папки `src/`).
4. Настройте строку подключения к БД в `WebModuleUnit1.pas` (конструктор класса):
   укажите свой `Data Source` (имя сервера/экземпляра).
5. Соберите проект: **Project → Build**. Получится файл `TourismWeb.dll`.

## Развёртывание в IIS

1. **Установка IIS** (Windows 10/11): Панель управления → Программы и компоненты →
   Включение или отключение компонентов Windows → Internet Information Services.
   Отметьте компоненты **World Wide Web Services → Application Development Features →
   ISAPI Extensions** и **ISAPI Filters**.
2. Создайте папку `C:\inetpub\wwwroot\TourismWeb` и скопируйте туда `TourismWeb.dll`.
3. Откройте **IIS Manager** (inetmgr): добавьте приложение — сайт Default Web Site →
   **Add Application**, псевдоним `TourismWeb`, физический путь — созданная папка.
4. Если DLL собрана под 32 бита — в пуле приложений включите
   **Enable 32-Bit Applications** (пул соответствует приложению).
5. В **ISAPI and CGI Restrictions** разрешите выполнение `TourismWeb.dll`.
6. Создайте БД на сервере: выполните скрипт [sql/create_database.sql](sql/create_database.sql)
   в SQL Server Management Studio.
7. Откройте в браузере: `http://localhost/TourismWeb/TourismWeb.dll`

## Схема базы данных

| Таблица  | Назначение                                   | Ключ       |
|----------|----------------------------------------------|------------|
| `Tours`  | справочник туров (услуги)                    | `TourID`   |
| `Clients`| справочник клиентов                          | `ClientID` |
| `Orders` | переменная информация: заказы туров          | `OrderID`  |

Внешние ключи: `Orders.ClientID → Clients.ClientID`, `Orders.TourID → Tours.TourID`.

## Файлы репозитория

```
├── README.md                 — этот файл
├── docs/analysis.md          — анализ рынка веб-ИС
├── sql/create_database.sql   — скрипт БД для MS SQL Server
└── src/
    ├── TourismWeb.dpr        — файл проекта (ISAPI DLL)
    ├── WebModuleUnit1.pas    — код веб-модуля и обработчики
    └── WebModuleUnit1.dfm    — описание действий веб-модуля
```

## Автор

[Смелов С.В./ОБПз-42505ПДиибд]
