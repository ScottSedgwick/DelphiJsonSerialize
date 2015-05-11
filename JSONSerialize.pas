unit JSONSerialize;

interface

type
  JSONPath = class(TCustomAttribute)
  private
    FName: string;
  public
    constructor Create(const AName: string);
    property Name: string read FName;
  end;

function JSONString(obj: TObject): string; overload;
function JSONString(intf: IInterface): string; overload;
function JSONString(ARecordPtr, TypeInfoPtr: Pointer): string; overload;

implementation

uses
  System.Classes,
  System.Generics.Collections,
  System.JSON,
  System.Rtti,
  System.SysUtils;

type
  ToJSON = class
  public
    class function FromValue(InValue: TValue): TJSONValue;
  end;

{ JSONName }

constructor JSONPath.Create(const AName: string);
begin
  FName := AName;
end;

function JSONSerializeObj(ptr, typinf: Pointer): TJSONObject; forward;
function JSONSerializeInterface(intf: IInterface): TJSONObject; forward;

class function ToJSON.FromValue(InValue: TValue): TJSONValue;
var
  I: Integer;
  AValue: TValue;
  AJSONValue: TJSONValue;
begin
  Result := nil;
  case InValue.Kind of
    tkChar, tkString, tkWChar, tkLString, tkWString, tkUString:
      if InValue.AsString <> '' then
        Result := TJSONString.Create(InValue.AsString);
    tkInteger:
      if InValue.AsInteger <> 0 then
        Result := TJSONNumber.Create(InValue.AsInteger);
    tkInt64:
      if InValue.AsInt64 <> 0 then
        Result := TJSONNumber.Create(InValue.AsInt64);
    tkFloat:
      if not ((InValue.AsExtended = 0) or (InValue.AsExtended = 25569)) then
        Result := TJSONNumber.Create(InValue.AsExtended);
    tkEnumeration:
      if InValue.AsBoolean then
        Result := TJSONTrue.Create;
    tkClass:
    begin
      if (InValue.AsObject is TJSONValue) then
        Result := ((InValue.AsObject as TJSONValue).Clone as TJSONValue)
      else
        Result := JSONSerializeObj(InValue.AsObject, InValue.TypeInfo);
      if Result.ToJSON = '{}' then
      begin
        FreeAndNil(Result);
      end;
    end;
    tkRecord:
    begin
      Result := JSONSerializeObj(InValue.GetReferenceToRawData, InValue.TypeInfo);
      if Result.ToJSON = '{}' then
        FreeAndNil(Result);
    end;
    tkInterface:
    begin
      Result := JSONSerializeInterface(InValue.AsInterface);
      if Result.ToJSON = '{}' then
        FreeAndNil(Result);
    end;
    tkArray, tkDynArray:
    begin
      Result := TJSONArray.Create;
      for I := 0 to InValue.GetArrayLength - 1 do
      begin
        AValue := InValue.GetArrayElement(I);
        AJSONValue := ToJSON.FromValue(AValue);
        if Assigned(AJSONValue) then
          (Result as TJSONArray).AddElement(AJSONValue);
      end;
      if Result.ToJSON = '[]' then
        FreeAndNil(Result);
    end;
    else
      Result := nil;
  end;
end;

procedure JSONSerializeValue(Result: TJSONObject; TypeKind: TTypeKind; InValue: TValue; JSONName: string);
var
  OutValue, Temp: TJSONValue;
  Root: TJSONObject;
  Names: TStringList;
  I: Integer;
begin
  OutValue := ToJSON.FromValue(InValue);
  if Assigned(OutValue) then
  begin
    Root := Result;
    names := TStringList.Create;
    try
      ExtractStrings(['\','/'], [], PWideChar(JSONName), names);
      for I := 0 to Names.Count - 2 do
      begin
        if not Root.TryGetValue(Names[I], Temp) then
        begin
          Temp := TJSONObject.Create;
          Root.AddPair(Names[I], Temp);
        end;
        Root := Temp as TJSONObject;
      end;
      Root.AddPair(Names[Names.Count - 1], OutValue);
    finally
      FreeAndNil(Names);
    end;
  end;
end;

function JSONSerializeObj(ptr, typinf: Pointer): TJSONObject;
var
  ctx: TRttiContext;
  t : TRttiType;
  p : TRttiProperty;
  f : TRttiField;
  a : TCustomAttribute;
begin
  Result := TJSONObject.Create;
  t := ctx.GetType(typinf);
  for f in t.GetFields do
    for a in f.GetAttributes do
      if a is JSONPath then
        JSONSerializeValue(Result, f.FieldType.TypeKind, f.GetValue(ptr), JSONPath(a).Name);
  for p in t.GetProperties do
    for a in p.GetAttributes do
      if a is JSONPath then
        JSONSerializeValue(Result, p.PropertyType.TypeKind, p.GetValue(ptr), JSONPath(a).Name);
end;

function JSONSerializeInterface(intf: IInterface): TJSONObject;
var
  obj: TObject;
begin
  obj := TObject(intf);
  Result := JSONSerializeObj(obj, obj.ClassInfo);
end;

function JSONString(obj: TObject): string;
var
  json: TJSONObject;
begin
  json := JSONSerializeObj(obj, obj.ClassInfo);
  try
    Result := json.ToJSON;
  finally
    FreeAndNil(json);
  end;
end;

function JSONString(intf: IInterface): string;
var
  json: TJSONObject;
begin
  json := JSONSerializeInterface(intf);
  try
    Result := json.ToJSON;
  finally
    FreeAndNil(json);
  end;
end;

function JSONString(ARecordPtr, TypeInfoPtr: Pointer): string;
var
  json: TJSONObject;
begin
  json := JSONSerializeObj(ARecordPtr, TypeInfoPtr);
  try
    Result := json.ToJSON;
  finally
    FreeAndNil(json);
  end;
end;

end.
