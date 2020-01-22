
Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	Var StructureValue;

	If NOT Parameters.Property("Nomenclature", StructureValue) Then
		Return;
	EndIf;

	StandardProcessing = False;

	ChoiceData = New ValueList;

	If NOT ModuleWarehouse.CheckPackageUseAndGetChoiceList(StructureValue,
	   ChoiceData, Parameters.SearchString) Then
		ChoiceData = Undefined;
	EndIf;

EndProcedure

