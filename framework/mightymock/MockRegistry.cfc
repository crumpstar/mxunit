<cfcomponent output="true">
<!---
  You'll see target and args used throughout. target is the method name
  and args is the struct representing the arguments. These are used
  as unique identifiers by hashing their values.
 --->

  <cfscript>

	  matcher = createObject('component','ArgumentMatcher');

	  function setMatcher(m){
      matcher = arguments.m;
	  }
	  
	  this.registry =  queryNew('id,type,method,argid,returns,throws,time,missingMethodArguments');
	  this.invocationRecord =  queryNew('uuid,id,time,status,pattern,method,missingMethodArguments');
	  this.registryDataMap = {};
//08-2012 Added to store the pattern object for invocation records.	  
	  this.registryInvocationPatternMap = {};
	  this.argMap = {};

	  patterns =[
	  '{string}',
	  '{any}',
	  '{date}',
	  '{object}',
	  '{struct}',
	  '{udf}',
	  '{numeric}',
	  '{array}',
	  '{query}',
	  '{xml}',
	  '{boolean}',
	  '{binary}',
	  '{image}',
	  '{*}',
	  '{+}'
	  ];

/*---------------------------------------------------------------*/


  function register(target,args){
    var id = id(target,args);
    queryAddRow(this.registry,1);
    querySetCell(this.registry,'id',id);
    querySetCell(this.registry,'type', argType(args));
    querySetCell(this.registry,'method',target);
    querySetCell(this.registry,'argid',argId(args));
    querySetCell(this.registry,'returns', '');
    //{undefined} //changed 06-09-09 in order to allow simplified syntax
    //for mocks (not stubs) since mocks return void
    querySetCell(this.registry,'throws', '{undefined}');
    querySetCell(this.registry,'time', getTickCount());
    try{
    	querySetCell(this.registry,'missingMethodArguments', args.toString());
    }
		catch(any e){
      querySetCell(this.registry,'missingMethodArguments', 'Component or Object. Cannot convert to String');
    }
    
    this.argMap[id] = args;
    //sets default behavior to null
    updateRegistry(target,args,'returns','');
 }


  function getArgumentMapEntry(target,args){
   var id = id(target,args);
   return this.argMap[id]; //where to catch undefined element exception? client?
  }


  function updateRegistry(target,args,column,value){
    var rowNum = getRowNum(target,args);
    var id = id(target,args);
    var mapId = 'behaviordata_' & id;
    this.registryDataMap[mapId] = value;
    //mr.updateRegistry('foo',args,'throws', 'myexception');
    if(column == 'throws'){
      querySetCell(getRegistry(),column, mapId, rowNum);
      querySetCell(getRegistry(),'returns', '', rowNum);
    }
    else {
      querySetCell(getRegistry(),column, mapId, rowNum);
      querySetCell(getRegistry(),'throws', '{undefined}', rowNum);
    }
  }



  function getReturnsData(target,args){  	    	
    var id = id(target,args);
    return this.registryDataMap['behaviordata_' & id];
  }


 function getRegisteredBehavior(target,args){		
 	var mock = findMock(target,args);
  	if (mock.returns != '') return 'returns';
  	if (mock.throws != '{undefined}') return 'throws';
  	$throw('UnmockedBehaviorException',' "#target#(...)" has not been mocked.',' This happens when you attempt to execute a object.method() that has not been mocked. Make sure you specify returns or throws behavior for this method.');
  }


  function exists(target,args){
   var item = findMock(target,args);
   return item.recordCount > 0;
  }


  function id(target,args){
   return uCase(target) & '_' &  argId(args) ;
  }


  function argId(args){
    var caseInsensitiveArgs = uCase(args.toString());
    return caseInsensitiveArgs.hashCode();
  }


  function argType(args){
   try{
      if (isPattern(args)) return 'pattern';
      return 'litteral';
    }
    catch(coldfusion.runtime.NonArrayException e1){
     $throw(type='InvalidArgumentTypeException',message='arguments not pattern or litteral : @',detail='argType(#args.toString()#)');
    }
    catch(coldfusion.runtime.ScopeCastException e2){
     $throw(type='InvalidArgumentTypeException',message='arguments not pattern or litteral : @',detail='argType(#args.toString()#)');
    }

  }


  function isWildcardPattern(args){
  	var lArgs = (isStruct(args)) ? args[listFirst(structKeyList(args))] : args;  	  
    if(lArgs == '{+}' || lArgs == '{*}') return true;
    return false;
  }


  function isPattern(args){
	 //iterate over	known patterns and see if value exists
	 var i = 1;
	 var isPattern = false;
	 var item = '';
	 for(item in args){
	 	if( patterns.contains(args[item]) ){
	     isPattern =  true;
	    }
	    else {
	     return false;
	    }
	   }
	 return isPattern;
	}
	
	function containsPattern(args){
	 //iterate over	known patterns and see if value exists
	 var i = 1;
	 var containsPattern = false;
	 var item = '';
	 for(item in args){
	 	if( patterns.contains(args[item]) ){
	     containsPattern =  true;
	     break;
	    }
	   }
	 return containsPattern;
	}
	
	


//invocation record smells like another object
 function addInvocationRecord(target,args,status,pattern){ //
    var id = id(target,args);
//08-2012 Add UUID as the id is a hash which is not unique, need a unique id for the deletion of invocation records    
    var uuid = createUUID();
    if (!isdefined("pattern")){pattern = '';}    
    if (!isPattern(args)){    	
    	//no pattern is defined so build a pattern from the argument literals
    	pattern = matcher.buildPatternFromArguments(args);
    }
    //sleep(5);//ensures, fwiw, that the recorded time will be unique
    queryAddRow(this.invocationRecord,1);
    querySetCell(this.invocationRecord,'uuid',uuid);
    querySetCell(this.invocationRecord,'id',id);    
    querySetCell(this.invocationRecord,'time', getTickCount());
    querySetCell(this.invocationRecord,'status',status);
    querySetCell(this.invocationRecord,'pattern',pattern.toString());
    querySetCell(this.invocationRecord,'method',target);
    try{
    	querySetCell(this.invocationRecord,'missingMethodArguments', args.toString());
    }
		catch(any e){
      try{
        querySetCell(this.invocationRecord,'missingMethodArguments', '#getMetaData(args).name#');
      }catch(any ae){
        querySetCell(this.invocationRecord,'missingMethodArguments', 'Component or Object. Cannot convert to String');
      }
    }
    //add the pattern object to the map this will make getting pattern matches for {any} much easier
    this.registryInvocationPatternMap[uuid]=pattern;
    return uuid;
 }
 


  function getRegistry(){
   return this.registry;
  }

  function reset(){
    this.registry =  queryNew('id,type,method,argid,returns,throws,time,missingMethodArguments');
	  this.invocationRecord =  queryNew('uuid,id,time,status,pattern,method,missingMethodArguments');
	  this.registryDataMap={};
	  this.registryInvocationPatternMap={};
	  //08-2012 Added to store the pattern object for invocation records.	  
	  this.registryInvocationPatternMap = {};
	  this.argMap = {};
  }

</cfscript>

<cffunction name="removeInvocationRecordById">
  <cfargument name="invocationRecordId" type="string" />
    <cfquery name="this.invocationRecord" dbtype="query" >
		SELECT * FROM this.invocationRecord
		where uuid <> '#invocationRecordId#'
	</cfquery>
	<cfset structDelete(this.registryInvocationPatternMap, arguments.invocationRecordId) />
</cffunction>

<cffunction name="getInvocationRecords">
  <cfargument name="target" type="string" />
  <cfargument name="args" type="struct" />
  <cfargument name="abortMe" type="boolean" required="false" default="false" />
	<cfset var records = getInvocationRecordsById(target,args) />
	<cfif containsPattern(args)>	
	 <cfif isWildcardPattern(args)>
		<cfset patternRecords = getInvocationRecordsByTarget(target, arguments.args[listFirst(structKeyList(arguments.args))]) />
	<cfelse>
		<cfset patternRecords = getInvocationRecordsByPattern(target,args, abortMe) />		  	
	 </cfif>	
		<cfquery name="records" dbtype="query" >
			SELECT * FROM records
			UNION
			SELECT * from patternRecords
		</cfquery>
		<cfquery name="records" dbtype="query" >
			SELECT DISTINCT * FROM records
		</cfquery>  
	</cfif>  	
	<cfreturn records />
</cffunction>

<cffunction name="getInvocationRecordsById">
  <cfargument name="target" type="string" />
  <cfargument name="args" type="struct" />
	<cfset var lid = id(target,args) />
  <cfset var q = '' />
	<cfquery name="q" dbtype="query">
	 select *
	 from this.invocationRecord
	 where id = '#lid#'
	</cfquery>
	<cfreturn q>
</cffunction>


<cffunction name="getInvocationRecordsByPattern">
  <cfargument name="target" type="string" />
  <cfargument name="args" type="struct" />
  <cfargument name="abortMe" type="boolean" required="false" default="false" />
  <cfset var lid = id(target,args) />
  <cfset var targetRecords =  getInvocationRecordsByTarget(arguments.target) />
  <cfset var anyPatternMatchedRecordIds = '' />
  <cfset var patternCorrected = '' />
  <cfset var argsRegex = '' />
  <cfset var q = '' />
		<!--- the pattern contains an any lets do the nasty business of matching them 		
		<cfset targetRecords = getInvocationRecordsByTarget(arguments.target) />
		--->
		<cfif abortMe>
		<cfdump var="#this.registryInvocationPatternMap#" />
		</cfif>
		<cfloop query="targetRecords">
			<!--- find any matching based on regex --->
			<cftry>
				<cfif abortMe>
				<cfdump var="#arguments.args#" />
				<cfdump var="#this.registryInvocationPatternMap[targetRecords.uuid]#" />				
				<cfdump var="loop" />
				</cfif>
				<cfif matcher.match(arguments.args, this.registryInvocationPatternMap[targetRecords.uuid])>
					<cfset anyPatternMatchedRecordIds = listAppend(anyPatternMatchedRecordIds, targetRecords.id) />
				</cfif>				
			<cfcatch type="MismatchedArgumentNumberException">
				<!--- do nothing no big deal because its entirely possible that an invocation doesn't match the pattern
					for example pattern {1={any}} but the invocation was actually {1={string},2={string}} 
					 --->
					 <cfif abortMe>
					 <cfdump var="#cfcatch#" />
					 </cfif>
			</cfcatch>
			<cfcatch type="MismatchedArgumentPatternException">
				<!--- do nothing no big deal because its entirely possible that an invocation doesn't match the pattern
					for example pattern {1={any}} but the invocation was actually {1={string},2={string}} 
					 --->
					 <cfif abortMe>
					 <cfdump var="#cfcatch#" />
					 </cfif>
			</cfcatch>
			<cfcatch type="NamedArgumentConflictException">
				<!--- do nothing no big deal because its entirely possible that an invocation doesn't match the pattern
					for example pattern {1={any}} but the invocation was actually {1={string},2={string}} 
					 --->
					<cfif abortMe>
					 <cfdump var="#cfcatch#" />
					 </cfif>
			</cfcatch>
			
			</cftry>			
		</cfloop> 
		
			<cfquery name="q" dbtype="query" >
				SELECT * FROM targetRecords
				WHERE id in ('#listChangeDelims(anyPatternMatchedRecordIds, "','")#');
			</cfquery> 
			<cfquery name="q" dbtype="query" >
				SELECT DISTINCT * FROM q
			</cfquery>
			
		
		
	<cfif arguments.abortMe>
		<cfdump var="#anyPatternMatchedRecordIds#" />
		<cfdump var="#q#" />
		<cfdump var="#argsRegex#" />
		<cfabort />
	</cfif>
	<cfreturn q>
</cffunction>

<cffunction name="getInvocationRecordsByTarget">
  <cfargument name="target" type="string" />
  <cfargument name="wildCard" type="string" required="false" default="" hint="pass in {+} to get only invocations that where called with one or more arguments any other value will return all invocations for the method"/>
  <cfset var q = '' />
	<cfquery name="q" dbtype="query">
	 select *
	 from this.invocationRecord
	 where method = '#target#'
	 <cfif arguments.wildCard EQ '{+}'>
	 	 AND pattern <> '{}'
	 </cfif>
	</cfquery>
	<cfreturn q>
</cffunction>


<cffunction name="findMock">
  <cfargument name="target" type="string" />
  <cfargument name="args" type="struct" />
  <cfargument name="pattern" type="struct" />
	<cfset var lid = id(target,args) />
  <cfset var q = '' />
	<cfquery name="q" dbtype="query" maxrows="1">
	 select *
	 from this.registry
	 where id = '#lid#'
	</cfquery>
	<cfif structKeyExists(arguments, 'pattern') and q.recordCount EQ 0>
		<cfset lid = id(target,pattern) />
		<cfquery name="q" dbtype="query" maxrows="1">
		 select *
		 from this.registry
		 where id = '#lid#'
		</cfquery>	
	</cfif>	
	<cfreturn q>
</cffunction>


<!---
  This might be a good place to record or buffer the literal which
  can be used later in the invocation record. and subsequently cleared.
 --->
<cffunction name="findByPattern" hint="Given a method name, looks up any assocatied patterns and returns id's of the matched pattern">
    <cfargument name="target" type="string" />
    <cfargument name="args" type="struct" />
    <cfset var q = '' />
	<cfset var lid = id(target,args) />
	  <cfset var patternArgs =  {} />
    <cfset var isMatch = false />
    <cfset var behavior = {} />
    <cfquery name="q" dbtype="query">
		  select *
		  from this.registry
		  where type='pattern' and method = '#target#'
    </cfquery>
  <cfloop query="q">
    <cfset patternArgs = this.argMap[q.id] />
    <cftry>
      <cfset isMatch = matcher.match(args,patternArgs) />
      <cfif isMatch>
       <cfset behavior['missingMethodName'] = q.method />
       <cfset behavior['missingMethodArguments']   = patternArgs />
       <cfreturn behavior />
      </cfif>
      <cfcatch type="MismatchedArgumentNumberException"></cfcatch>
      <cfcatch type="MismatchedArgumentPatternException"></cfcatch>
    </cftry>
  </cfloop>
  <cfset $throw('MismatchedArgumentPatternException',
                'An argument pattern could not be found for this litteral argument collection.',
                '#args.toString()#')/>
</cffunction>

<cffunction name="getRowNum">
  <cfargument name="target" type="string" />
	<cfargument name="args" type="struct" />
  <cfset var q = '' />
	<cfset var id = id(target,args)>
	<cfset var rownum = 0 />
	<cfquery name="q" dbtype="query">
	 select *
	 from this.registry
	</cfquery>
	<cfoutput query="q">
	 <cfif q.id eq id>
		 <cfreturn q.currentRow>
		</cfif>
	</cfoutput>
	<cfset $throw('InvalidRegistryEntryException','No entry exists for #id#. ', 'Make sure item is correctly registered.') />
</cffunction>

<cffunction name="$throw">
	<cfargument name="type" required="false" default="mxunit.exception.AssertionFailedError">
	<cfargument name="message" required="false" default="failed behaviour">
	<cfargument name="detail" required="false" default="Details details ...">
  <cfthrow type="#arguments.type#" message="#arguments.message#" detail="#arguments.detail#" />
</cffunction>
</cfcomponent>