
Procedure OnCopy(CopiedObject)
	Code = "";
EndProcedure



Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	If DataExchange.Load Then
		Return;
	EndIf;
			
	If NOT IsFolder Then
	
		If StrLen(TrimAll(BankAccount)) <> 20 Then
			MessageText = NStr("en = 'Bank account should be 20 character length.'; ru = 'Корр.счета банка должен иметь 20 знаков.'");
			ModuleCommonClientServer.InformUser(MessageText, ThisObject, "BankAccount", Cancel);
		EndIf;
		
		If NOT ModuleStringFunctionsClientServer.IsDigitString(TrimAll(BankAccount)) Then
			MessageText = NStr("en = 'Bank account should should contain digits only.'; ru = 'В составе Корр.счета банка должны быть только цифры.'");
			ModuleCommonClientServer.InformUser(MessageText, ThisObject, "BankAccount", Cancel);
		EndIf;
		
		If StrLen(TrimAll(Code)) <> 9 Then
			MessageText = NStr("en = 'Bank IN  should be 9-digit string.'; ru = 'БИК банка должен иметь 9 знаков.'");
			ModuleCommonClientServer.InformUser(MessageText, ThisObject, "Code", Cancel);
		EndIf;

		If NOT ModuleStringFunctionsClientServer.IsDigitString(TrimAll(Code)) Then
			MessageText = NStr("en = 'BIN should contain digits only.'; ru = 'В составе БИК банка должны быть только цифры.'");
			ModuleCommonClientServer.InformUser(MessageText, ThisObject, "Code", Cancel);
		EndIf;
		
	Else
		
		Position = CheckedAttributes.Find("Code");
		If Position <> Undefined Then
			CheckedAttributes.Delete(Position);
		EndIf;
		
	EndIf;

	
EndProcedure


