unit unit_sat;

{$mode objfpc}{$H+}
{$R-} // Отключить проверку диапазонов
{$OPTIMIZATION ON} // Включить оптимизацию
{$WARN SYMBOL_PLATFORM OFF}
{$TYPEDADDRESS OFF}
{$ASMMODE INTEL}
{$WARN 6058 OFF} // Disable "call to subroutine marked as inline"
interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls, Math;

type

    TCelestialBody = record
    Name: string;
    GM: Double;     // Гравитационный параметр (м³/с²)
    Radius: Double; // Радиус тела (в км)
  end;

  { TForm1 }

  TForm1 = class(TForm)
    ButtonCalculate: TButton;
    CheckBoxCustomBody: TCheckBox;
    ComboBoxPlanet: TComboBox;
    ComboBoxSatellite: TComboBox;
    EditRadius: TEdit;
    EditMass: TEdit;
    EditApoapsisTarget: TEdit;
    EditEccentricityTarget: TEdit;
    EditPeriapsisInit: TEdit;
    EditApoapsisInit: TEdit;
    EditPeriapsisTarget: TEdit;
    EditSemiMajorAxisInit: TEdit;
    EditEccentricityInit: TEdit;
    EditSemiMajorAxisTarget: TEdit;
    GroupBoxInitialOrbit: TGroupBox;
    GroupBoxTargetOrbit: TGroupBox;
    LabelPlanet: TLabel;
    LabelApoapsisTarget: TLabel;
    LabelEccentricityTarget: TLabel;
    LabelPeriapsisInit: TLabel;
    LabelApoapsisInit: TLabel;
    LabelPeriapsisTarget: TLabel;
    LabelSemiMajorAxisInit: TLabel;
    LabelEccentricityInit: TLabel;
    LabelSemiMajorAxisTarget: TLabel;
    MemoResults: TMemo;
    RadioGroupInitialOrbit: TRadioGroup;
    RadioGroupTargetOrbit: TRadioGroup;
    procedure ButtonCalculateClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure RadioGroupInitialOrbitClick(Sender: TObject);
    procedure RadioGroupTargetOrbitClick(Sender: TObject);
    procedure UpdateSatellitesList;
    procedure ComboBoxPlanetChange(Sender: TObject);
    procedure CheckBoxCustomBodyChange(Sender: TObject);
  private
    FLastGM: Double;
    FLastRadius: Double;
    function GetBurnType(DeltaV: Double): string;
    procedure GetGravityParams(out GM, Radius: Double);
    procedure UpdateInitialOrbitInputs;
    procedure UpdateTargetOrbitInputs;
    procedure EditScientificKeyPress(Sender: TObject; var Key: Char);
    procedure EditScientificChange(Sender: TObject);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure SatelliteChanged(Sender: TObject);
    function CalculateDeltaVWithDetails(out Vperi, Vapo, Period: Double; out Impulses: Integer): Double;
    function SafeStrToFloat(const S: string; Default: Double = 0.0): Double;
    procedure ValidateOrbitParameters;
  public
  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

const
  // Основные планеты (индексы 0-8)
  Planets: array[0..8] of TCelestialBody = (
  (Name: 'Меркурий'; GM: 2.203178e13; Radius: 2439.7),
  (Name: 'Венера';   GM: 3.248586e14; Radius: 6049.0),
  (Name: 'Земля';    GM: 3.986004e14; Radius: 6371.0),
  (Name: 'Марс';     GM: 4.282831e13; Radius: 3375.8),
  (Name: 'Юпитер';   GM: 1.266865e17; Radius: 69373.0),
  (Name: 'Сатурн';   GM: 3.793119e16; Radius: 57216.0),
  (Name: 'Уран';     GM: 5.793940e15; Radius: 24702.0),
  (Name: 'Нептун';   GM: 6.836530e15; Radius: 24085.0),
  (Name: 'Плутон';   GM: 8.71e11;    Radius: 1187.0)
);
  // Спутники (группируем по родительским планетам)
  Satellites: array[0..6] of array of TCelestialBody = (
    // Земля (индекс 2 в основном массиве планет)
    (
      (Name: 'Луна';      GM: 4.9048695e12; Radius: 1737.4)
    ),

    // Марс (индекс 3)
    (
      (Name: 'Фобос';     GM: 7.08e9;      Radius: 11.1),
      (Name: 'Деймос';    GM: 1.48e9;      Radius: 6.2)
    ),

    // Юпитер (индекс 4)
    (
      (Name: 'Ио';        GM: 5.959916e12; Radius: 1821.6),
      (Name: 'Европа';    GM: 3.202739e12; Radius: 1560.8),
      (Name: 'Ганимед';   GM: 9.887819e12; Radius: 2631.2),
      (Name: 'Каллисто';  GM: 7.179289e12; Radius: 2410.3)
    ),

    // Сатурн (индекс 5)
    (
      (Name: 'Мимас';     GM: 2.503e9;    Radius: 198.2),
      (Name: 'Энцелад';   GM: 7.209e9;    Radius: 252.1),
      (Name: 'Тефия';     GM: 4.121e10;   Radius: 533.0),
      (Name: 'Диона';     GM: 7.311e10;   Radius: 561.7),
      (Name: 'Рея';       GM: 1.538e11;   Radius: 764.3),
      (Name: 'Титан';     GM: 8.978e12;   Radius: 2575.5),
      (Name: 'Япет';      GM: 1.205e11;   Radius: 735.6)
    ),

    // Уран (индекс 6)
    (
      (Name: 'Миранда';   GM: 4.4e9;     Radius: 235.8),
      (Name: 'Ариэль';    GM: 1.35e11;   Radius: 578.9),
      (Name: 'Умбриэль';  GM: 1.17e11;   Radius: 584.7),
      (Name: 'Титания';   GM: 2.37e11;   Radius: 788.9),
      (Name: 'Оберон';    GM: 2.01e11;   Radius: 761.4)
    ),

    // Нептун (индекс 7)
    (
      (Name: 'Тритон';    GM: 1.428e12;  Radius: 1353.4)
    ),

    // Плутон (индекс 8)
    (
      (Name: 'Харон';     GM: 1.058e11;  Radius: 606.0)
    )
  );

{ TForm1 }

// Фильтрация вводимых символов
procedure TForm1.EditScientificKeyPress(Sender: TObject; var Key: Char);
var
  Edit: TEdit absolute Sender;
  HasE: Boolean;
begin
  HasE := (Pos('e', Edit.Text) > 0) or (Pos('E', Edit.Text) > 0);

  // Разрешаем:
  // - Цифры 0-9
  // - Десятичную точку (зависит от FormatSettings.DecimalSeparator)
  // - 'e/E' (но только одну)
  // - '+/-' (только после 'e/E')
  // - Backspace (#8) и Delete (#127)

  if not (Key in ['0'..'9', FormatSettings.DecimalSeparator, 'e', 'E', '+', '-', #8, #127]) then
    Key := #0
  else if (Key in ['e', 'E']) and HasE then
    Key := #0  // Блокируем вторую 'e'
  else if (Key in ['+', '-']) and not HasE then
    Key := #0; // Знаки только в экспоненте
end;

// Проверка корректности числа
procedure TForm1.EditScientificChange(Sender: TObject);
var
  Edit: TEdit absolute Sender;
begin
  // Просто сбрасываем цвет фона
  Edit.Color := clWindow;
end;

procedure TForm1.FormKeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #13 then  // Код клавиши Enter
    ButtonCalculate.Click;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  // 1. Настройка основного ComboBox для планет
  ComboBoxPlanet.Items.Add('Меркурий');
  ComboBoxPlanet.Items.Add('Венера');
  ComboBoxPlanet.Items.Add('Земля');
  ComboBoxPlanet.Items.Add('Марс');
  ComboBoxPlanet.Items.Add('Юпитер');
  ComboBoxPlanet.Items.Add('Сатурн');
  ComboBoxPlanet.Items.Add('Уран');
  ComboBoxPlanet.Items.Add('Нептун');
  ComboBoxPlanet.Items.Add('Плутон');
  ComboBoxPlanet.ItemIndex := 2;
  ComboBoxPlanet.OnChange := @ComboBoxPlanetChange; // Важно!

  // 2. Настройка ComboBox для спутников
  ComboBoxSatellite := TComboBox.Create(Self);
  with ComboBoxSatellite do
  begin
    Parent := Self; // Указываем владельца
    Left := ComboBoxPlanet.Left + ComboBoxPlanet.Width + 10; // Позиция справа от основного
    Top := ComboBoxPlanet.Top; // Выравниваем по верхнему краю
    Width := 150; // Ширина
    Visible := False; // По умолчанию скрыт
    Style := csDropDownList;     // Запрет ручного ввода
    DropDownCount := 8;          // Показывать 8 пунктов без прокрутки
    OnChange := @SatelliteChanged // Обработчик изменения (если нужен)
  end;

  // Первоначальная загрузка спутников
  UpdateSatellitesList;

  ButtonCalculate.Caption := 'Рассчитать (Enter)';
  ButtonCalculate.Default := True; // Реагирует на Enter

  // Настройка RadioGroup
  RadioGroupInitialOrbit.Caption := 'Начальная орбита';
  RadioGroupInitialOrbit.Items.Add('Перицентр + апоцентр');
  RadioGroupInitialOrbit.Items.Add('Большая полуось + эксцентриситет');
  RadioGroupInitialOrbit.ItemIndex := 0;

  RadioGroupTargetOrbit.Caption := 'Целевая орбита';
  RadioGroupTargetOrbit.Items.Add('Перицентр + апоцентр');
  RadioGroupTargetOrbit.Items.Add('Большая полуось + эксцентриситет');
  RadioGroupTargetOrbit.ItemIndex := 0;

  // Настройка LabelResult
  MemoResults.Caption := 'Введите параметры орбит';

  // Инициализация полей ввода
  UpdateInitialOrbitInputs;
  UpdateTargetOrbitInputs;

  // Настройка десятичного разделителя (обязательно!)
  FormatSettings.DecimalSeparator := '.'; // или ',' для европейских локалей

  EditMass.Enabled := False;
  EditRadius.Enabled := False;
  CheckBoxCustomBody.Hint := 'Включите для ввода параметров произвольного небесного тела';
  // Установка значений по умолчанию для Земли
  EditPeriapsisInit.Text := '150';
  EditApoapsisInit.Text := '150';
  EditPeriapsisTarget.Text := '150';
  EditApoapsisTarget.Text := '150';
   // Привязка обработчиков
  EditMass.OnKeyPress := @EditScientificKeyPress;
  EditMass.OnChange := @EditScientificChange;

  EditRadius.OnKeyPress := @EditScientificKeyPress;
  EditRadius.OnChange := @EditScientificChange;

  ComboBoxPlanet.OnChange := @ComboBoxPlanetChange;
end;

function TForm1.GetBurnType(DeltaV: Double): string;
begin
  if DeltaV > 0 then
    Result := 'разгон'
  else
    Result := 'торможение';
end;

function TForm1.SafeStrToFloat(const S: string; Default: Double): Double;
begin
  if Trim(S) = '' then
    Result := Default
  else
    Result := StrToFloat(S);
end;

procedure TForm1.ValidateOrbitParameters;
begin
  if (Trim(EditPeriapsisInit.Text) = '') or
     (Trim(EditApoapsisInit.Text) = '') or
     (Trim(EditPeriapsisTarget.Text) = '') or
     (Trim(EditApoapsisTarget.Text) = '') then
    raise EConvertError.Create('Заполните все параметры орбит');
end;

procedure TForm1.UpdateSatellitesList;
var
  PlanetIndex, i: Integer;
begin
  ComboBoxSatellite.Clear;
  PlanetIndex := ComboBoxPlanet.ItemIndex;

  if (PlanetIndex >= 2) and (PlanetIndex <= 8) then
  begin
    ComboBoxSatellite.Items.BeginUpdate;
    try
      ComboBoxSatellite.Items.Add('(Сама планета)');
      for i := 0 to High(Satellites[PlanetIndex-2]) do
        ComboBoxSatellite.Items.Add(Satellites[PlanetIndex-2][i].Name);
    finally
      ComboBoxSatellite.Items.EndUpdate;
    end;

    ComboBoxSatellite.Visible := True;
    ComboBoxSatellite.ItemIndex := 0;
    // Убедимся, что обработчик назначен
    ComboBoxSatellite.OnChange := @SatelliteChanged;
  end
  else
  begin
    ComboBoxSatellite.Visible := False;
  end;
end;

// Обработчик изменения планеты
procedure TForm1.ComboBoxPlanetChange(Sender: TObject);
begin
  try
    UpdateSatellitesList;
    FLastGM := 0;
    // Добавляем проверку перед расчётом
    if (EditPeriapsisInit.Text <> '') and (EditApoapsisInit.Text <> '') and
       (EditPeriapsisTarget.Text <> '') and (EditApoapsisTarget.Text <> '') then
    begin
      ButtonCalculate.Click;
    end;
  except
    on E: EConvertError do
      MemoResults.Lines.Text := 'Ошибка: заполните все параметры орбит';
  end;
end;

procedure TForm1.SatelliteChanged(Sender: TObject);
begin
  FLastGM := 0;
  // Пересчёт при любом изменении выбора (даже если вернулись к "Сама планета")
  if ButtonCalculate.Enabled then
    ButtonCalculate.Click;
end;

procedure TForm1.UpdateInitialOrbitInputs;
begin
  // Показываем только нужные поля для начальной орбиты
  LabelPeriapsisInit.Visible := (RadioGroupInitialOrbit.ItemIndex = 0);
  EditPeriapsisInit.Visible := (RadioGroupInitialOrbit.ItemIndex = 0);
  LabelApoapsisInit.Visible := (RadioGroupInitialOrbit.ItemIndex = 0);
  EditApoapsisInit.Visible := (RadioGroupInitialOrbit.ItemIndex = 0);
  LabelSemiMajorAxisInit.Visible := (RadioGroupInitialOrbit.ItemIndex = 1);
  EditSemiMajorAxisInit.Visible := (RadioGroupInitialOrbit.ItemIndex = 1);
  LabelEccentricityInit.Visible := (RadioGroupInitialOrbit.ItemIndex = 1);
  EditEccentricityInit.Visible := (RadioGroupInitialOrbit.ItemIndex = 1);
end;

procedure TForm1.UpdateTargetOrbitInputs;
begin
  // Аналогично для целевой орбиты
  LabelPeriapsisTarget.Visible := (RadioGroupTargetOrbit.ItemIndex = 0);
  EditPeriapsisTarget.Visible := (RadioGroupTargetOrbit.ItemIndex = 0);
  LabelApoapsisTarget.Visible := (RadioGroupTargetOrbit.ItemIndex = 0);
  EditApoapsisTarget.Visible := (RadioGroupTargetOrbit.ItemIndex = 0);
  LabelSemiMajorAxisTarget.Visible := (RadioGroupTargetOrbit.ItemIndex = 1);
  EditSemiMajorAxisTarget.Visible := (RadioGroupTargetOrbit.ItemIndex = 1);
  LabelEccentricityTarget.Visible := (RadioGroupTargetOrbit.ItemIndex = 1);
  EditEccentricityTarget.Visible := (RadioGroupTargetOrbit.ItemIndex = 1);
end;

procedure TForm1.RadioGroupInitialOrbitClick(Sender: TObject);
begin
  UpdateInitialOrbitInputs;
end;

procedure TForm1.RadioGroupTargetOrbitClick(Sender: TObject);
begin
  UpdateTargetOrbitInputs;
end;

procedure TForm1.GetGravityParams(out GM, Radius: Double);
var
  PlanetIndex, SatelliteIndex: Integer;
begin
  if CheckBoxCustomBody.Checked then
  begin
    GM := StrToFloatDef(EditMass.Text, 0) * 6.67430e-11;
    Radius := StrToFloatDef(EditRadius.Text, 0) * 1000;
    EditMass.Color := clWindow;
    EditRadius.Color := clWindow;
  end
  else
  begin
    PlanetIndex := ComboBoxPlanet.ItemIndex;

    // Ключевое изменение: проверяем, выбран ли спутник явно
    if ComboBoxSatellite.Visible and (ComboBoxSatellite.ItemIndex > 0)
       and (ComboBoxSatellite.Text <> '') then
    begin
      // Используем параметры выбранного спутника
      SatelliteIndex := ComboBoxSatellite.ItemIndex - 1;
      GM := Satellites[PlanetIndex-2][SatelliteIndex].GM;
      Radius := Satellites[PlanetIndex-2][SatelliteIndex].Radius * 1000;
    end
    else
    begin
      // Используем параметры самой планеты
      GM := Planets[PlanetIndex].GM;
      Radius := Planets[PlanetIndex].Radius * 1000;
    end;
  end;
end;

procedure TForm1.CheckBoxCustomBodyChange(Sender: TObject);
begin
  // При переключении режима сбрасываем подсветку
  EditMass.Color := clWindow;
  EditRadius.Color := clWindow;

  // Активируем/деактивируем поля ввода
  EditMass.Enabled := CheckBoxCustomBody.Checked;
  EditRadius.Enabled := CheckBoxCustomBody.Checked;

  // Сбрасываем кэш
  FLastGM := 0;
end;

function TForm1.CalculateDeltaVWithDetails(out Vperi, Vapo, Period: Double; out Impulses: Integer): Double;
var
  GM, PlanetRadius: Double;
  r_peri_init, r_apo_init, r_peri_target, r_apo_target: Double;
  DeltaV1, DeltaV2: Double;
  V_init, V_target: Double;
begin
  // Получаем гравитационный параметр и радиус тела
  GetGravityParams(GM, PlanetRadius);

  // Расчёт параметров орбит (с учётом радиуса тела)
  if RadioGroupInitialOrbit.ItemIndex = 0 then
  begin
    r_peri_init := StrToFloat(EditPeriapsisInit.Text) * 1000 + PlanetRadius;
    r_apo_init := StrToFloat(EditApoapsisInit.Text) * 1000 + PlanetRadius;
  end
  else
  begin
    r_peri_init := StrToFloat(EditSemiMajorAxisInit.Text) * 1000 * (1 - StrToFloat(EditEccentricityInit.Text)) + PlanetRadius;
    r_apo_init := StrToFloat(EditSemiMajorAxisInit.Text) * 1000 * (1 + StrToFloat(EditEccentricityInit.Text)) + PlanetRadius;
  end;

  if RadioGroupTargetOrbit.ItemIndex = 0 then
  begin
    r_peri_target := StrToFloat(EditPeriapsisTarget.Text) * 1000 + PlanetRadius;
    r_apo_target := StrToFloat(EditApoapsisTarget.Text) * 1000 + PlanetRadius;
  end
  else
  begin
    r_peri_target := StrToFloat(EditSemiMajorAxisTarget.Text) * 1000 * (1 - StrToFloat(EditEccentricityTarget.Text)) + PlanetRadius;
    r_apo_target := StrToFloat(EditSemiMajorAxisTarget.Text) * 1000 * (1 + StrToFloat(EditEccentricityTarget.Text)) + PlanetRadius;
  end;

  // Вычисляем скорости для вывода (на целевой орбите)
  Vperi := Sqrt(GM * (2/r_peri_target - 2/(r_peri_target + r_apo_target)));
  Vapo := Sqrt(GM * (2/r_apo_target - 2/(r_peri_target + r_apo_target)));
  Period := 2 * Pi * Sqrt(Power((r_peri_target + r_apo_target)/2, 3)/GM);

  // Определяем тип перехода
  if SameValue(r_peri_init, r_peri_target, 1.0) then
  begin
    // Случай 1: Перицентры совпадают - импульс в ПЕРИЦЕНТРЕ
    Impulses := 1;
    V_init := Sqrt(GM*(2/r_peri_init - 2/(r_peri_init + r_apo_init)));
    V_target := Sqrt(GM*(2/r_peri_init - 2/(r_peri_init + r_apo_target)));
    Result := V_target - V_init;
    MemoResults.Lines.Add(Format('ΔV: %.2f м/с (%s в перицентре)',
  [Result, GetBurnType(Result)]));
  end
  else if SameValue(r_apo_init, r_apo_target, 1.0) then
  begin
    // Случай 2: Апоцентры совпадают - импульс в АПОЦЕНТРЕ
    Impulses := 1;
    V_init := Sqrt(GM*(2/r_apo_init - 2/(r_peri_init + r_apo_init)));
    V_target := Sqrt(GM*(2/r_apo_init - 2/(r_peri_target + r_apo_init)));
    Result := V_target - V_init;
    MemoResults.Lines.Add(Format('ΔV: %.2f м/с (%s в апоцентре)',
  [Result, GetBurnType(Result)]));
  end
  else
  begin
    // Двухимпульсный переход
    Impulses := 2;
    // Первый импульс (в перицентре начальной орбиты)
    DeltaV1 := Abs(Sqrt(GM*(2/r_peri_init - 2/(r_peri_init + r_apo_target))) -
               Sqrt(GM*(2/r_peri_init - 2/(r_peri_init + r_apo_init))));
    // Второй импульс (в апоцентре целевой орбиты)
    DeltaV2 := Abs(Sqrt(GM*(2/r_apo_target - 2/(r_peri_target + r_apo_target))) -
               Sqrt(GM*(2/r_apo_target - 2/(r_peri_init + r_apo_target))));
    Result := DeltaV1 + DeltaV2;

    MemoResults.Lines.Add(Format('ΔV1: %.2f м/с (в перицентре)', [DeltaV1]));
    MemoResults.Lines.Add(Format('ΔV2: %.2f м/с (в апоцентре)', [DeltaV2]));
  end;
end;

procedure TForm1.ButtonCalculateClick(Sender: TObject);
var
  DeltaV, Vperi, Vapo, Period: Double;
  Impulses: Integer;
begin
  try
    // Для произвольного тела проверяем ввод
    if CheckBoxCustomBody.Checked then
    begin
      if (Trim(EditMass.Text) = '') or (Trim(EditRadius.Text) = '') then
        raise EConvertError.Create('Введите массу и радиус тела');
    end;

    DeltaV := CalculateDeltaVWithDetails(Vperi, Vapo, Period, Impulses);

    MemoResults.Lines.Clear;
    MemoResults.Lines.Add('Результаты расчёта:');

    if Impulses = 1 then
      MemoResults.Lines.Add(Format('ΔV: %.2f м/с (одноимпульсный)', [DeltaV]))
    else
    begin
      MemoResults.Lines.Add(Format('ΔV1: %.2f м/с', [Vperi]));
      MemoResults.Lines.Add(Format('ΔV2: %.2f м/с', [Vapo]));
      MemoResults.Lines.Add(Format('Общий ΔV: %.2f м/с', [DeltaV]));
    end;

    MemoResults.Lines.Add('------------------');
    MemoResults.Lines.Add(Format('Скорость в перицентре: %.2f м/с', [Vperi]));
    MemoResults.Lines.Add(Format('Скорость в апоцентре: %.2f м/с', [Vapo]));
    MemoResults.Lines.Add(Format('Период обращения: %.2f мин', [Period/60]));

  except
    on E: EConvertError do
      MemoResults.Lines.Text := 'Ошибка: ' + E.Message;
    on E: Exception do
      MemoResults.Lines.Text := 'Математическая ошибка: ' + E.Message;
  end;
end;

end.
