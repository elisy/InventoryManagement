
Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	If NOT IsFolder AND Type <> Category.Type Then
		Type = Category.Type;
	EndIf;

	If NOT IsFolder AND Type <> Enums.NomenclatureTypes.Product Then

		EnableCustomsDeclarations  = False;
		EnableSerialNumbers        = False;

	EndIf;

EndProcedure


