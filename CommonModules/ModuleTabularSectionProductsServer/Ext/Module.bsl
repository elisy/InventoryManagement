// PROCEDURE "OnChange" AT SERVER.
// PROCEDURE IS CALLED FROM CLIENT MODULE IF REQUIRED
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

Procedure AttributesOnChangeAtServer(TabularSectionStructure, StructureActions, CachedValues) Export

	Var StructureValue;

	ActionsMap = New Map;

	ProcessBarcodesServer(TabularSectionStructure, StructureActions, CachedValues, ActionsMap);

	If TabularSectionStructure.Property("TabularSectionRows", StructureValue) Then
		For each CurrentRow In StructureValue Do
			CurrentActionStructure = ActionsMap[CurrentRow];
			If CurrentActionStructure <> Undefined Then
				ProcessTabularSectionRowServer(CurrentRow, CurrentActionStructure, CachedValues);
			EndIf;
		EndDo;
	EndIf;

	If TabularSectionStructure.Property("CurrentRow", StructureValue) Then
		ProcessTabularSectionRowServer(StructureValue, StructureActions, CachedValues);
	EndIf;

EndProcedure


Procedure ProcessTabularSectionRowServer(CurrentRow, StructureActions, CachedValues)

	CheckCharacteristicAndPackageServer(CurrentRow       , StructureActions, CachedValues);

EndProcedure



// RECALCULATION AND FILLING PROCEDURES (SERVER)



Procedure CheckCharacteristicAndPackageServer(CurrentRow, StructureActions, CachedValues)

	Var Characteristic;
	Var Package;

	CheckCharacteristicByOwner = StructureActions.Property("CheckCharacteristicByOwner", Characteristic);
	CheckPackageByOwner        = StructureActions.Property("CheckPackageByOwner"      , Package);

	If CheckCharacteristicByOwner OR CheckPackageByOwner Then
		Ownership = Catalogs.Nomenclature.CheckCharacteristicAndPackageOwnership(CurrentRow.Nomenclature, Characteristic, Package);

		If CheckCharacteristicByOwner
		   AND Ownership.CharactiristicDoesNotBelongToTheOwner Then
			CurrentRow.Characteristic = Catalogs.NomenclatureCharacteristics.EmptyRef();
		EndIf;

		If CheckPackageByOwner
		   AND Ownership.PackageDoesNotBelongToTheOwner Then
			CurrentRow.Package = Catalogs.NomenclaturePackages.EmptyRef();
		EndIf;
	EndIf;

EndProcedure


Procedure ProcessBarcodesServer(TabularSectionStructure, StructureActions, CachedValues, MapActions)
	
	//Not implemented yet

EndProcedure



