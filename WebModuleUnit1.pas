unit WebModuleUnit1;

interface

uses
  System.SysUtils, System.Classes, Web.HTTPApp, Data.DB, Data.Win.ADODB;

type
  TWebModule1 = class(TWebModule)
    procedure WebModule1DefaultAction(Sender: TObject; Request: TWebRequest;
      Response: TWebResponse; var Handled: Boolean);
    procedure WebModule1ToursAction(Sender: TObject; Request: TWebRequest;
      Response: TWebResponse; var Handled: Boolean);
    procedure WebModule1OrderAction(Sender: TObject; Request: TWebRequest;
      Response: TWebResponse; var Handled: Boolean);
  private
    FConn: TADOConnection;
    FQuery: TADOQuery;
    function Page(const ATitle, ABody: string): string;
    function Q(const S: string): string; // экранирование HTML
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  WebModuleClass: TComponentClass = TWebModule1;

implementation

{$R *.dfm}

constructor TWebModule1.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FConn := TADOConnection.Create(Self);
  FConn.LoginPrompt := False;
  // При необходимости укажите свой сервер и способ входа:
  // Integrated Security=SSPI — вход под учётной записью Windows,
  // либо User ID=...;Password=... — SQL-аутентификация
  FConn.ConnectionString :=
    'Provider=SQLOLEDB.1;Data Source=localhost;' +
    'Initial Catalog=TourismWeb;Integrated Security=SSPI;';
  FConn.Connected := True;
  FQuery := TADOQuery.Create(Self);
  FQuery.Connection := FConn;
end;

destructor TWebModule1.Destroy;
begin
  FQuery.Free;
  FConn.Free;
  inherited;
end;

function TWebModule1.Q(const S: string): string;
begin
  Result := S;
  Result := StringReplace(Result, '&', '&amp;', [rfReplaceAll]);
  Result := StringReplace(Result, '<', '&lt;', [rfReplaceAll]);
  Result := StringReplace(Result, '>', '&gt;', [rfReplaceAll]);
end;

function TWebModule1.Page(const ATitle, ABody: string): string;
begin
  Result :=
    '<!DOCTYPE html>' + sLineBreak +
    '<html lang="ru"><head><meta charset="utf-8">' +
    '<title>' + Q(ATitle) + '</title>' +
    '<style>' +
    'body{font-family:Arial,sans-serif;max-width:900px;margin:30px auto;}' +
    'table{border-collapse:collapse;width:100%;}' +
    'td,th{border:1px solid #999;padding:6px 10px;text-align:left;}' +
    'th{background:#2d5f8a;color:#fff;}' +
    'h1{color:#2d5f8a;}' +
    '</style></head><body>' +
    '<h1>' + Q(ATitle) + '</h1>' + ABody +
    '<hr><p><a href="/">На главную</a></p></body></html>';
end;

// ---------- Главная страница ----------
procedure TWebModule1.WebModule1DefaultAction(Sender: TObject;
  Request: TWebRequest; Response: TWebResponse; var Handled: Boolean);
begin
  Response.Content := Page('Турфирма «Кругосвет»',
    '<p>Веб-приложение турфирмы. Серверный модуль: Delphi 10.2 WebBroker (ISAPI).' +
    ' База данных: MS SQL Server.</p>' +
    '<ul>' +
    '<li><a href="/tours">Каталог туров</a></li>' +
    '<li><a href="/order">Оформить заказ</a></li>' +
    '</ul>');
  Handled := True;
end;

// ---------- Каталог туров ----------
procedure TWebModule1.WebModule1ToursAction(Sender: TObject;
  Request: TWebRequest; Response: TWebResponse; var Handled: Boolean);
var
  SB: TStringBuilder;
begin
  SB := TStringBuilder.Create;
  try
    try
      FQuery.Close;
      FQuery.SQL.Text :=
        'SELECT TourID, TourName, Country, DurationDays, Price FROM Tours ORDER BY Price';
      FQuery.Open;

      SB.AppendLine('<h2>Каталог туров</h2>');
      SB.AppendLine('<table><tr><th>Название</th><th>Страна</th>' +
        '<th>Дней</th><th>Цена, руб.</th></tr>');
      while not FQuery.Eof do
      begin
        SB.AppendLine(Format(
          '<tr><td><a href="/order?tour=%d">%s</a></td><td>%s</td><td>%d</td><td>%.2f</td></tr>',
          [FQuery.FieldByName('TourID').AsInteger,
           Q(FQuery.FieldByName('TourName').AsString),
           Q(FQuery.FieldByName('Country').AsString),
           FQuery.FieldByName('DurationDays').AsInteger,
           FQuery.FieldByName('Price').AsFloat]));
        FQuery.Next;
      end;
      SB.AppendLine('</table>');
      FQuery.Close;
    except
      on E: Exception do
        SB.AppendLine('<p style="color:red">Ошибка доступа к базе данных: ' +
          Q(E.Message) + '</p>');
    end;
    Response.Content := Page('Каталог туров', SB.ToString);
  finally
    SB.Free;
  end;
  Handled := True;
end;

// ---------- Оформление заказа (GET — форма, POST — приём заказа) ----------
procedure TWebModule1.WebModule1OrderAction(Sender: TObject;
  Request: TWebRequest; Response: TWebResponse; var Handled: Boolean);
var
  SB: TStringBuilder;
  TourID, ClientID, OrderID, Persons: Integer;
  Name, Phone: string;
begin
  SB := TStringBuilder.Create;
  try
    if Request.MethodType = mtPost then
    begin
      // Приём данных формы
      Name   := Trim(Request.ContentFields.Values['name']);
      Phone  := Trim(Request.ContentFields.Values['phone']);
      TourID := StrToIntDef(Trim(Request.ContentFields.Values['tour_id']), 0);
      Persons := StrToIntDef(Trim(Request.ContentFields.Values['persons']), 1);
      if Persons < 1 then Persons := 1;

      if (Name = '') or (Phone = '') or (TourID = 0) then
      begin
        Response.Content := Page('Ошибка',
          '<p style="color:red">Заполните все поля формы.</p>' +
          '<p><a href="/order">Вернуться к форме</a></p>');
        Handled := True;
        Exit;
      end;

      try
        // Находим или создаём клиента
        FQuery.Close;
        FQuery.SQL.Text := 'SELECT ClientID FROM Clients WHERE Phone = :p';
        FQuery.Parameters.ParamByName('p').Value := Phone;
        FQuery.Open;
        if FQuery.Eof then
        begin
          FQuery.Close;
          FQuery.SQL.Text := 'INSERT INTO Clients (FullName, Phone) VALUES (:n, :p)';
          FQuery.Parameters.ParamByName('n').Value := Name;
          FQuery.Parameters.ParamByName('p').Value := Phone;
          FQuery.ExecSQL;
          FQuery.SQL.Text := 'SELECT ClientID FROM Clients WHERE Phone = :p';
          FQuery.Parameters.ParamByName('p').Value := Phone;
          FQuery.Open;
        end;
        ClientID := FQuery.FieldByName('ClientID').AsInteger;

        // Создаём заказ
        FQuery.Close;
        FQuery.SQL.Text :=
          'INSERT INTO Orders (ClientID, TourID, Persons) ' +
          'VALUES (:c, :t, :p)';
        FQuery.Parameters.ParamByName('c').Value := ClientID;
        FQuery.Parameters.ParamByName('t').Value := TourID;
        FQuery.Parameters.ParamByName('p').Value := Persons;
        FQuery.ExecSQL;

        // Узнаём номер созданного заказа
        FQuery.SQL.Text :=
          'SELECT MAX(OrderID) AS OrderID FROM Orders';
        FQuery.Open;
        OrderID := FQuery.FieldByName('OrderID').AsInteger;
        FQuery.Close;

        SB.AppendLine(Format(
          '<h2>Заказ №%d принят!</h2>', [OrderID]));
        SB.AppendLine('<p>Спасибо, ' + Q(Name) +
          '. Менеджер свяжется с вами по телефону ' + Q(Phone) + '.</p>');
      except
        on E: Exception do
          SB.AppendLine('<p style="color:red">Ошибка базы данных: ' +
            Q(E.Message) + '</p>');
      end;
    end
    else
    begin
      // Показ формы
      TourID := StrToIntDef(Trim(Request.QueryFields.Values['tour']), 0);
      SB.AppendLine('<h2>Оформление заказа</h2>');
      SB.AppendLine('<form method="post" action="/order">');
      SB.AppendLine('<p>Ваше имя: <input type="text" name="name" required></p>');
      SB.AppendLine('<p>Телефон: <input type="text" name="phone" required></p>');
      SB.Append('<p>Тур: <select name="tour_id">');
      try
        FQuery.Close;
        FQuery.SQL.Text :=
          'SELECT TourID, TourName, Price FROM Tours ORDER BY TourName';
        FQuery.Open;
        while not FQuery.Eof do
        begin
          if FQuery.FieldByName('TourID').AsInteger = TourID then
            SB.Append('<option value="' +
              IntToStr(FQuery.FieldByName('TourID').AsInteger) + '" selected>')
          else
            SB.Append('<option value="' +
              IntToStr(FQuery.FieldByName('TourID').AsInteger) + '">');
          SB.Append(Q(FQuery.FieldByName('TourName').AsString) +
            ' — ' + FormatFloat('0.00', FQuery.FieldByName('Price').AsFloat) +
            ' руб.</option>');
          FQuery.Next;
        end;
        FQuery.Close;
      except
        on E: Exception do
          SB.Append('<option>Нет связи с базой данных</option>');
      end;
      SB.AppendLine('</select></p>');
      SB.AppendLine('<p>Человек: <input type="number" name="persons" value="1" min="1"></p>');
      SB.AppendLine('<p><input type="submit" value="Отправить заказ"></p>');
      SB.AppendLine('</form>');
    end;
    Response.Content := Page('Оформление заказа', SB.ToString);
  finally
    SB.Free;
  end;
  Handled := True;
end;

end.
