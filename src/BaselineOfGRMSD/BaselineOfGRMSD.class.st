Class {
	#name : #BaselineOfGRMSD,
	#superclass : #BaselineOf,
	#category : #BaselineOfGRMSD
}

{ #category : #baselines }
BaselineOfGRMSD >> baseline: spec [

	<baseline>
	spec for: #common do: [ 
		spec
			baseline: 'OSSubprocess' with: [ 
				spec repository:
						'github://pharo-contributions/OSSubprocess/repository' ];
			baseline: 'Jun' with: [ 
				spec
					loads: 'Chemistry-Full';
					repository: 'github://tomooda/Jun:main/repository' ].
		spec
			package: 'GRMSD'
			with: [ spec requires: #( 'OSSubprocess' 'Jun' ) ].

		spec group: 'default' with: #( 'GRMSD' ) ]
]
