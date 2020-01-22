////////////////////////////////////////////////////////////////////////////////
// SERVICE PROCEDURES AND FUNCTIONS

// Procedure checks Nomenclature Property Assignment Level values
//
// Parameters:
//  Cancel       - False if check was failed.
//  CurrentValue - current Nomenclature Property Assignment Level value
//  ValidValue   - valid Nomenclature Property Assignment Level value.
//
Procedure CheckNomenclaturePropertyAssignmentLevel(Cancel, CurrentValue, ValidValue)

	If CurrentValue <> ValidValue Then

		MessageText = NStr("en = 'Nomenclature %Owner% has %CurrentValue% package use flag'; ru = 'Для номенклатуры %Owner% установлен признак использования упаковок %CurrentValue%'");
		MessageText = StrReplace(MessageText, "%Owner%", String(Owner));
		MessageText = StrReplace(MessageText, "%CurrentValue%", String(CurrentValue));

		ModuleCommonClientServer.InformUser(MessageText, ThisObject, "Owner", Cancel);

	EndIf;

EndProcedure


////////////////////////////////////////////////////////////////////////////////
// EVENT HANDLERS
Procedure BeforeWrite(Cancel)

	If DataExchange.Load Then
		Return;
	EndIf;

	If IsNew() Then

		AttributeStructure = New Structure;
		If TypeOf(Owner) = Type("CatalogRef.Nomenclature") Then
			AttributeStructure.Insert("PackageUse", "Category.PackageUse");
		Else // if owner type is NomenclatureCategories catalog.
			AttributeStructure.Insert("PackageUse", "PackageUse");
		EndIf;

		AssignmentLevelAttrubuteValue = ModuleTradeManagement.GetObjectAttributeValues(Owner, AttributeStructure);

		If TypeOf(Владелец) = Type("CatalogRef.Nomenclature") Then

			CheckNomenclaturePropertyAssignmentLevel(Cancel,
				AssignmentLevelAttrubuteValue.PackageUse,
				Enums.NomenclaturePropertyAssignmentLevel.NomenclatureItemLevel);
		Else // if owner type is NomenclatureCategories catalog.

			CheckNomenclaturePropertyAssignmentLevel(Cancel,
				AssignmentLevelAttrubuteValue.PackageUse,
				Enums.NomenclaturePropertyAssignmentLevel.NomenclatureCategoryLevel);
		EndIf;
	EndIf;

EndProcedure // BeforeWrite()

