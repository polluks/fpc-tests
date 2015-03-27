unit SearchReplaceUnit;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  {$ifdef HASAMIGA}
  Intuition,
  {$endif}
  ExtCtrls, SynEdit, SynEditTypes, PrefsUnit;

type

  { TSearchReplaceWin }

  TSearchReplaceWin = class(TForm)
    CancelButton: TButton;
    UseCaseSen: TCheckBox;
    UseWholeWord: TCheckBox;
    ChoosePrompt: TCheckBox;
    ChooseBackward: TRadioButton;
    ChooseBegin: TRadioButton;
    ChooseCursor: TRadioButton;
    ChooseForward: TRadioButton;
    ChooseGlobal: TRadioButton;
    ChooseSel: TRadioButton;
    Label1: TLabel;
    Label10: TLabel;
    Label11: TLabel;
    Label12: TLabel;
    Label13: TLabel;
    HistoryBox: TListBox;
    HistoryLabel: TPanel;
    PromptReplaceLabel: TLabel;
    Label15: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    OriginPanel: TPanel;
    OriginPanel1: TPanel;
    OriginPanel2: TPanel;
    Panel1: TPanel;
    HistoryPanel: TPanel;
    SearchPanel: TPanel;
    ReplaceEdit: TEdit;
    ReplaceLabel: TLabel;
    ResultPanel: TPanel;
    SearchButton: TButton;
    SearchEdit: TEdit;
    SearchSettings: TPanel;
    SHToggle: TToggleBox;
    RHToggle: TToggleBox;
    UseRegExp: TCheckBox;
    procedure CancelButtonClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure HistoryBoxDblClick(Sender: TObject);
    procedure SearchAgainClick(Sender: TObject);
    procedure SearchBackClick(Sender: TObject);
    procedure SearchButtonClick(Sender: TObject);
    procedure SearchEditEditingDone(Sender: TObject);
    procedure SHToggleClick(Sender: TObject);
    procedure RHToggleChange(Sender: TObject);
  private
    SearchHist: TStringList;
    ReplaceHist: TStringList;
    SearchString: string;
    ReplaceString: string;
    SearchSett: TSynSearchOptions;
    ReplaceMode: Boolean;
    InEvent: Boolean;
    procedure GetSearchSettings;
    procedure MyBeep;
  public
    procedure StartReq(AsReplace: Boolean);
  end;

var
  SearchReplaceWin: TSearchReplaceWin;

implementation

uses
  MainUnit;

{$R *.lfm}

{ TSearchReplaceWin }

procedure TSearchReplaceWin.SearchButtonClick(Sender: TObject);
var
  Res: Integer;
begin
  if SearchEdit.Text = '' then
  begin
    MyBeep;
    ResultPanel.Caption := 'Nothing to find';
    Exit;
  end;
  ReplaceString := '';
  ResultPanel.caption := '';
  GetSearchSettings;
  SearchString := SearchEdit.Text;
  if SearchHist.IndexOf(SearchString) < 0 then
    SearchHist.Insert(0, SearchString);
  if ReplaceMode then
  begin
    ReplaceString := ReplaceEdit.Text;
    if ReplaceHist.IndexOf(ReplaceString) < 0 then
      ReplaceHist.Insert(0, ReplaceString);
    while ReplaceHist.Count > 100 do
      ReplaceHist.Delete(ReplaceHist.Count - 1);
  end;
  Close;
  Res := Form1.CurEditor.SearchReplace(SearchString, ReplaceString, SearchSett);
  if Res <= 0 then
  begin
    MyBeep;
    ResultPanel.Caption:= 'Nothing found';
    Show;
  end;
  if SHToggle.Checked or (not RHToggle.Enabled) then
    HistoryBox.Items.Assign(SearchHist)
  else
    HistoryBox.Items.Assign(ReplaceHist);
end;

procedure TSearchReplaceWin.SearchEditEditingDone(Sender: TObject);
begin
  {$ifdef AROS}
  SearchButtonClick(Sender);
  {$endif}
end;

procedure TSearchReplaceWin.SHToggleClick(Sender: TObject);
begin
  if InEvent then
    Exit;
  InEvent := True;
  if not SHToggle.Checked then
    SHToggle.Checked := True;
  if RHToggle.Checked then
    RHToggle.Checked := False;
  HistoryLabel.Caption := 'Search History';
  HistoryBox.Items.Assign(SearchHist);
  InEvent := False;
end;

procedure TSearchReplaceWin.RHToggleChange(Sender: TObject);
begin
  if InEvent then
    Exit;
  InEvent := True;
  if not RHToggle.Checked then
    RHToggle.Checked := True;
  if SHToggle.Checked then
    SHToggle.Checked := False;
  HistoryLabel.Caption := 'Replace History';
  HistoryBox.Items.Assign(ReplaceHist);
  InEvent := False;
end;

procedure TSearchReplaceWin.GetSearchSettings;
begin
  SearchSett := [];
  if ChooseBackward.Checked then
    Include(SearchSett, ssoBackwards);
  if ChooseSel.Checked then
    Include(SearchSett, ssoSelectedOnly);
  if UseRegExp.Checked then
    Include(SearchSett, ssoRegExpr);
  if UseCaseSen.Checked then
    Include(SearchSett, ssoMatchCase);
  if UseWholeWord.Checked then
    Include(SearchSett, ssoWholeWord);
  if ChooseBegin.Checked then
    Include(SearchSett, ssoEntireScope);
  if ReplaceMode then
  begin
    Include(SearchSett, ssoReplaceAll);
    Include(SearchSett, ssoReplace);
    if ChoosePrompt.Checked then
      Include(SearchSett, ssoPrompt);
  end;
end;

procedure TSearchReplaceWin.MyBeep;
begin
  {$ifdef HASAMIGA}
  Intuition.DisplayBeep(nil);
  {$else}
  SysUtils.Beep;
  {$endif}
end;

procedure TSearchReplaceWin.SearchAgainClick(Sender: TObject);
var
  Res: Integer;
begin
  Exclude(SearchSett, ssoEntireScope);
  Res := Form1.CurEditor.SearchReplace(SearchString, '', SearchSett + [ssoFindContinue]);
  if Res <= 0 then
    MyBeep;
end;

procedure TSearchReplaceWin.HistoryBoxDblClick(Sender: TObject);
begin
  if (HistoryBox.ItemIndex >= 0) and (HistoryBox.ItemIndex < HistoryBox.Items.Count) then
  begin
    if SHToggle.Checked or not (RHToggle.Enabled) then
    begin
      SearchEdit.Text := HistoryBox.Items[HistoryBox.ItemIndex];
    end else
    begin
      ReplaceEdit.Text := HistoryBox.Items[HistoryBox.ItemIndex];
    end;
  end;
end;

procedure TSearchReplaceWin.FormCreate(Sender: TObject);
begin
  SearchHist := TStringList.Create;
  ReplaceHist := TStringList.Create;
  Prefs.GetSearchHist(SearchHist, False);
  Prefs.GetSearchHist(ReplaceHist, True);
  UseCaseSen.Checked := Prefs.CaseSens;
  UseWholeWord.Checked := Prefs.WholeWord;
  UseRegExp.Checked := Prefs.RegExp;
  ChooseForward.Checked := Prefs.SearchFwd;
  ChooseBegin.Checked := Prefs.SearchBegin;
  ChooseGlobal.Checked := Prefs.SearchGlobal;
  ChoosePrompt.Checked := Prefs.PromptReplace;
end;

procedure TSearchReplaceWin.CancelButtonClick(Sender: TObject);
begin
  Close;
end;

procedure TSearchReplaceWin.FormDestroy(Sender: TObject);
begin
  Prefs.CaseSens := UseCaseSen.Checked;
  Prefs.WholeWord := UseWholeWord.Checked;
  Prefs.RegExp := UseRegExp.Checked;
  Prefs.SearchFwd := ChooseForward.Checked;
  Prefs.SearchBegin := ChooseBegin.Checked;
  Prefs.SearchGlobal := ChooseGlobal.Checked;
  Prefs.PromptReplace := ChoosePrompt.Checked;
  Prefs.SetSearchHist(SearchHist, False);
  Prefs.SetSearchHist(ReplaceHist, True);
  SearchHist.Free;
  ReplaceHist.Free;
end;

procedure TSearchReplaceWin.SearchBackClick(Sender: TObject);
begin
  if Form1.CurEditor.SearchReplace(SearchString, '', SearchSett + [ssoBackwards,ssoFindContinue]) <= 0 then
    MyBeep;
end;

procedure TSearchReplaceWin.StartReq(AsReplace: Boolean);
begin
  ReplaceMode := AsReplace;
  ResultPanel.caption := '';
  if AsReplace then
    SearchButton.Caption := 'Replace'
  else
    SearchButton.Caption := 'Find';
  ReplaceLabel.Enabled := AsReplace;
  ReplaceEdit.Enabled := AsReplace;
  PromptReplaceLabel.Enabled := AsReplace;
  ChoosePrompt.Enabled := AsReplace;
  InEvent := False;
  RHToggle.Enabled := AsRePlace;
  Show;
  if not AsReplace then
    SHToggleClick(SHToggle);
  if SHToggle.Checked or (not RHToggle.Enabled) then
    HistoryBox.Items.Assign(SearchHist)
  else
    HistoryBox.Items.Assign(ReplaceHist);
  BringToFront;
  SearchEdit.SetFocus;
end;

end.

