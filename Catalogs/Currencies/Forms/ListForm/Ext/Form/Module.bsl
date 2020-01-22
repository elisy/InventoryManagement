
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	ExchangeRateDate = BegOfDay(CurrentDate());
	ExchangeRateTitle = NStr("en = 'Exchange rate on %CurrentDate%'; ru = 'Курс на %CurrentDate%'");
	ExchangeRateTitle = StrReplace(ExchangeRateTitle, "%CurrentDate%", Формат(CurrentDate(), "DLF=DD"));
	Items.ExchangeRate.Title = ExchangeRateTitle;
	List.Parameters.SetParameterValue ("EndDate", ExchangeRateDate);

EndProcedure


&AtClient
Procedure ChoiceProcessing(SelectedValue, ChoiceSource)

	If TypeOf(SelectedValue) = Type("Structure") Then
		OpenForm("Catalog.Currencies.ObjectForm", SelectedValue, ThisForm);
	EndIf;

EndProcedure


&AtClient
Procedure CommandDownloadExchangeRates(Command)
	
	DoMessageBox(NStr("en = 'Not implemented.'; ru = 'Функциональность не реализована.'"));

EndProcedure


&AtClient
Procedure CommandChooseFromISOList(Command)
	
	OpenForm("Catalog.Currencies.Form.ISO4217",, ThisForm, ThisForm);

EndProcedure


&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "OnExchangeRatesChanged" Then
		Items.Currencies.Refresh();
	EndIf;

EndProcedure

