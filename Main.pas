unit Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls, scControls, scGPPagers,
  scGrids, Vcl.Grids, Vcl.StdCtrls, Vcl.Mask, scGPExtControls, scGPControls,
  gtPDFClasses, gtCstPDFDoc, gtExPDFDoc, gtExProPDFDoc, gtPDFDoc, Vcl.FileCtrl;

type
  TFrmMain = class(TForm)
    scGPPageControl1: TscGPPageControl;
    scGPPageControlPage1: TscGPPageControlPage;
    FileOpenDialog1: TFileOpenDialog;
    scGPPanel1: TscGPPanel;
    Label1: TLabel;
    ed_pdf_file: TscGPEdit;
    btn_choose_pdf: TscGPButton;
    Label2: TLabel;
    ed_size: TscGPEdit;
    Label4: TLabel;
    ed_page: TscGPEdit;
    Label3: TLabel;
    cb_selected_page: TscGPComboBox;
    scGPPanel2: TscGPPanel;
    btn_convert: TscGPButton;
    gtPDFDocument1: TgtPDFDocument;
    Label5: TLabel;
    cb_convert_to: TscGPComboBox;
    Label6: TLabel;
    ed_output: TscGPEdit;
    btn_choose_output: TscGPButton;
    ed_hidden_filename: TscGPEdit;
    scStatusBar1: TscStatusBar;
    ProgressBar1: TscGPProgressBar;
    procedure FormCreate(Sender: TObject);
    procedure btn_choose_pdfClick(Sender: TObject);
    procedure btn_convertClick(Sender: TObject);
    procedure btn_choose_outputClick(Sender: TObject);
  private
    { Private declarations }
    procedure ClearForm();
  public
    { Public declarations }
  end;

var
  FrmMain: TFrmMain;
  Bitmap1: TBitmap;
  Output_DPI: Integer;
  Desktop_DPI: Integer;

implementation

{$R *.dfm}

procedure TFrmMain.btn_choose_outputClick(Sender: TObject);
begin
  FileOpenDialog1.Options := [fdoPickFolders];
  if FileOpenDialog1.Execute then
  begin
    ed_output.Text := FileOpenDialog1.FileName;
  end;
end;

procedure TFrmMain.btn_choose_pdfClick(Sender: TObject);
var
  fileSizeKB: Integer;
  fileSizeMB: Double;
begin
  FileOpenDialog1.Options := [];
  if FileOpenDialog1.Execute then
  begin
//    ShowMessage(ChangeFileExt(ExtractFileName(FileOpenDialog1.FileName), ''));
    ed_pdf_file.Text := FileOpenDialog1.FileName;
    gtPDFDocument1 := TgtPDFDocument.Create(nil);
    gtPDFDocument1.LoadFromFile(ed_pdf_file.Text);

    ed_hidden_filename.Text := ChangeFileExt(ExtractFileName(FileOpenDialog1.FileName), '');
    fileSizeKB := Round(gtPDFDocument1.FileSize / 1000);

    if fileSizeKB < 1000 then
      ed_size.Text := IntToStr(fileSizeKB) + ' KB'
    else
    begin
      fileSizeMB := gtPDFDocument1.FileSize / 1000000;
      ed_size.Text := Format('%.2f MB', [fileSizeMB]);
    end;

    ed_page.Text := gtPDFDocument1.PageCount.ToString;

    gtPDFDocument1.Reset;
  end;
end;

procedure TFrmMain.btn_convertClick(Sender: TObject);
var
  i: Integer;
begin
  Output_DPI := 120;   // Required DPI of hi-res image
  Desktop_DPI := 96;   // Current DPI of screen or in PDF viewer

  if ed_pdf_file.Text <> '' then
  begin
    Screen.Cursor := crHourGlass;
    try
      gtPDFDocument1 := TgtPDFDocument.Create(nil);
      gtPDFDocument1.LoadFromFile(ed_pdf_file.Text);

      ProgressBar1.MaxValue := StrToInt(ed_page.Text);
      ProgressBar1.Value := 0;

      for i := 1 to StrToInt(ed_page.Text) do
      begin
        Bitmap1 := TBitmap.Create;
        Bitmap1.Width := Round(gtPDFDocument1.GetPageSize(i, muPixels).Width * (Output_DPI/Desktop_DPI));   // Warning
        Bitmap1.Height := Round(gtPDFDocument1.GetPageSize(i, muPixels).Height * (Output_DPI/Desktop_DPI));  // Warning

        gtPDFDocument1.RenderToDC(
                        Bitmap1.Canvas.Handle,  // Handle of the bitmap canvas
                        Bitmap1.Width,          // Width of page at required DPI
                        Bitmap1.Height,         // Height of page at required DPI
                                i,              // Number of the page
                                Output_DPI,     // Horizontal DPI
                                Output_DPI,     // Vertical DPI
                                0,              // Angle of rotation
                                True,           // Enable anti-aliasing
                                False);         // Not for printing

        if ed_output.Text <> '' then
          Bitmap1.SaveToFile(ed_output.Text + '\' + ed_hidden_filename.Text + '_' + IntToStr(i) + '.' + cb_convert_to.Items[cb_convert_to.ItemIndex].Caption)
        else
          Bitmap1.SaveToFile(ed_hidden_filename.Text + '_' + IntToStr(i) + '.' + cb_convert_to.Items[cb_convert_to.ItemIndex].Caption);

        ProgressBar1.Value := ProgressBar1.Value + 1;
        Bitmap1.FreeImage;
      end;

      ShowMessage('Convert success!');
      ProgressBar1.Value := 0;
      Screen.Cursor := crDefault;
      ClearForm();
      gtPDFDocument1.Reset;
      except on Err:Exception do
      begin
        ProgressBar1.Value := 0;
        Screen.Cursor := crDefault;
        Writeln('Sorry, an exception was raised. ');
        Writeln(Err.Classname + ':' + Err.Message);
        Readln;
      end;
    end;
  end
  else
    ShowMessage('Source file is not defined!');

end;

procedure TFrmMain.FormCreate(Sender: TObject);
var
  PanelWidth: Integer;
begin
  PanelWidth := scStatusBar1.Width div 2;
  scStatusBar1.Panels[0].Width := PanelWidth;
  scStatusBar1.Panels[1].Width := PanelWidth;

  scStatusBar1.Panels[1].Text := 'ZSPdf v1.0.0';
  FrmMain.Caption := 'ZSPdf (Pdf to Image Converter) - Zaviera Solutions';

  ProgressBar1.Width := PanelWidth;
  ClearForm();
end;

procedure TFrmMain.ClearForm();
begin
  ed_pdf_file.Text := '';
  ed_pdf_file.ReadOnly := True;

  ed_size.Text := '';
  ed_size.ReadOnly := True;

  ed_page.Text := '';
  ed_page.ReadOnly := True;

  ed_output.Text := '';
  ed_output.ReadOnly := True;

  ed_hidden_filename.Text := '';
  ed_hidden_filename.Visible := False;

  cb_selected_page.ItemIndex := 0;
  cb_convert_to.ItemIndex := 0;

end;

end.
