# jsonpath
#### Command line JSON data extraction utility

## What/Why

This is an implementation of [JSONPath][1] (like [XPath][2] for [JSON][3]) in
the [OCaml][4] language, intended for use as a command line tool in shell
pipelines. It is **not** meant to be used as a library within other OCaml
programs.

If you're processing JSON in OCaml, check out the functions available in
[Yojson.Basic.Util][5]. That way, you'll have the full power of the language
available, rather than the restricted feature set of `jsonpath`.

Even better: write an ATD file defining the type of your JSON data, and run
[Atdgen][6] to generate code that will convert your JSON data into native OCaml
values like records, lists, and variants. Then the type system will ensure that
your operations are consistent with the structure you defined.

Despite those options, there still may be times when you need to perform a
simple, ad hoc extraction on some JSON records, and you don't want to bother
writing a throwaway program. `jsonpath` is for those times.

## How

### Setup

Building requires OCaml 3.12 or newer with `Findlib`, `Core_kernel`, `Menhir`,
and `Yojson`. Those libraries are available in [OPAM][7]. Then just type make,
which will invoke OCamlbuild and produce the executable `jsonpath`.

### Usage

`jsonpath` takes JSON records on standard input (one per line) and returns a
JSON list of extracted results for each record. The extraction is performed
according to the path specified as a command line argument. For example:

    $ cat sample.json
    { "store": { "name": "Jim's Sporting Goods", "city": "New York", "products": [ { "name": "Basketball", "price": 12.49 }, { "name": "Football", "price": 17.25 } ] } }
    { "store": { "name": "Bob's Electronics", "city": "Los Angeles", "products": [ { "name": "Xbox", "price": 279.99 }, { "name": "TV", "price": 600 } ] } } 

I can extract the price of every product in each store with `jsonpath` like so:

    $ ./jsonpath '$.store.products.*.price' <sample.json 
    [12.49,17.25]
    [279.99,600]

Here `$` represents the root of a JSON record. Applying the path `$` to a JSON
record returns a list containing one result: the whole JSON record. All paths
begin with `$`. You can write this `$` if you want, or you can omit it, since
its presence at the beginning is implicit. `$` is not allowed elsewhere in
paths.

So, starting with a list containing the whole record, `jsonpath` applies the
path components to each element of the list of values returned so far. In our
example:

- `$` begins with one list item, the JSON object.
- `.store` extracts the member of this object named store, another JSON object.
- `.products` extracts the member named products, a JSON array.
- `.*` extracts all the products, in this case two JSON objects.
- `.price` finally returns the member named price, applied to **both** objects.

### Path Syntax

In general, the allowed components of a path are:

- `.*` or `[*]`: Wildcard; returns all elements of a JSON array, or all members
  of a JSON object (just the values, without their keys)
- `.field_name`: Returns the value with that name from a JSON object, or `null`
  if the name is not present. Allowed name characters: `[A-Za-z0-9_]`, not
  starting with a digit.
- `['field_name']`: Alternate syntax allowing arbitrary name characters. Quotes
  are required, but you can use single or double quotes. Inside a quoted name,
  all characters are literal except the quote, which must be escaped with
  backslash. The string will be parsed according to JSON conventions.
- `['field1','field2']`: You can do multiple field names too with the bracket
  syntax, separated by comma.
- `..field_name`: Performs a depth-first search from the current position, collecting
  all values with that name in any sub-object.
- `..['field1','field2']`: You can also search for multiple names. The output
  will have all results for field1 followed by all results for field2.
- `[0]`: Returns the first element of an array. Negative numbers are allowed;
  they index from the end of the array. Indexing out of bounds is an error.
- `[0,1,2]`: Returns the first, second, and third elements.
- `[1:3]`: Slice the array JavaScript-style, returning the second and third
  elements. Either number can be omitted. Numbers outside the array bounds are
  clipped to be within the bounds.

Here are some more examples of paths:

All products in the store: `'$.store.products.*'`

    [{"name":"Basketball","price":12.49},{"name":"Football","price":17.25}]
    [{"name":"Xbox","price":279.99},{"name":"TV","price":600}]

Anything with a name: `'..name'`

    ["Jim's Sporting Goods","Basketball","Football"]
    ["Bob's Electronics","Xbox","TV"]

The last product listed: `'..products[-1]'`

    [{"name":"Football","price":17.25}]
    [{"name":"TV","price":600}]

The city and name of the store, in that order: `'$.store["city","name"]'`

    ["New York","Jim's Sporting Goods"]
    ["Los Angeles","Bob's Electronics"]

### Applying Multiple Paths

If the operation you want cannot be expressed in a single path, you can specify
multiple paths on the command line. `jsonpath` will apply them all and merge
the results together, preserving their order. For instance:

The name of the store, then all its prices:

    $ ./jsonpath '["store"]["name"]' '..price' <sample.json
    ["Jim's Sporting Goods",12.49,17.25]
    ["Bob's Electronics",279.99,600]

## Notes

The [original JSONPath definition][8] includes a few more features:

- Step values in slices, like `[1:10:2]`. Could add these.
- "Expressions of the underlying script language" in parentheses, applied to
  the current node called `@`, like `[(@.length - 1)]`. This will never be
  supported. If you want to write an OCaml program, write an OCaml program.
- Filter expressions, using a restricted set of operators, like `[?(@.price >
  100)]`. I might add support for these, but I'm undecided... the syntax is
  really awful, and if you feel the need for these filters, it may be a good
  point to consider writing a real OCaml program with [Yojson combinators][5]
  or an [ATD][6].

[1]: https://developer.gnome.org/json-glib/unstable/JsonPath.html
[2]: http://www.w3.org/TR/xpath/
[3]: http://www.json.org/
[4]: http://ocaml.org/
[5]: http://mjambon.com/yojson-doc/Yojson.Basic.Util.html
[6]: http://mjambon.com/atdgen/atdgen-manual.html
[7]: http://opam.ocamlpro.com/
[8]: http://goessner.net/articles/JsonPath/
