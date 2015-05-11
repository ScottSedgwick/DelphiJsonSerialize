unit StreamingTestTypes;

interface

uses
  JSONSerialize;

{$RTTI EXPLICIT
  METHODS(DefaultMethodRttiVisibility)
  FIELDS(DefaultFieldRttiVisibility)
  PROPERTIES(DefaultPropertyRttiVisibility)}

type
  TSubObject = class
  private
    FSubProperty1: string;
  public
    [JSONPath('JSONSubField1')]
    SubField1: Integer;
    [JSONPath('JSONSubProperty1')]
    property SubProperty1: string read FSubProperty1 write FSubProperty1;
  end;

  IStreamingIntf = interface
    function GetSubObject: TSubObject;
    property SubObject1: TSubObject read GetSubObject;
  end;

  TDynStrings = array of string;

  TStreamingType = class(TInterfacedObject, IStreamingIntf)
  private
    FSubObject1: TSubObject;
    FStrings: TDynStrings;
    function GetSubObject: TSubObject;
  public
    constructor Create;
    destructor Destroy; override;
    procedure AddString(const Value: string);
  public
    [JSONPath('JSONField1')]
    Field1: string;
    [JSONPath('JSONSubObject1')]
    property SubObject1: TSubObject read GetSubObject;
    [JSONPath('JSONArrayProperty')]
    property Strings: TDynStrings read FStrings write FStrings;
  end;

  TIntPair = array[0..1] of Integer;

  TStreamingRecord = record
  public
    [JSONPath('JSON_A')]
    A: string;
    [JSONPath('JSON_B')]
    B: TIntPair;
  end;

implementation

{ TStreamingType }

procedure TStreamingType.AddString(const Value: string);
var
  curSize: Integer;
begin
  curSize := Length(FStrings);
  SetLength(FStrings, curSize + 1);
  FStrings[curSize] := Value;
end;

constructor TStreamingType.Create;
begin
  inherited;
  FSubObject1 := TSubObject.Create;
end;

destructor TStreamingType.Destroy;
begin
  FSubObject1.Free;
  inherited;
end;

function TStreamingType.GetSubObject: TSubObject;
begin
  Result := FSubObject1;
end;

end.
