///////////////////////////////////////////////////////////////////////////////////
// Procedures and functions of preparing register record sets to post.

Procedure InitializePostingAdditionalProperties(DocumentRef, StructureAdditionalProperties, PostingMode = Undefined) Export
	
	// Keys TablesRegisterRecords and Posting are created in AdditionalProperties structure.

	// "RegisterRecords" - structure containing value tables with records of registers.
	StructureAdditionalProperties.Insert("RegisterRecords", New Structure);

	// "Posting" - structure containing document properties and attributes to post.
	StructureAdditionalProperties.Insert("Posting", New Structure);
	
	// Structure containing TempTablesManager key with the appropriate value.
	// Contains the key (temporary table name) for the each temporary table and the value containing the flag of temporary table records existance.
	StructureAdditionalProperties.Posting.Insert("StructureTempTables", New Structure("TempTablesManager", New TempTablesManager));
	StructureAdditionalProperties.Posting.Insert("PostingMode", PostingMode);
	StructureAdditionalProperties.Posting.Insert("DocumentMetadata", DocumentRef.Metadata());
	
	// Query with document data.
	Query = New Query(
	"SELECT
	|	_Document_.Ref AS Ref,
	|	_Document_.Number AS Number,
	|	_Document_.Date AS Date,
	|	_Document_.PointInTime AS PointInTime,
	|	_Document_.Presentation AS Presentation
	|FROM
	|	Document." + StructureAdditionalProperties.Posting.DocumentMetadata.Name + " AS _Document_
	|WHERE
	|	_Document_.Ref = &DocumentRef");
	
	Query.SetParameter("DocumentRef", DocumentRef);
	
	QueryResult = Query.Execute();

	// Create keys containing document data.
	For each Column In QueryResult.Columns Do
	
		StructureAdditionalProperties.Posting.Insert(Column.Name);
		
	EndDo;

	QueryResultSelection = QueryResult.Choose();
	QueryResultSelection.Next();

	// Fill key values using document data.
	FillPropertyValues(StructureAdditionalProperties.Posting, QueryResultSelection);

EndProcedure // InitializePostingAdditionalProperties()



Function GetRegisterArray(Recorder, DocumentMetadata)

	Query = New Query;
	Query.SetParameter("Recorder", Recorder);

	ArrayRegisters = New Array;

	QueryText  = "";
	TableCounter = 0;
	Inxex  = 0;

	RegistersCount = DocumentMetadata.RegisterRecords.Count();

	For each Register In DocumentMetadata.RegisterRecords Do

		If TableCounter > 0 Then

			QueryText = QueryText + "
			|UNION ALL
			|";

		EndIf;

		TableCounter = TableCounter + 1;
		Inxex  = Inxex  + 1;

		QueryText = QueryText + 
		"
		|SELECT TOP 1
		|""" + Register.Name + """ AS RegisterName
		|
		|FROM " + Register.FullName() + "
		|
		|WHERE Recorder = &Recorder
		|";

		If TableCounter = 256 OR Inxex = RegistersCount Then

			Query.Text  = QueryText;
			QueryText  = "";
			TableCounter = 0;

			If ArrayRegisters.Count() = 0 Then

				ArrayRegisters = Query.Execute().Unload().UnloadColumn("RegisterName");
			Else

				Selection = Query.Execute().Choose();
				While Selection.Next() Do
					ArrayRegisters.Add(Selection.RegisterName);
				EndDo;

			EndIf;
		EndIf;
	EndDo;

	Return ArrayRegisters;

EndFunction // GetRegisterArray()



Procedure PrepareRecordSetsToWrite(StructureObject) Export

	For each RecordSet In StructureObject.RegisterRecords Do

		If TypeOf(RecordSet) = Type("KeyAndValue") Then
			RecordSet = RecordSet.Value;
		EndIf;

		If RecordSet.Count() > 0 Then
			RecordSet.Clear();
		EndIf;

	EndDo;

	ArrayRegisters = GetRegisterArray(StructureObject.Ref, StructureObject.AdditionalProperties.Posting.DocumentMetadata);

	For each RegisterName In ArrayRegisters Do
		StructureObject.RegisterRecords[RegisterName].Write = True;
	EndDo;

EndProcedure





Procedure WriteRecordSets(Object) Export
	Var RegistersToCheck;

	// Registers requiring to calculate record changing tables.
	If Object.AdditionalProperties.Posting.Property("RegistersToCheck", RegistersToCheck) Then

		For each RecordSet In RegistersToCheck Do
		
			If RecordSet.Write Then
				// If Record Set has the Write flag then record changing temporary table should be builded on record set writing.
				RecordSet.AdditionalProperties.Insert("BuildChanges", True);

				If NOT RecordSet.AdditionalProperties.Property("Posting") Then

					RecordSet.AdditionalProperties.Insert("Posting", New Structure);

				EndIf;

				If NOT RecordSet.AdditionalProperties.Posting.Property("StructureTempTables") Then

					RecordSet.AdditionalProperties.Posting.Insert("StructureTempTables", Object.AdditionalProperties.Posting.StructureTempTables);

				EndIf;
			EndIf;
		EndDo;
	EndIf;

	Object.RegisterRecords.Write();

EndProcedure



