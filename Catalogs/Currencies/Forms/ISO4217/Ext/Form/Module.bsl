
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	CloseOnChoice = False;
	FillCurrencyTable();
	
EndProcedure


&AtClient
Procedure ListCurrenciesSelection(Item, SelectedRow, Field, StandardProcessing)
	ProcessSelectionInListCurrencies(Item.CurrentData);
EndProcedure


&AtServer
// Fills currency list from ISO4217 template
//
Procedure FillCurrencyTable()
	
	XMLList = Catalogs.Currencies.GetTemplate("ISO4217").GetText();
	
	Table = ModuleCommon.ReadXMLIntoTable(XMLList).Data;
	
	For each Row In Table Do
		NewRow = Currencies.Add();
		NewRow.Code           = Row.Code;
		NewRow.CodeAlphabetic = Row.CodeSymbol;
		NewRow.Currency       = Row.Name;
		NewRow.Entity         = Row.Description;
		NewRow.IsDownloable   = False;
	EndDo;
	
EndProcedure


&AtClient
Procedure Choose(Command)
	ProcessSelectionInListCurrencies(Items.ListCurrencies.CurrentData);
EndProcedure


&AtClient
// On selected event handler of ListCurrencies control
// Notifies the parent form about choice. Closes the form.
//
Procedure ProcessSelectionInListCurrencies(CurrentData)
	
	ChoiceParameters = New Structure("Code, Description, DescriptionLong, IsDownloable");
	ChoiceParameters.Code             = CurrentData.Code;
	ChoiceParameters.Description      = CurrentData.CodeAlphabetic;
	ChoiceParameters.DescriptionLong  = CurrentData.Currency;
	ChoiceParameters.IsDownloable     = CurrentData.IsDownloable;
	
	NotifyChoice(ChoiceParameters);
	
EndProcedure


