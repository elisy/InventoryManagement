

Procedure AddStructure(Destination, Source) Export

	For each KeyAndValue In Source Do
		Destination.Insert(KeyAndValue.Key, KeyAndValue.Value);
	EndDo;

EndProcedure




