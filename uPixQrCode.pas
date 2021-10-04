unit uPixQrCode;

interface

uses
  System.SysUtils, System.Classes, DelphiZXIngQRCode, VCL.Graphics;

type
  TPixQrCode = class(TComponent)
  private
    { Private declarations }
    fChave:         String;
    fBeneficiario:  String;
    fCidade:        String;
    fValor:         Currency;
    fAlturaBitmap:  Integer;
    fLarguraBitmap: Integer;
  protected
    { Protected declarations }
    function CRC16CCITT(texto: string): WORD;
    function PayLoadEstatico(CodTransferencia: String = ''): String;
  public
    { Public declarations }
    function GerarQrCode: TMemoryStream;
  published
    { Published declarations }
    property  LarguraBitmap:  Integer  read fLarguraBitmap  write  fLarguraBitmap;
    property  AlturaBitmap:   Integer  read fAlturaBitmap   write  fAlturaBitmap;
    property  Chave:          String   read fChave          write  fChave;
    property  Beneficiario:   String   read fBeneficiario   write  fBeneficiario;
    property  Cidade:         String   read fCidade         write  fCidade;
    property  Valor:          Currency read fValor          write  fValor;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('PixQrCode', [TPixQrCode]);
end;

{ TPixQrCode }

function TPixQrCode.CRC16CCITT(texto: string): WORD;
const
  polynomial = $1021;
var
  crc: WORD;
  i, j: Integer;
  b: Byte;
  bit, c15: Boolean;
begin
  crc := $FFFF;

  for i := 1 to length(texto) do
  begin
    b := Byte(texto[i]);

    for j := 0 to 7 do
    begin
      bit := (((b shr (7 - j)) and 1) = 1);
      c15 := (((crc shr 15) and 1) = 1);
      crc := crc shl 1;

      if (c15 xor bit) then
        crc := crc xor polynomial;
    end;
  end;

 Result := crc and $FFFF;
end;

function TPixQrCode.GerarQrCode: TMemoryStream;
var
  xQRCode: TDelphiZXingQRCode;
  xQRCodeBitmap: TBitmap;
  xRow, xCol: Integer;
  xMStream: TMemoryStream;

   procedure ResizeBitmap(aBitmap: TBitmap; const aNewWidth, aNewHeight: integer);
   var
     xBuffer: TBitmap;
   begin
     xBuffer := TBitmap.Create;
     try
       xBuffer.SetSize(aNewWidth, aNewHeight);
       xBuffer.Canvas.StretchDraw(Rect(0, 0, aNewWidth, aNewHeight), aBitmap);
       aBitmap.SetSize(aNewWidth, aNewHeight);
       aBitmap.Canvas.Draw(0, 0, xBuffer);
     finally
       xBuffer.Free;
     end;
   end;
begin
  xMStream := TMemoryStream.Create;
  xQRCodeBitmap := TBitmap.Create;
  xQRCode := TDelphiZXingQRCode.Create;
  try
    xQRCode.Data := PayLoadEstatico('***');
    xQRCode.Encoding := TQRCodeEncoding(qrUTF8BOM);

    xQRCode.QuietZone := 2;
    xQRCodeBitmap.SetSize(xQRCode.Rows, xQRCode.Columns);
    for xRow := 0 to xQRCode.Rows - 1 do
    begin
      for xCol := 0 to xQRCode.Columns - 1 do
      begin
        if (xQRCode.IsBlack[xRow, xCol]) then
        begin
          xQRCodeBitmap.Canvas.Pixels[xCol, xRow] := clBlack;
        end else
        begin
          xQRCodeBitmap.Canvas.Pixels[xCol, xRow] := clWhite;
        end;
      end;
    end;

    // resize QRCode
    ResizeBitmap(xQRCodeBitmap, fLarguraBitmap, fAlturaBitmap);

    xQRCodeBitmap.SaveToStream(xMStream);
    xMStream.Position := 0;

    Result:= xMStream;
  finally
    xQRCodeBitmap.Free;
    xQRCode.Free;
  end;
end;

function TPixQrCode.PayLoadEstatico(CodTransferencia: String): String;
const Payload_Format_Indicator: String = '000201';
const Merchant_Account_Information: String = '26';
const Merchant_Category_Code :  String = '52040000';
const Transaction_Currency  : String = '530398654';
const Country_Code : String = '5802BR';
const Merchant_Name : String = '59';
const Merchant_City : String = '60';
const Additional_Data_Field_Template : String = '62';
const CRC162 : String = '6304';
Var
 CODPayLoad,Merchant_Account_Information_String,Valor_Total,txid,CRC: String;
begin
  Merchant_Account_Information_String:= '0014BR.GOV.BCB.PIX01'+Length(fChave).ToString+
  fChave;
  Valor_Total:=FormatFloat('#####0.00;00.00',fValor);
  Valor_Total:=StringReplace(Valor_Total,',','.',[]);
  txid:='05'+FormatFloat('00',LengTh(CodTransferencia))+CodTransferencia;
  CODPayLoad:=Payload_Format_Indicator+
  Merchant_Account_Information+Length(Merchant_Account_Information_String).ToString+
  Merchant_Account_Information_String+Merchant_Category_Code+Transaction_Currency+
  FormatFloat('00',Length(Valor_Total))+Valor_Total+Country_Code+Merchant_Name+
  FormatFloat('00',LengTh(fBeneficiario))+fBeneficiario+Merchant_City+FormatFloat('00',Length(fCidade))+
  fCidade+Additional_Data_Field_Template+FormatFloat('00',LengTh(txid))+txid+'6304';
  CRC:=inttohex(CRC16CCITT(CODPayLoad), 4);
  result:=CODPayLoad+CRC;
end;

end.
