Class {
	#name : #GRMSD,
	#superclass : #Object,
	#instVars : [
		'octavePath'
	],
	#category : #GRMSD
}

{ #category : #accessing }
GRMSD >> baseDirectory [
	^ FileLocator localDirectory / 'GRMSD'
]

{ #category : #private }
GRMSD >> checkoutGRMSD [

	(LGitRepository on: self baseDirectory) checkoutHead
]

{ #category : #private }
GRMSD >> cloneGRMSD [

	self baseDirectory ensureDeleteAll.
	(LGitRepository on: self baseDirectory) clone: self gitRepositoryUrl
]

{ #category : #private }
GRMSD >> compileHungarian2Mex [

	^ self compileOctfile:
		  (self hungarian2MexFile parent / self hungarian2basename 
			   withExtension: 'cpp')
]

{ #category : #private }
GRMSD >> compileHungarian3Mex [

	^ self compileOctfile:
		  (self hungarian3MexFile parent / self hungarian3basename 
			   withExtension: 'cpp')
]

{ #category : #private }
GRMSD >> compileOctfile: aFileReference [

	^ (OSSUnixSubprocess new
		   workingDirectory: aFileReference parent absolutePath pathString;
		   command: self mkoctfilePath absolutePath pathString;
		   arguments: { 
				   '-mex'.
				   aFileReference basename };
		   runAndWait;
		   isSuccess)
		  ifTrue: [ self ]
		  ifFalse: [ nil ]
]

{ #category : #defaults }
GRMSD >> defaultOctavePath [

	^ Smalltalk os isWindows
		  ifTrue: [ 
			  | octaveBase |
			  octaveBase := FileLocator C / 'Program Files' / 'GNU Octave'.
			  octaveBase isDirectory
				  ifTrue: [ 
					  (octaveBase allChildrenMatching: 'octave-cli.exe')
						  ifEmpty: [ octaveBase / 'mingw64' / 'bin' / 'octave-cli.exe' ]
						  ifNotEmpty: #max ]
				  ifFalse: [ octaveBase / 'mingw64' / 'bin' / 'octave-cli.exe' ] ]
		  ifFalse: [ FileLocator root / 'usr' / 'local' / 'bin' / 'octave' ]
]

{ #category : #private }
GRMSD >> ensureGRMSD [

	self mainScriptFile isFile ifFalse: [ self ensureLatestGRMSD ].
	self hungarian2MexFile isFile ifFalse: [ 
		self compileHungarian2Mex ifNil: [ ^ nil ] ].
	self hungarian3MexFile isFile ifFalse: [ 
		self compileHungarian3Mex ifNil: [ ^ nil ] ]
]

{ #category : #private }
GRMSD >> ensureLatestGRMSD [

	(self baseDirectory isDirectory and: [ 
		 (self baseDirectory / '.git') isDirectory ])
		ifTrue: [ self checkoutGRMSD ]
		ifFalse: [ self cloneGRMSD ]
]

{ #category : #private }
GRMSD >> ensureOctavePath [

	| path |
	(octavePath notNil and: [ octavePath isExecutable ]) ifTrue: [ 
		^ octavePath ].
	path := self defaultOctavePath.
	path isExecutable ifTrue: [ ^ path ].
	^ UIManager default
		  chooseExistingFileReference: 'Select the Octave interpreter'
		  extensions: #( '' 'exe' )
		  path: FileLocator home
		  preview: false
]

{ #category : #accessing }
GRMSD >> gitRepositoryUrl [
	^ 'https://github.com/ReactionMap/GRMSD.git'
]

{ #category : #private }
GRMSD >> hungarian2MexFile [
	^ self baseDirectory / 'algo' / 'sub' / self hungarian2basename withExtension: 'mex'
]

{ #category : #private }
GRMSD >> hungarian2basename [

	^ 'Hungarian2'
]

{ #category : #private }
GRMSD >> hungarian3MexFile [
	^ self baseDirectory / 'algo' / 'sub' / self hungarian3basename withExtension: 'mex'
]

{ #category : #private }
GRMSD >> hungarian3basename [

	^ 'Hungarian3'
]

{ #category : #accessing }
GRMSD >> mainScriptBasename [

	^ 'grmsd.m'
]

{ #category : #private }
GRMSD >> mainScriptFile [
	^ self baseDirectory / self mainScriptBasename
]

{ #category : #private }
GRMSD >> mkoctfilePath [

	^ self octavePath ifNotNil: [ :path | path parent / 'mkoctfile' ]
]

{ #category : #private }
GRMSD >> newTemporaryFile [

	[ 
	| basename |
	basename := String streamContents: [ :stream | 
		            128 timesRepeat: [ 
			            stream nextPut:
				            '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ' atRandom ] ].
	(self baseDirectory / basename) exists ifFalse: [ 
		^ (self baseDirectory / basename)
			  ensureCreateFile;
			  yourself ] ] repeat
]

{ #category : #accessing }
GRMSD >> octavePath [

	| path |
	(octavePath notNil and: [ octavePath isExecutable ]) ifTrue: [ 
		^ octavePath ].
	path := self defaultOctavePath.
	path isExecutable ifTrue: [ ^ octavePath := path ].
	^ (UIManager default
		   chooseExistingFileReference: 'Select the Octave interpreter'
		   extensions: #( '' 'exe' )
		   path: FileLocator home
		   preview: false) ifNotNil: [ :ref | octavePath := ref ]
]

{ #category : #private }
GRMSD >> queryDirectory [

	self baseDirectory / 'query'
]

{ #category : #services }
GRMSD >> similarityMatrixFrom: aCollectionOfJunMoleculeGeometry [

	aCollectionOfJunMoleculeGeometry ifEmpty: [ ^ Array new ].
	self ensureGRMSD ifNil: [ ^ Array new ].
	self octavePath ifNil: [ ^ Array new ] ifNotNil: [ :octave | 
		| inputFile outputFile |
		inputFile := self newTemporaryFile.
		outputFile := self newTemporaryFile.
		[ 
		'running GRMSD' displayProgressFrom: 0 to: 1 during: [ :progress | 
			inputFile writeStreamDo: [ :stream | 
				| numAtoms |
				numAtoms := aCollectionOfJunMoleculeGeometry anyOne numberOfAtoms.
				3 timesRepeat: [ 
					stream
						nextPutAll: (numAtoms asFloat printShowingDecimalPlaces: 1);
						nextPut: $, ].
				stream
					nextPutAll: numAtoms printString;
					nextPut: Character lf.
				aCollectionOfJunMoleculeGeometry do: [ :geometry | 
					geometry atomsDo: [ :atom | 
						stream
							nextPutAll: (atom position x printShowingDecimalPlaces: 5);
							nextPut: $,;
							nextPutAll: (atom position y printShowingDecimalPlaces: 5);
							nextPut: $,;
							nextPutAll: (atom position z printShowingDecimalPlaces: 5);
							nextPut: $,;
							nextPutAll: atom number printString;
							nextPut: Character lf ] ] ].
			progress value: 0.3.
			(OSSUnixSubprocess new
				 workingDirectory: self baseDirectory absolutePath fullName;
				 command: octave absolutePath fullName;
				 arguments: { 
						 self mainScriptBasename.
						 inputFile basename.
						 inputFile basename.
						 outputFile basename };
				 runAndWait;
				 isSuccess) ifFalse: [ ^ Array new ].
			progress value: 0.7.
			^ Array streamContents: [ :arrayStream | 
				  outputFile readStreamDo: [ :stream | 
					  | count |
					  count := 0.
					  [ stream atEnd ] whileFalse: [ 
						  progress value: 0.7
							  +
							  (0.3 * (count := count + 1)
							   / aCollectionOfJunMoleculeGeometry size).
						  arrayStream nextPut:
							  ((stream nextLine substrings: ',') collect: [ :string | 
								   Float readFrom: string ]) ] ] ] ] ] ensure: [ 
			inputFile ensureDelete.
			outputFile ensureDelete ] ]
]

{ #category : #services }
GRMSD >> similarityTo: aJunMoleculeGeometry withAll: aCollectionOfJunMoleculeGeometry [

	aCollectionOfJunMoleculeGeometry ifEmpty: [ ^ Array new ].
	self ensureGRMSD ifNil: [ ^ Array new ].
	self octavePath ifNil: [ ^ Array new ] ifNotNil: [ :octave | 
		| queryFile targetFile resultFile |
		queryFile := self newTemporaryFile.
		targetFile := self newTemporaryFile.
		resultFile := self newTemporaryFile.
		[ 
		'running GRMSD' displayProgressFrom: 0 to: 1 during: [ :progress | 
			queryFile writeStreamDo: [ :stream | 
				| numAtoms |
				numAtoms := aJunMoleculeGeometry numberOfAtoms.
				3 timesRepeat: [ 
					stream
						nextPutAll: (numAtoms asFloat printShowingDecimalPlaces: 1);
						nextPut: $, ].
				stream
					nextPutAll: numAtoms printString;
					nextPut: Character lf.
				aJunMoleculeGeometry atomsDo: [ :atom | 
					stream
						nextPutAll: (atom position x printShowingDecimalPlaces: 5);
						nextPut: $,;
						nextPutAll: (atom position y printShowingDecimalPlaces: 5);
						nextPut: $,;
						nextPutAll: (atom position z printShowingDecimalPlaces: 5);
						nextPut: $,;
						nextPutAll: atom number printString;
						nextPut: Character lf ] ].
			targetFile writeStreamDo: [ :stream | 
				| numAtoms |
				numAtoms := aCollectionOfJunMoleculeGeometry anyOne numberOfAtoms.
				3 timesRepeat: [ 
					stream
						nextPutAll: (numAtoms asFloat printShowingDecimalPlaces: 1);
						nextPut: $, ].
				stream
					nextPutAll: numAtoms printString;
					nextPut: Character lf.
				aCollectionOfJunMoleculeGeometry do: [ :geometry | 
					geometry atomsDo: [ :atom | 
						stream
							nextPutAll: (atom position x printShowingDecimalPlaces: 5);
							nextPut: $,;
							nextPutAll: (atom position y printShowingDecimalPlaces: 5);
							nextPut: $,;
							nextPutAll: (atom position z printShowingDecimalPlaces: 5);
							nextPut: $,;
							nextPutAll: atom number printString;
							nextPut: Character lf ] ] ].
			progress value: 0.3.
			(OSSUnixSubprocess new
				 workingDirectory: self baseDirectory absolutePath fullName;
				 command: octave absolutePath fullName;
				 arguments: { 
						 self mainScriptBasename.
						 queryFile basename.
						 targetFile basename.
						 resultFile basename };
				 runAndWait;
				 isSuccess) ifFalse: [ ^ Array new ].
			progress value: 0.7.
			^ resultFile readStreamDo: [ :stream | 
				  progress value: 0.9.

				  (stream nextLine substrings: ',') collect: [ :string | 
					  Float readFrom: string ] ] ] ] ensure: [ 
			queryFile ensureDelete.
			targetFile ensureDelete.
			resultFile ensureDelete ] ]
]
