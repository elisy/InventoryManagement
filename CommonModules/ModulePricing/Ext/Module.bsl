////////////////////////////////////////////////////////////////////////////////
// SERVICE PROCEDURES AND FUNCTIONS

// Builds query to check Nomenclature items table part of the nomenclature pricing document
//
// Parameters:
// QueryText - string to add query text
// QueryParameters - structure containing query parameters
// PricingDocument - DocumentObject to check
//
Procedure BuildQueryToCheckPriceWriting(QueryText, QueryParameters, PricingDocument)
	
	QueryText = QueryText + 
	"SELECT
	|	TemporaryTableProducts.LineNumber AS LineNumber,
	|	TemporaryTableProducts.Nomenclature AS Nomenclature,
	|	TemporaryTableProducts.Characteristic AS Characteristic,
	|	TemporaryTableProducts.PriceCategory AS PriceCategory
	|INTO TemporaryTableProducts
	|FROM
	|	&Products AS TemporaryTableProducts
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MAX(DocumentProducts.LineNumber) AS LineNumber,
	|	DocumentProducts.Nomenclature,
	|	DocumentProducts.Characteristic,
	|	DocumentProducts.PriceCategory
	|FROM
	|	TemporaryTableProducts AS DocumentProducts
	|
	|GROUP BY
	|	DocumentProducts.Nomenclature,
	|	DocumentProducts.Characteristic,
	|	DocumentProducts.PriceCategory
	|
	|HAVING
	|	COUNT(*) > 1";
		
	QueryParameters.Insert("Products",	PricingDocument.Products.Unload(,"LineNumber,Nomenclature,Characteristic,PriceCategory"));
	
EndProcedure // BuildQueryToCheckPriceWriting()




// Show error messages after nomenclature pricing document check
//
// Parameters:
// Selection       - Query results
// PricingDocument - DocumentObject to show error messages
// Cancel          - The flag showing post cancellation
//
Procedure NotifyNomenclaturePriceWritingErrors(Selection, PricingDocument, Cancel)
	
	While Selection.Next() Do
		
		If ValueIsFilled(Selection.PriceCategory) Then
			
			If ValueIsFilled(Selection.Characteristic) Then
				
				ErrorMessage = NStr("en = 'Repeated nomenclature item ""%Nomenclature%"" with characteristic ""%Characteristic%"" and price category ""%PriceCategory%""'; ru = 'Номенклатура ""%Nomenclature%"" с характеристикой ""%Characteristic%"" с видом цены ""%PriceCategory%"" повторяется'");
				ErrorMessage = StrReplace(ErrorMessage,"%Nomenclature%",Selection.Nomenclature);
				ErrorMessage = StrReplace(ErrorMessage,"%Characteristic%",Selection.Characteristic);
				ErrorMessage = StrReplace(ErrorMessage,"%PriceCategory%",Selection.PriceCategory);
				
			Else
				
				ErrorMessage = NStr("en = 'Repeated nomenclature item ""%Nomenclature%"" with price category ""%PriceCategory%""'; ru = 'Номенклатура ""%Nomenclature%"" с видом цены ""%PriceCategory%"" повторяется'");
				ErrorMessage = StrReplace(ErrorMessage,"%Nomenclature%",Selection.Nomenclature);
				ErrorMessage = StrReplace(ErrorMessage,"%PriceCategory%",Selection.PriceCategory);
				
			EndIf;
			
		Else
			
			If ValueIsFilled(Selection.Characteristic) Then
				
				ErrorMessage = NStr("en = 'Repeated nomenclature item ""%Nomenclature%"" with characteristic ""%Characteristic%""'; ru = 'Номенклатура ""%Nomenclature%"" с характеристикой ""%Characteristic%"" повторяется'");
				ErrorMessage = StrReplace(ErrorMessage,"%Nomenclature%",Selection.Nomenclature);
				ErrorMessage = StrReplace(ErrorMessage,"%Characteristic%",Selection.Characteristic);
				
			Else
				
				ErrorMessage = NStr("en = 'Repeated nomenclature item ""%Nomenclature%""'; ru = 'Номенклатура ""%Nomenclature%"" повторяется'");
				ErrorMessage = StrReplace(ErrorMessage,"%Nomenclature%",Selection.Nomenclature);
				
			EndIf;
			
		EndIf;
		
		ModuleCommonClientServer.InformUser(
			ErrorMessage,
			PricingDocument,
			ModuleTradeManagement.GetMessageByTabularSectionRow("Products", Selection.LineNumber, "Nomenclature"),
			Cancel);
			
	EndDo;
	
EndProcedure // NotifyNomenclaturePriceWritingErrors()





////////////////////////////////////////////////////////////////////////////////
// DOCUMENT FILL CHECK PROCEDURE AND FUNCTIONS

// Check Nomenclature Pricing document
//
// Parameters:
// PricingDocument - DocumentObject, document to check
// Cancel          - Cancel flag
//
Procedure NomenclaturePricingDocumentFillCheckProcessing(PricingDocument,Cancel) Export
	
	QueryText = "";
	QueryParameters = New Structure();
	
	// Build query text to check
	BuildQueryToCheckPriceWriting(QueryText, QueryParameters, PricingDocument);
	
	Query = New Query(QueryText);
	
	For each QueryParameter In QueryParameters Do
		Query.SetParameter(QueryParameter.Key, QueryParameter.Value);
	EndDo;
	
	QueryResult = Query.ExecuteBatch();
	
	Selection = QueryResult[1].Choose();
	
	// Notify user
	NotifyNomenclaturePriceWritingErrors(Selection, PricingDocument, Cancel);
	
EndProcedure // NomenclaturePricingDocumentFillCheckProcessing()




////////////////////////////////////////////////////////////////////////////////
// PROCEDURES AND FUNCTIONS OF NOMENCLATURE PRICE REGISTRATION

Procedure WriteNomenclaturePrices(AdditionalProperties, RegisterRecords, Cancel) Export
	
	Table = AdditionalProperties.RegisterRecords.TableProducts;
	
	If Cancel OR Table.Count() = 0 Then
		Return;
	EndIf;
	
	RecordsNomenclaturePrices = RegisterRecords.NomenclaturePrices;
	RecordsNomenclaturePrices.Write = True;
	RecordsNomenclaturePrices.Load(Table);
	
EndProcedure // WriteNomenclaturePrices()






////////////////////////////////////////////////////////////////////////////////
// PROCEDURES AND FUNCTIONS TO SERVE PRICE CATEGORIES FILLED BY INFOBASE DATA

// Returns required field names and types that should exist in Data Composition Schema
// to fill prices from InfoBase data
//
// Returns:
// Map
// Keyas are fiend names and values are their types
//
Function GetRequiredDataCompositionSchemaFields() Export
	
	Fields = New Map();
	Fields.Insert("Nomenclature", New TypeDescription("CatalogRef.Nomenclature"));
	If GetFunctionalOption("EnableNomenclatureCharacteristics") Then
		Fields.Insert("Characteristic", New TypeDescription("CatalogRef.NomenclatureCharacteristics"));
	EndIf;
	If GetFunctionalOption("EnableNomenclaturePackages") Then
		Fields.Insert("Package", New TypeDescription("CatalogRef.NomenclaturePackages"));
	EndIf;
	Fields.Insert("Price", New TypeDescription("Number"));
	Fields.Insert("Currency", New TypeDescription("CatalogRef.Currencies"));
	
	Return Fields;
	
EndFunction



// Checks Data Composition Schema data set for existance of predefined field and its type.
//
// Parameters:
// DataSet 			- data set to check
// FieldName		- String containing field name
// ValueType		- TypeDescription. Type of the field
// ErrorMessage 	- String containing error title
//
// Returns:
// Boolean
// True if data set contains required field.
//
Function CheckDCSDataSetField(DataSet, FieldName, ValueType, ErrorMessage = Undefined)
	Field = DataSet.Fields.Find(FieldName);
	Result = Field <> Undefined AND Field.ValueType = ValueType;
	If NOT Result Then
		MessageToShow = ?(ValueIsFilled(ErrorMessage), ErrorMessage + ": ", "") 
			+ NStr("en = 'Data composition schema should contain field ''%FieldName%'' with type ''%ValueType%''.'; ru = 'Схема компоновки данных для заполнения цен должна содержать поле ''%FieldName%'' с типом значений ''%ValueType%''.'");
		MessageToShow = StrReplace(MessageToShow, "%FieldName%", FieldName);
		MessageToShow = StrReplace(MessageToShow, "%ValueType%", ValueType);
		Message(MessageToShow);
	EndIf;
	Return Result;
EndFunction




// Function checks Data Composition Schema searching price calculation restrictions 
//
// Parameters:
// DataCompositionSchema	- DataCompositionSchema, Data Composition Schema to check
// ErrorMessage		- String containing caption
//
// Returns:
// Boolean
// True if DataCompositionSchema is valid
//
Function CheckDataCompositionSchema(DataCompositionSchema, ErrorMessage = Undefined) Export
	
	Result = True;
	
	If DataCompositionSchema.DataSets.Count() = 1 Then
		ActiveDataSet = DataCompositionSchema.DataSets[0];				
		Fields = GetRequiredDataCompositionSchemaFields();
		For each Field In Fields Do
			If NOT CheckDCSDataSetField(ActiveDataSet, Field.Key, Field.Value, ErrorMessage) Then
				Result = False;
			EndIf;
		EndDo;
	Else
		Message(?(ValueIsFilled(ErrorMessage), ErrorMessage + ": ", "") 
			+ NStr("en = 'Data composition schema should contain single data set. Multiple data sets are not supported.'; ru = 'Схема компоновки данных для заполнения цен должна содержать один набор данных.'"));
		Result = False;
	EndIf;
	
	Return Result;
	
EndFunction

