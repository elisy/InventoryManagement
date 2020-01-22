



////////////////////////////////////////////////////////////////////////////////
// NOMENCLATURE CATALOG FUNCTIONS 

Function GetPropertySetByNomenclatureCategory(NomenclatureCategory, ErrorString = "") Export
	
	If NOT ValueIsFilled(NomenclatureCategory) Then
		ErrorString = NStr("en = 'Nomenclature category was not specified!'; ru = 'Не указан вид номенклатуры!'");
		Return Undefined;
	EndIf;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	NomenclatureCategories.PropertySet
	|FROM
	|	Catalog.NomenclatureCategories AS NomenclatureCategories
	|WHERE
	|	NomenclatureCategories.Ref = &Category";
	
	Query.SetParameter("Category", NomenclatureCategory);
	Selection = Query.Execute().Choose();
	
	If Selection.Next() AND ValueIsFilled(Selection.PropertySet) Then
		Return Selection.PropertySet;
	EndIf;
	
	ErrorString = NStr("en = 'Nomenclature category does not contain property set!'; ru = 'Для вида номенклатуры не задан набор свойств!'");
	Return Undefined;
	
EndFunction



