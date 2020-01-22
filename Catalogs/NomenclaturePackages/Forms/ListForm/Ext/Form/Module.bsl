&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("Filter") AND Parameters.Filter.Property("Owner") Then

		Owner       = Parameters.Filter.Owner;
		FilterOwner = Undefined;

		If TypeOf(Owner) = Type("CatalogRef.Nomenclature") Then

			If Owner.Category.PackageUse = Enums.NomenclaturePropertyAssignmentLevel.NomenclatureItemLevel Then
				FilterOwner = Owner;
			ElsIf Owner.Category.PackageUse = Enums.NomenclaturePropertyAssignmentLevel.NomenclatureCategoryLevel Then
				FilterOwner = Owner.Category;
			EndIf;

		ElsIf TypeOf(Owner) = Type("CatalogRef.NomenclatureCategories") Then

			If Owner.PackageUse = Enums.NomenclaturePropertyAssignmentLevel.NomenclatureCategoryLevel Then
				FilterOwner = Owner;
			EndIf;

		EndIf;

		If FilterOwner = Undefined Then

			TitleText = NStr("en = 'Item ""%Owner%"" does not use packages'; ru = 'Для элемента: ""%Owner%"" упаковки не используются'");
			TitleText = StrReplace(TitleText, "%Owner%", String(Owner));

			AutoTitle = False;
			Title     = TitleText;

			Items.List.ReadOnly = True;

		EndIf;

		Parameters.Filter.Owner = FilterOwner;

	EndIf;

EndProcedure

