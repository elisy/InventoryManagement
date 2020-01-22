////////////////////////////////////////////////////////////////////////////////
// SERVICE PROCEDURES AND FUNCTIONS

// Initialize nomenclature pricing
//
Procedure InitializeDocument()
	 	
	ResponsibleUser = SessionParameters.CurrentUser;

EndProcedure // InitializeDocument()



////////////////////////////////////////////////////////////////////////////////
// EVENT HANDLERS


Procedure Filling(FillingData, StandardProcessing)
	
	InitializeDocument();
	
EndProcedure


Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	ModulePricing.NomenclaturePricingDocumentFillCheckProcessing(ThisObject, Cancel);

EndProcedure


Procedure Posting(Cancel, PostingMode)
	
	ModulePostingServer.InitializePostingAdditionalProperties(Ref, AdditionalProperties);

	Documents.NomenclaturePricing.InitializeDocumentData(Ref, AdditionalProperties);

	ModulePostingServer.PrepareRecordSetsToWrite(ThisObject);

	ModulePricing.WriteNomenclaturePrices(AdditionalProperties, RegisterRecords, Cancel);

	ModulePostingServer.WriteRecordSets(ThisObject);
	
EndProcedure


Procedure UndoPosting(Cancel)
	
	ModulePostingServer.InitializePostingAdditionalProperties(Ref, AdditionalProperties);

	ModulePostingServer.PrepareRecordSetsToWrite(ThisObject);

	ModulePostingServer.WriteRecordSets(ThisObject);

EndProcedure



Procedure OnCopy(CopiedObject)
	
	InitializeDocument();
	
EndProcedure

