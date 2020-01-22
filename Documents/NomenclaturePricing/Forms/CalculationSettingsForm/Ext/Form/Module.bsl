
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	LoadOldPrices = Parameters.LoadOldPrices;
	LoadPriceCategories();
	SelectedOnly = 0;
	BlankOnly = 0;
	OldPriceDate = CurrentDate();
	
	PricingModesFillByInfobaseData = Enums.PricingModes.FillByInfobaseData;
	PricingModesFillByOtherPriceCategories = Enums.PricingModes.FillByOtherPriceCategories;
	
	Items.OK.Title = ?(LoadOldPrices, NStr("en = 'Fill'; ru = 'Загрузить'"), NStr("en = 'Calculate'; ru = 'Рассчитать'"));
	Items.PriceCategoriesRecalculate.Title = ?(LoadOldPrices, NStr("en = 'Fill'; ru = 'Загрузить'"), NStr("en = 'Recalculate'; ru = 'Пересчитать'"));
	Items.GroupParametersOldPriceRecalculation.Visible = LoadOldPrices;
	
EndProcedure



&AtServer
Procedure LoadPriceCategories()
	
	Query = New Query();
	Query.Text = "SELECT
	             |	PriceCategories.Ref,
	             |	PriceCategories.PricingMode
	             |FROM
	             |	Catalog.PriceCategories AS PriceCategories
	             |WHERE
	             |	PriceCategories.Ref IN(&ArrayPriceCategories)";
	Query.SetParameter("ArrayPriceCategories", Parameters.PriceCategories);
	TablePriceCategories = Query.Execute().Unload();
	
	// Load them manually in the form order	
	For each PriceCategory In Parameters.PriceCategories Do
		RowPriceCategory = PriceCategories.Add();
		RowPriceCategory.Reference = PriceCategory;
		RowPriceCategory.PricingMode = TablePriceCategories.Find(PriceCategory, "Ref").PricingMode;
		RowPriceCategory.Recalculate = True;
	EndDo;
	
EndProcedure


&AtClient
Procedure OK(Command)
	
	ArrayPriceCategories = New Array();            	
	For each PriceCategory In PriceCategories Do
		If PriceCategory.Recalculate Then
			ArrayPriceCategories.Add(PriceCategory.Reference);
		EndIf;
	EndDo;
	
	Result = New Structure();
	Result.Insert("LoadOldPrices", LoadOldPrices);
	Result.Insert("PriceCategories", ArrayPriceCategories);
	Result.Insert("SelectedOnly", SelectedOnly = 1);
	Result.Insert("BlankOnly", BlankOnly = 1);
	
	If LoadOldPrices Then
		Result.Insert("OldPriceDate", OldPriceDate);	
		Result.Insert("PricePercent", PricePercent);
	EndIf;		
	
	Close(Result);	

EndProcedure


&AtClient
Procedure PriceCategoriesSelectAll(Command)
	For each PriceCategory In PriceCategories Do
		PriceCategory.Recalculate = True;
	EndDo;
EndProcedure


&AtClient
Procedure PriceCategoriesDeselectAll(Command)
	For each PriceCategory In PriceCategories Do
		PriceCategory.Recalculate = False;
	EndDo;
EndProcedure