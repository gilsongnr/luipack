unit DropDownManager;

{$mode objfpc}{$H+}

interface

uses
  Controls, LMessages, Forms, Classes, SysUtils;

type

  { TDropDownManager }

  //todo: add create control on demand, OnCreateControl
  // specific code for TForm/TFrame (make use of window shadow)
  TDropDownManager = class(TComponent)
  private
    FControl: TWinControl;
    FMasterControl: TControl;
    FOnHide: TNotifyEvent;
    FOnShow: TNotifyEvent;
    function ControlGrabsFocus(AControl: TControl): Boolean;
    procedure FocusChangeHandler(Sender: TObject; LastControl: TControl);
    function GetDroppedDown: Boolean;
    procedure RemoveHandlers;
    procedure SetState(DoEvents: Boolean);
    procedure SetDroppedDown(const Value: Boolean);
    procedure UserInputHandler(Sender: TObject; Msg: Cardinal);
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    destructor Destroy; override;
    procedure UpdateState;
    property DroppedDown: Boolean read GetDroppedDown write SetDroppedDown;
  published
    property Control: TWinControl read FControl write FControl;
    property MasterControl: TControl read FMasterControl write FMasterControl;
    property OnHide: TNotifyEvent read FOnHide write FOnHide;
    property OnShow: TNotifyEvent read FOnShow write FOnShow;
  end;

implementation

{ TDropDownManager }

function TDropDownManager.ControlGrabsFocus(AControl: TControl): Boolean;
begin
  Result := (AControl <> FControl) and (AControl <> FMasterControl) and
    not FControl.IsParentOf(AControl) and (GetParentForm(FControl) = GetParentForm(AControl));
end;

procedure TDropDownManager.FocusChangeHandler(Sender: TObject; LastControl: TControl);
begin
  if ControlGrabsFocus(Screen.ActiveControl) then
    DroppedDown := False;
end;

function TDropDownManager.GetDroppedDown: Boolean;
begin
  if FControl <> nil then
    Result := FControl.Visible
  else
    Result := False;
end;

procedure TDropDownManager.RemoveHandlers;
begin
  Application.RemoveOnUserInputHandler(@UserInputHandler);
  Screen.RemoveHandlerActiveControlChanged(@FocusChangeHandler);
end;

procedure TDropDownManager.SetState(DoEvents: Boolean);
begin
  if FControl.Visible then
  begin
    if FControl.CanFocus then
      FControl.SetFocus;
    if Assigned(FOnShow) and DoEvents then
      FOnShow(Self);
    Application.AddOnUserInputHandler(@UserInputHandler);
    Screen.AddHandlerActiveControlChanged(@FocusChangeHandler);
  end
  else
  begin
    RemoveHandlers;
    if Assigned(FOnHide) and DoEvents then
      FOnHide(Self);
  end;
end;

procedure TDropDownManager.SetDroppedDown(const Value: Boolean);
begin
  if FControl = nil then
    raise Exception.Create('TDropDownWindow.Visible: Control not set');
  if FControl.Visible = Value then
    Exit;
  FControl.Visible := Value;
  SetState(True);
end;

procedure TDropDownManager.UserInputHandler(Sender: TObject; Msg: Cardinal);
begin
  case Msg of
    LM_LBUTTONDOWN, LM_LBUTTONDBLCLK, LM_RBUTTONDOWN, LM_RBUTTONDBLCLK,
    LM_MBUTTONDOWN, LM_MBUTTONDBLCLK, LM_XBUTTONDOWN, LM_XBUTTONDBLCLK:
    begin
      if ControlGrabsFocus(Application.MouseControl) then
        DroppedDown := False;
    end;
  end;
end;

procedure TDropDownManager.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if Operation = opRemove then
  begin
    if AComponent = FControl then
      FControl := nil
    else if AComponent = FMasterControl then
      FMasterControl := nil;;
  end;
end;

destructor TDropDownManager.Destroy;
begin
  RemoveHandlers;
  inherited Destroy;
end;

procedure TDropDownManager.UpdateState;
begin
  if FControl <> nil then
    SetState(False);
end;

end.

