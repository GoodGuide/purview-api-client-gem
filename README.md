# Purview API
# 

This is the gem for access to the Purview API

## Configuration

In your Gemfile:

    gem 'purview_api'

In your code:

    require 'purview_api'

The entity soup RESTful API endpoint and credentials can be set like this:

```Ruby
    PurviewApi.configure do |config|
      config.url = 'http://localhost:3000'
      config.email = 'admin@goodguide.com'
      config.password = 'password'
    end
```

## Testing

This gem supports Rails/ActiveRecord versions < 5 (5.0.0.beta3 currently)

To run tests in a docker container:

    bundle install
    docker-compose run shell
    bin/rake

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

The namespace for the API is `PurviewApi` which is assumed in the examples below for brevity i.e. if you read

    Catalog.find_all

it means

    PurviewApi::Catalog.find_all

### Identity

All objects within the entity soup have an internal numeric id that is unique for the class of objects to which they apply.  Ids are immutable and are not reused. Catalogs, providers, and attributes also have a name.  Names are mutable but cannot be null.  Catalog and provider names are unique to within their class e.g. you can have a catalog and provider called "Foo", but only one of each.  Attribute names must be unique for the entity type and catalog in which they are definied, e.g. within a catalog you can have a company attribute called 'country' and a product attribute called 'country' and they can have distinct definitions.

### CRUD

Read objects with `<Class>.find(id)` or `<Class>.find_all(params)`

Create objects with `<Class>.new(<params>)` followed by `<object>.save`

Update objects with `<object>.<field> = <new value>` followed by `<object>.save`

Destroy objects and their dependent objects with `<object>.destroy`

After saving a new object its `#id` method will return the entity soup numeric id.  Any object that has no id when saved is treated as new and the API will attempt to create it.

Be careful with destroy it destroys all the dependent objects so destroying a catalog destroys all the entities, attributes and attribute values contained within it.  There is no system to restrict CRUD operations as yet.

### Multi-get

Not documented yet - see spec tests


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

### Access control

Not yet implemented


## API use

### Catalog

A catalog is uniquely named and exists to contain entities (products, brands, ingredients etc.), definitions of attributes applicable to the entities within it (name, price, toxicity).  The entity soup repository is pre-populated with a catalog named 'GoodGuide' which has an entity soup id of 1.

A catalog requires a unique name (case sensitive string) and optional description accessible via the `#name` and `#description` methods

#### Read

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

Fields of a category are accessed by the appropriately named method on the object.  For example:

    category = Category.find_by_name("GoodGuide")
    puts category.name
    => "GoodGuide"


#### Create

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

#### Update

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

#### Read

Access providers directly via `Provider.find`, `Provider.find_all` or `Provider.find_by_name`

    provider = Provider.find(id) # returns a single provider or nil
    provider = Provider.find_by_name(name)  # returns a single provider or nil
    providers = Provider.find_all # returns all providers matching params, or []

Fields of a provider are accessed by the appropriately named method on the object.  For example:

    provider = Provider.find_by_name("GoodGuide")
    puts provider.name
    => "GoodGuide"

#### Create and update

Providers are created in the same manner as a catalog using `Provider.new` and `#save` methods.  Providers must be uniquely named.

The name of a provider is mutable and may be changed by assigning the name field and saving it:

    provider.name = 'new name'
    provider.save
    => true

#### Destroy

Destroying a provider will remove it permanently from the system along with all associated attribute values.  Be sure this is what you want to do as there is no protection system as yet to prevent accidental deletion.

Destroy an entity with its `#destroy` method:

    provider.destroy
     => true

### Entity

Entities are contained within a catalog and are typed.  Entities are typed and the set of types available is not hard coded in the entity soup system and therefore could be extended at any time.  Therefore the API gem use a generic class `Entity` to access them and the caller supplies a `type` parameter to select which entities to access and what type new entities are.  The type of an entity is immutable.

#### Entity types
The entity types known to the system are returned by `Entity.types` which returns an array of objects with a name method.  Although there are currently no other fields of an entity type object there may be at a later date (and it might be used to support type specific CRUD).

    Entity.types.collect(&:name)
    => ["Product", "Ingredient", "Brand", "Company", "Category"]


TODO:
* Add an Entity.type_names method
* Reinstate the Entity.Types class now the namespace problem is resolved?
* Add bulk entity creation to catalog class via nested attributes support

#### Read

Get catalogs directly via `Entity.find` and `Entity.find_all`

    entity = Entity.find(id) # find one entity, or nil by its id
    entities = Entity.find_all # find all entities matching params, or []

The only model parameters applicable to an entity query are `type` and `catalog_id` for example:

    Entity.find_all(type: 'Product').count
    => # Number of product entities in the soup, or 0 if none
    Entity.find_all(catalog_id: 1).count
    => # Number of entities of any type in the GoodGuide catalog, or 0 if none
    Entity.find_all(catalog_id: 1, type: 'Product').count
    => # Number of product entities in the GoodGuide catalog, or 0 if none

As previously mentioned catalog specific queries may also be performed via an instance of a catalog.  For example

   c = Catalog.find_by_name("GoodGuide")
   c.entities(type: 'Product')
   => # All product entities in the GoodGuide catalog

#### Create and Update

Create an entity using the `Entity.new` and then `#save` for example

    e = Entity.new(type: 'Product', catalog_id: 1)
    e.save
    => true

The save should always work so long as the catalog is valid (and there are no communications errors).

After creating or reading an entity object there is no valid operation to update it, its type and catalog are fixed.

#### Destroy

Destroying an entity will remove it permanently from the system along with all associated data which means its attribute values.

Destroy an entity with its `#destroy` method:

    entity.destroy
     => true

##### Attribute Values

For convenience the Entity Soup gem always requests all the attribute values defined for an entity using an implicit addition of `include: :attr_values` (this is in the default 'view' for an entity resource).  Using the `#attr_values` method will always get the previously fetched attr_values:

    e.attr_values
    => [<attr_value>]  # or []

To force a reload of the attribute values of an entity, within the bounds of the current caching configuration, use the `#attr_values!` method e.g.

    e.attr_values!
    e.attr_values!(break: true)   # force any API level caching to be ignored

If you need to load entities without the attribute values either explicitly override the `include` paramter or use the `bare` view:

    e = Entity.find(1, include: nil)
    e.attr_values
    -> []
    e = Entity.find(1, view: :bare)
    e.attr_values
    -> []

TODO:
* Add Category.new_entity and Category.new_entities for scoped and bulk entity creation?
* Will we eventually need a move operation to migrate entities between catalogs, or simply allow write to catalog_id?
* We may eventually want to model destruction with a state flag that flags it as deleted (allowing for other things like blacklisting), alternatively use internally defined attributes as meta-data to do this (but requires extra joins to retrieve entities so not good), or relying on Arroyo logging to log deleted data for possible batch recovery.
* Bulk Entity.destroy with or list of ids (applies to other models)

### Attribute

Attributes define properties of given entity types within a catalog - without any attributes an entity is a bare id.  Attributes must be named uniquely for a given entity type and catalog so that an attribute called 'size' in one catalog is distinct from 'size' in another catalog.  Similarly an attribute named 'organic' for an ingredient is different from an attribute named 'organic' for a product.

Only the name of an attribute is mutable after creation, since changing the type and options of an attribute would affect the validation of all its current attribute values.

Note that to avoid clashes with Rails methods and types the attribute class is named Attr, and values of that attribute for an entity are described by the AttrValue class.


#### Attribute types
The attribute types known to the system are returned by `Attr.types` which returns an array of objects with name and options methods.

    Attr.types.collect(&:name)
    => ["DerivedAttr", "NumericAttr", "FloatAttr", "PercentageAttr", "JSONAttr", "StringAttr", "IntegerAttr"]

The options method returns a hash of type specific options as configured for that attribute.  Standard options available for all types include `allow_nil`, `default_value`, and `list`.  So far only DerivedAttr defines an additional type specific option which is `rule`.


#### Read

Access attributes directly via `Attr.find` and `Attr.find_all`:

    attr = Attr.find(id) # returns a single attribute or nil if not found
    attrs = Attr.find_all(params) # returns all attributes matching params, or []

For example if you wish to find attributes with a given name use:

    attrs = Attr.find_all(name: 'foo')

To constrain to a given catalog and entity_type use:

    attrs = Attr.find_all(catalog_id: catalog.id, entity_type: 'Product', name: 'foo')

Using the attrs method of a catalog instance automatically applies the appropriate catalog_id constraint so the above is equivalent to:

    attrs = catalog.attrs(entity_type: 'Product', name: 'foo')

Fields of an attribute are accessed by the appropriately named method on the object.  For example:

    attrs = catalog.attrs(entity_type: 'Product', name: 'foo')
    attrs.first.name
    => 'foo'

You may also introspect on `#type`, `#options`, `#entity_type` and `#catalog_id`.  As previously mentioned the options of an attribute are a Hash which may be introspected via indifferent key names e.g.

    attrs.first.options[:allow_nil]
    => true
    attrs.first.options['allow_nil']
    => true

#### Create and update

Create an attribute using the `Attr.new` and then `#save` on the new object.  When creating an attribute you must supply the attribute type, entity type to which it applies, and catalog in which it exists. The options for the type are optional and will take the default values for the specified type (generally allow_nil=true, default_value=nil and list=false)

    a = Attr.new(name: 'name', type: 'IntegerAttr', entity_type: 'Product', catalog_id: 1)
    a.save
    => true

After creating an attribute only its name can be changed, all other fields are immutable. Changes to them will be silently ignored on save.


#### Destroy

Destroying an attribute will remove it permanently from the system along with all associated data which means attribute values of that type, regardless of provider.  Be sure this is what you want to do.

Destroy an attribute with its `#destroy` method:

    attr.destroy
     => true

TODO:
* Add an Attr.type_names method
* Add find_by_name method?
* Add catalog method?
* Mash the options
* Consider allowing changing of attribute type and options with optional synchronous revalidation of data.
* Consider doing the above by a copy/paste type operation i.e. create a new attribute and do bulk copy of values to the new attribute

### Attribute Value

For convenience the entity soup RESTful API folds in the attribute name into the output for every value, and interpolates attribute names into an attribute id when receiving attribute value data.  Since attribute names are unique for a given entity type this avoids the API user from having to bother with using attribute ids (unless they really want to).  If any attribute id is supplied then this overrides any name that might have been provided.  Remember attr names are mutable so attr_ids are the most persistent way to reference them.

#### Read

Access attribute values directly via `AttrValue.find` and `AttrValue.find_all`:

    attr_value = AttrValue.find(id) # returns a single attribute value or nil if not found
    attr_values = AttrValue.find_all(params) # returns all attribute values matching params, or []

For example if you wish to find attribute values for a given entity use:

    attr_values = AttrValue.find_all(entity_id: entity.id)

Because attribute values belong to a given provider you may find more than one value per attribute and entity.  Supply a specific provider_id to eliminate this problem

To get the value of a specific attribute for an entity you can either provide the attribute id or a name which will be resolved to an attribute id internally

    attr_values = AttrValue.find_all(entity_id: entity.id, name: 'foo')

which assuming the entity is in catalog 1 is equivalent to:

    attr = Attr.find_all(name: 'foo', catalog_id: 1).first
    attr_values = AttrValue.find_all(entity_id: entity.id, attr.id)

For convenience you can also use the `#attr_values` method of an entity instance:

    attr_values = entity.attr_values

However if you do this since they are usually internally cached when the entity was returned you must filter by provider or attribute name manually.


#### Create

You can either create attribute values directly with the standard `AttrValue.new` followed by `#save` or you can attach them directly to an entity via `Entity#update_attr_values`

    a = AttrValue.new(name: 'size, entity_id: entity.id, provider_id: provider.id)
    a.save
    => true
    a.value
    => nil

Note in this case the value starts as nil because it is allowed and no value was specified when creating the attribute value instance.  Override that behavior by specifying the value directly on create:

    a = AttrValue.new(name: 'size, entity_id: entity.id, provider_id: provider.id, value: 42)
    a.save
    => true
    a.value
    => 42

As a convenience if you have an entity use update_attr_values which allows you to set one or more attribute values for an entity.  The attribute values are specified either as a single set of hash params, or an array of hashes.  If the hash contains an id key it is assumed it is updating an existing attribute value, if not it is assumed it is creating a new attribute value. A feature lets you supply an attribute name instead of an id and that will get resolved to attr_id and id values appropriately (however a bug prevents this working correctly if multiple providers supply data for that attribute).

#### Update

After creating only the value field can be modified and saved.  Changes to any other field will be silently ignored.

    a.value = 42
    a.save
    => true

Note that if you set the value to a non-conforming object for that type it may be coerced on save by the API, so the string "42" can be coerced to a number 42.  But the string "asdasd" is not a valid number and will cause a save error

    a.value = "42
    a.save
    => true
    AttrValue.find(a.id).value
    => 42
    a.value = "not a number"
    a.save
    => false
    a.errors
    => {value"=>["not a number is not an integer"]}

Or if you try to define the same attribute value twice with the same entity and provider you'll get an error like:

    {'attr_id'=> ['has already been taken']}


#### Destroy

Destroying an attribute value will remove it permanently from the system along with all associated data which means its attribute values.

Destroy an attribute value with its `#destroy` method:

    attr_value.destroy
     => true


TODO:
* update to attribute values via Entity#save instead of Entity#update_attr_values
* what to do about having to manually filter cached attr_values, remove caching feature or implement include mechanism?
* fix bug of attribute name to id and attr_id resolution where there are multiple providers supplying values for that attribute and entity.

