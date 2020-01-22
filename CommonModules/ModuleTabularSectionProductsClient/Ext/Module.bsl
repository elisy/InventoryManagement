// PROCEDURE "OnChange" AT CLIENT.
// THIS PROCEDURE IS CALLED FROM DOCUMENT FORMS.
//
// StructureActions - Structure. The following fields are available:
//  "CheckCharacteristicByOwner", Characteristic.
//  "CheckPackageByOwner"       , Package.
//  "RecalculateUnitQuantity".
//  "RecalculateUnitPlanQuantity".
//  "FillSalesPrice"              , ActionStructureParameters.
//  "RecalculateAmount".
//  "RecalculatePricePerPackage"  , UnitQuantityBeforeRecalculation.
//  "RecalculateVATAmount".
//  "FillVATRate".
//  "RecalculateUnitQuantityByApplicationSettings".
//  "FillPrice".
//  "ProcessBarcodes".
//  "CheckSerialNumbersByOwner", ActionStructureParameters.
//  "FillNomenclatureByPartnerNomenclature".
//  "FillSalesConditions"
//  "FillPurchaseConditions"

Procedure AttributesOnChangeAtClient(TabularSection, CurrentRow, StructureActions, CachedValues) Export

	Var StructureValue;

	If CachedValues = Undefined Then
		CachedValues = New Structure;
		CachedValues.Insert("PackageConversionFactors", New Map);
		CachedValues.Insert("VATRates"                , New Map);
		CachedValues.Insert("Barcodes"                , New Map);
	EndIf;

	TabularSectionProcessingParameters = GetTabularSectionProcessingParameters(TabularSection,
	   CurrentRow,
	   StructureActions,
	   CachedValues);

	If TabularSectionProcessingParameters.ServerCallIsRequired Then
		TabularSectionStructure = New Structure;
		TabularSectionStructure.Insert("TabularSectionFieldStructure", GetTabularSectionFieldStructure(TabularSectionProcessingParameters.StructureActions));

		If TabularSectionProcessingParameters.EntireTabularSectionProcessingIsRequired Then
			TabularSectionRows = New Array;
			For each TabularSectionRow In TabularSection Do
				CurrentRow = GetCurrentRowData(TabularSectionRow, TabularSectionStructure.TabularSectionFieldStructure);
				CurrentRow.Insert("_RowId_", TabularSectionRow.GetID());

				TabularSectionRow.Add(CurrentRow);
			EndDo;

			TabularSectionStructure.Insert("TabularSectionRows" , TabularSectionRows);

			ModuleTabularSectionProductsServer.AttributesOnChangeAtServer(TabularSectionStructure, StructureActions, CachedValues);

			For each CurrentRow In TabularSectionStructure.TabularSectionRows Do
				If CurrentRow.Property("_RowId_", StructureValue) Then
					CurrentRowTS = TabularSection.FindByID(StructureValue);
				Else
					CurrentRowTS = TabularSection.Add();
				EndIf;

				ЗаполнитьЗначенияСвойств(CurrentRowTS, CurrentRow);
			EndDo;
		Else
			TabularSectionStructure.Insert("CurrentRow" , GetCurrentRowData(CurrentRow, TabularSectionStructure.TabularSectionFieldStructure));

			ModuleTabularSectionProductsServer.AttributesOnChangeAtServer(TabularSectionStructure, StructureActions, CachedValues);
			ЗаполнитьЗначенияСвойств(CurrentRow, TabularSectionStructure.CurrentRow);
		EndIf;
	Else // client processing is available
		ActionsMap = New Map;

		ProcessBarcodesClient(TabularSection, StructureActions, CachedValues, ActionsMap);

		If TabularSectionProcessingParameters.EntireTabularSectionProcessingIsRequired Then
			For each CurrentRow In TabularSection Do
				CurrentActionStructure = ActionsMap[CurrentRow];
				If CurrentActionStructure <> Undefined Then
					ProcessTabularSectionRowClient(CurrentRow, CurrentActionStructure, CachedValues);
				EndIf;
			EndDo;
		Else
			ProcessTabularSectionRowClient(CurrentRow, StructureActions, CachedValues);
		EndIf;
	EndIf;

EndProcedure



Procedure ProcessTabularSectionRowClient(CurrentRow, StructureActions, CachedValues)

	CheckCharacteristicAndPackageClient(CurrentRow       , StructureActions, CachedValues);

EndProcedure




Procedure CheckCharacteristicAndPackageClient(CurrentRow, StructureActions, CachedValues)

	If StructureActions.Property("CheckCharacteristicByOwner") Then
		CurrentRow.Characteristic = Undefined;
	EndIf;

	If StructureActions.Property("CheckPackageByOwner") Then
		CurrentRow.Package = Undefined;
	EndIf;

EndProcedure





Procedure ProcessBarcodesClient(TabularSection, StructureActions, CachedValues, MapActions)

	Var StructureActionParameters;
	//Not implemented yet

EndProcedure






// INTERACTIVE PROCEDURES

Procedure ChooseNomenclaturePackage(ChoiceData, StandardProcessing, CurrentRow) Export

	StandardProcessing = False;

	If ValueIsFilled(CurrentRow.Nomenclature) Then
		ChoiceData = New ValueList;
		ChoiceData.Add(PredefinedValue("Catalog.NomenclaturePackages.EmptyRef"), "<unpackaged>");

		If NOT ModuleWarehouse.CheckPackageUseAndGetChoiceList(CurrentRow.Nomenclature, ChoiceData) Then
			DoMessageBox(NStr("en = 'This nomenclature item has no packages enabled.'; ru = 'Для данной номенклатуры отключено использование упаковок.'"));
		EndIf;
	EndIf;

EndProcedure



Procedure ChooseNomenclatureCharacteristic(Form, Item, StandardProcessing, CurrentRow) Export

	StandardProcessing = False;

	If ValueIsFilled(CurrentRow.Nomenclature) Then
		CharacteristicOwner = Undefined;
		If ModuleWarehouse.CheckCharacteristicUseAndGetOwnerToChoose(CurrentRow.Nomenclature, CharacteristicOwner) Then
			If CharacteristicOwner = Undefined Then
				DoMessageBox(NStr("en = 'There are no defined characteristics of the current nomenclature.'; ru = 'Для данной номенклатуры характеристики не заданы.'"));
			Else
				FormParameters = New Structure;
				FormParameters.Insert("CurrentItem"   , CurrentRow.Characteristic);
				FormParameters.Insert("ParameterOwner", CharacteristicOwner);
				FormParameters.Insert("Nomenclature"  , CurrentRow.Nomenclature);

				OpenForm("Catalog.NomenclatureCharacteristics.ChoiceForm", FormParameters, Item);
			EndIf;
		Else
			DoMessageBox(NStr("en = 'This nomenclature item has no characteristics enabled.'; ru = 'Для данной номенклатуры отключено использование характеристик.'"));
		EndIf;
	EndIf;

EndProcedure



// OTHER PROCEDURES

Function GetTabularSectionProcessingParameters(TabularSection, CurrentRow, StructureCommonActions, CachedValues)

	Var Characteristic;
	Var Package;
	Var StructureActionParameters;

	ServerCallIsRequired                     = False;
	EntireTabularSectionProcessingIsRequired = False;

	StructureActions = New Structure;
	ModuleTradeManagementClientServer.AddStructure(StructureActions, StructureCommonActions);

	HasNewRows = False;
	HasEditedRows = False;

	StructureActions.Property("CheckCharacteristicByOwner", Characteristic);
	StructureActions.Property("CheckPackageByOwner"       , Package);
	If (ValueIsFilled(Characteristic)
	 OR ValueIsFilled(Package))
	   AND ValueIsFilled(CurrentRow.Nomenclature) Then
		ServerCallIsRequired = True;
	EndIf;

	Return New Structure("ServerCallIsRequired, EntireTabularSectionProcessingIsRequired, StructureActions",
	   ServerCallIsRequired,
	   EntireTabularSectionProcessingIsRequired,
	   StructureActions);

EndFunction


Function GetTabularSectionFieldStructure(StructureActions)

	Var StructureActionParameters;

	TabularSectionFieldStructure = New Structure;

	If StructureActions.Property("CheckCharacteristicByOwner") Then
		TabularSectionFieldStructure.Insert("Nomenclature");
		TabularSectionFieldStructure.Insert("Characteristic");
	EndIf;

	If StructureActions.Property("CheckPackageByOwner") Then
		TabularSectionFieldStructure.Insert("Nomenclature");
		TabularSectionFieldStructure.Insert("Package");
	EndIf;

	Return TabularSectionFieldStructure;

EndFunction



Function GetCurrentRowData(CurrentRow, TabularSectionFieldStructure)

	CurrentRowData = New Structure;
	ModuleTradeManagementClientServer.AddStructure(CurrentRowData, TabularSectionFieldStructure);
	FillPropertyValues(CurrentRowData, CurrentRow);

	Return CurrentRowData;

EndFunction



