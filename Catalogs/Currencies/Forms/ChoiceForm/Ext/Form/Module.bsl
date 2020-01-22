////////////////////////////////////////////////////////////////////////////////
// EVENT HANDLERS
//


&AtClient
Procedure ListSelection(Item, SelectedRow, Field, StandardProcessing)
	
	NotifyChoice(SelectedRow);
	StandardProcessing = False;

EndProcedure


&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("ChoiceForm") Then
		CloseOnChoice = False;
	EndIf;
	
	If Parameters.Property("DownloableCurrencies") Then
		SetFilterByDownloableCurrencies();
	EndIf;

EndProcedure


////////////////////////////////////////////////////////////////////////////////
// PRIVATE FUNCTIONS AND PROCEDURES


&AtServer
// Procedure sets dynamic list query to select independent currencies
//
Procedure SetFilterByDownloableCurrencies()
	
	FilterItem = List.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterItem.LeftValue = New DataCompositionField("IsDownloable");
	FilterItem.ComparisonType = DataCompositionComparisonType.Equal;
	FilterItem.Use = True;
	FilterItem.RightValue = True;
	
EndProcedure


