# bcp47

This project is a subset implementation of the BCP47 spec.

Currently only the language and region subtags are supported - there is no plan to implement the others.

## Languages

Languages are defined by **ISO 639-1 alpha-2**; that is the 2 letter lowercase language code.

These have been augmented to contain the plural rule names and the language's direction.

	> BCP47::Language.find('ru')
	
	=> #<BCP47::Language:0x007fe2ba43db50
			@plural_rule_names=["one", "few", "many", "other"],
			@direction="ltr",
			@code="ru",
			@name="Russian">

## Regions

Regions are defined by **ISO 3166-1**; that is the 2 letter uppercase region code.

	> BCP47::Region.find('MX')
	
	=> #<BCP47::Region:0x007fe2ba070e50
			@code="MX",
			@name="Mexico"> 
	
## Tags

The combination of a language and a region is called a Tag ::

	> BCP47::Tag.new('pt-BR')

	 => #<BCP47::Tag:0x007fe2bb005b90 @code="pt-BR",
	 	 	@language=#<BCP47::Language:0x007fe2ba256918
	 			@plural_rule_names=["one", "other"],
			  	@direction="ltr",
		  		@code="pt",
	  			@name="Portuguese">,
	 		@region=#<BCP47::Region:0x007fe2ba412e28
				@code="BR",
				@name="Brazil">> 

## Contributing to bcp47
 
* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet.
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it.
* Fork the project.
* Start a feature/bugfix branch.
* Commit and push until you are happy with your contribution.
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

#### Copyright

Copyright (c) 2012 Christopher Dell. See LICENSE.txt for further details.

