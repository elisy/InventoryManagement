

Function CheckPackageUseAndGetChoiceList(Nomenclature, ChoiceData, SearchString = Undefined) Export

	Query = New Query(
	"SELECT
	|	ISNULL(CatalogPackages.Ref, UNDEFINED) AS Package,
	|	PRESENTATION(CatalogPackages.Ref) AS PackagePresentation,
	|	PRESENTATION(CatalogPackages.ConversionFactor) AS ConversionFactorPresentation,
	|	PRESENTATION(CatalogNomenclature.Unit) AS UnitPresentation,
	|	CASE
	|		WHEN CatalogNomenclature.Category.PackageUse = VALUE(Enum.NomenclaturePropertyAssignmentLevel.DoNotUse)
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS UsePackages
	|FROM
	|	Catalog.Nomenclature AS CatalogNomenclature
	|		LEFT JOIN Catalog.NomenclaturePackages AS CatalogPackages
	|		ON (CatalogPackages.Owner = CASE
	|				WHEN CatalogNomenclature.Category.PackageUse = VALUE(Enum.NomenclaturePropertyAssignmentLevel.NomenclatureCategoryLevel)
	|					THEN CatalogNomenclature.Category
	|				WHEN CatalogNomenclature.Category.PackageUse = VALUE(Enum.NomenclaturePropertyAssignmentLevel.NomenclatureItemLevel)
	|					THEN CatalogNomenclature.Ref
	|				ELSE FALSE
	|			END)
	|WHERE
	|	CatalogNomenclature.Ref = &Nomenclature" + ?(SearchString = Undefined, "", "AND CatalogPackages.Description LIKE &SearchString") + "
	|ORDER BY
	|	CatalogPackages.ConversionFactor,
	|	CatalogPackages.Ref
	|AUTOORDER
	|");

	Query.SetParameter("Nomenclature", Nomenclature);

	If SearchString <> Undefined Then
		Query.SetParameter("SearchString", SearchString + "%");
	EndIf;

	Selection = Query.Execute().Choose();
	While Selection.Next() Do
		If Selection.UsePackages Then
			If Selection.Package <> Undefined Then
				ChoiceData.Add(Selection.Package, Selection.PackagePresentation
				   + " (" + Selection.ConversionFactorPresentation + " " + Selection.UnitPresentation + ")");
			EndIf;
		Else
			Return False;
		EndIf;
	EndDo;

	Return True;

EndFunction



Function CheckCharacteristicUseAndGetChoiceList(Nomenclature, ChoiceData, SearchString = Undefined) Export

	Query = New Query("SELECT
	                  |	ISNULL(CatalogCharacteristics.Ref, UNDEFINED) AS Characteristic,
	                  |	PRESENTATION(CatalogCharacteristics.Ref) AS CharacteristicPresentation,
	                  |	CASE
	                  |		WHEN CatalogNomenclature.Category.CharacteristicUse = VALUE(Enum.NomenclaturePropertyAssignmentLevel.DoNotUse)
	                  |			THEN FALSE
	                  |		ELSE TRUE
	                  |	END AS EnableCharacteristics
	                  |FROM
	                  |	Catalog.Nomenclature AS CatalogNomenclature
	                  |		LEFT JOIN Catalog.NomenclatureCharacteristics AS CatalogCharacteristics
	                  |		ON (CatalogCharacteristics.Owner = CASE
	                  |				WHEN CatalogNomenclature.Category.CharacteristicUse = VALUE(Enum.NomenclaturePropertyAssignmentLevel.NomenclatureCategoryLevel)
	                  |					THEN CatalogNomenclature.Category
	                  |				WHEN CatalogNomenclature.Category.CharacteristicUse = VALUE(Enum.NomenclaturePropertyAssignmentLevel.NomenclatureItemLevel)
	                  |					THEN CatalogNomenclature.Ref
	                  |				ELSE FALSE
	                  |			END)
	                  |WHERE
	                  |	CatalogNomenclature.Ref = &Nomenclature" + ?(SearchString = Undefined, "", "AND CatalogCharacteristics.Description Like &SearchString") + "
					  |ORDER BY
					  |	CatalogCharacteristics.Ref
					  |AUTOORDER
					  |");

	Query.SetParameter("Nomenclature", Nomenclature);

	If SearchString <> Undefined Then
		Query.SetParameter("SearchString", SearchString + "%");
	EndIf;

	Selection = Query.Execute().Choose();
	While Selection.Next() Do
		If Selection.EnableCharacteristics Then
			If Selection.Characteristic <> Undefined Then
				ChoiceData.Add(Selection.Characteristic, Selection.CharacteristicPresentation);
			EndIf;
		Else
			Return False;
		EndIf;
	EndDo;

	Return True;

EndFunction



Function CheckCharacteristicUseAndGetOwnerToChoose(Nomenclature, CharacteristicOwner) Export

	StructureAttributes = New Structure;
	StructureAttributes.Insert("NomenclatureCategory"           , "Category");
	StructureAttributes.Insert("CharacteristicUse", "Category.CharacteristicUse");
	AttributeValues = ModuleCommon.GetObjectAttributeValues(Nomenclature, StructureAttributes);

	If AttributeValues.CharacteristicUse = Enums.NomenclaturePropertyAssignmentLevel.DoNotUse Then
		CharacteristicUse = False;
	Else
		CharacteristicUse = True;

		If AttributeValues.CharacteristicUse = Enums.NomenclaturePropertyAssignmentLevel.NomenclatureCategoryLevel Then
			CharacteristicOwner = AttributeValues.NomenclatureCategory;
		Else
			CharacteristicOwner = Nomenclature;
		EndIf;
	EndIf;

	Return CharacteristicUse;

EndFunction


