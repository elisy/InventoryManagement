Procedure InitializeDocumentData(DocumentRef, AdditionalProperties) Export

	Query = New Query(
	// 0 TableNomenclaturePrices
	"SELECT
	|	Products.Nomenclature AS Nomenclature,
	|	Products.Characteristic AS Characteristic,
	|	Products.Package AS Package,
	|	Products.PriceCategory AS PriceCategory,
	|	Products.Price AS Price,
	|	Products.PriceCategory.PriceCurrency AS Currency,
	|	Products.Ref.Date AS PERIOD
	|FROM
	|	Document.NomenclaturePricing.Products AS Products
	|WHERE
	|	Products.Ref = &Reference");

	Query.SetParameter("Reference", DocumentRef);
	Result = Query.ExecuteBatch();

	AdditionalProperties.RegisterRecords.Insert("TableProducts", Result[0].Unload());

EndProcedure // InitializeDocumentData()



