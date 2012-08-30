# GoodGuide Entity Soup Gem

This is the gem for access to the GoodGuide entity soup repository via an underlying RESTful API

## Configuration

In your Gemfile:

    gem 'goodguide-entity_soup'

In your code:

    require 'goodguide/entity_soup'

The entity soup RESTful API endpoint is located by the url property which must be set before the first access of any API object and cannot be changed subsequently.  The default is `http:/entity-soup.goodguide.com`.

    GoodGuide::EntitySoup.url = 'http://localhost:3000'

## Entity Soup Data Model  

The entity soup data model consists of uniquely named catalogs and providers, plus typed entities and attributes, and attribute values.  

In psuedo code:

   Catalog(name: <unique string>, description: <string)
     has_many :attrs
     has_many :entities

   Provider(name: <unique string>)
     has_many :attr_values

   Entity(type: <enum>)
     belongs_to :catalog
     has_many :attr_values

   Attr(name: <unique string>, type: <enum>, entity_type: <enum>, options: <hash>)
     belongs_to :catalog
     has_many :attr_values

   AttrValue(value: <object>) 
     belongs_to :attr
     belongs_to :entity
     belongs_to :provider

   Entity.types = 'Company' | 'Brand' | 'Category' | 'Product' | 'Ingredient'
   Attr.types = 'StringAttr' | 'DerivedAttr' | 'NumericAttr' | 'IntegerAttr' | 'FloatAttr' | 'PercentageAttr' | 'JSONAttr'

In English:

Catalogs contain typed entities such as products, brands, ingredients etc.  A catalog also contains attributes which apply to the entities within the catalog, each attribute is applicable to a specific type of entity and attributes of that entity type are uniquely named.  Therefore a product 'toxocity' attribute is distinct from an ingredient 'toxicty' attribute.  Attributes are also typed so a product 'name' attribute can be a string, but a product 'weight' can be a float with applicable checking on setting and updating of the attribute value at the repository level.  

Every entity within a catalog may have attribute values according to the attributes defined for that entity type within the catalog. If not defined the attribute values simply don't exist and querying for them will return nil.

## API philosophy

### Namespace

The namespace for the API is `GoodGuide::EntitySoup` which is assumed in the examples below for brevity i.e. if you read

    Catalog.find_all

it means

    GoodGuide::EntitySoup::Catalog.find_all

### Identity

All objects within the entity soup have an internal numeric id that is unique for the class of objects to which they apply.  Ids are immutable and are not reused. Catalogs, providers, and attributes also have a name.  Names are mutable but cannot be null.  Catalog and provider names are unique to within their class e.g. you can have a catalog and provider called "Foo", but only one of each.  Attribute names must be unique for the entity type and catalog in which they are definied, e.g. within a catalog you can have a company attribute called 'country' and a product attribute called 'country' and they can have distinct definitions. 

### CRUD

Read objects with `<Class>.find(id)` or `<Class>.find_all(params)`

Create objects with `<Class>.new(<params>)` followed by `<object>.save`

Update objects with `<object>.<field> = <new value>` followed by `<object>.save`

Destroy objects and their dependent objects with `<object>.destroy`

Be careful with destroy it destroys all the dependent objects so destroying a catalog destroys all the entities, attributes and attribute values contained within it.  There is no system to restrict CRUD operations as yet.

TODO: 
* add ACL based access restrictions. 
* add updated and created timestamp access
* add reload
* make find(name) work for catalog, provider (because they have a unique name)
* make Entity#attr_value(name) work

### Error handling

Non-communication errors do not cause exceptions so #find returns nil if the id is invalid, #find_all returns an empty array if the scope does not match any objects.  Saving, updating or destroying an object returns false if there is an error. Errors from an operation on an object are returned via the `errors` method of the object.  E.g.

    c1 = Catalog.new(name: 'foo')
    c1.save
    => true
    c2 = Catalog.new(name: 'foo')
    c2.save  #will fail because catalog names must be unique
    => false
    c2.errors
    => {"name"=>["has already been taken"]} 

Communication and other errors will cause standard Ruby exceptions to be thrown but these are as to be expected "exceptional".

TODO
* implement save! and destroy! to raise exceptions instead of return true or false
            
### Constraining scope 

Constraining the scope of a read operation is done by adding params in the form of a hash (implicitly or explicitly).  For example to find all integer attributes known to product soup use:

    Attr.find(type: 'IntegerAttr')

to further constrain it to integer attributes of product entities use

    Attr.find(type: 'IntegerAttr', entity_type: 'Product')

### Caching

The interface to the entity soup RESTful API supports caching via the Cacher gem.  By default caching is disabled.  To use caching you must implicitly or explicitly configure Cacher with an ActiveSupport::Cache compatible cache instance and explicitly enable it by calling `Cacher.enable!`.  If you are using the Cacher within the `Rails` environment it will implicitly use the Rails configured cache.  To explicitly configure the Cacher cache use something like:

    require 'active_support/cache/dalli_store'
    cache = ActiveSupport::Cache::DalliStore.new(<dalli params>)
    Cacher.configure { |cacher| cacher.cache = cache }
    
then

    Cacher.enable!

Once you have enabled the cacher to read new data directly and repopulate the cache by supplying `break: true` as part of a call's parameter hash.  To bypass the cache entirely disable Cacher again:

     Cacher.disable!

but remember that re-enabling it will give you old cached data. 

TODO:
* how to flush the cache completely?
* auto break cache for relevant objects after write?


## API use

### Catalog

A catalog is uniquely named and exists to contain entities (products, brands, ingredients etc.), definitions of attributes applicable to the entities within it (name, price, toxicity).  The entity soup repository is pre-populated with a catalog named 'GoodGuide' which has an entity soup id of 1.

A catalog requires a unique name (case sensitive string) and optional description accessible via the `#name` and `#description` methods

Get catalogs directly via `Catalog.find`, `Catalog.find_all` or `Catalog.find_by_name`

    catalog = Catalog.find(id) # find one catalog, or nil by its id
    catalog = Catalog.find_by_name(name) # find all catalogs with given name or nil
    catalogs = Catalog.find_all # find all catalogs matching params, or []

The attributes and entities defined within a catalog are accessed via the `#attrs` and `#entities` methods

    attrs = catalog.attrs(<params>) # find all attributes constrained by params if supplied, [] if none
    entities = catalog.entities(<params>)  # find all entities constrained by params if supplied, [] if none

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

If the save fails find the errors via `#errors` for example trying to create a catalog with a duplicate name will fail:

    c = Catalog.new(name: 'Goodguide')
    c.save
    => false
    c.errors
    => {"name"=>["has already been taken"]} 

Update a catalog by assigning its attributes and then saving e.g.

    c = Catalog.new(name: 'Goo')
    c.save
    => true
    c.description 
    => nil
    c.description = 'Another new catalog'
    c.save
    => true

### Provider

A provider is uniquely named and identifies the source of an entity's attribute values.  The existance of a provider supports the notion that attribute values may be multi-valued if there are multiple sources of data, and also partitioning data for privacy reasons, and potentially versioning of data.  The entity soup repository is pre-populated with a provider named 'GoodGuide' which has an entity soup id of 1.

A provider has a unique name (case sensitive string) that must be present when creating.

Access providers directly via `Provider.find`, `Provider.find_all` or `Provider.find_by_name`

    provider = Provider.find(id) # returns a single provider or nil  
    provider = Provider.find_by_name(name)  # returns a single provider or nil
    providers = Provider.find_all # returns all providers matching params, or []

Fields of a proviider are access by the appropriately named method on the object.  For example:

    provider = Provider.find_by_name("GoodGuide")
    puts provider.name
    _=> "GoodGuide"_

Providers are created in the same manner as a catalog using `Provider.new` and `#save` methods.  Providers must be uniquely named.

### Attribute

### Entity

### Attribute Value




