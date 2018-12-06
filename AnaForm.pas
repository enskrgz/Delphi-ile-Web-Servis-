unit AnaForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils,
   System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
   System.Actions, Vcl.ActnList,
  Vcl.StdCtrls, Soap.InvokeRegistry,
   Soap.Rio, Soap.SOAPHTTPClient, Soap.SOAPHTTPTrans, QueryDocumentWS1,
  Xml.xmldom, Xml.XMLIntf, Xml.XMLDoc;

type
  TForm1 = class(TForm)
    Button1: TButton;
    HTTPRIO1: THTTPRIO;
    MemoLog: TMemo;
    Button2: TButton;
    Button3: TButton;
    ActionList1: TActionList;
    ActionGetCreditCout: TAction;
    ActionSendInvoice: TAction;
    Action1: TAction;
    XMLDocument1: TXMLDocument;
    procedure ActionGetCreditCoutExecute(Sender: TObject);
    procedure HTTPRIO1HTTPWebNode1BeforePost(const HTTPReqResp: THTTPReqResp;
      Data: Pointer);
    procedure HTTPRIO1BeforeExecute(const MethodName: string;
      SOAPRequest: TStream);
    procedure HTTPRIO1AfterExecute(const MethodName: string;
      SOAPResponse: TStream);
    procedure ActionSendInvoiceExecute(Sender: TObject);
    procedure Button3Click(Sender: TObject);
  private
    procedure LogEkle(Str1: String);
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

uses InvoiceWS1, WinInet;

const
//
PR_cbc = 'cbc';
  NS_cbc = 'urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2';
  PR_cac = 'cac';
  NS_cac = 'urn:oasis:names:specification:ubl:schema:xsd:UBL-CommonAggregateComponents-2.1';
//
  HizliUserName = '111111190';
  HizliPassword = '1';
  // HizliServiceUrl = 'http://94.103.42.45:8080/InvoiceService/InvoiceWS';
  HizliServiceUrl = 'https://servis.hizlibilisimteknolojileri.net/InvoiceService/InvoiceWS';
  hizliservis2 ='https://servis.hizlibilisimteknolojileri.net/QueryInvoiceService/QueryDocumentWS' ;
  sourceUrn = '';

procedure TForm1.ActionGetCreditCoutExecute(Sender: TObject);
var
  Servis: InvoiceWS;
  servis2: QueryDocumentWS;
  Cevap: CreditInfo;
  cevap2:DocumentQueryResponse;

begin
  inherited;
  Screen.Cursor := crSQLWait;
  try
    Servis := GetInvoiceWS(False, HizliServiceUrl, HTTPRIO1);
   // servis2:= GetQueryDocumentWS(False,hizliservis2,HTTPRIO1);
   // Cevap2:= servis2.QueryOutboxDocumentsWithDocumentDate('01.01.2017','23.11.2018','1','ALL','YES','1');
    //MemoLog.Lines.Add( IntToStr(Cevap2.documentsCount) );
    Cevap := Servis.getCustomerCreditCount('4620553774');
    if Cevap.code = '000' then
    begin
      ShowMessage('Toplam Krediniz: ' + cevap.totalCredit.DecimalString);
    end else
    begin
      ShowMessage('HATA: ' + Cevap.explanation);
    end;
  finally
    if Cevap <> nil then Cevap.Free;
    Screen.Cursor := crDefault;
  end;
end;

procedure TForm1.ActionSendInvoiceExecute(Sender: TObject);
var
  Servis: InvoiceWS;
  Sorgu: updateInvoice;
  Cevap: updateInvoiceResponse;
  Sayac: Integer;
const
  FaturaSayisi = 5;
begin
  inherited;
  Screen.Cursor := crSQLWait;
  try
    Servis := GetInvoiceWS(False, HizliServiceUrl, HTTPRIO1);

    SetLength(Sorgu, FaturaSayisi);   //amacı anlayamadım(enes)
    for Sayac := 0 to FaturaSayisi - 1 do
    begin
      Sorgu[Sayac] := InputDocument.Create;
      Sorgu[Sayac].documentUUID := '16a3fbc4-3539-4384-b4a3-16268b4912fc'; // GUID Kendimiz üretmeliyiz
      Sorgu[Sayac].xmlContent := ''; // Faturamızın UBL formatındaki hali
      Sorgu[Sayac].sourceUrn := 'urn:mail:defaultgb@hizlibilisimteknolojileri.net'; // Bizim urn (GB) kodumuz (Faturayı gönderenin)
      Sorgu[Sayac].destinationUrn := 'urn:mail:defaultgb@hizlibilisimteknolojileri.net'; // Alıcının urn (PK) kodu. (Faturayı alacak olanın)
      Sorgu[Sayac].documentNoPrefix := ''; // Fatura no üretilirken kullanılan ön ek (Zorunlu değil)
      Sorgu[Sayac].localId := '66'; // Yerel DB Referans ID
      Sorgu[Sayac].documentId := 'GIB20180000056891'; // Fatura GİB numarası (Örn: GIB2018000000001)
    end;

    Cevap := Servis.sendInvoice(Sorgu);
    for Sayac := 0 to Length(Cevap) - 1 do
    begin
      if Cevap[Sayac].code = '000' then
      begin
        ShowMessage('Gönderme Başarılı: ' + cevap[Sayac].documentID);
      end else
      begin
        ShowMessage('HATA: ' + Cevap[Sayac].explanation);
      end;
    end;
  finally
    for Sayac := 0 to Length(Cevap) - 1 do
    begin
      if Cevap[Sayac] <> nil then Cevap[Sayac].Free;
    end;
    Screen.Cursor := crDefault;
  end;
end;

procedure TForm1.Button3Click(Sender: TObject);
var

servis1:QueryDocumentWS;
cevap: DocumentQueryResponse;
cevapdty:ResponseDocument;
begin
 servis1:=GetQueryDocumentWS(False,hizliservis2,HTTPRIO1);
 cevap:=DocumentQueryResponse.Create;

MemoLog.Lines.Add(servis1.QueryOutboxDocument('Envelope_UUID','f661c25c-61ac-4a16-aa8e-5366b8117288','NO').stateExplanation);
ShowMessage(cevap.stateExplanation);





end;

procedure TForm1.HTTPRIO1AfterExecute(const MethodName: string;
  SOAPResponse: TStream);
var                                           // bu procedure xml okuyor
  StrList1 : TStringList;                     //işlem tamamlandıktan sonra yani response dolunca
begin
  StrList1 := TStringList.Create;
  try
    SOAPResponse.Seek(0, soFromBeginning);
    StrList1.LoadFromStream(SOAPResponse);
    LogEkle('CEVAP OLARAK GELEN XML KODLARI' + #13#10#13#10 + StringReplace(StrList1.Text, '><', '>' + #13#10 + '<', [rfReplaceAll]) + #13#10);
  finally
    FreeAndNil(StrList1);
  end;
end;

procedure TForm1.HTTPRIO1BeforeExecute(const MethodName: string;
  SOAPRequest: TStream);
var
  StrList1: TStringList;
begin
  inherited;
  StrList1 := TStringList.Create;
  try
    SOAPRequest.Position := 0;
    StrList1.LoadFromStream(SOAPRequest);
    LogEkle('GÖNDERİLEN XML KODLARI' + #13#10#13#10 + StringReplace(StrList1.Text, '><', '>' + #13#10 + '<', [rfReplaceAll]) + #13#10);
  finally
    StrList1.Free;
  end;
end;

procedure TForm1.HTTPRIO1HTTPWebNode1BeforePost(const HTTPReqResp: THTTPReqResp;
  Data: Pointer);
var
  HeaderStr: string;
begin
  HeaderStr := 'Username: ' + HizliUserName;
  HttpAddRequestHeaders(Data, PChar(HeaderStr), Length(HeaderStr), HTTP_ADDREQ_FLAG_ADD);
  HeaderStr := 'Password: ' + HizliPassword;
  HttpAddRequestHeaders(Data, PChar(HeaderStr), Length(HeaderStr), HTTP_ADDREQ_FLAG_ADD);
end;

procedure TForm1.LogEkle(Str1: String);
begin
  MemoLog.Lines.Add(FormatDateTime('hh:nn:ss', Now) + ' ' + Str1);
end;

end.
