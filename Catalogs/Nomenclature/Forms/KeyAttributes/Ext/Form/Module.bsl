
&AtClient
Procedure Edit(Command)

	Result = New Array;
	If EditNomenclatureCategory Then
		Result.Add("Category");
		Result.Add("EnableCustomsDeclarations");
	EndIf;

	If EditCustomsDeclarationAccounting Then
		Result.Add("EnableCustomsDeclarations");
	EndIf;

	Close(Result);

EndProcedure


