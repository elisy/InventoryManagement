
//Check NomenclatureType attribute
//Check CharacteristicUse attribute
//Check PackageUse attribute
Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	If IsFolder Then
		Return;
	EndIf;

	// Create or change the appropriate property set
	If NOT Cancel Then
		RefreshNomenclaturePropertySetAttribute();
	EndIf;
	
EndProcedure


Function PropertySetShouldBeChanged()
	
	Result = ModuleCommon.GetObjectAttributeValues(PropertySet, New Structure("Description,DeletionMark"));
	Return (Result.Description <> Description) OR (Result.DeletionMark <> DeletionMark);
	
EndFunction


Procedure OnCopy(CopiedObject)
	
	PropertySet = Catalogs.PropertySets.EmptyRef();
	
EndProcedure


Procedure RefreshNomenclaturePropertySetAttribute()
	
	If NOT ValueIsFilled(PropertySet) Then
		ListObject = Catalogs.PropertySets.CreateItem();
	Else
		If NOT PropertySetShouldBeChanged() Then
			Return;
		EndIf;
		
		ListObject = PropertySet.GetObject();
	EndIf;
	
	ListObject.Description  = Description;
	ListObject.Parent       = Catalogs.PropertySets.Catalog_Nomenclature;
	ListObject.DeletionMark = DeletionMark;
	ListObject.Write();
	NomenclaturePropertySet = ListObject.Ref;
	
EndProcedure


