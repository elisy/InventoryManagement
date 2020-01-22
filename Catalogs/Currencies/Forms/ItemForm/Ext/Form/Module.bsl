////////////////////////////////////////////////////////////////////////////////
// EVENT HANDLERS
//


&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("Code") Then
		Object.Code = Parameters.Code;
	EndIf;
	
	If Parameters.Property("Description") Then
		Object.Description = Parameters.Description;
	EndIf;
	
	If Parameters.Property("DescriptionLong") Then
		Object.DescriptionLong = Parameters.DescriptionLong;
	EndIf;
	
	If Parameters.Property("IsDownloable") Then
		Object.IsDownloable = Parameters.IsDownloable;
	EndIf;
	
	If  Object.IsDownloable Then
		ExchangeRateSource = 1;
		Object.BaseCurrency = Catalogs.Currencies.EmptyRef();
	ElsIf ValueIsFilled(Object.BaseCurrency) Then
		ExchangeRateSource = 2;
	EndIf;
	
	ReadSpellingSettings();

EndProcedure


&AtClient
Procedure OnOpen(Cancel)
	
	EnableGroupBaseCurrency();
	
EndProcedure


&AtClient
Procedure ExchangeRateSourceOnChange(Item)
	
	EnableGroupBaseCurrency();
	
EndProcedure


&AtClient
Procedure BaseCurrencyStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	PrepareBaseCurrencyChoiceData(ChoiceData, Object.Ref);
	
EndProcedure



&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)

	// Set downloading and base currency attributes
	If ExchangeRateSource = 1 Then
		Object.IsDownloable = True;
		Object.BaseCurrency = Null;
		Object.DependentRateCoefficient = 0;
	ElsIf ExchangeRateSource = 2 Then
		Object.IsDownloable = False;
	Else
		Object.IsDownloable = False;
		Object.BaseCurrency = Null;
		Object.DependentRateCoefficient = 0;
	EndIf;

EndProcedure


&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	BuildSpellingSettings();
	
EndProcedure


////////////////////////////////////////////////////////////////////////////////
// PRIVATE FUNCTIONS AND PROCEDURES
//

&AtServer
// Procedure reads spelling settings and fills controls.
//
Procedure ReadSpellingSettings()
	
	StringSettings = StrReplace(Object.SpellingSettings, ",", Chars.LF);
	
	CurrencyName           = TrimAll(StrGetLine(StringSettings, 1));
	CurrencyNamePlural     = TrimAll(StrGetLine(StringSettings, 2));
	CurrencyCentName       = TrimAll(StrGetLine(StringSettings, 3));
	CurrencyCentNamePlural = TrimAll(StrGetLine(StringSettings, 4));
	FractionalPartLength   = TrimAll(StrGetLine(StringSettings, 5));
	
	If FractionalPartLength = Undefined Then
		FractionalPartLength = FractionalPartLength.ChoiceList[0].DataPath;
	EndIf;
	
EndProcedure



&AtServer
// Procedure builds spelling settings from controls
//
Procedure BuildSpellingSettings()
	
	Object.SpellingSettings = CurrencyName + ", "
									 + CurrencyName + ", "
									 + CurrencyNamePlural + ", "
									 + CurrencyCentName + ", "
									 + CurrencyCentNamePlural + ", "
									 + FractionalPartLength;
	
EndProcedure



&AtClient
// Procedure enables or disabled the base currency group according to base currency
//
Procedure EnableGroupBaseCurrency()
	
	If ExchangeRateSource = 2 Then
		Items.GroupBaseCurrency.CurrentPage = 
		   Items.GroupBaseCurrencyAdditionalSettings;
	Else
		Items.GroupBaseCurrency.CurrentPage = 
		   Items.GroupEmptyPage;
	EndIf;
	
EndProcedure




&AtServerNoContext 
// Prepares choice list selecting independent currency list without the current currency
//
Procedure PrepareBaseCurrencyChoiceData(ChoiceData, Reference)
	
	ChoiceData = New ValueList;
	
	Query = New Query;
	
	Query.Text = "SELECT
	             |	Currencies.Ref,
	             |	Currencies.DescriptionLong
	             |FROM
	             |	Catalog.Currencies AS Currencies
	             |WHERE
	             |	Currencies.Ref <> &Reference
	             |	AND Currencies.BaseCurrency = VALUE(Catalog.Currencies.EmptyRef)";
	
	Query.Parameters.Items("Reference", Reference);
	
	Selection = Query.Execute().Выбрать();
	
	While Selection.Next() Do
		ChoiceData.Add(Selection.Ref, Selection.DescriptionLong);
	EndDo;
	
EndProcedure


