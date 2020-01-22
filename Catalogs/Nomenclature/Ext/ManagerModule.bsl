Function CheckCharacteristicAndPackageOwnership(Nomenclature, Characteristic, Package) Export

	CharactiristicDoesNotBelongToTheOwner = ValueIsFilled(Characteristic);
	PackageDoesNotBelongToTheOwner       = ValueIsFilled(Package);
	If CharactiristicDoesNotBelongToTheOwner OR PackageDoesNotBelongToTheOwner Then
		Query = New Query;
		Query.SetParameter("Nomenclature", Nomenclature);

		QueryText = "";

		If CharactiristicDoesNotBelongToTheOwner Then
			QueryText = "SELECT TOP 1
			            |	1 AS Result
			            |FROM
			            |	Catalog.Nomenclature AS CatalogNomenclature
			            |		INNER JOIN Catalog.NomenclatureCharacteristics AS CatalogCharacteristics
			            |		ON (CatalogCharacteristics.Owner = CASE
			            |				WHEN CatalogNomenclature.Category.CharacteristicUse = VALUE(Enum.NomenclaturePropertyAssignmentLevel.NomenclatureCategoryLevel)
			            |					THEN CatalogNomenclature.Category
			            |				WHEN CatalogNomenclature.Category.CharacteristicUse = VALUE(Enum.NomenclaturePropertyAssignmentLevel.NomenclatureItemLevel)
			            |					THEN CatalogNomenclature.Ref
			            |				ELSE FALSE
			            |			END)
			            |WHERE
			            |	CatalogNomenclature.Ref = &Nomenclature
			            |	AND CatalogCharacteristics.Ref = &Characteristic";

			Query.SetParameter("Characteristic", Characteristic);
		EndIf;

		If PackageDoesNotBelongToTheOwner Then
			If CharactiristicDoesNotBelongToTheOwner Then
				QueryText = QueryText + "
				|UNION ALL";
			EndIf;

			QueryText = QueryText + "SELECT TOP 1
			                        |	2 AS Result
			                        |FROM
			                        |	Catalog.Nomenclature AS CatalogNomenclature
			                        |		INNER JOIN Catalog.NomenclaturePackages AS CatalogPackages
			                        |		ON (CatalogPackages.Owner = CASE
			                        |				WHEN CatalogNomenclature.Category.PackageUse = VALUE(Enum.NomenclaturePropertyAssignmentLevel.NomenclatureCategoryLevel)
			                        |					THEN CatalogNomenclature.Category
			                        |				WHEN CatalogNomenclature.Category.PackageUse = VALUE(Enum.NomenclaturePropertyAssignmentLevel.NomenclatureItemLevel)
			                        |					THEN CatalogNomenclature.Ref
			                        |				ELSE FALSE
			                        |			END)
			                        |WHERE
			                        |	CatalogNomenclature.Ref = &Nomenclature
			                        |	AND CatalogPackages.Ref = &Package";

			Query.SetParameter("Package", Package);
		EndIf;

		Query.Text = QueryText;

		Selection = Query.Execute().Choose();
		While Selection.Next() Do
			If Selection.Result = 1 Then
				CharactiristicDoesNotBelongToTheOwner = False;
			ElsIf Selection.Result = 2 Then
				PackageDoesNotBelongToTheOwner = False;
			EndIf;
		EndDo;
	EndIf;

	Return New Structure("CharactiristicDoesNotBelongToTheOwner, PackageDoesNotBelongToTheOwner",
	   CharactiristicDoesNotBelongToTheOwner,
	   PackageDoesNotBelongToTheOwner);

EndFunction


Function GetKeyAttributes() Export

	Result = New Array;
	Result.Add("Category");
	Result.Add("EnableCustomsDeclarations");

	Return Result;

EndFunction

