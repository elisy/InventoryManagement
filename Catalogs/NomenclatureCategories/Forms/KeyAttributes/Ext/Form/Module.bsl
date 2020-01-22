

&AtClient
Procedure EnableEditing(Command)
	
	Result = New Array;
	
	If EnableNomenclatureType Then
		
		Result.Add("Type");
		
	EndIf;
	
	If EnableCharacteristicUse Then
		
		Result.Add("CharacteristicUse");
		
	EndIf;
	
	If EnablePackageUse Then
		
		Result.Add("PackageUse");
		
	EndIf;

	Close(Result);
	
EndProcedure

