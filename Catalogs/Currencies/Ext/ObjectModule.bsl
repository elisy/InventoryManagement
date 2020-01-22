
Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	If ThisObject.IsDownloable
	   AND (ThisObject.BaseCurrency) Then
		ModuleCommonClientServer.InformUser(
					  NStr("en = 'Currency cannot be both dependent and auto updatable.'; ru = 'Валюта не может быть зависимой и при этом загружаться с сайта РБК'"));
		Return;
	EndIf;
	
EndProcedure


Procedure OnWrite(Cancel)

	ModuleCurrencyRates.IsCurrencyRateValidOn01_01_1980(ThisObject.Ref);
	
	If ValueIsFilled(ThisObject.BaseCurrency) Then
		ModuleCurrencyRates.WriteDependentRegisterInformationа(ThisObject.BaseCurrency, ThisObject.Ref);
	EndIf;
	
EndProcedure

