&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	ModuleVersionControl.OnCreateAtServer(ThisForm);
	
	If Object.PricingMode = Enums.PricingModes.EmptyRef() Then
		Object.PricingMode = Enums.PricingModes.Manual;
	EndIf;		
	
	If Object.PricingMode = Enums.PricingModes.FillByInfobaseData Then
		DataCompositionSchema = Object.Ref.DataCompositionSchema;
	ElsIf Object.PricingMode = Enums.PricingModes.FillByOtherPriceCategories Then
		InitializePageCalculationRules(True);	
	EndIf;
	
EndProcedure


&AtClient
Procedure OnOpen(Cancel)

	ConfigurePageVisibility();
	
	InitializeIdentifierValue();	
	
EndProcedure


&AtServer
Procedure InitializePageCalculationRules(InitializeMainExpression)
	
	If NOT CalculationRulePageHasBeenInitialized Then
		
		EnablePriceGroups = GetFunctionalOption("EnablePriceGroups");
		
		Items.Expressions.Visible = EnablePriceGroups;
		Items.GroupExpression.Visible = NOT EnablePriceGroups;
		
		If EnablePriceGroups Then
			
			CurrentPriceGroup = -1;
			Expression = Expressions.Add();
			Expression.PriceGroup = "<All price groups>";
			If InitializeMainExpression Then
				Expression.PriceCalculationExpression = Object.PriceCalculationExpression;
			EndIf;
			
			For each RowPriceGroup In Object.PriceGroups Do
				Expression = Expressions.Add();
				Expression.PriceGroup = RowPriceGroup.PriceGroup; 	
				Expression.PriceCalculationExpression = RowPriceGroup.PriceCalculationExpression; 	
			EndDo;						
			
		EndIf;
		
		FillBasePriceTable();
		BuildOperatorTree();
		
		CalculationRulePageHasBeenInitialized = True;	
		
	EndIf;
	
EndProcedure	


&AtClient
Procedure PricingModeOnChange(Item)

	ConfigurePageVisibility();
	
	If Items.GroupPages.ChildItems.PageCalculationRules.Visible Then
		InitializePageCalculationRules(False);
	EndIf;

	
EndProcedure


&AtClient
Procedure ConfigurePageVisibility()
	
	Items.GroupPages.ChildItems.PageDataCompositionSchema.Visible = Object.PricingMode = PredefinedValue("Enum.PricingModes.FillByInfobaseData");
	Items.GroupPages.ChildItems.PageCalculationRules.Visible = Object.PricingMode = PredefinedValue("Enum.PricingModes.FillByOtherPriceCategories");
	
	For each Page In Items.GroupPages.ChildItems Do
		If Page.Visible Then
			Items.GroupPages.CurrentPage = Page;
			Break;
		EndIf;
	EndDo;
	
EndProcedure


&AtClient
Procedure DescriptionOnChange(Item)
	InitializeIdentifierValue();
EndProcedure



&AtClient
Procedure InitializeIdentifierValue()
	Items.Identifier.ChoiceList[0].Value = GetIdentifier(Object.Description);
EndProcedure



&AtClient
Function GetIdentifier(StringDescription)
	
	Separators	=  " .,+,-,/,*,?,=,<,>,(,)%!@#$%&*""№:;{}[]?()\|/`~'^_";
	
	Identifier = "";
	SpecialCharacterFound = False;
	For CharacterNumber = 1 To StrLen(StringDescription) Do
		Char = Mid(StringDescription, CharacterNumber, 1);
		If Find(Separators, Char) <> 0 Then
			SpecialCharacterFound = True;
		ElsIf SpecialCharacterFound Then
			SpecialCharacterFound = False;
			Identifier = Identifier + Upper(Char);
		Else
			Identifier = Identifier + Char;		
		EndIf;
	EndDo;
	
	Return Identifier;
		
EndFunction



&AtServer
Procedure FillBasePriceTable()
	
	Query = New Query();
	Query.Text = "SELECT
	             |	PriceCategories.Ref AS Reference,
	             |	PriceCategories.Identifier,
	             |	PriceCategories.InfluencingPriceCategories.(
	             |		InfluencingPriceCategory
	             |	)
	             |FROM
	             |	Catalog.PriceCategories AS PriceCategories
	             |WHERE
	             |	PriceCategories.Ref <> &CurrentPrice";
	Query.SetParameter("CurrentPrice", Object.Ref); 
	TablePriceCategories = Query.Execute().Unload();
	
	CurrentArray = New Array();
	CurrentArray.Add(Object.Ref);
	
	While CurrentArray.Count() > 0 Do
		ArrayDeleted = New Array();
		For each Row In TablePriceCategories Do
			For each PriceCategory In CurrentArray Do
				If Row.InfluencingPriceCategories.Find(PriceCategory, "InfluencingPriceCategory") <> Undefined Then
					ArrayDeleted.Add(Row);
					Break;
				EndIf;
			EndDo;
		EndDo;
		CurrentArray.Clear();
		For each DeletedRow In ArrayDeleted Do
			CurrentArray.Add(DeletedRow.Ref);
			TablePriceCategories.Delete(DeletedRow);
		EndDo;
	EndDo;
	
	TablePriceCategories.Columns.Delete(TablePriceCategories.Columns.InfluencingPriceCategories);
	ValueToFormAttribute(TablePriceCategories, "AvailableBasePriceCategories");
	
EndProcedure
					   



&AtServer
Procedure BuildOperatorTree()
	
	Tree = ModuleExpressions.GetEmptyOperatorTree();
	
	OperatorGroup = ModuleExpressions.AddOperatorGroup(Tree, "Operators");
	ModuleExpressions.AddOperator(Tree, OperatorGroup, "+", " + ");
	ModuleExpressions.AddOperator(Tree, OperatorGroup, "-", " - ");
	ModuleExpressions.AddOperator(Tree, OperatorGroup, "*", " * ");
	ModuleExpressions.AddOperator(Tree, OperatorGroup, "/", " / ");
	OperatorGroup = ModuleExpressions.AddOperatorGroup(Tree, "Logical operators and constants");
	ModuleExpressions.AddOperator(Tree, OperatorGroup, "<", " < ");
	ModuleExpressions.AddOperator(Tree, OperatorGroup, ">", " > ");
	ModuleExpressions.AddOperator(Tree, OperatorGroup, "<=", " <= ");
	ModuleExpressions.AddOperator(Tree, OperatorGroup, ">=", " >= ");
	ModuleExpressions.AddOperator(Tree, OperatorGroup, "=", " = ");
	ModuleExpressions.AddOperator(Tree, OperatorGroup, "<>", " <> ");
	ModuleExpressions.AddOperator(Tree, OperatorGroup, "AND", " AND ");
	ModuleExpressions.AddOperator(Tree, OperatorGroup, "OR", " OR ");
	ModuleExpressions.AddOperator(Tree, OperatorGroup, "NOT", " NOT ");
	ModuleExpressions.AddOperator(Tree, OperatorGroup, "TRUE", " TRUE ");
	ModuleExpressions.AddOperator(Tree, OperatorGroup, "FALSE", " FALSE ");
	OperatorGroup = ModuleExpressions.AddOperatorGroup(Tree, "Functions");
	ModuleExpressions.AddOperator(Tree, OperatorGroup, "Maximum", "Max(,)", 2);
	ModuleExpressions.AddOperator(Tree, OperatorGroup, "Minimum", "Min(,)", 2);
	ModuleExpressions.AddOperator(Tree, OperatorGroup, "Rounding", "Round(,)", 2);
	ModuleExpressions.AddOperator(Tree, OperatorGroup, "Integer part", "Int(,)", 2);
	ModuleExpressions.AddOperator(Tree, OperatorGroup, "Condition", "?(,,)", 3);
	
	OperatorTreeStorageAddress = PutToTempStorage(Tree, UUID);
	
EndProcedure



&AtServer
Procedure RetrieveBasePricesFromExpression(CurrentObject, Expression)
	
	ArrayItems = ModuleStringFunctionsClientServer.Split(Expression, "[");
	
	For Index = 1 To ArrayItems.Count() - 1 Do
		If ValueIsFilled(ArrayItems[Index]) Then
			IdentifierEnd = Find(ArrayItems[Index], "]");
			If IdentifierEnd > 0 Then
				BasePriceIdentifier = Left(ArrayItems[Index], IdentifierEnd - 1);
				BasePrices = AvailableBasePriceCategories.FindRows(New Structure("Identifier", BasePriceIdentifier));
				If BasePrices.Count() > 0 Then
					If CurrentObject.InfluencingPriceCategories.FindRows(New Structure("InfluencingPriceCategory", BasePrices[0])).Count() = 0 Then
						CurrentObject.InfluencingPriceCategories.Add().InfluencingPriceCategory = BasePrices[0].Reference;
					EndIf;
				EndIf;
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure


&AtClient
Procedure ExpressionsBeforeDeleteRow(Item, Cancel)

	If Item.CurrentRow = 0 Then
		Cancel = True;
	Else
		CurrentPriceGroup = -1;
	EndIf;		

EndProcedure


&AtClient
Procedure ExpressionsPriceCalculationExpressionStartChoice(Item, ChoiceData, StandardProcessing)

	StandardProcessing = False;
	EditingResult = OpenFormModal("CommonForm.ExpressionBuilder", 
		GetPriceEditingFormParameters(Items.Expressions.CurrentData.PriceCalculationExpression), Item);
		
	If EditingResult <> Undefined Then
		Items.Expressions.CurrentData.PriceCalculationExpression = EditingResult;
	EndIf;

EndProcedure


&AtClient
Function GetBasePriceCategoryArray() 
	BasePriceCategoryArray = New Array();
	For each PriceCategory In AvailableBasePriceCategories Do
		BasePriceCategoryArray.Add(PriceCategory.Identifier);
	EndDo;
	Return BasePriceCategoryArray;
EndFunction


&AtClient
Function GetPriceEditingFormParameters(Expression) 	
	Return New Structure("Expression,Parameters,ParametersTitle,Operators", Expression, GetBasePriceCategoryArray(), "Available price categories", OperatorTreeStorageAddress);
EndFunction



&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	CurrentObject.PriceGroups.Clear();
	CurrentObject.InfluencingPriceCategories.Clear();
	
	If CurrentObject.PricingMode = Enums.PricingModes.FillByInfobaseData Then
		If ValueIsFilled(DataCompositionSchema) Then
			If ModulePricing.CheckDataCompositionSchema(DataCompositionSchema.Get()) Then
				#If ThickClientOrdinaryApplication Or ThickClientManagedApplication Then
				CurrentObject.DataCompositionSchema = DataCompositionSchema;
				#EndIf
			Else
				Cancel = True;
			EndIf;	
		Else			
			Cancel = True;
			Message = New UserMessage();
			Message.Text = NStr("en = 'Data composition schema should be configured to support price filling.'; ru = 'Необходимо настроить схему компоновки данных для заполнения цен.'");
			Message.SetData(Object);
			Message.Message();
		EndIf;
	ElsIf CurrentObject.PricingMode = Enums.PricingModes.FillByOtherPriceCategories Then
		If EnablePriceGroups Then
			CurrentObject.PriceCalculationExpression = Expressions[0].PriceCalculationExpression;					
			For Index = 1 To Expressions.Count() - 1 Do
				NewRow = CurrentObject.PriceGroups.Add();
				NewRow.PriceGroups = Expressions[Index].PriceGroup; 	
				NewRow.PriceCalculationExpression = Expressions[Index].PriceCalculationExpression; 	
				
				RetrieveBasePricesFromExpression(CurrentObject, Expressions[Index].PriceCalculationExpression);
			EndDo;		
		EndIf;
		RetrieveBasePricesFromExpression(CurrentObject, CurrentObject.PriceCalculationExpression);
	EndIf;

EndProcedure


&AtClient
Procedure ExpressionsOnStartEdit(Item, NewRow, Clone)
	
	If Item.CurrentData.PriceGroup = Undefined Then
		Item.CurrentData.PriceGroup = PredefinedValue("Catalog.PriceCategories.EmptyRef")
	EndIf;

EndProcedure

&AtClient
Procedure ExpressionsOnActivateRow(Item)
	Item.ChildItems.ExpressionsPriceGroup.ReadOnly = Item.CurrentRow = 0;
EndProcedure


&AtClient
Procedure ExpressionsBeforeEditEnd(Item, NewRow, CancelEdit, Cancel)
	If NOT CancelEdit AND (NOT ValueIsFilled(Item.CurrentData.PriceGroup) OR Expressions.FindRows(New Structure("PriceGroup", Item.CurrentData.PriceGroup)).Count() > 1) Then
		Cancel = True;
		Message = New UserMessage();
		Message.Text = ?(ValueIsFilled(Item.CurrentData.PriceGroup),
			NStr("en = 'Price group ''%PriceGroup%'' already contains expression. Choose another group.'; ru = 'Для ценовой группы ''%PriceGroup%'' формула уже задана.'"),
			NStr("en = 'You should choose price group.'; ru = 'Необходимо выбрать ценовую группу.'"));
		Message.Text = StrReplace(Message.Text, "%PriceGroup%", Item.CurrentData.PriceGroup); 
		Message.Field = "Expressions.PriceGroup";
		Message.SetData(Object);
		Message.Message();
	EndIf;
EndProcedure


&AtClient
Procedure DataCompositionSchemaBuilder(Command)
	
	#If ThickClientOrdinaryApplication Or ThickClientManagedApplication Then
		DCS = ?(ValueIsFilled(DataCompositionSchema), DataCompositionSchema.Get(), Undefined);
		If DCS = Undefined Then
			DCS = GenerateNewDataCompositionSchema();
		EndIf;

		DCSW = New DataCompositionSchemaWizard(DCS);
		DCSW.Edit(ThisForm);
	#Else
		DoMessageBox(NStr("en = 'To configure data composition schema you should run the application in thick client mode.'; ru = 'Для того, чтобы настроить схему компоновки данных для расчета цены по данным базы, необходимо запустить конфигурацию в режиме толстого клиента.'"));
	#EndIf

EndProcedure
		

&AtServer
Function GenerateNewDataCompositionSchema()
	
	DCS = New DataCompositionSchema;
	Source = DCS.DataSources.Add();
	Source.Name = "NomenclaturePricesDataSource";
	Source.DataSourceType = "Local";
	DataSet = DCS.DataSets.Add(Type("DataCompositionSchemaDataSetQuery"));
	DataSet.Name = "NomenclaturePrices";
	DataSet.Query = "	
				   	|SELECT
				   	|	VALUE(Catalog.Nomenclature.EmptyRef) AS Nomenclature,";
	If GetFunctionalOption("EnableNomenclatureCharacteristics") Then
		DataSet.Query = DataSet.Query + "
					|	VALUE(Catalog.NomenclatureCharacteristics.EmptyRef) AS Characteristic,";
	EndIf;
	If GetFunctionalOption("EnableNomenclaturePackages") Then
		DataSet.Query = DataSet.Query + "
					|	VALUE(Catalog.NomenclaturePackages.EmptyRef) AS Package,";
	EndIf;				
	DataSet.Query = DataSet.Query + "				
				   	|	0 AS Price,
				   	|	VALUE(Catalog.Currencies.EmptyRef) AS Currency
				   	|{SELECT
				   	|	Nomenclature.*,";
	If GetFunctionalOption("EnableNomenclatureCharacteristics") Then
		DataSet.Query = DataSet.Query + "
				   	|	Characteristic.*,";
	EndIf;
	If GetFunctionalOption("EnableNomenclaturePackages") Then					
		DataSet.Query = DataSet.Query + "		
				   	|	Package.*,";
	EndIf;					
	DataSet.Query = DataSet.Query + "						
				   	|	Price,
				   	|	Currency.*}";
	DataSet.DataSource = "NomenclaturePricesDataSource";
	DataSet.AutoFillAvailableFields = False;
	
	RequiredFields = ModulePricing.GetRequiredDataCompositionSchemaFields();
	For each RequiredField In RequiredFields Do	
		NewField = DataSet.Fields.Add(Type("DataCompositionSchemaDataSetField"));
		NewField.Field = RequiredField.Key;
		NewField.DataPath = RequiredField.Key;
		NewField.ValueType = RequiredField.Value;		
	EndDo;   	
	
	Return DCS;

EndFunction


&AtClient
Procedure ChoiceProcessing(SelectedValue, ChoiceSource)
	
	#If ThickClientOrdinaryApplication Or ThickClientManagedApplication Then
	If Type(SelectedValue) = Type("DataCompositionSchema") Then
		DataCompositionSchema = New ValueStorage(SelectedValue);
	EndIf;
	#EndIf

EndProcedure


&AtClient
Procedure ExpressionBuilder(Command)

	EditingResult = OpenFormModal("CommonForm.ExpressionBuilder", 
		GetPriceEditingFormParameters(Object.PriceCalculationExpression), Items.PriceCalculationExpression);
		
	If EditingResult <> Undefined Then
		Object.PriceCalculationExpression = EditingResult;
	EndIf;

EndProcedure


&AtClient
Procedure CheckExpression(Command)
	
	Expression = ?(EnablePriceGroups, 
		?(Items.Expressions.CurrentData <> Undefined, Items.Expressions.CurrentData.PriceCalculationExpression, ""), 
		Object.PriceCalculationExpression);	
		
	ModuleExpressionsClient.CheckExpressionInteractively(Expression, GetBasePriceCategoryArray(), ?(EnablePriceGroups, "Expressions.PriceCalculationExpression", "Object.PriceCalculationExpression"));

EndProcedure


&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	If Items.GroupPages.ChildItems.PageCalculationRules.Visible Then
		If EnablePriceGroups Then
			For each Expression In Expressions Do
				ErrorMessage = NStr("en = 'Error in expression: ''%PriceGroup%'''; ru = 'Ошибка в формуле для ценовой группы ''%PriceGroup%'''");
				ErrorMessage = StrReplace(ErrorMessage, "%PriceGroup%", Expression.PriceGroup);
				If NOT ModuleExpressionsClient.CheckExpression(Expression.PriceCalculationExpression, GetBasePriceCategoryArray(), "", ErrorMessage) Then
					Cancel = True;
				EndIf;
			EndDo;	
		Else
			Cancel = NOT ModuleExpressionsClient.CheckExpression(Object.PriceCalculationExpression, GetBasePriceCategoryArray(), "Object.PriceCalculationExpression");
		EndIf;
	EndIf;

EndProcedure

&AtClient
Procedure ExpressionsBeforeAddRow(Item, Cancel, Clone, Parent, Folder)
	If Clone AND Item.CurrentRow = 0 Then
		Cancel = True;
	EndIf;
EndProcedure

