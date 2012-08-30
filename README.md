# GoodGuide Entity Soup Gem

This is the gem for access to the GoodGuide entity soup API

## Configuration

In your Gemfile:

gem 'goodguide-entity_soup'

In your code:

require 'goodguide/entity_soup'

The entity soup API located by the url property which must be set before the first access.  The default is http:/entity-soup.goodguide.com

GoodGuide::EntitySoup.url = 'http://localhost:3000'

## Model  

The data model consists of catalogs, providers, entities, attributes and attribute values.  They each have a class under the namespace GoodGuide::EntitySoup which is assumed in the examples below ie. Catalog.find_all means GoodGuide::EntitySoup::Catalog.find_all

### API philosophiy

The general philosophy of the API is that objects are found with find or find_all on the appropriate class, created via new() followed by save.  Updating is performed by getting an object, assigning parameters that have changed then saving.  Normal non-communication errors do not cause exceptions e.g find of a non-existant id returns nil, saving a new or updated object returns false if the data is not conforming.  Errors from save or update are returned via the errors method on the object.

### Catalog

A catalog is uniquely named and exists to contain entities (products, brands, ingredients etc.) and attributes applicable to the entities within it (name, price, toxicity).  The entity soup repository is prepopulated with a catalog named 'GoodGuide' which has an entity soup id of 1. 

A catalog requires a unique name (case sensitive string) and description (may be blank).

TODO: add updated and created timestamp access

Access catalogs directly via find, find_all or find_by_name

catalog = Catalog.find(id) # find one catalog, or nil by its id
catalog = Catalog.find_by_name(name) # find all catalogs with given name or nil
catalogs = Catalog.find_all # find all catalogs, or []

Eg. 

catalog = Catalog.find_by_name("GoodGuide")
puts catalog.name
=> "GoodGuide"

The attributes and entities defined within a catalog are accessed via the attrs and entities methods

attrs = catalog.attrs(params = {}) # find all attributes constrained by params if supplied
entities = catalog.entities(params = {})  # find all entities constrained by params if supplied

Eg. to get all product attributes in the GoodGuide catalog:

attrs = Catalog.find(1).attrs(entity_type: 'Product')

To get all string based product attributes in the GoodGuide catalog:

attrs = Catalog.find(1).attrs(type: 'StringAttr', entity_type: 'Product')

To get all products in the GoodGuide catalog:

products = Catalog.find(1).entities(type: 'Product')

Create a new catalog with Catalog.new and then save on the new object:

c = Catalog.new(name: 'Foo', description: 'My new catalog')
c.save
=> true

TODO: implement save! to raise exception

If the save fails find the errors via #errors for example trying to create a catalog with a duplicate name will fail:

c = Catalog.new(name: 'Goodguide')
c.save
=> false
c.errors
=> {"name"=>["has already been taken"]} 

Update a catalog by assigning it's attributes and then saving e.g.

c = Catalog.new(name: 'Goo')
c.save
=> true
c.description 
=> nil
c.description = 'Another new catalog'
c.save
=> true

TODO: add reload method

### Provider

A provider is uniquely named and identifies who provided attribute values.  It supports the notion that attribute values may be multi-valued if there are conflicting sources of data, and also partitioning data for privacy reasons.  The entity soup repository is prepopulated with a provider named 'GoodGuide' which has an entity soup id of 1.

A provider has a unique name (case sensitive string) that must be present when creating.

Access providers directly via find, find_all or find_by_name

provider = Provider.find(id)   
provider = Provider.find_by_name(name) 
providers = Provider.find_all 

Eg. 

provider = Provider.find_by_name("GoodGuide")
puts provider.name
=> "GoodGuide"

Providers are created in the same manner as a catalog using Provider.new and #save methods.  Providers must be uniquely named.

### Attribute

### Entity

### Attribute Value




