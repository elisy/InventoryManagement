
////////////////////////////////////////////////////////////////////////////////
// ROW ORDER CONFIGURATION PROCEDURES

&AtClient
Procedure MoveRowUp(Command)
	
	ModuleRowOrderClient.MoveRowUp(List, Items.List);
	
EndProcedure

&AtClient
Procedure MoveRowDown(Command)
	
	ModuleRowOrderClient.MoveRowDown(List, Items.List);

EndProcedure

&AtClient
Procedure RestoreRowOrder(Command)
	
	ModuleRowOrderClient.RestoreRowOrder(List, Items.List);
	
EndProcedure



////////////////////////////////////////////////////////////////////////////////
// VALID PRICE RANGES CONFIGURATION

&AtClient
Procedure ConfigureValidPriceRanges(Command)
	
 	OpenForm("Catalog.PriceCategories.Form.ValidPriceRangesForm",,,,);

EndProcedure

