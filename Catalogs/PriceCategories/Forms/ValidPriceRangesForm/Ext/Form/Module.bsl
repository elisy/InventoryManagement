////////////////////////////////////////////////////////////////////////////////
// PRIVATE PROCEDURES AND FUNCTIONS

&AtServer
Procedure WriteValidPriceRanges()
	
	Query = New Query(
		"SELECT
		|	Constants.MaximalSalesPriceCategory,
		|	Constants.MaximalPurchasePriceCategory,
		|	Constants.MinimalSalesPriceCategory
		|FROM
		|	Constants AS Constants");
		
	Selection = Query.Execute().Choose();
	If Selection.Next() Then
		
		If MinimalSalesPriceCategory <> Selection.MinimalSalesPriceCategory Then
			Constants.MinimalSalesPriceCategory.Set(MinimalSalesPriceCategory);
		EndIf;
			
		If MaximalSalesPriceCategory <> Selection.MaximalSalesPriceCategory Then
			Constants.MaximalSalesPriceCategory.Set(MaximalSalesPriceCategory);
		EndIf;
		
		If MaximalPurchasePriceCategory <> Selection.MaximalPurchasePriceCategory Then
			Constants.MaximalPurchasePriceCategory.Set(MaximalPurchasePriceCategory);
		EndIf;
				
	EndIf;
	Modified = False;
	
EndProcedure

&AtServer
Procedure ReadValidPriceRanges()
	
	Query = New Query(
		"SELECT
		|	Constants.MaximalSalesPriceCategory,
		|	Constants.MaximalPurchasePriceCategory,
		|	Constants.MinimalSalesPriceCategory
		|FROM
		|	Constants AS Constants");
		
	Selection = Query.Execute().Choose();
	If Selection.Next() Then
		MinimalSalesPriceCategory = Selection.MinimalSalesPriceCategory;	
		MaximalSalesPriceCategory = Selection.MaximalSalesPriceCategory;	
		MaximalPurchasePriceCategory = Selection.MaximalPurchasePriceCategory;
	EndIf;
	
EndProcedure



////////////////////////////////////////////////////////////////////////////////
// COMMAND EVENT HANDLERS 


&AtClient
Procedure WriteAndClose(Command)
	
	WriteValidPriceRanges();
	Close();
	
EndProcedure

&AtClient
Procedure Write(Command)
	
	WriteValidPriceRanges();
EndProcedure



////////////////////////////////////////////////////////////////////////////////
// FORM EVENT HANDLERS

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	ReadValidPriceRanges();
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, StandardProcessing)
	
	If NOT Modified Then
		Return;
	EndIf;
	
	Result = DoQueryBox(NStr("en = 'Do you want to save modified data?'; ru = 'Данные изменены. Сохранить?'"),QuestionDialogMode.YesNoCancel);
	If Result = DialogReturnCode.Yes Then
		WriteValidPriceRanges();
	ElsIf Result = DialogReturnCode.Cancel Then
		Cancel = True;
	EndIf;

EndProcedure



