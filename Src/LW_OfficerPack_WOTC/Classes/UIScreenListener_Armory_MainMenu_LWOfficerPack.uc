//---------------------------------------------------------------------------------------
//  FILE:    UIScreenListener_Armory_MainMenu_LWOfficerPack
//  AUTHOR:  Amineri
//
//  PURPOSE: Implements hooks to add button to List in order to invoke OfficerUI for viewing
//--------------------------------------------------------------------------------------- 

class UIScreenListener_Armory_MainMenu_LWOfficerPack extends UIScreenListener;


var UIListItemString_SelfContained OfficerListItem; // for integration into existing list
var UIListItemString_SelfContained NewDismissListItem; // for replacing dismiss button to move to bottom of list
var UIArmory_MainMenu ParentScreen;
var UIListItemString DismissListItem;

var delegate<OnItemSelectedCallback> NextOnSelectionChanged;

var localized string strOfficerMenuOption;
var localized string strOfficerTooltip;
var localized string OfficerListItemDescription;

delegate OnItemSelectedCallback(UIList _list, int itemIndex);

// This event is triggered after a screen is initialized
event OnInit(UIScreen Screen)
{
	local UIPanel BG;
	local XComGameState_Unit Unit;

	ParentScreen = UIArmory_Mainmenu(Screen); 

	Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ParentScreen.UnitReference.ObjectID));

	//update mousewheel controls so that mousewheel moves scrollbar when over list
    if(ParentScreen != none)
    {
            BG = ParentScreen.Spawn(class'UIPanel', ParentScreen).InitPanel('armoryMenuBG');
            BG.bShouldPlayGenericUIAudioEvents = false;  
            BG.ProcessMouseEvents(ParentScreen.List.OnChildMouseEvent); // hook mousewheel to scroll MainMenu list instead of rotating soldier
    }

	if (class'LWOfficerUtilities'.static.IsOfficer(Unit) || class'UIArmory_LWOfficerPromotion'.default.ALWAYSSHOW) 
	{
		//link in selection-change info
		NextOnSelectionChanged = ParentScreen.List.OnSelectionChanged;
		ParentScreen.List.OnSelectionChanged = OnSelectionChanged;
		
		InsertOfficerListButton(Unit);
	}

	class'LWOfficerUtilities'.static.GCandValidationChecks();

}

//This event is triggered after a screen receives focus
event OnReceiveFocus(UIScreen Screen)
{
	local XComGameState_Unit Unit;

	ParentScreen = UIArmory_Mainmenu(Screen);
	Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ParentScreen.UnitReference.ObjectID));

	if (class'LWOfficerUtilities'.static.IsOfficer(Unit)) 
	{
		InsertOfficerListButton(Unit);
	}
}

// This event is triggered after a screen loses focus
//event OnLoseFocus(UIScreen Screen);


// This event is triggered when a screen is removed
event OnRemoved(UIScreen Screen)
{
	//clear reference to UIScreen so it can be garbage collected
	ParentScreen = none;

	//garbage collect officer states in case one was dismissed
	class'LWOfficerUtilities'.static.GCandValidationChecks();
}

simulated function InsertOfficerListButton(XComGameState_Unit Unit)
{
	DismissListItem = FindDismissListItem(ParentScreen.List);
	DismissListItem.Hide(); // TODO: change this to remove if remove glitches for UIList is fixed
	AddListButton();
	CreateDismissButton(Unit);
	ParentScreen.List.MoveItemToBottom(DismissListItem);
}

//adds a button to the existing MainMenu list
simulated function AddListButton()
{
	OfficerListItem = UIListItemString_SelfContained(ParentScreen.Spawn(class'UIListItemString_SelfContained', ParentScreen.List.ItemContainer).InitListItem(Caps(strOfficerMenuOption)).SetDisabled(false, strOfficerTooltip));
	OfficerListItem.SetButtonBGClickHander (OnOfficerButtonCallback);
}

simulated function CreateDismissButton(XComGameState_Unit Unit)
{
	local bool bTutorialObjectInProgress, bInTutorialPromote, bUnitIsTraining, bCantDismiss;

	bInTutorialPromote = !class'XComGameState_HeadquartersXCom'.static.IsObjectiveCompleted('T0_M2_WelcomeToArmory');
	bTutorialObjectInProgress = class'XComGameState_HeadquartersXCom'.static.AnyTutorialObjectivesInProgress();
	bUnitIsTraining = Unit.IsTraining() || Unit.IsPsiTraining() || Unit.IsPsiAbilityTraining();

	bCantDismiss = bInTutorialPromote || bTutorialObjectInProgress || bUnitIsTraining;

	NewDismissListItem = UIListItemString_SelfContained(ParentScreen.Spawn(class'UIListItemString_SelfContained', ParentScreen.List.ItemContainer).InitListItem(ParentScreen.m_strDismiss).SetDisabled(bCantDismiss, strOfficerTooltip));
	NewDismissListItem.SetButtonBGClickHander (OnDismissButtonCallback);
}


//callback handler for list button -- invokes the LW officer ability UI
simulated function OnOfficerButtonCallback(UIButton kButton)
{
	local XComHQPresentationLayer HQPres;
	local UIArmory_LWOfficerPromotion OfficerScreen;

	HQPres = `HQPRES;
	OfficerScreen = UIArmory_LWOfficerPromotion(HQPres.ScreenStack.Push(HQPres.Spawn(class'UIArmory_LWOfficerPromotion', HQPres), HQPres.Get3DMovie()));
	OfficerScreen.InitPromotion(ParentScreen.GetUnitRef(), false);
}

//callback handler for list button -- invokes the base-game dismiss functionality
simulated function OnDismissButtonCallback(UIButton kButton)
{
	ParentScreen.OnDismissUnit();
}

simulated function OnSelectionChanged(UIList ContainerList, int ItemIndex)
{
	if (ContainerList.GetItem(ItemIndex) == OfficerListitem) 
	{
		ParentScreen.MC.ChildSetString("descriptionText", "htmlText", class'UIUtilities_Text'.static.AddFontInfo(OfficerListItemDescription, true));
		return;
	}
	if (ContainerList.GetItem(ItemIndex) == DismissListitem) 
	{
		ParentScreen.MC.ChildSetString("descriptionText", "htmlText", class'UIUtilities_Text'.static.AddFontInfo(ParentScreen.m_strDismissDesc, true));
		return;
	}
	NextOnSelectionChanged(ContainerList, ItemIndex);
}

simulated function UIListItemString FindDismissListItem(UIList List)
{
	local int Idx;
	local UIListItemString Current;

	for (Idx = 0; Idx < List.ItemCount ; Idx++)
	{
		Current = UIListItemString(List.GetItem(Idx));
		//`log("Dismiss Search: Text=" $ Current.Text $ ", DismissName=" $ ParentScreen.m_strDismiss);
		if (Current.Text == ParentScreen.m_strDismiss)
			return Current;
	}
	return none;
}

defaultproperties
{
	// Leaving this assigned to none will cause every screen to trigger its signals on this class
	ScreenClass = UIArmory_MainMenu;
}