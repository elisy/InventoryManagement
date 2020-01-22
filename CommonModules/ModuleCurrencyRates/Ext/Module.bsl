// Procedure copies source currency information into information register for the destination currency
//
// Parameters
//  SourceCurrency – Catalog.Currencies – base currency reference
//  DestinationCurrency – Catalog.Currencies – dependent currency reference
//
Procedure WriteDependentRegisterInformationа(SourceCurrency, DestinationCurrency) Export
	
	Query = New Query;
	Query.Text = "SELECT *
				  | FROM InformationRegister.CurrencyRates
				  | WHERE Currency = &SourceCurrency";
	Query.SetParameter("SourceCurrency", SourceCurrency);
	
	Selection = Query.Execute().Choose();
	
	RegisterCurrencyRates = InformationRegisters.CurrencyRates;
	RateSet = RegisterCurrencyRates.CreateRecordSet();
	
	RateSet.Filter.Currency.ComparisonType  = ComparisonType.Equal;
	RateSet.Filter.Currency.Value      = DestinationCurrency;
	RateSet.Filter.Currency.Use = True;
	
	DependentRateCoefficient = DestinationCurrency.DependentRateCoefficient;
	
	While Selection.Next() Do
		
		NewRateSetRecord = RateSet.Add();
		NewRateSetRecord.Currency     = DestinationCurrency;
		NewRateSetRecord.Ratio        = Selection.Ratio;
		NewRateSetRecord.ExchangeRate = Selection.ExchangeRate + Selection.ExchangeRate*DependentRateCoefficient/100;
		NewRateSetRecord.Period       = Selection.Period;
		
	EndDo;
	
	RateSet.Write();
	
EndProcedure



// Checks if currency exchange rate and ratio have been defined on 01 January 1980.
// If not defines rate = 1 and ratio = 1.
//
// Parameters:
//  Currency - reference to Currencies catalog
//
Procedure IsCurrencyRateValidOn01_01_1980(Currency) Export
	
	RateDate = Date("19800101");
	RateStructure = InformationRegisters.CurrencyRates.GetLast(RateDate, New Structure("Currency", Currency));
	
	If (RateStructure.ExchangeRate = 0) OR (RateStructure.Ratio = 0) Then
		
		RegisterCurrencyRates = InformationRegisters.CurrencyRates.CreateRecordManager();
		
		RegisterCurrencyRates.Period    = RateDate;
		RegisterCurrencyRates.Currency    = Currency;
		RegisterCurrencyRates.ExchangeRate      = 1;
		RegisterCurrencyRates.Ratio = 1;
		RegisterCurrencyRates.Write();
	EndIf;
	
EndProcedure // IsCurrencyRateValidOn01_01_1980()




