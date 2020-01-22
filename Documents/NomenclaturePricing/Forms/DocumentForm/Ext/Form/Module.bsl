&AtClient
Var CachedValues;


&AtServer
Var CatalogPriceCategories;


&AtServer
Var CurrencyRates;


&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Version control handler
	ModuleVersionControl.OnCreateAtServer(ThisForm);
	
	ManualPricingMode = Enums.PricingModes.Manual;
	
	LoadPriceCategoriesCatalog();
	LoadCurrencyRates();
	
	InitializeSelectedPriceCategories();		
	
	If Object.Products.Count() > 0 Then
		BuildPriceCategoriesTable();	
		FillTabularSectionProducts();
		FillBasePrices();
		Items.GroupPages.CurrentPage = Items.GroupPricing;
	EndIf;
	
	EnablePriceGroups = GetFunctionalOption("EnablePriceGroups");
	EnableNomenclatureCharacteristics = GetFunctionalOption("EnableNomenclatureCharacteristics");
	EnableNomenclaturePackages = GetFunctionalOption("EnableNomenclaturePackages");
	
	Items.SubmenuChoose.Visible = EnablePriceGroups;	
	SetCalculateAutomatically(True);
	
EndProcedure



&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)

	#If WebClient Then
		SetCalculateAutomatically(False);
		Items.TablePricesCalculateAutomatically.Visible = False;
	#Else
		SetCalculateAutomatically(Settings["CalculateAutomatically"]);
	#EndIf

EndProcedure



&AtServer
Procedure SetCalculateAutomatically(NewValue)
	CalculateAutomatically = NewValue;
	Items.TablePricesCalculateAutomatically.Check = NewValue;
EndProcedure



&AtClient
Procedure SetCalculateAutomaticallyAtClient(NewValue)
	CalculateAutomatically = NewValue;
	Items.TablePricesCalculateAutomatically.Check = NewValue;
EndProcedure



&AtClient
Procedure TablePricesCharacteristicStartChoice(Item, ChoiceData, StandardProcessing)
	
	ModuleTabularSectionProductsClient.ChooseNomenclatureCharacteristic(ThisForm, Item, StandardProcessing, Items.TablePrices.CurrentData);
	
EndProcedure


&AtClient
Procedure TablePricesPackageStartChoice(Item, ChoiceData, StandardProcessing)
	
	ModuleTabularSectionProductsClient.ChooseNomenclaturePackage(ChoiceData, StandardProcessing, Items.TablePrices.CurrentData);
	
EndProcedure



&AtServer
Procedure SetIsDependentIsInfluencingFlags()
	
	For each PriceCategory In SelectedPriceCategories Do
		PriceCategory.IsDependent = False;
		PriceCategory.IsInfluencing = False;
	EndDo;
	
	For each PriceCategory In SelectedPriceCategories Do
		If PriceCategory.IsSelected Then 
			For each DependentPriceCategory In PriceCategory.DependentPrices Do
				DependentPriceCategoryRow = FindPriceCategoryRow(SelectedPriceCategories, DependentPriceCategory.Value);
				DependentPriceCategoryRow.IsDependent = NOT DependentPriceCategoryRow.IsSelected;
			EndDo;
			For each InfluencingPriceCategory In PriceCategory.InfluencingPrices Do
				SelectedPriceCategoryRow = FindPriceCategoryRow(SelectedPriceCategories, InfluencingPriceCategory.Value);
				SelectedPriceCategoryRow.IsInfluencing = NOT SelectedPriceCategoryRow.IsSelected;
			EndDo;
		EndIf;
	EndDo;
EndProcedure




&AtClient
Procedure SetIsDependentIsInfluencingFlagsAtClient()
	For each PriceCategory In SelectedPriceCategories Do
		PriceCategory.IsDependent = False;
		PriceCategory.IsInfluencing = False;
	EndDo;
	For each PriceCategory In SelectedPriceCategories Do
		If PriceCategory.IsSelected Then 
			For each DependentPriceCategory In PriceCategory.DependentPrices Do
				DependentPriceCategoryRow = FindPriceCategoryRowAtClient(SelectedPriceCategories, DependentPriceCategory.Value);
				DependentPriceCategoryRow.IsDependent = NOT DependentPriceCategoryRow.IsSelected;
			EndDo;
			For each InfluencingPriceCategory In PriceCategory.InfluencingPrices Do
				SelectedPriceCategoryRow = FindPriceCategoryRowAtClient(SelectedPriceCategories, InfluencingPriceCategory.Value);
				SelectedPriceCategoryRow.IsInfluencing = NOT SelectedPriceCategoryRow.IsSelected;
			EndDo;
		EndIf;
	EndDo;
EndProcedure



&AtServer
Procedure InitializeSelectedPriceCategories()
	
	SelectedPriceCategories.Load(GetPriceCategoriesCatalog());
	
	SelectedPriceCategories.Sort("Level");
	
	ArrayPriceCategories = New Array();
	For each RowNomenclatureItem In Object.Products Do
		If ArrayPriceCategories.Find(RowNomenclatureItem.PriceCategory) = Undefined Then
			ArrayPriceCategories.Add(RowNomenclatureItem.PriceCategory);
		EndIf;
	EndDo;	

	For each PriceCategory In ArrayPriceCategories Do
		FindPriceCategoryRow(SelectedPriceCategories, PriceCategory).IsSelected = True;
	EndDo;
	
	SetIsDependentIsInfluencingFlags();
	
EndProcedure


&AtServer
Function GetPriceCategoriesCatalog()
	If CatalogPriceCategories = Undefined Then
		CatalogPriceCategories = GetFromTempStorage(CatalogPriceCategoriesStorageAddress);
	EndIf;
	Return CatalogPriceCategories;
EndFunction



&AtServer
Procedure LoadCurrencyRates()
	Query = New Query();
	Query.Text = "SELECT
				 |	CurrencyRatesSliceLast.Currency,
				 |	CurrencyRatesSliceLast.ExchangeRate,
				 |	CurrencyRatesSliceLast.Ratio
				 |FROM
				 |	InformationRegister.CurrencyRates.SliceLast AS CurrencyRatesSliceLast";
	CurrencyRatesStorageAddress = PutToTempStorage(Query.Execute().Unload(), UUID);
EndProcedure



&AtServer
Function GetCurrencyRates()
	If CurrencyRates = Undefined Then
		CurrencyRates = GetFromTempStorage(CurrencyRatesStorageAddress);
	EndIf;
	Return CurrencyRates;
EndFunction



&AtServer
Function FindCurrencyRow(Currency)	
	Rows = GetCurrencyRates().FindRows(New Structure("Currency", Currency));
	If Rows.Count() = 0 Then
		Message(NStr("en = 'Missing exchange rate: '; ru = 'Не установлен курс валюты: '") + Currency);
		Return Undefined;
	Else
		Return	Rows[0];
	EndIf;	
EndFunction




&AtServer
Function RecalculateCurrency(SourceCurrency, DestinationCurrency, Price)	
	If SourceCurrency <> DestinationCurrency Then
		SourceCurrencyRow = FindCurrencyRow(SourceCurrency);
		DestinationCurrencyRow = FindCurrencyRow(DestinationCurrency);
		If SourceCurrencyRow <> Undefined AND DestinationCurrencyRow <> Undefined Then
			Return Price * SourceCurrencyRow.ExchangeRate * DestinationCurrencyRow.Ratio / DestinationCurrencyRow.ExchangeRate * SourceCurrencyRow.Ratio;		
		EndIf;
	EndIf;
	
	Return Price;    	
EndFunction



&AtServer
Function GetCurrencyRecalculationRow(SourceCurrency, DestinationCurrency)	
	If SourceCurrency <> DestinationCurrency Then
		SourceCurrencyRow = FindCurrencyRow(SourceCurrency);
		DestinationCurrencyRow = FindCurrencyRow(DestinationCurrency);
		If SourceCurrencyRow <> Undefined AND DestinationCurrencyRow <> Undefined Then
			Return StrReplace("*" + String(SourceCurrencyRow.ExchangeRate) + "*" + String(DestinationCurrencyRow.Ratio) + "/" + String(DestinationCurrencyRow.ExchangeRate) + "*" + String(SourceCurrencyRow.Ratio), ",", ".");		
		EndIf;
	EndIf;
	
	Return "";	
EndFunction



&AtServer
Function FindPricesTableRows(Table, RowKey)
	Return Table.FindRows(New Structure("Nomenclature,Characteristic,Package", RowKey.Nomenclature, RowKey.Characteristic, RowKey.Package));
EndFunction



&AtServer
Procedure LoadPrice(DestinationTable, SourceRow, Val PriceCategory = Undefined, Val PriceCurrency = Undefined, BlankOnly = False)
	DestinationTableRows = FindPricesTableRows(DestinationTable, SourceRow);
	If DestinationTableRows.Count() = 0 Then
		DestinationTableRow = DestinationTable.Add();
		DestinationTableRow.Nomenclature = SourceRow.Nomenclature;
		DestinationTableRow.Characteristic = SourceRow.Characteristic;
		DestinationTableRow.Package = SourceRow.Package;
	Else
		DestinationTableRow = DestinationTableRows[0];
	EndIf;
	If PriceCategory = Undefined Then
		PriceCategory = SourceRow.PriceCategory;
	EndIf;
	CurrentPrice = DestinationTableRow[GetPriceColumnName(PriceCategory)];
	If (CurrentPrice = 0 OR NOT BlankOnly) AND SourceRow.Price <> Null Then		
		Price = SourceRow.Price;
		If PriceCurrency <> Undefined AND SourceRow.Currency <> Null Then
			Price = RecalculateCurrency(SourceRow.Currency, PriceCurrency, Price);
		EndIf;
		DestinationTableRow[GetPriceColumnName(PriceCategory)] = Price;
	EndIf;
EndProcedure



&AtServer
Procedure FillTabularSectionProducts()
	
	For each Row In Object.Products Do
		LoadPrice(TablePrices, Row);
	EndDo;
	
EndProcedure


&AtServer
Function GetPriceColumnName(PriceCategory)
	Return "PriceCategory" + StrReplace(PriceCategory.UUID(), "-", "");
EndFunction


&AtServer
Function AddFormField(Name, Title = Undefined, OnChangeHandler = "", StartChoiceHandler = "", BackColor = Undefined, TitleBackColor = Undefined)
	              
	NewField = Items.Add("TablePrices" + Name, Type("FormField"), Items.TablePrices);	
	NewField.DataPath = "TablePrices." + Name;
	NewField.Title = ?(ValueIsFilled(Title), Title, Name);
	NewField.EditMode = ColumnEditMode.Directly;
	NewField.Type = FormFieldType.InputField; 		
	If TitleBackColor <> Undefined Then
		NewField.TitleBackColor = TitleBackColor;
	EndIf;
	If BackColor <> Undefined Then
		NewField.BackColor = BackColor;
	EndIf;
		
	If ValueIsFilled(OnChangeHandler) Then
		NewField.SetAction("OnChange", OnChangeHandler);
	EndIf;
	If ValueIsFilled(StartChoiceHandler) Then
		NewField.SetAction("StartChoice", StartChoiceHandler);
	EndIf;
	
	Return NewField;
	
EndFunction



&AtServer
Procedure BuildPriceCategoriesTable()	
	
	ValueTable = CreateEmptyNomenclatureTable();
	
	For each PriceCategory In SelectedPriceCategories Do
		If PriceCategory.IsSelected OR PriceCategory.IsInfluencing Then 
			ValueTable.Columns.Add(GetPriceColumnName(PriceCategory.Ref), New TypeDescription("Number", New NumberQualifiers(15, 2, AllowedSign.Nonnegative)), String(PriceCategory.Ref));
		EndIf;
	EndDo;	
	
	TablePricesColumns = New Array();
	For each Attribute In GetAttributes("TablePrices") Do
		If Find(Attribute.Name, "PriceCategory") Then
			TablePricesColumns.Add("TablePrices." + Attribute.Name);
		EndIf;
	EndDo;
	
	ChangeAttributes(,TablePricesColumns);
	
	TablePricesColumns = New Array();
	For each Column In ValueTable.Columns Do
		If Find(Column.Name, "PriceCategory") Then
			TablePricesColumns.Add(New FormAttribute(Column.Name, Column.ValueType, "TablePrices", Column.Title, True));
		EndIf;
	EndDo;
	
	ChangeAttributes(TablePricesColumns);
	
	While Items.TablePrices.ChildItems.Count() > 3 Do
		Items.Delete(Items.TablePrices.ChildItems[Items.TablePrices.ChildItems.Count() - 1]);
	EndDo;
	
	For each PriceCategory In SelectedPriceCategories Do
		If PriceCategory.IsSelected Then			
			TitleBackColor = Undefined;
			BackColor = Undefined;
			If PriceCategory.PricingMode = Enums.PricingModes.FillByInfobaseData Then				
				TitleBackColor = New Color(245, 245, 245); 
				BackColor = New Color(245, 250, 255);				
			ElsIf PriceCategory.PricingMode = Enums.PricingModes.FillByOtherPriceCategories Then				
				TitleBackColor = New Color(220, 220, 220); 
				BackColor = New Color(250, 240, 230);
			EndIf;
			AddFormField(GetPriceColumnName(PriceCategory.Ref), String(PriceCategory.Ref) + " (" + String(PriceCategory.Currency) +")", "PriceOnChange",, BackColor, TitleBackColor);
		EndIf;
	EndDo;	
	
	TablePrices.Load(ValueTable);
	
EndProcedure


&AtServer
Function FindInfluencingAndDependentPrices(TablePriceCategories, CurrentPriceCategory, Stack = Undefined)
	
	CatalogRow = TablePriceCategories.Find(CurrentPriceCategory, "Ref");
	Level = 0;
	
	For each BasePriceCategory In CatalogRow.InfluencingPriceCategories Do
		RowBasePriceCategory = TablePriceCategories.Find(BasePriceCategory.InfluencingPriceCategory, "Ref");
		BasePriceCategoryLevel = RowBasePriceCategory.Level;
		
		If Stack = Undefined Then
			Stack = New Array();
		EndIf;
		Stack.Add(CatalogRow);
		BasePriceCategoryLevel = FindInfluencingAndDependentPrices(TablePriceCategories, BasePriceCategory.InfluencingPriceCategory, Stack);
		
		If BasePriceCategoryLevel > Level Then
			Level = BasePriceCategoryLevel;
		EndIf;
		For each StackItem In Stack Do
			If StackItem.InfluencingPrices.FindByValue(RowBasePriceCategory.Ref) = Undefined Then
				StackItem.InfluencingPrices.Add(RowBasePriceCategory.Ref);
			EndIf;
			If RowBasePriceCategory.DependentPrices.FindByValue(StackItem.Ref) = Undefined Then
				RowBasePriceCategory.DependentPrices.Add(StackItem.Ref);
			EndIf;
		EndDo;
		Stack.Delete(Stack.Count() - 1);
	EndDo;
	
	Level = Level + 1;              	
	CatalogRow.Level = Level;
	
	Return Level; 
	
EndFunction



&AtServer
Procedure LoadPriceCategoriesCatalog()
	
	Query = New Query();
	Query.Text = "SELECT
				 |	PriceCategories.Ref,
				 |	PriceCategories.InfluencingPriceCategories.(
				 |		InfluencingPriceCategory
				 |	),
				 |	PriceCategories.PricingMode,
				 |	PriceCategories.Identifier,
				 |	PriceCategories.PriceGroups.(
				 |		PriceGroup,
				 |		PriceCalculationExpression
				 |	),
				 |	PriceCategories.PriceCurrency AS Currency,
				 |	PriceCategories.DataCompositionSchema,
				 |	PriceCategories.PriceCalculationExpression
				 |FROM
				 |	Catalog.PriceCategories AS PriceCategories";
	TablePriceCategories = Query.Execute().Unload();
	
	TablePriceCategories.Columns.Add("Level", New TypeDescription("Number"));
	TablePriceCategories.Columns.Add("InfluencingPrices", New TypeDescription("ValueList"));	
	TablePriceCategories.Columns.Add("DependentPrices", New TypeDescription("ValueList"));
	
	For each RowPriceCategory In TablePriceCategories Do
		FindInfluencingAndDependentPrices(TablePriceCategories, RowPriceCategory.Ref);
	EndDo;
	
	CatalogPriceCategoriesStorageAddress = PutToTempStorage(TablePriceCategories, UUID);
	
EndProcedure


&AtServer
Function FindPriceCategoryRow(Table, PriceCategory)	
	Return Table.FindRows(New Structure("Ref", PriceCategory))[0];
EndFunction


&AtClient
Function FindPriceCategoryRowAtClient(Table, PriceCategory)	
	Return Table.FindRows(New Structure("Ref", PriceCategory))[0];
EndFunction


&AtServer
Function TableContainsPriceCategory(Table, PriceCategory)	
	Return Table.FindRows(New Structure("Ref", PriceCategory)).Count() > 0;
EndFunction


&AtClient
Function TableContainsPriceCategoryAtClient(Table, PriceCategory)	
	Return Table.FindRows(New Structure("Ref", PriceCategory)).Count() > 0;
EndFunction



&AtClient
Procedure GoToPricing(Command)

	Items.GroupPages.CurrentPage = Items.GroupPages.ChildItems.GroupPricing;
	OnGroupPricingChanging();

EndProcedure


&AtClient
Procedure GoToPriceCategoryList(Command)
	Items.GroupPages.CurrentPage = Items.GroupPages.ChildItems.GroupPriceCategories;
EndProcedure



&AtServer
Procedure RecalculatePrices(NomenclatureTable, PriceCategories = Undefined, BlankOnly = False)
	TablePriceGroups = GetNomenclaturePriceGroups(NomenclatureTable);
	For each NomenclaturePosition In NomenclatureTable Do
		TablePricesRow = FindPricesTableRows(TablePrices, NomenclaturePosition)[0]; 
		PriceGroup = TablePriceGroups.Find(TablePricesRow.Nomenclature, "Ref").PriceGroup;
		RecalculatePricesInRow(TablePricesRow, PriceGroup, PriceCategories, , BlankOnly);	
	EndDo;
EndProcedure




&AtServer
Procedure CalculatePricesByRowIdentifier(RowId, FillPricesFromInfobase = False, ChangedField = Undefined)
	
	TablePricesRow = TablePrices.FindByID(RowId);
	
	NomenclatureTable = CreateEmptyNomenclatureTable();
	NewRow = NomenclatureTable.Add();
	NewRow.Nomenclature = TablePricesRow.Nomenclature;
	NewRow.Characteristic = TablePricesRow.Characteristic;
	NewRow.Package = TablePricesRow.Package;	
	
	If FillPricesFromInfobase Then
		LoadBasePriceValues(NomenclatureTable);		
		CalculatePricesByInfobaseData(NomenclatureTable);
	EndIf;
	
	TablePriceGroups = GetNomenclaturePriceGroups(NomenclatureTable);
	PriceGroup = TablePriceGroups.Find(TablePricesRow.Nomenclature, "Ref").PriceGroup;
	
	RecalculatePricesInRow(TablePrices.FindByID(RowId), PriceGroup, ,ChangedField);
	
EndProcedure




&AtServer
Procedure RecalculatePricesInRow(TablePricesRow, PriceGroup, PriceCategories = Undefined, ChangedField = Undefined, BlankOnly = False)	
	If PriceCategories = Undefined Then
		PriceCategories = New Array();
		For each PriceCategory In SelectedPriceCategories Do
			If PriceCategory.IsSelected Then
				PriceCategories.Add(PriceCategory.Ref);
			EndIf;
		EndDo;
	EndIf;	
	BeginRecalculation = ChangedField = Undefined;
	For each PriceCategory In PriceCategories Do
		If NOT BeginRecalculation Then
			If GetPriceColumnName(PriceCategory) = ChangedField Then
				BeginRecalculation = True;
			EndIf;
		Else
			If PriceCategory.PricingMode = Enums.PricingModes.FillByOtherPriceCategories Then
				If NOT BlankOnly Then
					TablePricesRow[GetPriceColumnName(PriceCategory)] = 0;
				EndIf;
				CalculatePricesInRow(TablePricesRow, PriceGroup, PriceCategory, BlankOnly);
			EndIf;
		EndIf;
	EndDo;
EndProcedure





&AtServer
Procedure CalculatePricesInRow(TablePricesRow, PriceGroup, PriceCategory, BlankOnly = False)	
	CurrentPrice = 0;
	TablePricesRow.Property(GetPriceColumnName(PriceCategory), CurrentPrice);
	CatalogPriceCategoriesRow = FindPriceCategoryRow(GetPriceCategoriesCatalog(), PriceCategory);
	If CurrentPrice = 0 OR NOT BlankOnly Then					
		PriceGroups = CatalogPriceCategoriesRow.PriceGroups.FindRows(New Structure("PriceGroup", PriceGroup));
		If PriceGroups.Count() > 0 Then
			PriceCalculationExpression = PriceGroups[0].PriceCalculationExpression;
		Else
			PriceCalculationExpression = CatalogPriceCategoriesRow.PriceCalculationExpression;
		EndIf;
		If ValueIsFilled(PriceCalculationExpression) Then
			For each BasePriceCategory In CatalogPriceCategoriesRow.InfluencingPriceCategories Do
				BasePriceCategoryRow = FindPriceCategoryRow(GetPriceCategoriesCatalog(), BasePriceCategory.InfluencingPriceCategory);
				ReplacementString = " TablePricesRow." + GetPriceColumnName(BasePriceCategoryRow.Ref) + " "
					+ GetCurrencyRecalculationRow(BasePriceCategoryRow.Currency, CatalogPriceCategoriesRow.Currency); 
				PriceCalculationExpression = StrReplace(PriceCalculationExpression, "[" + BasePriceCategoryRow.Identifier + "]", ReplacementString);
			EndDo;
			TablePricesRow[GetPriceColumnName(PriceCategory)] = Eval(PriceCalculationExpression);
		EndIf;
	EndIf;
EndProcedure


&AtServer
Function GetPriceCategoryLevel(PriceCategory)
	Return FindPriceCategoryRow(GetPriceCategoriesCatalog(), PriceCategory).Level;
EndFunction


&AtClient
Procedure GroupPagesOnCurrentPageChange(Item, CurrentPage)
	
	If CurrentPage = Items.GroupPricing AND SelectedPricesHaveBeenChanged Then
		OnGroupPricingChanging();		
		SelectedPricesHaveBeenChanged = False;
	EndIf;		
	
EndProcedure



&AtClient
Procedure OnGroupPricingChanging()
	RecalculatePrices = ?(TablePrices.Count() > 0, Вопрос(NStr("en = 'Price composition has been changed. Do you want to recalculate prices?'; ru = 'Состав цен изменился. Пересчитать цены?'"), QuestionDialogMode.YesNo) = DialogReturnCode.Yes, True);
	RebuildPriceTable(RecalculatePrices);
EndProcedure



&AtServer
Procedure RebuildPriceTable(RecalculatePrices)
	FillPricesInTabularSection();
	BuildPriceCategoriesTable();
	FillTabularSectionProducts();
	If RecalculatePrices Then		
		CalculateAllPrices();
	Else
		FillBasePrices();
	EndIf;
EndProcedure



&AtServer
Procedure FillPricesInTabularSection(SaveNullAndBasePrices = True)
	
	Object.Products.Clear();
	For each PriceRow In TablePrices Do
		For each PriceCategory In SelectedPriceCategories Do
			If PriceCategory.IsSelected OR SaveNullAndBasePrices AND PriceCategory.IsInfluencing Then
				Price = 0;
				If PriceRow.Property(GetPriceColumnName(PriceCategory.Ref), Price) 
					AND Price > 0 OR SaveNullAndBasePrices Then
					NewRow = Object.Products.Add();
					NewRow.Nomenclature   = PriceRow.Nomenclature;
					NewRow.Characteristic = PriceRow.Characteristic;
					NewRow.Package        = PriceRow.Package;
					NewRow.PriceCategory  = PriceCategory.Ref;
					NewRow.Price          = Price;
				EndIf;
			EndIf;
		EndDo;
	EndDo;
	
EndProcedure


&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	FillPricesInTabularSection(False);
EndProcedure


&AtServer
Function CreateEmptyNomenclatureTable()
	
	ValueTable = New ValueTable();
	
	ValueTable.Columns.Add("Nomenclature", New TypeDescription("CatalogRef.Nomenclature"));
	ValueTable.Columns.Add("Characteristic", New TypeDescription("CatalogRef.NomenclatureCharacteristics"));
	ValueTable.Columns.Add("Package", New TypeDescription("CatalogRef.NomenclaturePackages"));
	
	Return ValueTable;
	
EndFunction


&AtServer
Procedure AddDCSDataSetField(DataSet, FieldName, ValueType)
	DataSetField = DataSet.Fields.Add(Type("DataCompositionSchemaDataSetField"));
	DataSetField.Field = FieldName;
	DataSetField.DataPath = FieldName; 
	DataSetField.ValueType = New TypeDescription(ValueType); 
EndProcedure


&AtServer
Procedure AddDCSDataSetLink(DCS, NomenclatureDataSet, CurrentDataSet, Field)
	Link = DCS.DataSetLinks.Add();				
	Link.SourceDataSet = NomenclatureDataSet.Name;
	Link.DestinationDataSet = CurrentDataSet.Name;
	Link.SourceExpression = Field;
	Link.DestinationExpression = Field;
	Link.Required = True;
EndProcedure


&AtServer
Procedure AddDCSSelectedField(DataCompositionGroup, Field)
	SelectedField = DataCompositionGroup.Selection.Items.Add(Type("DataCompositionSelectedField"));
	SelectedField.Field = New DataCompositionField(Field);
	SelectedField.Use = True;
EndProcedure


&AtServer
Procedure CalculatePriceValuesByInfobaseData(NomenclatureTable, PriceCategory, BlankOnly = False)	
	
	If NomenclatureTable.Count() > 0 Then 
		
		CatalogRow = FindPriceCategoryRow(GetPriceCategoriesCatalog(), PriceCategory);
		If CatalogRow.PricingMode = Enums.PricingModes.FillByInfobaseData Then
			
			DCS = CatalogRow.DataCompositionSchema.Object(); 			
			If ModulePricing.CheckDataCompositionSchema(DCS, "Price category '" + PriceCategory.Ref + "'") Then
				CurrentDataSet = DCS.DataSets[0];				
				
				NomenclatureDataSet = DCS.DataSets.Add(Type("DataCompositionSchemaDataSetObject"));
				NomenclatureDataSet.Name = "NomenclatureTable";
				NomenclatureDataSet.ObjectName = "NomenclatureTable";
				NomenclatureDataSet.DataSource = CurrentDataSet.DataSource;
				
				AddDCSDataSetField(NomenclatureDataSet, "Nomenclature", "CatalogRef.Nomenclature");
				AddDCSDataSetField(NomenclatureDataSet, "Characteristic", "CatalogRef.NomenclatureCharacteristics");
				AddDCSDataSetField(NomenclatureDataSet, "Package", "CatalogRef.NomenclaturePackages");
				
				DCS.DataSetLinks.Clear();
				AddDCSDataSetLink(DCS, NomenclatureDataSet, CurrentDataSet, "Nomenclature");
				AddDCSDataSetLink(DCS, NomenclatureDataSet, CurrentDataSet, "Characteristic");
				AddDCSDataSetLink(DCS, NomenclatureDataSet, CurrentDataSet, "Package");
				
				DCS.DefaultSettings.Structure.Clear();
				Group = DCS.DefaultSettings.Structure.Add(Type("DataCompositionGroup"));
				Group.Use = True;                     					
				DCS.DefaultSettings.Filter.Items.Clear();
				AddDCSSelectedField(Group, "Nomenclature");
				AddDCSSelectedField(Group, "Characteristic");
				AddDCSSelectedField(Group, "Package");
				AddDCSSelectedField(Group, "Package");
				AddDCSSelectedField(Group, "Currency");
			
				TemplateComposer = New DataCompositionTemplateComposer;
				CompositionTemplate = TemplateComposer.Execute(DCS, DCS.DefaultSettings, , , Type("DataCompositionValueCollectionTemplateGenerator"));
				
				ExternalDataSets = New Structure;
				ExternalDataSets.Insert("NomenclatureTable", NomenclatureTable);
				
				CompositionProcessor = New DataCompositionProcessor;
				CompositionProcessor.Initialize(CompositionTemplate, ExternalDataSets);
				OutputProcessor = New DataCompositionResultValueCollectionOutputProcessor;			

				ReportData = New ValueTable();
				OutputProcessor.SetObject(ReportData);
				ReportData = OutputProcessor.Output(CompositionProcessor);

				LoadPricesFromValueTable(ReportData, PriceCategory, CatalogRow.Currency, BlankOnly);
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure	


&AtServer
Procedure ClearPrices(NomenclatureTable, PriceCategories)
	For each Row In NomenclatureTable Do
		PriceCategoryRow = FindPricesTableRows(TablePrices, Row)[0];
		For each PriceCategory In PriceCategories Do
			PriceCategoryRow[GetPriceColumnName(PriceCategory)] = 0;
		EndDo;
	EndDo;
EndProcedure



&AtServer
Procedure CalculatePricesByInfobaseData(NomenclatureTable, PriceCategories = Undefined, BlankOnly = False)		
	
	If PriceCategories = Undefined Then
		PriceCategories = New Array();
		For each Price In SelectedPriceCategories Do
			If Price.IsSelected AND Price.PricingMode = Enums.PricingModes.FillByInfobaseData Then
				PriceCategories.Add(Price.Ref);
			EndIf;		
		EndDo;	
	EndIf;
	
	If NOT BlankOnly Then
		ClearPrices(NomenclatureTable, PriceCategories);
	EndIf;
	
	For each Price In PriceCategories Do
		CalculatePriceValuesByInfobaseData(NomenclatureTable, Price, BlankOnly);
	EndDo;
	
EndProcedure


&AtServer
Procedure LoadPricesFromValueTable(SourcePriceTable, PriceCategory = Undefined, PriceCurrency = Undefined, BlankOnly = False)
	
	For each Row In SourcePriceTable Do
		LoadPrice(TablePrices, Row, PriceCategory, PriceCurrency, BlankOnly);
	EndDo;	
	
EndProcedure


&AtServer
Procedure ClearInfluencingPriceValues(NomenclatureTable)
	
	If ValueIsFilled(InfluencingPriceCategoriesArrayStorageAddress) Then
		PriceCategories = GetFromTempStorage(InfluencingPriceCategoriesArrayStorageAddress);
		ClearPrices(NomenclatureTable, PriceCategories);
	EndIf;
	
EndProcedure



&AtServer
Procedure LoadBasePriceValues(NomenclatureTable, PriceCategories = Undefined, Date = Undefined, PricePercent = 0)
	
	If PriceCategories = Undefined Then
		PriceCategories = New Array();
		For each PriceCategory In PriceCategories Do
			If PriceCategory.IsInfluencing Then
				PriceCategories.Add(PriceCategory.Ref);
			EndIf;
		EndDo;		
		InfluencingPriceCategoriesArrayStorageAddress = PutToTempStorage(PriceCategories, UUID);
	EndIf;	
	
	ClearPrices(NomenclatureTable, PriceCategories);
	
	If PriceCategories.Count() > 0 Then
		
		TempTablesManager = New TempTablesManager;
		Query = New Query;
		Query.TempTablesManager = TempTablesManager;

		Query.Text="SELECT
		           |	TableNomenclature.Nomenclature,
		           |	TableNomenclature.Characteristic,
		           |	TableNomenclature.Package
		           |INTO TableNomenclature
		           |FROM
		           |	&TableNomenclature AS TableNomenclature";
		Query.SetParameter("TableNomenclature", NomenclatureTable);				   
		Query.Execute();
					   
		Query = New Query();	
		Query.TempTablesManager = TempTablesManager;
		Query.Text = "SELECT
		             |	NomenclaturePricesSliceLast.Nomenclature,
		             |	NomenclaturePricesSliceLast.Characteristic,
		             |	NomenclaturePricesSliceLast.Package,
		             |	NomenclaturePricesSliceLast.PriceCategory,
		             |	NomenclaturePricesSliceLast.Price + NomenclaturePricesSliceLast.Price * &PricePercent / 100 AS Price
		             |FROM
		             |	InformationRegister.NomenclaturePrices.SliceLast(
		             |			&Period,
		             |			(Nomenclature, Characteristic, Package) IN
		             |					(SELECT
		             |						TableNomenclature.Nomenclature,
		             |						TableNomenclature.Characteristic,
		             |						TableNomenclature.Package
		             |					FROM
		             |						TableNomenclature AS TableNomenclature)
		             |				AND PriceCategory IN (&PriceCategories)) AS NomenclaturePricesSliceLast";
		
		Query.SetParameter("PriceCategories", PriceCategories);	
		Query.SetParameter("PricePercent", PricePercent);	
		If Date = Undefined Then
			Date = CurrentDate();
		EndIf;
		Query.SetParameter("Period", Date);	
		Result = Query.Execute().Unload();	
		LoadPricesFromValueTable(Result);
		TempTablesManager.Close();
		
	EndIf;
	
EndProcedure



&AtServer
Procedure FillBasePrices()
	TableNomenclature = TablePrices.Unload(,"Nomenclature,Characteristic,Package"); 
	LoadBasePriceValues(TableNomenclature);	
EndProcedure



&AtServer
Procedure CalculateAllPrices()
	NomenclatureTable = TablePrices.Unload(,"Nomenclature,Characteristic,Package"); 
	ClearInfluencingPriceValues(NomenclatureTable);
	LoadBasePriceValues(NomenclatureTable);	
	CalculatePricesByInfobaseData(NomenclatureTable);
	RecalculatePrices(NomenclatureTable);
EndProcedure


&AtServer
Procedure CalculatePrices(Parameters)
	If NOT Parameters.SelectedOnly Then
		NomenclatureTable = TablePrices.Unload(,"Nomenclature,Characteristic,Package"); 
	Else
		NomenclatureTable = CreateEmptyNomenclatureTable();
		For each SelectedRow In Items.TablePrices.SelectedRows Do
			PriceRow = TablePrices.FindByID(SelectedRow);
			NomenclatureRow = NomenclatureTable.Add();
			NomenclatureRow.Nomenclature = PriceRow.Nomenclature;
			NomenclatureRow.Characteristic = PriceRow.Characteristic;
			NomenclatureRow.Package = PriceRow.Package;
		EndDo;
	EndIf;
	If Parameters.LoadOldPrices Then
		LoadBasePriceValues(NomenclatureTable, Parameters.PriceCategories, Parameters.OldPriceDate, Parameters.PricePercent);	
	EndIf;
	If NOT Parameters.LoadOldPrices OR CalculateAutomatically Then
		LoadBasePriceValues(NomenclatureTable);	
		CalculatePricesByInfobaseData(NomenclatureTable, ?(NOT Parameters.LoadOldPrices, Parameters.PriceCategories, Undefined), Parameters.BlankOnly);
		RecalculatePrices(NomenclatureTable, ?(NOT Parameters.LoadOldPrices, Parameters.PriceCategories, Undefined), Parameters.BlankOnly);
	EndIf;
EndProcedure


&AtClient
Procedure PriceOnChange(Item)
	If CalculateAutomatically Then
		CalculatePricesByRowIdentifier(Items.TablePrices.CurrentData.GetID(),, StrReplace(Item.Name, "TablePrices", ""));
	EndIf;
EndProcedure


&AtClient
Procedure TablePricesNomenclatureOnChange(Item)
	
	CurrentRow = Items.TablePrices.CurrentData;

	StructureActions = New Structure;
	StructureActions.Insert("CheckCharacteristicByOwner", CurrentRow.Characteristic);
	StructureActions.Insert("CheckPackageByOwner"       , CurrentRow.Package);

	ModuleTabularSectionProductsClient.AttributesOnChangeAtClient(TablePrices, CurrentRow, StructureActions, CachedValues);
	
	If CalculateAutomatically Then
		CalculatePricesByRowIdentifier(Items.TablePrices.CurrentData.GetID(), True);
	EndIf;

EndProcedure


&AtClient
Procedure TablePricesCharacteristicOnChange(Item)
	
	CurrentRow = Items.TablePrices.CurrentData;

	StructureActions = New Structure;

	ModuleTabularSectionProductsClient.AttributesOnChangeAtClient(TablePrices, CurrentRow, StructureActions, CachedValues);
	
	If CalculateAutomatically Then
		CalculatePricesByRowIdentifier(Items.TablePrices.CurrentData.GetID(), True);
	EndIf;

EndProcedure


&AtClient
Procedure TablePricesPackageOnChange(Item)
	
	CurrentRow = Items.TablePrices.CurrentData;

	StructureActions = New Structure;

	ModuleTabularSectionProductsClient.AttributesOnChangeAtClient(TablePrices, CurrentRow, StructureActions, CachedValues);
	
	If CalculateAutomatically Then
		CalculatePricesByRowIdentifier(Items.TablePrices.CurrentData.GetID(), True);
	EndIf;

EndProcedure


&AtClient
Procedure CalculateAutomaticallyFlag(Command)
	SetCalculateAutomatically(NOT CalculateAutomatically);
EndProcedure


&AtClient
Procedure SelectedPriceCategoriesIsSelectedOnChange(Item)
	SetIsDependentIsInfluencingFlagsAtClient();
	SelectedPricesHaveBeenChanged = True;
EndProcedure


&AtClient
Procedure Recalculate(Command)
	RunPriceCalculation();
EndProcedure


&AtClient
Procedure LoadOldPrices(Command)
	RunPriceCalculation(True);
EndProcedure


&AtClient
Procedure RunPriceCalculation(LoadOldPrices = False)
	ResultParameters = OpenFormModal("Document.NomenclaturePricing.Form.CalculationSettingsForm", GetCalculationParameters(LoadOldPrices), ThisForm);
	If ResultParameters <> Undefined Then
		CalculatePrices(ResultParameters);
		Modified = True;
	EndIf;
EndProcedure


&AtClient
Function GetCalculationParameters(LoadOldPrices = False)
	PriceCategories = New Array();
	For each PriceCategory In SelectedPriceCategories Do
		If PriceCategory.IsSelected AND ((PriceCategory.PricingMode = FillPriceManually) = LoadOldPrices) Then
			PriceCategories.Add(PriceCategory.Ref);
		EndIf;
	EndDo;
	Return New Structure("LoadOldPrices,PriceCategories", LoadOldPrices, PriceCategories);
EndFunction


&AtServer
Function GetNomenclaturePriceGroups(NomenclatureTable)
	
	ArrayNomenclature = New Array();	
	For each Item In NomenclatureTable Do
		If ArrayNomenclature.Find(Item.Nomenclature) = Undefined Then
			ArrayNomenclature.Add(Item.Nomenclature);
		EndIf;
	EndDo;
	
	Query = New Query();
	Query.Text = "SELECT
	             |	Nomenclature.Ref,
	             |	Nomenclature.PriceGroup
	             |FROM
	             |	Catalog.Nomenclature AS Nomenclature
	             |WHERE
	             |	Nomenclature.Ref IN (&ArrayNomenclature)";
	Query.SetParameter("ArrayNomenclature", ArrayNomenclature);
	Return Query.Execute().Unload();
	
EndFunction


&AtClient
Procedure AddPriceGroup(Command)
	OpenFormModal("Catalog.PriceGroups.ChoiceForm", , ThisForm);	
	Modified = True;
EndProcedure



&AtServer
Procedure AddPriceGroupNomenclatureItems(PriceGroup)
	Query = New Query();
	Query.Text = "SELECT
	             |	Nomenclature.Ref AS Nomenclature,
	             |	ISNULL(NomenclatureCharacteristics.Ref, VALUE(Catalog.NomenclatureCharacteristics.EmptyRef)) AS Characteristic
	             |FROM
	             |	Catalog.Nomenclature AS Nomenclature
	             |		FULL JOIN Catalog.NomenclatureCharacteristics AS NomenclatureCharacteristics
	             |		ON (NomenclatureCharacteristics.Owner = Nomenclature.Ref
	             |				OR NomenclatureCharacteristics.Owner = Nomenclature.Category)
	             |WHERE
	             |	Nomenclature.PriceGroup = &PriceGroup";
	Query.SetParameter("PriceGroup", PriceGroup);
	NomenclatureTable = Query.Execute().Unload();
	Index = 0;
	While Index < NomenclatureTable.Count() Do
		If TablePrices.FindRows(New Structure("Nomenclature,Characteristic", NomenclatureTable[Index].Nomenclature, NomenclatureTable[Index].Characteristic)).Count() = 0 Then
			NewRow = TablePrices.Add();
			NewRow.Nomenclature = NomenclatureTable[Index].Nomenclature;
			NewRow.Characteristic = NomenclatureTable[Index].Characteristic;
			Index = Index + 1;
		Else
			NomenclatureTable.Delete(Index);			
		EndIf;
	EndDo;
	If CalculateAutomatically Then
		NomenclatureTable.Columns.Add("Package", New TypeDescription("CatalogRef.NomenclaturePackages"));
		NomenclatureTable.FillValues(Catalogs.NomenclaturePackages.EmptyRef(), "Package");
		LoadBasePriceValues(NomenclatureTable);		
		CalculatePricesByInfobaseData(NomenclatureTable);
		RecalculatePrices(NomenclatureTable);
	EndIf;
EndProcedure



&AtClient
Procedure ChoiceProcessing(SelectedValue, ChoiceSource)
	AddPriceGroupNomenclatureItems(SelectedValue);
EndProcedure

